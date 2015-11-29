package Hex64Publications::Core;

use Data::Dumper;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use File::Slurp;
use File::Find;
use Time::Piece;
use 5.010; #because of ~~
use Cwd;
use strict;
use warnings;


use Exporter;
our @ISA= qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw( 
    create_user_id
    generate_html_for_key
    generate_html_for_id
    tune_html
    get_author_id_for_uid
    get_author_id_for_master
    get_master_for_id
    get_html_for_bib
    get_teams_of_author
    get_team_members
    add_team_for_author
    remove_team_for_author
    uniq
    get_entry_id
    get_entry_key
    get_entry_title
    get_team_for_id
    get_team_id
    get_tag_id
    get_master_id_for_uid
    get_master_id_for_master
    get_master_id_for_author_id
    get_tags_for_entry
    get_tag_name_for_id
    get_all_tags
    get_all_teams
    get_all_our_types
    get_all_bibtex_types
    get_all_existing_bibtex_types
    get_types_for_landing_page
    get_bibtex_types_for_our_type
    get_description_for_our_type
    get_type_description
    get_landing_for_our_type
    toggle_landing_for_our_type
    get_all_entry_ids
    get_all_non_hidden_entry_ids
    nohtml
    delete_entry_by_id
    get_author_ids_for_tag_id
    get_author_ids_for_tag_id_and_team
    get_tags_for_author
    get_tags_for_team
    add_field_to_bibtex_code
    has_bibtex_field
    clean_tag_name
    get_dir_size
    get_visibility_for_id
    postprocess_all_entries_after_author_uids_change
    postprocess_all_entries_after_author_uids_change_w_creating_authors
    after_edit_process_authors
    get_html_for_entry_id
    get_exceptions_for_entry_id
    get_year_for_entry_id
    get_backup_filename
    get_backup_creation_time
    get_backup_age_in_days
    clean_ugly_bibtex_fileds
    clean_ugly_bibtex_fileds_for_all_entries
    do_delete_backup
    do_delete_broken_or_old_backup
    prepare_backup_table
    get_month_numeric
    get_current_year
    get_current_month
    get_number_of_publications_in_year
    get_publications_main_hashed_args
    get_publications_main
    get_publications_core_from_array
    get_publications_core_from_set
    get_publications_core
    get_single_publication
    );



our $bibtex2html_tmp_dir = "./tmp";
####################################################################################
sub get_number_of_publications_in_year{
  say "CALL: get_number_of_publications_in_year";
    my $self = shift;
    my $year = shift;

    my @objs = get_publications_main($self, undef, $year, undef, undef, undef, undef, 0, undef);
    return scalar @objs;
}
####################################################################################
sub get_publications_main_hashed_args{
    my ($self, $args) = @_;

    return get_publications_core($self, 
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
sub get_publications_main{
  say "CALL: get_publications_main - calling this function without arguments hash is deprecated! Call get_publications_main_hashed_args instead!";
    my $self = shift;

    return undef;

    my $author = shift || $self->param('author') || undef;
    my $year = shift || $self->param('year') || undef;
    my $bibtex_type = shift || $self->param('bibtex_type') || undef;
    my $entry_type = shift || $self->param('entry_type') || undef;
    my $tag = shift || $self->param('tag') || undef;
    my $team = shift || $self->param('team') || undef;
    my $permalink = shift || $self->param('permalink') || undef;
    my $hidden = shift || undef;
    return get_publications_core($self, $author, $year, $bibtex_type, $entry_type, $tag, $team, 0, $permalink, $hidden);
}
####################################################################################
sub get_publications_core_from_array{
  say "CALL: get_publications_core_from_array";
    my $self = shift;
    my $array = shift;
    my $sort = shift;

    $sort = 1 unless defined $sort;

    my $dbh = $self->app->db;

    my @objs = EntryObj->getFromArray($dbh, $array, $sort);
    return @objs;

}
########################################################################################################################################################################
sub get_publications_core_from_set{
  say "CALL: get_publications_core_from_set";
    my $self = shift;
    my $set = shift;
    
    my $dbh = $self->app->db;
    my @array;

    while (defined(my $e = $set->each)) {
        push @array, $e;
    }

    # array may be empty here!

    return get_publications_core_from_array($self, \@array);
}
####################################################################################

sub get_publications_core{
  # say "CALL: get_publications_core";
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

    my $dbh = $self->app->db;

    my $teamid = get_team_id($dbh, $team) || undef;
    my $master_id = get_master_id_for_master($dbh, $author) || undef;
    if($master_id == -1){
      $master_id = $author; # it means that author was given as master_id and not as master name
    }


    my $tagid = get_tag_id($dbh, $tag) || undef;
    if($tagid == -1){
      $tagid = $tag; # it means that tag was given as tag_id and not as tag name
    }
    
    $teamid = undef unless defined $team;
    $master_id = undef unless defined $author;
    $tagid = undef unless defined $tag;
    

    my @objs = EntryObj->getByFilter($dbh, $master_id, $year, $bibtex_type, $entry_type, $tagid, $teamid, $visible, $permalink, $hidden);
    return @objs;
}
####################################################################################
sub get_single_publication {
    my $self = shift;
    my $eid = shift;
    my $hidden = shift;
    my $dbh = $self->app->db;

    say "CALL: get_single_publication. Hidden=$hidden";


    my @objs;
    my $obj = EntryObj->new({id => $eid});
    $obj->initFromDB($dbh);
    if(defined $hidden and $obj->isHidden()==$hidden){
        push @objs, $obj; 
    }
    elsif(!defined $hidden){
        push @objs, $obj; 
    }

    return @objs;
};
####################################################################################
# ################################################################################
# sub getTagTypeName{
#     my $self = shift;
#     my $type = shift || 1;

#     my $dbh = $self->app->db;

#     my $sth = $dbh->prepare("SELECT name FROM TagType WHERE id = ?");
#     $sth->execute($type);
#     my $row = $sth->fetchrow_hashref();
#     return $row->{name};# || "not found";
# }
################################################################################
sub get_current_month {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  return $mon;
}
################################################################################
sub get_current_year {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

  return $year+1900;
}
################################################################################
sub get_month_numeric {
    my $str = shift;
    $str = lc($str);
    $_ = $str;

    return 1 if /jan/ or /january/ or /januar/ or /1/ or /01/;
    return 2 if /feb/ or /february/ or /februar/ or /2/ or /02/;
    return 3 if /mar/ or /march/  or /3/ or /03/;
    return 4 if /apr/ or /april/  or /4/ or /04/;
    return 5 if /may/ or /mai/ or /maj/ or /5/ or /05/;
    return 6 if /jun/ or /june/ or /juni/ or /6/ or /06/;
    return 7 if /jul/ or /july/ or /juli/ or /7/ or /07/;
    return 8 if /aug/ or /august/ or /8/ or /08/;
    return 9 if /sep/ or /september/ or /sept/ or /9/ or /09/;
    return 10 if /oct/ or /october/ or /oktober/ or /10/ or /010/;
    return 11 if /nov/ or /november/ or /11/ or /011/;
    return 12 if /dec/ or /december/ or /dezember/ or /12/ or /012/;

    return 0;
}
################################################################################
sub clean_tag_name {
   my $tag = shift;
   $tag =~ s/^\s+|\s+$//g;
   $tag =~ s/\s/_/g;
   $tag =~ s/\./_/g;
   $tag =~ s/_$//g;
   $tag =~ s/\///g;
   $tag =~ s/\?/_/g;

   return ucfirst($tag);
}
################################################################################
sub uniq {
    return keys %{{ map { $_ => 1 } @_ }};
}
################################################################################
sub nohtml{
   my $key = shift;
   my $type = shift;
   return "<span class=\"label label-danger\">NO HTML </span><span class=\"label label-default\">($type) $key</span>" . "<BR>";
}
####################################################################################
sub do_delete_backup{   # added 22.08.14
    my $self = shift;
    my $id = shift;
    my $backup_dbh = $self->app->backup_db;

    prepare_backup_table($backup_dbh);

    my $sth = $backup_dbh->prepare("SELECT filename FROM Backup WHERE id = ?");
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();
    my $fname = $row->{filename};

    my $sth2 = $backup_dbh->prepare("DELETE FROM Backup WHERE id=?");
    $sth2->execute($id);

    $self->write_log("destroying backup id $id");

    unlink $fname; 

    $self->redirect_to("/backup");
}
####################################################################################
sub do_delete_broken_or_old_backup {   # added 22.08.14
    my $self = shift;
    my $backup_dbh = $self->app->backup_db;

    prepare_backup_table($backup_dbh);

    my $sth = $backup_dbh->prepare("SELECT id, creation_time, filename FROM Backup ORDER BY creation_time DESC");
    $sth->execute();

    my $backup_age_in_days_to_delete_automatically = $self->config->{backup_age_in_days_to_delete_automatically};
    my $file_age_counter = 1; # 1 (one) backup will not be deleted for files older than $backup_age_in_days_to_delete


    my @ids;
    my @fnames;
    # $exists = 1 if -e $fname;

    while(my $row = $sth->fetchrow_hashref()) {
        my $id = $row->{id};
        my $fname = $row->{filename};

        push @ids, $id;
        push @fnames, $fname;
    }

    my $i = 0;
    foreach my $id (@ids){
        my $b_age = get_backup_age_in_days($self, $id);
        my $fname = $fnames[$i];
        my $exists = 0;
        $exists = 1 if -e $fname;

        if($exists == 0){
            # CAN DELETE
            do_delete_backup($self, $id);
        }
        else{   # file exists
            if($b_age > $backup_age_in_days_to_delete_automatically){
                # we delete only automatically-created backups
                if($fname =~ /cron/){
                    if($file_age_counter >0){   # we leave some untouched
                        $file_age_counter = $file_age_counter - 1;
                    }
                    else{   # rest should be deleted
                        do_delete_backup($self, $id);
                    }
                }
            }
        }
        $i = $i+1;
    }
}
####################################################################################
sub prepare_backup_table{
   my $backup_dbh = shift;


   $backup_dbh->do("CREATE TABLE IF NOT EXISTS Backup(
      id INTEGER PRIMARY KEY,
      creation_time INTEGER,
      filename TEXT,
      UNIQUE(filename) ON CONFLICT REPLACE
      )");

    # FOR THE FUTURE!!
    $backup_dbh->do("CREATE TABLE IF NOT EXISTS User(
      id INTEGER PRIMARY KEY,
      login TEXT NOT NULL,
      email TEXT,
      passwd TEXT NOT NULL,
      name TEXT,
      rank INTEGER DEFAULT 0,
      master_id INTEGER DEFAULT 0,
      tennant_id INTEGER DEFAULT 0
      )");
};
##################################################################
sub postprocess_all_entries_after_author_uids_change{  # assigns papers to their authors ONLY. No tags, no regeneration.
    my $self = shift;

    $self->write_log("reassing papers to authors started");

    my $qry = "SELECT DISTINCT bibtex_key, id, bib FROM Entry";
    my $sth = $self->app->db->prepare( $qry );  
    $sth->execute(); 

    my @bibs;
    while(my $row = $sth->fetchrow_hashref()) {
        my $bib = $row->{bib};
        my $key = $row->{bibtex_key};
        my $id = $row->{id};

        push @bibs, $bib;
    }
    $sth->finish();

    foreach my $entry_str(@bibs){
        my $entry_obj = new Text::BibTeX::Entry();
        $entry_obj->parse_s($entry_str);
    
        assign_entry_to_existing_authors_no_add($self, $entry_obj);
    }

    $self->write_log("reassing papers to authors finished");
};

##################################################################
sub postprocess_all_entries_after_author_uids_change_w_creating_authors{  # assigns papers to their authors ONLY. No tags, no regeneration. Not existing authors will be created
    my $self = shift;

    $self->write_log("reassigning papers to authors (with authors creation) started");

    my $qry = "SELECT DISTINCT bibtex_key, id, bib FROM Entry";
    my $sth = $self->app->db->prepare( $qry );  
    $sth->execute(); 

    my @bibs;
    while(my $row = $sth->fetchrow_hashref()) {
        my $bib = $row->{bib};
        my $key = $row->{bibtex_key};
        my $id = $row->{id};

        push @bibs, $bib;
    }
    $sth->finish();

    foreach my $entry_str(@bibs){
        my $entry_obj = new Text::BibTeX::Entry();
        $entry_obj->parse_s($entry_str);
    
        after_edit_process_authors($self->app->db, $entry_obj);
        assign_entry_to_existing_authors_no_add($self, $entry_obj);
    }

    $self->write_log("reassigning papers to authors (with authors creation) finished");
};

####################################################################################
sub clean_ugly_bibtex_fileds_for_all_entries {
    my $self = shift;
    my $dbh = $self->app->db;
    $self->write_log("clean_ugly_bibtex_fileds_for_all_entries started");
    
    
    my @ids = get_all_entry_ids($dbh);
    for my $id (@ids){
      clean_ugly_bibtex_fileds($dbh, $id);
    }
    $self->write_log("clean_ugly_bibtex_fileds_for_all_entries finished");
};
####################################################################################
sub clean_ugly_bibtex_fileds {
    my $dbh = shift;
    my $eid = shift;

    # TODO: move this into config
    our @bib_fields_to_delete = qw(bdsk-url-1 bdsk-url-2 bdsk-url-3 date-added date-modified owner tags);

    my @ary = $dbh->selectrow_array("SELECT bib FROM Entry WHERE id = ?", undef, $eid);  
    my $entry_str = $ary[0];

    my $entry = new Text::BibTeX::Entry();
    $entry->parse_s($entry_str);
    return -1 unless $entry->parse_ok;
    my $key = $entry->key;

    my $num_deleted = 0;

    for my $field (@bib_fields_to_delete){
      $entry->delete($field) if defined $entry->exists($field);
      $num_deleted++  if defined $entry->exists($field);
    }
    
    if( $num_deleted > 0){
        my $new_bib = $entry->print_s;


        # celaning errors caused by sqlite - mysql import
        
        $new_bib =~ s/''\{(.)\}/"\{$1\}/g;
        $new_bib =~ s/"\{(.)\}/\\"\{$1\}/g;

        $new_bib =~ s/\\\\/\\/g;
        $new_bib =~ s/\\\\/\\/g;


        my $sth2 = $dbh->prepare( "UPDATE Entry SET bib=?, need_html_regen = 1 WHERE id =?" );  
        $sth2->execute($new_bib, $eid);
        $sth2->finish();

        # generate_html_for_id($dbh, $eid);
    }
};

##################################################################

sub assign_entry_to_existing_authors_no_add{
    my $self = shift;
    my $entry = shift;
    my $dbh = $self->app->db;

    my $entry_key = $entry->key;
    my $key = $entry->key;
    my $eid = get_entry_id($dbh, $entry_key);

    

    # $dbh->begin_work; #transaction

    
    my $sth = $dbh->prepare('DELETE FROM Entry_to_Author WHERE entry_id = ?');
    if(defined $sth){
      $sth->execute($eid);
    }
    else{
      print 'cannot execute DELETE FROM Entry_to_Author WHERE entry_id = ?. FIXME Core.pm.';
    }
    

    my @names;
    if($entry->exists('author')){
      my @authors = $entry->split('author');
      my (@n) = $entry->names('author');
      @names = @n;
    }
    elsif($entry->exists('editor')){
      my @authors = $entry->split('editor');
      my (@n) = $entry->names('editor');
      @names = @n;
    }

    for my $name (@names){
        my $uid = create_user_id($name);
        my $aid = get_author_id_for_uid($dbh, $uid);
        my $mid = get_master_id_for_author_id($dbh, $aid);    

        if(defined $mid and $mid != -1){
            # my $sth3 = $dbh->prepare('INSERT OR IGNORE INTO Entry_to_Author(author_id, entry_id) VALUES(?, ?)');
            my $sth3 = $dbh->prepare('INSERT IGNORE Entry_to_Author(author_id, entry_id) VALUES(?, ?)');
            if(defined $sth3){
              $sth3->execute($mid, $eid); 
              $sth3->finish();
            }
            else{
              print 'INSERT OR IGNORE INTO Entry_to_Author(author_id, entry_id) VALUES(?, ?). FIXME Core.pm';
            }
        }
    }
    # $dbh->commit; #end transaction
}
##################################################################

sub after_edit_process_authors{
    my $dbh = shift;
    my $entry = shift;

    my $entry_key = $entry->key;
    my $key = $entry->key;
    my $eid = get_entry_id($dbh, $entry_key);

    my $sth = undef;
    $sth = $dbh->prepare('DELETE FROM Entry_to_Author WHERE entry_id = ?');
    $sth->execute($eid) if $eid > 0; 


    my @names;

    if($entry->exists('author')){
      my @authors = $entry->split('author');
      my (@n) = $entry->names('author');
      @names = @n;
    }
    elsif($entry->exists('editor')){
      my @authors = $entry->split('editor');
      my (@n) = $entry->names('editor');
      @names = @n;
    }

    # authors need to be added to have their ids!!
    for my $name (@names){
      my $uid = create_user_id($name);

      my $aid = get_author_id_for_uid($dbh, $uid);

      # say "\t pre! entry $eid -> uid $uid, aid $aid";


      my $sth0 = $dbh->prepare('INSERT INTO Author(uid, master) VALUES(?, ?)');
      $sth0->execute($uid, $uid) if $aid eq '-1';

      $aid = get_author_id_for_uid($dbh, $uid);
      my $mid = get_master_id_for_author_id($dbh, $aid);

      # if author was not in the uid2muid config, then mid = aid
      if($mid eq -1){
         $mid = $aid;
      }
      
      # say "\t pre2! entry $eid -> uid $uid, aid $aid, mid $mid";

      my $sth2 = $dbh->prepare('UPDATE Author SET master_id=? WHERE id=?');
      $sth2->execute($mid, $aid);


    }

    for my $name (@names){
      my $uid = create_user_id($name);
      my $aid = get_author_id_for_uid($dbh, $uid);
      my $mid = get_master_id_for_author_id($dbh, $aid);       #there tables are not filled yet!!

      # say "\t !!! entry $eid -> uid $uid, aid $aid, mid $mid";

      if(defined $mid and $mid != -1){ #added 5.05.2015 - may skip some authors!
        my $sth3 = $dbh->prepare('INSERT IGNORE INTO Entry_to_Author(author_id, entry_id) VALUES(?, ?)');
        # my $sth3 = $dbh->prepare('UPDATE Entry_to_Author SET author_id = ? WHERE entry_id = ?');
        $sth3->execute($mid, $eid);
      }

      
      # my $tid = get_team_id($dbh, "NOTEAM");
      # my $sth2 = $dbh->prepare("INSERT OR IGNORE INTO Author_to_Team(author_id, team_id, start, stop) Values (?, ?, ?, ?)");
      # $sth2->execute($aid, $tid, 0, 0);
    }
}
################################################################################
sub get_visibility_for_id {
   my $self = shift;
   my $id = shift;
   
   my $dbh = $self->app->db;

   my $sth;
   $sth = $dbh->prepare( "SELECT display FROM Author WHERE id=?" );
   $sth->execute($id); 
   
   my $row = $sth->fetchrow_hashref();
   my $disp = $row->{display};

   return $disp;
}
################################################################################
sub delete_entry_by_id{
  my $dbh = shift;
  my $id = shift;

  my $sth = $dbh->prepare( "DELETE FROM Entry WHERE id = ?" );  
  $sth->execute($id);

  my $sth2 = $dbh->prepare( "DELETE FROM Entry_to_Tag WHERE entry_id = ?" );  
  $sth2->execute($id);

  my $sth3 = $dbh->prepare( "DELETE FROM Entry_to_Author WHERE entry_id = ?" );  
  $sth3->execute($id);
};
################################################################################
sub get_all_non_hidden_entry_ids{
   my $dbh = shift;
   
   my $qry = "SELECT DISTINCT id FROM Entry WHERE hidden=0";
   my $sth = $dbh->prepare( $qry );  
   $sth->execute(); 

   my @ids;
   
   while(my $row = $sth->fetchrow_hashref()) {
      my $eid = $row->{id};
      push @ids, $eid if defined $eid;
   }

   return @ids;   
}
################################################################################
sub get_all_entry_ids{
   my $dbh = shift;
   
   my $qry = "SELECT DISTINCT id FROM Entry";
   my $sth = $dbh->prepare( $qry );  
   $sth->execute(); 

   my @ids;
   
   while(my $row = $sth->fetchrow_hashref()) {
      my $eid = $row->{id};
      push @ids, $eid if defined $eid;
   }

   return @ids;   
}
################################################################################
sub get_all_tags{
   my $dbh = shift;
   
   my $qry = "SELECT DISTINCT id, name FROM Tag ORDER BY name ASC";
   my $sth = $dbh->prepare( $qry );  
   $sth->execute(); 

   my @tags;
   my @ids;
   my @parents;
   
   while(my $row = $sth->fetchrow_hashref()) {
      my $tid = $row->{id};
      my $tag = $row->{name};
      my $parent = 0;

      push @tags, $tag if defined $tag;
      push @ids, $tid if defined $tid;
      push @parents, $parent if defined $parent;
   }

   return (\@tags, \@ids, \@parents);   
}
################################################################################
sub get_types_for_landing_page{
    my $dbh = shift;

    my $qry = "SELECT DISTINCT our_type FROM OurType_to_Type WHERE landing=1 ORDER BY our_type ASC";
    my $sth = $dbh->prepare( $qry ) or die $dbh->errstr;  
    $sth->execute();

    my @otypes;

    while(my $row = $sth->fetchrow_hashref()) {
        my $otype = $row->{our_type};
        push @otypes, $otype if defined $otype;
    }
    # @otypes = uniq @otypes;
    return @otypes;

    # my @otypes = ('article', 'volumes', 'inproceedings', 'techreport', 'misc', 'theses');

    # return @otypes;
}
################################################################################
sub get_bibtex_types_for_our_type{
    my $dbh = shift;
    my $type = shift;

    my $qry = "SELECT bibtex_type
           FROM OurType_to_Type
           WHERE our_type=?
           ORDER BY bibtex_type ASC";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($type);

    my @btypes;

    while(my $row = $sth->fetchrow_hashref()) {
        my $btype = $row->{bibtex_type};
        push @btypes, $btype if defined $btype;
    }
    return @btypes;
}
################################################################################
sub get_description_for_our_type{
    my $dbh = shift;
    my $type = shift;

    my $qry = "SELECT description
           FROM OurType_to_Type
           WHERE our_type=?";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($type);

    my $row = $sth->fetchrow_hashref();
    my $description = $row->{description} || get_type_description($dbh, $type);
    return $description;
}
################################################################################
sub get_landing_for_our_type{
    my $dbh = shift;
    my $type = shift;

    my $qry = "SELECT landing
           FROM OurType_to_Type
           WHERE our_type=?";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($type);

    my $row = $sth->fetchrow_hashref();
    my $landing = $row->{landing} || 0;
    return $landing;
}
################################################################################
sub set_landing_for_our_type{
    my $dbh = shift;
    my $type = shift;
    my $val = shift;

    say "set type $type val $val";

    if(defined $val and ($val == 0 or $val==1)){
        my $qry = "UPDATE OurType_to_Type SET landing=? WHERE our_type=?";
        my $sth = $dbh->prepare( $qry );  
        $sth->execute($val, $type);
    }
}

################################################################################
sub toggle_landing_for_our_type{
    my $dbh = shift;
    my $type = shift;

    my $curr = get_landing_for_our_type($dbh, $type);

    

    if($curr == 0){
        set_landing_for_our_type($dbh, $type, '1');
    }
    elsif($curr == 1){
        set_landing_for_our_type($dbh, $type, '0');
    }
}
################################################################################
sub get_DB_description_for_our_type{
    my $dbh = shift;
    my $type = shift;

    my $qry = "SELECT description
           FROM OurType_to_Type
           WHERE our_type=?";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($type);

    my $row = $sth->fetchrow_hashref();
    my $description = $row->{description} || undef;
    return $description;
}
################################################################################
sub get_all_existing_bibtex_types{

    ## defined by bibtex and constant

    return ('article', 'book', 'booklet', 'conference', 'inbook', 'incollection', 'inproceedings', 'manual', 'mastersthesis', 'misc', 'phdthesis', 'proceedings', 'techreport', 'unpublished');
}
################################################################################
sub get_all_bibtex_types{
    my $dbh = shift;

    my $qry = "SELECT DISTINCT bibtex_type, our_type
           FROM OurType_to_Type
           ORDER BY our_type ASC";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute();  

    my @btypes;

    while(my $row = $sth->fetchrow_hashref()) {
        my $btype = $row->{bibtex_type};
      
        push @btypes, $btype if defined $btype;
    }

    return @btypes;
}
################################################################################
sub get_all_our_types{
    my $dbh = shift;

    my $qry = "SELECT DISTINCT our_type
           FROM OurType_to_Type
           ORDER BY our_type ASC";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute();  

    my @otypes;

    while(my $row = $sth->fetchrow_hashref()) {
        my $otype = $row->{our_type};
      
        push @otypes, $otype if defined $otype;
    }

    return @otypes;
}

################################################################################
sub get_type_description{
    my $dbh = shift;
    my $type = shift;


    my $db_type = get_DB_description_for_our_type($dbh, $type);
    return $db_type if defined $db_type;

    # in case of no secription, the name is the description itself
    return "Publications of type ".$type;
}
################################################################################
sub get_all_teams{
   my $dbh = shift;
   
   my $qry = "SELECT DISTINCT id, name FROM Team";
   my $sth = $dbh->prepare( $qry );  
   $sth->execute(); 

   my @teams;
   my @ids;
   
   while(my $row = $sth->fetchrow_hashref()) {
      my $tid = $row->{id};
      my $team = $row->{name};

      push @teams, $team if defined $team;
      push @ids, $tid if defined $tid;
   }

   return (\@teams, \@ids);   
}
################################################################################
sub get_tags_for_entry{
   my $dbh = shift;
   my $eid = shift;

   my $qry = "SELECT Entry_to_Tag.tag_id, Tag.name 
              FROM Entry_to_Tag 
              LEFT JOIN Tag 
              ON Tag.id = Entry_to_Tag.tag_id 
              WHERE Entry_to_Tag.entry_id=? 
              ORDER BY Tag.name";
   my $sth = $dbh->prepare( $qry );  
   $sth->execute($eid); 

   my @tags;
   my @ids;
   my @parents;
   
   while(my $row = $sth->fetchrow_hashref()) {
      my $tid = $row->{tag_id};
      my $tag = get_tag_name_for_id($dbh, $tid);
      my $parent = '0';

      push @tags, $tag if defined $tag;
      push @ids, $tid if defined $tid;
      push @parents, $parent if defined $parent;
   }

   return (\@tags, \@ids, \@parents);   
}
##########################################################################
sub get_year_for_entry_id{
   my $dbh = shift;
   my $eid = shift;

   my $sth = $dbh->prepare( "SELECT year FROM Entry WHERE id=?" );     
   $sth->execute($eid);

   my $row = $sth->fetchrow_hashref();
   my $year = $row->{year};
   return $year;
}
##########################################################################
sub get_html_for_entry_id{
   my $dbh = shift;
   my $eid = shift;

   my $sth = $dbh->prepare( "SELECT html, bibtex_key FROM Entry WHERE id=?" );     
   $sth->execute($eid);

   my $row = $sth->fetchrow_hashref();
   my $html = $row->{html};
   my $key = $row->{bibtex_key};
   my $type = $row->{type};


   return nohtml($key, $type) unless defined $html;
   return $html;
}
##########################################################################
sub get_exceptions_for_entry_id{
   my $dbh = shift;
   my $eid = shift;

   my $sth = $dbh->prepare( "SELECT team_id FROM Exceptions_Entry_to_Team  WHERE entry_id=?" );  
   $sth->execute($eid); 

   my @exceptions;
   
   while(my $row = $sth->fetchrow_hashref()) {
      my $team_id = $row->{team_id};
      push @exceptions, $team_id;
   }

   return @exceptions;
}

##########################################################################
sub get_entry_key{
   my $dbh = shift;
   my $eid = shift;

   my $sth = $dbh->prepare( "SELECT bibtex_key FROM Entry WHERE id=?" ); 
   $sth->execute($eid);

   my $row = $sth->fetchrow_hashref();
   my $key = $row->{bibtex_key};
   return $key;
}
##########################################################################
sub get_entry_title{
    my $dbh = shift;
    my $eid = shift;

    my $sth = $dbh->prepare( "SELECT title FROM Entry WHERE id=?" ); 
    $sth->execute($eid);

    my $row = $sth->fetchrow_hashref();
    my $title = $row->{title} || "title undefined";

    $title =~ s/\{//g;
    $title =~ s/\}//g;
    return $title;
}
##########################################################################
sub get_entry_id{
   my $dbh = shift;
   my $key = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Entry WHERE bibtex_key=?" );     
   $sth->execute($key);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id};
   return -1 unless defined $id;
   print "ID = -1 for key $key\n" unless defined $id;
   return $id;
}
##########################################################################
sub get_master_id_for_uid{
   my $dbh = shift;
   my $uid = shift;

   my $sth = $dbh->prepare( "SELECT master_id FROM Author WHERE uid=?" );     
   $sth->execute($uid);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{master_id} || -1;
   print "ID = -1 for author $uid\n" unless defined $id;
   return $id;
}
##########################################################################
sub get_master_id_for_master{
   my $dbh = shift;
   my $master = shift;

   my $sth = $dbh->prepare( "SELECT master_id FROM Author WHERE master=?" );     
   $sth->execute($master);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{master_id} || -1;
   print "ID = -1 for author $master\n" unless defined $id;
   return $id;
}
##########################################################################
sub get_master_id_for_author_id{
   my $dbh = shift;
   my $id = shift;

   my $sth = $dbh->prepare( "SELECT master_id FROM Author WHERE id=?" );     
   $sth->execute($id);

   my $row = $sth->fetchrow_hashref();
   my $mid = $row->{master_id} || -1;
   print "ID = -1 for author id $id\n" unless defined $id;
   return $mid;
}
##########################################################################
sub get_author_id_for_uid{
   my $dbh = shift;
   my $master = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Author WHERE uid=?" );     
   $sth->execute($master);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id} || -1;
   print "ID = -1 for author $master\n" unless defined $id;
   return $id;
}
##########################################################################
sub get_author_id_for_master{
   my $dbh = shift;
   my $master = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Author WHERE master=?" );     
   $sth->execute($master);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id} || -1;
   print "ID = -1 for author $master\n" unless defined $id;
   return $id;
}
##########################################################################
sub get_master_for_id{
   my $dbh = shift;
   my $id = shift;

   my $sth = $dbh->prepare( "SELECT master FROM Author WHERE id=?" );     
   $sth->execute($id);

   my $row = $sth->fetchrow_hashref();
   my $master = $row->{master} || -1;
   
   return $master;
}
##########################################################################
sub get_team_id{
   my $dbh = shift;
   my $team = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Team WHERE name=?" );     
   $sth->execute($team);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id} || -1;
   print "ID = -1 for team $team\n" unless defined $id;
   return $id;
}
##########################################################################
sub get_team_for_id{
   my $dbh = shift;
   my $id = shift;

   my $sth = $dbh->prepare( "SELECT name FROM Team WHERE id=?" );     
   $sth->execute($id);

   my $row = $sth->fetchrow_hashref();
   my $name = $row->{name} || undef;
   
   return $name;
}
##########################################################################
sub get_tag_id{
   my $dbh = shift;
   my $tag = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Tag WHERE name=?" );     
   $sth->execute($tag);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id} || -1;
   print "ID = -1 for tag $tag\n" unless defined $id;
   return $id;
}
##########################################################################
sub get_tag_name_for_id{
   my $dbh = shift;
   my $id = shift;

   my $sth = $dbh->prepare( "SELECT name FROM Tag WHERE id=?" );     
   $sth->execute($id);

   my $row = $sth->fetchrow_hashref();
   my $name = $row->{name} || -1;
   print "ID = -1 for tag $id\n" unless defined $name;
   return $name;
}
# ##########################################################################
# sub get_tag_name_for_permalink{
#    my $dbh = shift;
#    my $permalink = shift;

#    my $sth = $dbh->prepare( "SELECT name FROM Tag WHERE permalink=?" );     
#    $sth->execute($permalink);

#    my $row = $sth->fetchrow_hashref();
#    my $name = $row->{name} || -1;
#    print "permalink = -1 for tag $permalink\n" unless defined $name;
#    return $name;
# }

################################################################################
sub add_team_for_author {
   my $self = shift;
   my $master_id = shift;
   my $teamid = shift;

   my $dbh = $self->app->db;

   my $qry = "INSERT IGNORE INTO Author_to_Team(author_id, team_id) VALUES (?,?)";
   my $sth = $dbh->prepare( $qry );  
   $sth->execute($master_id, $teamid); 

   $self->write_log("Author with master id $master_id becomes a member of team with id $teamid.");
}
################################################################################
sub remove_team_for_author {
   my $self = shift;
   my $master_id = shift;
   my $teamid = shift;

   my $dbh = $self->app->db;

   my $qry = "DELETE FROM Author_to_Team WHERE author_id=? AND team_id=?";
   my $sth = $dbh->prepare( $qry );  
   $sth->execute($master_id, $teamid); 

   $self->write_log("Author with master id $master_id IS NO LONGER a member of team with id $teamid.");
}

################################################################################
sub get_team_members {
   my $self = shift;
   my $teamid = shift;
   my $dbh = $self->app->db;

    
   my @author_ids;
   my @start_arr;
   my @stop_arr;

   
   my $qry = "SELECT DISTINCT (author_id), start, stop
            FROM Author_to_Team 
            JOIN Author 
            ON Author.master_id = Author_to_Team.author_id
            WHERE team_id=?
            ORDER BY display DESC";#, uid ASC";

   my $sth = $dbh->prepare( $qry );  
   $sth->execute($teamid); 

   my $disp;
   while(my $row = $sth->fetchrow_hashref()) {
      my $aid = $row->{author_id};
      my $start = $row->{start};
      my $stop = $row->{stop};

      push @author_ids, $aid if defined $aid;
      push @start_arr, $start if defined $start;
      push @stop_arr, $stop if defined $stop;
   }
   return (\@author_ids, \@start_arr, \@stop_arr);   
}

################################################################################
sub get_teams_of_author {
   my $self = shift;
   my $mid = shift;
   my $dbh = $self->app->db;

    
   my @teams;
   my @team_ids;
   my @start_arr;
   my @stop_arr;

   
   my $qry = "SELECT author_id, team_id, start, stop
            FROM Author_to_Team 
            WHERE author_id=?
            ORDER BY start DESC";

   my $sth = $dbh->prepare( $qry );  
   $sth->execute($mid); 

   my $disp;
   while(my $row = $sth->fetchrow_hashref()) {
      my $teamid = $row->{team_id};
      my $start = $row->{start};
      my $stop = $row->{stop};


      my $team = get_team_for_id($dbh, $teamid);

      push @team_ids, $teamid if defined $teamid;
      push @teams, $team if defined $team;
      push @start_arr, $start if defined $start;
      push @stop_arr, $stop if defined $stop;
   }
   return (\@teams, \@start_arr, \@stop_arr, \@team_ids);   
}
################################################################################
sub get_author_ids_for_tag_id {
   my $self = shift;
   my $tag_id = shift;
   my $dbh = $self->app->db;

   say "tag_id $tag_id";

   my $qry = "SELECT DISTINCT Entry_to_Author.author_id
            FROM Entry_to_Author 
            LEFT JOIN Entry_to_Tag ON Entry_to_Author.entry_id = Entry_to_Tag.entry_id 
            LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 
            WHERE Entry_to_Tag.tag_id =? 
            AND Entry_to_Author.author_id IS NOT NULL";

   my $sth = $dbh->prepare( $qry );  
   $sth->execute($tag_id); 

   my @author_ids;
   
   while(my $row = $sth->fetchrow_hashref()) {
      my $author_id = $row->{author_id};

      push @author_ids, $author_id if defined $author_id;
   }

   return @author_ids;
}
################################################################################
sub get_author_ids_for_tag_id_and_team {
   my $self = shift;
   my $tag_id = shift;
   my $team_id = shift;
   my $dbh = $self->app->db;
   my $current_year = get_current_year();

   my $qry = "SELECT DISTINCT Entry_to_Author.author_id
            FROM Entry_to_Author 
            LEFT JOIN Entry_to_Tag ON Entry_to_Author.entry_id = Entry_to_Tag.entry_id 
            LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 
            WHERE Entry_to_Tag.tag_id =? 
            AND Entry_to_Author.author_id IS NOT NULL
            AND Entry_to_Author.author_id IN (
                SELECT DISTINCT (author_id)
                FROM Author_to_Team 
                JOIN Author 
                ON Author.master_id = Author_to_Team.author_id
                WHERE team_id=?
                AND Author_to_Team.start <= ?
                AND ((Author_to_Team.stop = 0) OR (Author_to_Team.stop >= ?))
            )";


   my $sth = $dbh->prepare( $qry );  
   $sth->execute($tag_id, $team_id, $current_year, $current_year); 

   # my (\@team_members, \@start_arr, \@stop_arr) = get_team_members($self, $team_id);    

   my @author_ids;
   
   while(my $row = $sth->fetchrow_hashref()) {
      my $author_id = $row->{author_id};

      push @author_ids, $author_id if defined $author_id;
   }

   return @author_ids;
}
################################################################################
sub get_tags_for_author {
    #todo: objectify!
   my $self = shift;
   my $master_id = shift;
   my $type = shift || 1;
   my $dbh = $self->app->db;

   my $qry = "SELECT DISTINCT Entry_to_Tag.tag_id, Tag.name 
            FROM Entry_to_Author 
            LEFT JOIN Entry_to_Tag ON Entry_to_Author.entry_id = Entry_to_Tag.entry_id 
            LEFT JOIN Tag ON Entry_to_Tag.tag_id = Tag.id 
            WHERE Entry_to_Author.author_id=? 
            AND Entry_to_Tag.tag_id IS NOT NULL
            AND Tag.type = ?
            ORDER BY Tag.name ASC";

   my $sth = $dbh->prepare( $qry );  
   $sth->execute($master_id, $type); 

   my @tag_ids;
   my @tags;
   
   while(my $row = $sth->fetchrow_hashref()) {
      my $tag_id = $row->{tag_id};
      my $tag = $row->{name};

      push @tag_ids, $tag_id if defined $tag_id;
      push @tags, $tag if defined $tag;

   }

   return (\@tag_ids, \@tags);
}
################################################################################
sub get_tags_for_team {
    my $self = shift;
    my $teamid = shift;
    my $type = shift || 1;
    my $dbh = $self->app->db;

    my @params;

    my $qry = "SELECT DISTINCT Entry.year, Tag.id as tagid, Tag.name as tagname
                FROM Entry
                LEFT JOIN Exceptions_Entry_to_Team  ON Entry.id = Exceptions_Entry_to_Team.entry_id
                LEFT JOIN Entry_to_Author ON Entry.id = Entry_to_Author.entry_id 
                LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 
                LEFT JOIN Author_to_Team ON Entry_to_Author.author_id = Author_to_Team.author_id 
                LEFT JOIN Entry_to_Tag ON Entry.id = Entry_to_Tag.entry_id 
                LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id 
                WHERE Entry.bibtex_key IS NOT NULL 
                AND Tag.type = ?";

    push @params, $type;
    
    if(defined $teamid){
        push @params, $teamid;
        push @params, $teamid;
        # push @params, $teamid;
        # $qry .= "AND Exceptions_Entry_to_Team.team_id=?  ";
        $qry .= "AND ((Exceptions_Entry_to_Team.team_id=? ) OR (Author_to_Team.team_id=? AND start <= Entry.year  AND (stop >= Entry.year OR stop = 0))) ";
    }
    $qry .= "ORDER BY Entry.year DESC";


    my $sth = $dbh->prepare_cached( $qry );  
    $sth->execute(@params); 

   my @tag_ids;
   my @tags;
   
   while(my $row = $sth->fetchrow_hashref()) {
      my $tag_id = $row->{tagid};
      my $tag = $row->{tagname};

      push @tag_ids, $tag_id if defined $tag_id;
      push @tags, $tag if defined $tag;

   }

   return (\@tag_ids, \@tags);
}
####################################################################################
sub add_field_to_bibtex_code {
    my $dbh = shift;
    my $eid = shift;
    my $field = shift;
    my $value = shift;

    say "call: add_field_to_bibtex_code eid $eid field $field value $value";

    my @ary = $dbh->selectrow_array("SELECT bib FROM Entry WHERE id = ?", undef, $eid);  
    my $entry_str = $ary[0];

    my $entry = new Text::BibTeX::Entry();
    $entry->parse_s($entry_str);
    return -1 unless $entry->parse_ok;
    my $key = $entry->key;
    $entry->set ($field, $value);
    my $new_bib = $entry->print_s;

    # my $sth2 = $dbh->prepare( "UPDATE Entry SET bib=?, modified_time=datetime('now', 'localtime'), need_html_regen = 1 WHERE id =?" );  
    my $sth2 = $dbh->prepare( "UPDATE Entry SET bib=?, modified_time=CURRENT_TIMESTAMP, need_html_regen = 1 WHERE id =?" );  
    
    $sth2->execute($new_bib, $eid);
    $sth2->finish();
};
####################################################################################
sub has_bibtex_field {
    my $dbh = shift;
    my $eid = shift;
    my $field = shift;

    my @ary = $dbh->selectrow_array("SELECT bib FROM Entry WHERE id = ?", undef, $eid);  
    my $entry_str = $ary[0];

    my $entry = new Text::BibTeX::Entry();
    $entry->parse_s($entry_str);
    return -1 unless $entry->parse_ok;
    my $key = $entry->key;

    return $entry->exists($field);
}
################################################################################

sub create_user_id {
   my ($name) = @_;

   my @first_arr = $name->part('first');
   my $first = join(' ', @first_arr);
   #print "$first\n";

   my @von_arr = $name->part ('von');
   my $von = $von_arr[0];
   #print "$von\n" if defined $von;

   my @last_arr = $name->part ('last');
   my $last = $last_arr[0];
   #print "$last\n";

   my @jr_arr = $name->part ('jr');
   my $jr = $jr_arr[0];
   #print "$jr\n";
   
   my $userID;
   $userID.=$von if defined $von;
   $userID.=$last;
   $userID.=$first if defined $first;
   $userID.=$jr if defined $jr;

   $userID =~ s/\\k\{a\}/a/g;   # makes \k{a} -> a
   $userID =~ s/\\l/l/g;   # makes \l -> l
   $userID =~ s/\\r\{u\}/u/g;   # makes \r{u} -> u # FIXME: make sure that the letter is caught
   # $userID =~ s/\\r{u}/u/g;   # makes \r{u} -> u # the same but not escaped 

   $userID =~ s/\{(.)\}/$1/g;   # makes {x} -> x
   $userID =~ s/\{\\\"(.)\}/$1e/g;   # makes {\"x} -> xe
   $userID =~ s/\{\"(.)\}/$1e/g;   # makes {"x} -> xe
   $userID =~ s/\\\"(.)/$1e/g;   # makes \"{x} -> xe
   $userID =~ s/\{\\\'(.)\}/$1/g;   # makes {\'x} -> x
   $userID =~ s/\\\'(.)/$1/g;   # makes \'x -> x
   $userID =~ s/\'\'(.)/$1/g;   # makes ''x -> x
   $userID =~ s/\"(.)/$1e/g;   # makes "x -> xe
   $userID =~ s/\{\\ss\}/ss/g;   # makes {\ss}-> ss
   $userID =~ s/\{(.*)\}/$1/g;   # makes {abc..def}-> abc..def
   $userID =~ s/\\\^(.)(.)/$1$2/g;   # makes \^xx-> xx
   # I am not sure if the next one is necessary
   $userID =~ s/\\\^(.)/$1/g;   # makes \^x-> x 
   $userID =~ s/\\\~(.)/$1/g;   # makes \~x-> x
   $userID =~ s/\\//g;   # removes \ 

   $userID =~ s/\{//g;   # removes {
   $userID =~ s/\}//g;   # removes }

   $userID =~ s/\(.*\)//g;   # removes everything between the brackets and the brackets also
   
   # print "$userID \n";
   return $userID;
}

################################################################################
sub generate_html_for_id{
   my $dbh = shift;
   my $eid = shift;

   my $sth = $dbh->prepare( "SELECT need_html_regen, bibtex_key, bib, html 
         FROM Entry 
         WHERE id = ?" );  
   $sth->execute($eid); 

   
   my $bib = undef;
   my $key = undef;
   my $old_html = undef;
   my $entry_needs_html_regeration = undef;
   
   while(my $row = $sth->fetchrow_hashref()) {
      $bib = $row->{bib};
      $old_html = $row->{html};
      $key = $row->{bibtex_key};
      $entry_needs_html_regeration = $row->{need_html_regen};
   }
    
   my ($html, $htmlbib) = get_html_for_bib($bib, $key);

   # this triggers: modified_time=CURRENT_TIMESTAMP  # minor severity

   my $sth2 = $dbh->prepare( "UPDATE Entry
      SET html = ? , html_bib = ?, need_html_regen = 0
      WHERE id = ?" );  
   $sth2->execute($html, $htmlbib, $eid); 
};
################################################################################
sub generate_html_for_key{
   my $dbh = shift;
   my $key = shift;

   my $eid = get_entry_id($dbh, $key);
   return generate_html_for_id($dbh, $eid);
};

################################################################################

sub get_html_for_bib{
   my $bib_str = shift;
   my $key = shift || 'no-bibtex-key';

    # fix for the coding problems with mysql
    $bib_str =~ s/J''urgen/J\\''urgen/g;
    $bib_str =~ s/''a/\\''a/g;
    $bib_str =~ s/''o/\\''o/g;
    $bib_str =~ s/''e/\\''e/g;

   my $out_file = $bibtex2html_tmp_dir."/out";
   my $outhtml = $out_file.".html";

   my $out_bibhtml = $out_file."_bib.html";
   my $databib = $bibtex2html_tmp_dir."/data.bib";

   open (MYFILE, '>'.$databib);
   print MYFILE $bib_str;
   close (MYFILE); 

   open (my $fh, '>'.$outhtml) or die "cannot touch $outhtml";
   close($fh);
   open ($fh, '>'.$out_bibhtml) or die "cannot touch $out_bibhtml";
   close($fh);

    my $cwd = getcwd();

   mkdir($bibtex2html_tmp_dir, 0777);

   # -nokeys  --- no number in brackets by entry
   # -nodoc   --- dont generate document but a part of it - to omit html head body headers
   # -single  --- does not provide links to pdf, html and bib but merges bib with html output
   my $bibtex2html_command = "bibtex2html -s ".$cwd."/descartes2 -nf slides slides -d -r --revkeys -no-keywords -no-header -nokeys --nodoc  -no-footer -o ".$out_file." $databib >/dev/null";
   # my $tune_html_command = "./tuneSingleHtmlFile.sh out.html";

   # print "COMMAND: $bibtex2html_command\n";
   my $syscommand = "export TMPDIR=".$bibtex2html_tmp_dir." && ".$bibtex2html_command;
   # say "=====\n";
   # say "cwd: ".$cwd."\n";
   # say $syscommand;
   # say "=====\n";
   system($syscommand);
   



   my $html =     read_file($outhtml);
   my $htmlbib =  read_file($out_bibhtml);

   $htmlbib =~ s/<h1>data.bib<\/h1>//g;

   $htmlbib =~ s/<a href="$outhtml#(.*)">(.*)<\/a>/$1/g;
   $htmlbib =~ s/<a href=/<a target="blank" href=/g;

   $html = tune_html($html, $key, $htmlbib);
   

   
   # now the output jest w out.html i out_bib.html

   return $html, $htmlbib;
};

################################################################################

sub tune_html{
   my $s = shift;
   my $key = shift;
   my $htmlbib = shift || "";

   # my $DIR="/var/www/html/publications-new";
   # my $DIRBASE="/var/www/html/";
   # #edit those two above always together!
   # my $WEBPAGEPREFIX="http://sdqweb.ipd.kit.edu/";
   # my $WEBPAGEPREFIXLONG="http://sdqweb.ipd.kit.edu/publications";

   # BASH CODE:
   # # replace links
   # sed -e s_"$DIR"_"$WEBPAGEPREFIXLONG"_g $FILE > $TMP && mv -f $TMP $FILE
   # # changes /var/www/html/publications-new to http://sdqweb.ipd.kit.edu/publications_new
   # $s =~ s/"$DIR"/"$WEBPAGEPREFIXLONG"/g;

   $s =~ s/out_bib.html#(.*)/\/publications\/get\/bibtex\/$1/g;
   
   # FROM .pdf">.pdf</a>&nbsp;]
   # TO   .pdf" target="blank">.pdf</a>&nbsp;]
   # $s =~ s/.pdf">/.pdf" target="blank">/g;


   $s =~ s/>.pdf<\/a>/ target="blank">.pdf<\/a>/g;
   $s =~ s/>slides<\/a>/ target="blank">slides<\/a>/g;
   $s =~ s/>http<\/a>/ target="blank">http<\/a>/g;
   $s =~ s/>.http<\/a>/ target="blank">http<\/a>/g;
   $s =~ s/>DOI<\/a>/ target="blank">DOI<\/a>/g;

   $s =~ s/<a (.*)>bib<\/a>/BIB_LINK_ID/g;
   
   

   # # for old system use:
   # #for x in `find $DIR -name "*.html"`;do sed 's_\[\&nbsp;<a href=\"_\[\&nbsp;<a href=\"http:\/\/sdqweb.ipd.kit.edu\/publications\/_g' $x > $TMP; mv $TMP $x; done

   # # replace &lt; and &gt; b< '<' and '>' in Samuel's files.
   # sed 's_\&lt;_<_g' $FILE > $TMP && mv -f $TMP $FILE
   # sed 's_\&gt;_>_g' $FILE > $TMP && mv -f $TMP $FILE
   $s =~ s/\&lt;/</g;
   $s =~ s/\&gt;/>/g;


   # ### insert JavaScript hrefs to show/hide abstracts on click ###
   # #replaces every newline command with <NeueZeile> to insert the Abstract link in the next step properly 
   # perl -p -i -e "s/\n/<NeueZeile>/g" $FILE
   $s =~ s/\n/<NeueZeile>/g;

   # #inserts the link to javascript
   # sed 's_\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">_\&nbsp;\|\&nbsp;<a href=\"javascript:showAbstract(this);\" onclick=\"showAbstract(this)\">Abstract</a><noscript> (JavaScript required!)</noscript>\&nbsp;\]<div style=\"display:none;\"><blockquote id=\"abstractBQ\">_g' $FILE > $TMP && mv -f $TMP $FILE
   # sed 's_</font></blockquote><NeueZeile><p>_</blockquote></div>_g' $FILE > $TMP && mv -f $TMP $FILE
   # $s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a href=\"javascript:showAbstract(this);\" onclick=\"showAbstract(this)\">Abstract<\/a><noscript> (JavaScript required!)<\/noscript>\&nbsp;\]<div style=\"display:none;\"><blockquote id=\"abstractBQ\">/g;

   
   #$s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a class="abstract-a" onclick=\"showAbstract(\'$key\')\">Abstract<\/a>\&nbsp; \]<div id=\"$key\" style=\"display:none;\"><blockquote id=\"abstractBQ\">/g;
   $s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a class="abstract-a" onclick=\"showAbstract(\'$key\')\">Abstract<\/a>\&nbsp; \] <div id=\"$key\" style=\"display:none;\"><blockquote id=\"abstractBQ\" style=\"text-align: justify;\">/g;
   $s =~ s/<\/font><\/blockquote><NeueZeile><p>/<\/blockquote><\/div>/g;

   #inserting bib DIV marker
   $s =~ s/\]/\] BIB_DIV_ID/g;

   $key =~ s/\./_/g;   

   # handling BIB_DIV_ID marker
   $s =~ s/BIB_DIV_ID/<div id="bib-of-$key" class="inline-bib" style=\"display:none;\">$htmlbib<\/div>/g;
   # handling BIB_LINK_ID marker
   $s =~ s/BIB_LINK_ID/<a class="abstract-a" onclick=\"showAbstract(\'bib-of-$key\')\">bib<\/a>/g;

   # #undo the <NeueZeile> insertions
   # perl -p -i -e "s/<NeueZeile>/\n/g" $FILE
   $s =~ s/<NeueZeile>/\n/g;
   
   $s =~ s/(\s)\s+/$1/g;  # !!! TEST

   $s =~ s/<p>//g;
   $s =~ s/<\/p>//g;


   $s;
}

################################################################################

sub get_dir_size {
  my $dir  = shift;
  my $size = 0;

  find( sub { $size += -f $_ ? -s _ : 0 }, $dir );

  return $size;
};

####################################################################################
sub get_backup_filename{
    my $self = shift;
    my $bip = shift;
    my $backup_dbh = $self->app->backup_db;

    my $sth = $backup_dbh->prepare("SELECT filename FROM Backup WHERE id=? LIMIT 1");
    $sth->execute($bip);
    my $row = $sth->fetchrow_hashref();
    return $row->{filename} || undef;
}

####################################################################################
sub get_backup_creation_time{
    my $self = shift;
    my $bip = shift;
    my $backup_dbh = $self->app->backup_db;

    my $sth = $backup_dbh->prepare("SELECT creation_time FROM Backup WHERE id=? LIMIT 1");
    $sth->execute($bip);
    my $row = $sth->fetchrow_hashref();
    return $row->{creation_time} || undef;
}
####################################################################################
sub get_backup_age_in_days{
    my $self = shift;
    my $bid = shift;
    my $backup_dbh = $self->app->backup_db;

    my $sth = $backup_dbh->prepare("SELECT (julianday('now', 'localtime') - julianday(creation_time)) as age FROM Backup WHERE id=? LIMIT 1");
    $sth->execute($bid);
    my $row = $sth->fetchrow_hashref();
    return $row->{age} || -1;
}

################################################################################


1;