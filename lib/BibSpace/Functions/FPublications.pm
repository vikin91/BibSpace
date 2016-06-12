package BibSpace::Functions::FPublications;

use 5.010; #because of ~~
use strict;
use warnings;
use Data::Dumper;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use DBI;

use BibSpace::Controller::Core;
use BibSpace::Model::MEntry;

use Exporter;
our @ISA= qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
    Fget_single_publication
    Ffix_months
    Fbibtex_key_exists
    Fget_html_preview
    Fget_entry_id_for_bibtex_key
    Fhandle_add_edit_publication
    Fget_publications_main_hashed_args_only
    Fget_publications_main_hashed_args
    Fget_publications_core_from_array_ref
    Fget_publications_core_from_set
    Fget_publications_core
    Fclean_ugly_bibtex_fields_for_all_entries
    );

####################################################################################
sub Fget_single_publication {
    my $dbh = shift;
    my $id = shift;

    say "CALL: FPUblications::get_single_publication id $id";

    my $mentry = MEntry->static_get($dbh, $id);
    return $mentry;
};
####################################################################################
sub Ffix_months {
    my $dbh = shift;

    say "CALL: FPUblications::fix_months";

    my @objs = MEntry->static_all($dbh);
    my $num_checks = 0;
    my $num_fixes = 0;

    for my $o (@objs){
        # say " checking fix month $num_checks";
        $num_fixes = $num_fixes + $o->fix_month();
        $o->save($dbh);
        $num_checks = $num_checks + 1;
    }

    return ($num_checks, $num_fixes);
};
####################################################################################
sub Fbibtex_key_exists {
    my $dbh = shift;
    my $key = shift;

    my @ary = $dbh->selectrow_array("SELECT COUNT(*) FROM Entry WHERE bibtex_key = ?", undef, $key);
    my $key_exists = $ary[0];
    return $key_exists;
};
####################################################################################
sub Fget_html_preview {
    my $new_bib = shift;
    
    my $e_dummy = MEntry->new();
    $e_dummy->{bib} = $new_bib;
    $e_dummy->populate_from_bib();
    my ($html, $html_bib) = $e_dummy->generate_html();
    return $html, $html_bib;
};
####################################################################################
sub Fget_entry_id_for_bibtex_key{
   my $dbh = shift;
   my $key = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Entry WHERE bibtex_key=?" );     
   $sth->execute($key);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id};
   return -1 unless defined $id;
   print "ID = -1 for key $key\n" unless defined $id;
   return $id;
};

####################################################################################
sub Fhandle_add_edit_publication {
  my ($dbh, $new_bib, $id, $action) = @_;

  say "CALL Fhandle_add_edit_publication: id $id action $action";

  # var that will be returned
  my $mentry; # the entry object
  my $status_code; # the status code
  my $existing_id; # id of exiting enrty having the same bibtex key
  my $added_under_id = -1;

  # $action => 'save'
  # $action => 'preview' i
  # $action => 'check_key'


  my $status_code_str = 'PREVIEW';

  # status_codes
  # -2 => PREVIEW
  # -1 => ERR_BIBTEX 
  # 0 => ADD_OK
  # 1 => EDIT_OK 
  # 2 => KEY_OK
  # 3 => KEY_TAKEN

  my $e;
  $e = MEntry->new() if $id < 0;
  $e = MEntry->static_get($dbh, $id) if $id > 0;
  $e = MEntry->new() if !defined $e; # by wrong id, we create new object. Should never happen
  $e->{id} = $id;
  $e->{bib} = $new_bib;
  my $bibtex_code_valid = $e->populate_from_bib();

  # We check Bibtex errors for all requests
  if($bibtex_code_valid == 0){
    $status_code_str = 'ERR_BIBTEX';
    return ($e, $status_code_str, -1, -1); 
  }

  $existing_id = Fget_entry_id_for_bibtex_key($dbh, $e->{bibtex_key});
  
  if($id > 0 and $existing_id == $e->{id}){ # editing mode, key ok, the user will update entry but not the key
    $status_code_str = 'KEY_OK';
  }
  elsif($id < 0 and $existing_id < 0){ # adding mode and key ok
    $status_code_str = 'KEY_OK';
  }
  elsif($id > 0 and $existing_id < 0){ # editing mode, key ok, the user will update the entry including the key 
    $status_code_str = 'KEY_OK';
  }
  else{
    $status_code_str = 'KEY_TAKEN';
    $e->generate_html();
    return ($e, $status_code_str, $existing_id, -1);
  }
  if($action eq 'check_key'){ # user wanted only to check key - we give him the preview as well
    $e->generate_html();
    $e->populate_from_bib();
    return ($e, $status_code_str, $existing_id, -1);
  }

  if($action eq 'preview'){ # user wanted only to check key and get preview
    $status_code_str = 'PREVIEW';
    $e->generate_html();
    $e->populate_from_bib();
    return ($e, $status_code_str, $existing_id, -1); 
  }

  if($action eq 'save'){    
    if($id > 0){ #editing
      $status_code_str = 'EDIT_OK';
    }
    else{ #adding
      $status_code_str = 'ADD_OK';
    }
    
    $e->populate_from_bib();
    $e->regenerate_html($dbh);
    
    $e->postprocess_updated($dbh); # this saves 
    $added_under_id = $e->{id};
  }
  else{
    warn "Fhandle_add_edit_publication action $action does not match the known actions: save, preview, check_key.";
  } # action save
  return ($e, $status_code_str, $existing_id, $added_under_id); 
};
##################################################################
####################################################################################
####################################################################################
sub Fget_publications_main_hashed_args_only {  # this function ignores the parameters given in the $self object
    my ($self, $args) = @_;
    return Fget_publications_core($self, 
                                 $args->{author},
                                 $args->{year},
                                 $args->{bibtex_type},
                                 $args->{entry_type},
                                 $args->{tag},
                                 $args->{team},
                                 $args->{visible},
                                 $args->{permalink},
                                 $args->{hidden},
                                 );
}
####################################################################################
sub Fget_publications_main_hashed_args { #
    my ($self, $args) = @_;

    return Fget_publications_core($self, 
                                 $args->{author} || $self->param('author') || undef, 
                                 $args->{year} || $self->param('year') || undef,
                                 $args->{bibtex_type} || $self->param('bibtex_type') || undef,
                                 $args->{entry_type} || $self->param('entry_type') || undef,
                                 $args->{tag} || $self->param('tag') || undef,
                                 $args->{team} || $self->param('team') || undef,
                                 $args->{visible} || 0,
                                 $args->{permalink} || $self->param('permalink') || undef,
                                 $args->{hidden},
                                 );
}

####################################################################################
sub Fget_publications_core_from_array_ref {
  say "CALL: Fget_publications_core_from_array. This function could be removed...";
    my $self = shift;
    my $array_ref = shift;
    my $sort = shift;
    $sort = 1 unless defined $sort;

    my $dbh = $self->app->db;

    my $keep_order = 0;
    $keep_order = 1 if $sort == 0;

    my @objs = MEntry->static_get_from_id_array($dbh, $array_ref, $keep_order);
    # say "Fget_publications_core_from_array_ref array_ref: ".Dumper $array_ref;
    # say "Fget_publications_core_from_array_ref results: ".Dumper \@objs;
    return @objs;
}
########################################################################################################################################################################
sub Fget_publications_core_from_set {
  say "CALL: Fget_publications_core_from_set";
    my $self = shift;
    my $set = shift;
    
    my $dbh = $self->app->db;
    my @array = $set->elements;

    # array may be empty here!

    return Fget_publications_core_from_array_ref($self, \@array);
}
####################################################################################

sub Fget_publications_core{
    my $self = shift;
    my $author = shift;
    my $year = shift;
    my $bibtex_type = shift;
    my $entry_type = shift;
    my $tag = shift;
    my $team = shift;
    my $visible = shift || 0;
    my $permalink = shift;
    my $hidden = shift;

    # say "CALL: get_publications_core author $author tag $tag";

    my $dbh = $self->app->db;

    my $teamid = BibSpace::Controller::Core::get_team_id($dbh, $team) || undef; # gives -1 if $team contains id
    $teamid = $team if defined $teamid and $teamid eq -1; # so team = teamid

    my $master_id = BibSpace::Controller::Core::get_master_id_for_master($dbh, $author) || undef;
    if($master_id == -1){
      $master_id = $author; # it means that author was given as master_id and not as master name
    }


    my $tagid = BibSpace::Controller::Core::get_tag_id($dbh, $tag) || undef;
    if($tagid == -1){
      $tagid = $tag; # it means that tag was given as tag_id and not as tag name
    }
    
    $teamid = undef unless defined $team;
    $master_id = undef unless defined $author;
    $tagid = undef unless defined $tag; 

    my @objs = MEntry->static_get_filter($dbh, 
                                         $master_id, 
                                         $year, 
                                         $bibtex_type, 
                                         $entry_type, 
                                         $tagid, 
                                         $teamid, 
                                         $visible, 
                                         $permalink, 
                                         $hidden);
    return @objs;
}
####################################################################################
sub Fclean_ugly_bibtex_fields_for_all_entries {
  my $dbh = shift; 
    
  my @entries = MEntry->static_all($dbh);
  my $num_del = 0;
  foreach my $e (@entries){
    $num_del = $num_del + $e->clean_ugly_bibtex_fields($dbh);
  }
  return $num_del;
};
####################################################################################
