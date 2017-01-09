package BibSpace::Functions::FPublications;

use 5.010;    #because of ~~
use strict;
use warnings;
use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use DBI;

use BibSpace::Controller::Core;
use BibSpace::Model::MEntry;

use Exporter;
our @ISA = qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
    Fdo_regenerate_html
    Ffix_months
    FprintBibtexWarnings
    Fhandle_add_edit_publication
    Fget_publications_main_hashed_args_only
    Fget_publications_main_hashed_args
    Fget_publications_core_from_array_ref
    Fget_publications_core_from_set
    Fget_publications_core
    Fclean_ugly_bibtex_fields_for_all_entries
    Fhandle_author_uids_change_for_all_entries
);
####################################################################################
sub Fdo_regenerate_html {
    my ($dbh, $bst_file, $force, @entries) = @_;


    my $num_fixes = 0;
    for my $e (@entries) {
        $e->{bst_file} = $bst_file;
        $e->regenerate_html( $force, $bst_file );
        $e->save($dbh);    # change to $storage->store_all or sth;
    }
}
####################################################################################
sub FprintBibtexWarnings {
    my $str = shift;

    my $msg = '';
    if ( $str ne '' ) {
        
        $str =~ s/Warning/<br\/>Warning/g;

        $msg .= "<br/><br/>";
        $msg .= "<strong>BibTeX Warnings</strong>: $str";
    }
    return $msg;
}
####################################################################################
sub Ffix_months {
    my ($dbh, @entries) = @_;

    my $num_checks = 0;
    my $num_fixes  = 0;

    for my $o (@entries) {
        # say " checking fix month $num_checks";
        $num_fixes = $num_fixes + $o->fix_month();
        $o->save($dbh);
        ++$num_checks;
    }

    return ( $num_checks, $num_fixes );
}


####################################################################################
sub Fhandle_add_edit_publication {
    my ( $dbh, $new_bib, $id, $action, $bst_file ) = @_;

    say "CALL Fhandle_add_edit_publication: id $id action $action";

    my $storage = StorageBase->get();

    # var that will be returned
    my $mentry;         # the entry object
    my $status_code;    # the status code
    my $existing_id    = -1;  # id of exiting enrty having the same bibtex key
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

    # Fhandle_preview
    # Fhandle_preview

    my $e;
    
    if( $id > 0){
        $e = $storage->entries_find( sub {$_->id == $id} ); 
    }
    else{
        $e = MEntry->new( id=>$id, bib=>$new_bib );
    }
   

    $e->{bib} = $new_bib;
    my $bibtex_code_valid = $e->populate_from_bib();

    # We check Bibtex errors for all requests
    if ( !$bibtex_code_valid ) {
        $status_code_str = 'ERR_BIBTEX';
        return ( $e, $status_code_str, -1, -1 );
    }

    my $tmp_e = $storage->entries_find( sub { ($_->bibtex_key cmp $e->bibtex_key)==0 } ); 
    # grep { $_->{bibtex_key} eq $e->{bibtex_key} } MEntry->static_all( $dbh );
    $existing_id = $tmp_e->{id} if defined $tmp_e;

    if ( $id > 0 and $existing_id == $e->{id} )
    {    # editing mode, key ok, the user will update entry but not the key
        $status_code_str = 'KEY_OK';
    }
    elsif ( $id < 0 and $existing_id < 0 ) {    # adding mode and key ok
        $status_code_str = 'KEY_OK';
    }
    elsif ( $id > 0 and $existing_id < 0 )
    { # editing mode, key ok, the user will update the entry including the key
        $status_code_str = 'KEY_OK';
    }
    else {
        $status_code_str = 'KEY_TAKEN';
        $e->generate_html($bst_file);
        return ( $e, $status_code_str, $existing_id, -1 );
    }
    if ( $action eq 'check_key' or $action eq 'preview' )
    {    # user wanted only to check key - we give him the preview as well
        $e->generate_html($bst_file);
        $e->populate_from_bib();
        return ( $e, $status_code_str, $existing_id, -1 );
    }

    if ( $action eq 'save' ) {
        if ( $id > 0 ) {    #editing
            $status_code_str = 'EDIT_OK';
        }
        else {              #adding
            $status_code_str = 'ADD_OK';
        }
        $e->generate_html($bst_file);
        $e->populate_from_bib();
        $e->fix_month();
        $e->save($dbh);    # so we save for sure

        # these functions require that the object is in the DB
        $e->postprocess_updated($dbh, $bst_file);    # this has optional save

        $storage->add_entry_authors( $e, 1 );

        $e->save($dbh);    # so we save for sure
        $added_under_id = $e->{id};
    }
    else {
        warn
            "Fhandle_add_edit_publication action $action does not match the known actions: save, preview, check_key.";
    }    # action save
    return ( $e, $status_code_str, $existing_id, $added_under_id );
}

####################################################################################
# this function ignores the parameters given in the $self object
sub Fget_publications_main_hashed_args_only {
    my ( $self, $args ) = @_;


    my @dbg = Fget_publications_core(
        $self,                $args->{author},     $args->{year},
        $args->{bibtex_type}, $args->{entry_type}, $args->{tag},
        $args->{team},        $args->{visible},    $args->{permalink},
        $args->{hidden}, $args->{debug},
    );
    return @dbg;
}
####################################################################################
sub Fget_publications_main_hashed_args {    #
    my ( $self, $args ) = @_;



    return Fget_publications_core(
        $self,
        $args->{author}      || $self->param('author')      || undef,
        $args->{year}        || $self->param('year')        || undef,
        $args->{bibtex_type} || $self->param('bibtex_type') || undef,
        $args->{entry_type}  || $self->param('entry_type')  || undef,
        $args->{tag}         || $self->param('tag')         || undef,
        $args->{team}        || $self->param('team')        || undef,
        $args->{visible}     || 0,
        $args->{permalink}   || $self->param('permalink')   || undef,
        $args->{hidden},
        $args->{debug},
    );
}

####################################################################################
sub Fget_publications_core_from_array_ref {
    say
        "CALL: Fget_publications_core_from_array_ref. This function could be removed...";
    my $self      = shift;
    my $array_ref = shift;
    my $sort      = shift;
    $sort = 1 unless defined $sort;

    my $dbh = $self->app->db;

    my $keep_order = 0;
    $keep_order = 1 if $sort == 0;

    return MEntry->static_get_from_id_array( $dbh, $array_ref, $keep_order );
}
####################################################################################
sub Fget_publications_core_from_set {
    say "CALL: Fget_publications_core_from_set";
    my $self = shift;
    my $set  = shift;

    my $dbh   = $self->app->db;
    my @array = $set->elements;

    # array may be empty here!

    return Fget_publications_core_from_array_ref( $self, \@array );
}
####################################################################################

sub Fget_publications_core_storage {
    my $self        = shift;
    my $author      = shift;
    my $year        = shift;
    my $bibtex_type = shift;
    my $entry_type  = shift;
    my $tag         = shift;
    my $team        = shift;
    my $visible     = shift // 0;
    my $permalink   = shift;
    my $hidden      = shift;
    my $debug       = shift // 0;

    my $storage = StorageBase->get();



    my $team_obj   = $storage->find_team_by_id_or_name($team);
    my $author_obj = $storage->find_author_by_id_or_name($author);
    my $tag_obj    = $storage->find_tag_by_id_or_name($tag);
    my $tag_obj_perm = $storage->find_tag_by_id_or_name($permalink);

    
    my $teamid = undef;
    $teamid = $team_obj->id if defined $team_obj;    
    my $master_id = undef;
    $master_id = $author_obj->id if defined $author_obj;
    my $tagid = undef;
    $tagid = $tag_obj->id if defined $tag_obj;

    # filtering
    my @entries = $storage->entries_all;

    # simple filters
    if( defined $year and length($year)>0 ){
        say "Comparing year: $year"  if $debug == 1;
        map { say $_->id . " year ". $_->year } @entries  if $debug == 1;
        @entries = grep { (defined $_->year and $_->year == $year) } @entries;
    }
    if(defined $bibtex_type){
        say "Comparing bibtex_type: $bibtex_type" if $debug == 1;
        map { say $_->id . " type ". $_->bibtex_type } @entries  if $debug == 1;

        @entries = grep { ($_->bibtex_type cmp $bibtex_type)==0 } @entries;
    }
    if(defined $entry_type){
        say "Comparing entry_type: $entry_type" if $debug == 1;
        map { say $_->id . " type ". $_->entry_type } @entries  if $debug == 1;

        @entries = grep { ($_->entry_type cmp $entry_type)==0;} @entries;
    }
    if(defined $permalink and defined $tag_obj_perm){
        @entries = grep { $_->has_tag($tag_obj_perm) } @entries;
    }
    if(defined $hidden){
        say "Comparing hidden: $hidden" if $debug == 1;
        map { say $_->id . " hidden ". $_->hidden } @entries  if $debug == 1;
        @entries = grep { $_->hidden == $hidden } @entries;
    }
    # complex filters
    if(defined $visible){
        @entries = grep { $_->is_visible } @entries;
    }
    if(defined $master_id and defined $author_obj){
        @entries = grep { $_->has_master_author($author_obj) } @entries;
    }
    if(defined $tagid and defined $tag_obj){
        @entries = grep { $_->has_tag($tag_obj) } @entries;
    }
    if(defined $teamid and defined $team_obj){
        @entries = grep { $_->has_team($team_obj) } @entries;
    }
    if($debug == 1){
        say "Input author = $author" if defined $author;
        say "Input year = $year" if defined $year;
        say "Input bibtex_type = $bibtex_type" if defined $bibtex_type;
        say "Input entry_type = $entry_type" if defined $entry_type;
        say "Input tag = $tag" if defined $tag;
        say "Input team = $team" if defined $team;
        say "Input visible = $visible" if defined $visible;
        say "Input permalink = $permalink" if defined $permalink;
        say "Input hidden = $hidden" if defined $hidden;
        say "Input debug = $debug" if defined $debug;
    }

    return @entries;
}
####################################################################################
sub Fget_publications_core {
    return Fget_publications_core_storage(@_);
}
####################################################################################
sub Fget_publications_core_old {
    my $self        = shift;
    my $author      = shift;
    my $year        = shift;
    my $bibtex_type = shift;
    my $entry_type  = shift;
    my $tag         = shift;
    my $team        = shift;
    my $visible     = shift // 0;
    my $permalink   = shift;
    my $hidden      = shift;

    # my $storage = StorageBase->get();
    # my @objs = $storage->entries_filter( sub { 
    #     (
    #             ($_->bibtex_type cmp $curr_bibtex_type)==0 
    #         and ($_->entry_type  cmp $curr_entry_type)==0 
    #         and  $_->year == $curr_year
    #         and  $_->is_visible  
    #         and !$_->is_hidden 
    #     )
    # });


    # say "CALL: get_publications_core author $author tag $tag";

    my $dbh = $self->app->db;

    my $team_obj = MTeam->static_get_by_name( $dbh, $team );
    if ( !defined $team_obj ){
        # no such master. Assume, that author id was given
        $team_obj = MTeam->static_get( $dbh, $team );    
    }

    my $author_obj = MAuthor->static_get_by_master( $dbh, $author );
    if ( !defined $author_obj ){
        # no such master. Assume, that author id was given
        $author_obj = MAuthor->static_get( $dbh, $author );    
    }

    my $tag_obj = MTag->static_get_by_name( $dbh, $tag );
    if ( !defined $tag_obj ){
        # no such master. Assume, that author id was given
        $tag_obj = MTag->static_get( $dbh, $tag );    
    }
    
    my $teamid = undef;
    $teamid = $team_obj->{id} if defined $team_obj;    

    my $master_id = undef;
    $master_id = $author_obj->{id} if defined $author_obj;

    my $tagid = undef;
    $tagid = $tag_obj->{id} if defined $tag_obj;

    # $teamid    = undef unless defined $team;
    # $master_id = undef unless defined $author or defined $author_obj;
    # $tagid     = undef unless defined $tag;


    my @dbg = MEntry->static_get_filter(
        $dbh,   $master_id, $year,    $bibtex_type, $entry_type,
        $tagid, $teamid,    $visible, $permalink,   $hidden
    );

    return @dbg;
}
####################################################################################
sub Fclean_ugly_bibtex_fields_for_all_entries {
    my $dbh = shift;

    my @entries = MEntry->static_all($dbh);
    my $num_del = 0;
    foreach my $e (@entries) {
        $num_del = $num_del + $e->clean_ugly_bibtex_fields($dbh);
    }
    return $num_del;
}
####################################################################################
sub Fhandle_author_uids_change_for_all_entries {
    my $dbh = shift;

    my $storage = StorageBase->get();
    my @all_entries = $storage->entries_all;

    my $num_authors_created  = 0;

    foreach my $e (@all_entries) {
        my $cre = $storage->add_entry_authors( $e, 0 );
        $e->save($dbh);

        $num_authors_created  = $num_authors_created + $cre;
    }
    return $num_authors_created;
}
####################################################################################
