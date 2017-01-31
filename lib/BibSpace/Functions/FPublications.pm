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
use DBIx::Connector;

use Scalar::Util;

use BibSpace::Functions::Core;

use Exporter;
our @ISA = qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
    Fdo_regenerate_html
    FprintBibtexWarnings
    Fhandle_add_edit_publication_Repo
    Fget_publications_main_hashed_args_only
    Fget_publications_main_hashed_args
    Fget_publications_core
);
####################################################################################
sub Fdo_regenerate_html {
    my ($repo, $bst_file, $force, @entries) = @_;


    my $num_fixes = 0;
    for my $e (@entries) {
        $e->bst_file($bst_file);
        $e->regenerate_html( $force, $bst_file );
    }
    $repo->save(@entries);
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
sub Fhandle_add_edit_publication_Repo {
my ( $entriesRepo, $new_bib, $id, $action, $bst_file ) = @_;

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

    say "Fhandle_add_edit_publication_Repo: id $id";
    
    if( $id > 0){
        $e = $entriesRepo->find( sub {$_->id == $id} ); 
    }
    if(!$e){
        $e = Entry->new( idProvider => $entriesRepo->getIdProvider, id=>$id, bib=>$new_bib );
    }
    $e->bib($new_bib);

    
    my $bibtex_code_valid = $e->populate_from_bib();

    # We check Bibtex errors for all requests
    if ( !$bibtex_code_valid ) {
        $status_code_str = 'ERR_BIBTEX';
        return ( $e, $status_code_str, -1, -1 );
    }

    my $tmp_e = $entriesRepo->find( sub { ($_->bibtex_key cmp $e->bibtex_key)==0 } ); 
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
        $entriesRepo->save($e);

        $added_under_id = $e->id;
    }
    else {
        warn
            "Fhandle_add_edit_publication_repo action $action does not match the known actions: save, preview, check_key.";
    }    # action save
    return ( $e, $status_code_str, $existing_id, $added_under_id );
}

####################################################################################
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

    my $team_obj;     
    if(defined $team){
        $team_obj = $self->app->repo->teams_find( sub{ $_->name eq $team } );
        if( !$team_obj ){
            $team_obj = $self->app->repo->teams_find( sub{ $_->id == $team } );
        }
    }
    my $author_obj;
    if(defined $author){
        if( Scalar::Util::looks_like_number($author) ){
            $author_obj = $self->app->repo->authors_find(sub{ $_->master_id == $author });
        }
        else{
            $author_obj = $self->app->repo->authors_find(sub{ $_->master eq $author });
        }
    }   
    my $tag_obj;
    if(defined $tag){
        $tag_obj = $self->app->repo->tags_find( sub{ $_->name eq $tag } );
        if( !$tag_obj ){
            $tag_obj = $self->app->repo->tags_find( sub{ $_->id == $tag } );    
        }
    }
    my $tag_obj_perm;
    if(defined $permalink){
        $tag_obj_perm = $self->app->repo->tags_find( sub{ $_->name eq $permalink } );
        if( !$tag_obj_perm ){
            $self->app->repo->tags_find( sub{ $_->id == $permalink } );
        }
    }
    
    my $teamid = undef;
    $teamid = $team_obj->id if defined $team_obj;    
    my $master_id = undef;
    $master_id = $author_obj->id if defined $author_obj;
    my $tagid = undef;
    $tagid = $tag_obj->id if defined $tag_obj;


    ### WARNING, always compare if something is null by searching by name OR id!!
    # my $cmp1 = undef == 33;
    # my $cmp2 = undef == 'dddd'; # this is 1!!!!!!!!!!!
    # my $cmp3 = $cmp1 or $cmp2;
    # my $cmp4 = undef eq 33;
    # my $cmp5 = undef eq 'dddd'; 
    # my $cmp6 = $cmp4 or $cmp5;
    # $self->app->logger->warn("undef == id: 1 $cmp1 / 2 $cmp2 / 3 $cmp3 / 4 $cmp4 / 5 $cmp5 / 6 $cmp6 / " );    

    # $self->app->logger->debug("==== START new Filtering ====", "Fget_publications_core_storage" );
    # filtering
    my @entries = $self->app->repo->entries_all;

    # simple filters
    if( defined $year and $year > 0 ){
        # $self->app->logger->debug("BEFORE Filtering year. Got ".scalar(@entries)." results", "Fget_publications_core_storage" );
        @entries = grep { (defined $_->year and $_->year == $year) } @entries;
        # $self->app->logger->debug("AFTER Filtering year. Got ".scalar(@entries)." results", "Fget_publications_core_storage" );
    }

    # $bibtex_type - is in fact query for OurType
    if(defined $bibtex_type){
        # $self->app->logger->debug("BEFORE Filtering bibtex_type. Got ".scalar(@entries)." results", "Fget_publications_core_storage" );
        @entries = grep { $_->matches_our_type($bibtex_type, $self->app->repo) } @entries;
        # $self->app->logger->debug("AFTER Filtering bibtex_type. Got ".scalar(@entries)." results", "Fget_publications_core_storage" );
    }
    if(defined $entry_type){
        # $self->app->logger->debug("BEFORE Filtering entry_type. Got ".scalar(@entries)." results", "Fget_publications_core_storage" );
        @entries = grep { $_->entry_type eq $entry_type } @entries;
        # $self->app->logger->debug("AFTER Filtering entry_type. Got ".scalar(@entries)." results", "Fget_publications_core_storage" );
    }
    if(defined $permalink and defined $tag_obj_perm){
        @entries = grep { $_->has_tag($tag_obj_perm) } @entries;
    }
    if(defined $hidden){
        # $self->app->logger->debug("BEFORE Filtering hidden. Got ".scalar(@entries)." results", "Fget_publications_core_storage" );
        @entries = grep { $_->hidden == $hidden } @entries;
        # $self->app->logger->debug("AFTER Filtering hidden. Got ".scalar(@entries)." results", "Fget_publications_core_storage" );
    }
    # complex filters
    if(defined $visible and $visible == 1){
        @entries = grep { $_->is_visible } @entries;
    }
    if(defined $master_id and defined $author_obj){
        # $self->app->logger->debug("BEFORE Filtering author. Got ".scalar(@entries)." results", "Fget_publications_core_storage" );
        @entries = grep { $_->has_master_author($author_obj) } @entries;
        # $self->app->logger->debug("AFTER Filtering author. Got ".scalar(@entries)." results", "Fget_publications_core_storage" );
    }
    if(defined $tagid and defined $tag_obj){
        # $self->app->logger->debug("BEFORE Filtering tag. Got ".scalar(@entries)." results", "Fget_publications_core_storage" );
        @entries = grep { $_->has_tag($tag_obj) } @entries;
        # $self->app->logger->debug("AFTER Filtering tag. Got ".scalar(@entries)." results", "Fget_publications_core_storage" );
    }
    if(defined $teamid and defined $team_obj){
        @entries = grep { $_->has_team($team_obj) } @entries;
    }
    if($debug == 1){
        say "Fget_publications_core_storage Input author = $author" if defined $author;
        say "Fget_publications_core_storage Input year = $year" if defined $year;
        say "Fget_publications_core_storage Input bibtex_type = $bibtex_type" if defined $bibtex_type;
        say "Fget_publications_core_storage Input entry_type = $entry_type" if defined $entry_type;
        say "Fget_publications_core_storage Input tag = $tag" if defined $tag;
        say "Fget_publications_core_storage Input team = $team" if defined $team;
        say "Fget_publications_core_storage Input visible = $visible" if defined $visible;
        say "Fget_publications_core_storage Input permalink = $permalink" if defined $permalink;
        say "Fget_publications_core_storage Input hidden = $hidden" if defined $hidden;
        say "Fget_publications_core_storage Input debug = $debug" if defined $debug;
        say "Fget_publications_core_storage Found ".scalar(@entries)." entries";
    }

    return @entries;
}
####################################################################################
sub Fget_publications_core {
    my @input = @_;
    # this is good for tests - 
    # with debug=>1, the number of returned entries should be identical
    # Fget_publications_core_old(@input);

    return Fget_publications_core_storage(@input);
}
####################################################################################
# Keep this for a while. Reason: see above (good for tests)
# sub Fget_publications_core_old {
#     my $self        = shift;
#     my $author      = shift;
#     my $year        = shift;
#     my $bibtex_type = shift;
#     my $entry_type  = shift;
#     my $tag         = shift;
#     my $team        = shift;
#     my $visible     = shift // 0;
#     my $permalink   = shift;
#     my $hidden      = shift;
#     my $debug       = shift // 0;


#     my $dbh = $self->app->db;

#     my $team_obj = MTeam->static_get_by_name( $dbh, $team );
#     if ( !defined $team_obj ){
#         # no such master. Assume, that author id was given
#         $team_obj = MTeam->static_get( $dbh, $team );    
#     }

#     my $author_obj = MAuthor->static_get_by_master( $dbh, $author );
#     if ( !defined $author_obj ){
#         # no such master. Assume, that author id was given
#         $author_obj = MAuthor->static_get( $dbh, $author );    
#     }

#     my $tag_obj = MTag->static_get_by_name( $dbh, $tag );
#     if ( !defined $tag_obj ){
#         # no such master. Assume, that author id was given
#         $tag_obj = MTag->static_get( $dbh, $tag );    
#     }
    
#     my $teamid = undef;
#     $teamid = $team_obj->{id} if defined $team_obj;    

#     my $master_id = undef;
#     $master_id = $author_obj->{id} if defined $author_obj;

#     my $tagid = undef;
#     $tagid = $tag_obj->{id} if defined $tag_obj;


#     my @entries = MEntry->static_get_filter(
#         $dbh,   $master_id, $year,    $bibtex_type, $entry_type,
#         $tagid, $teamid,    $visible, $permalink,   $hidden
#     );

#     if($debug == 1){
#         say "DB Input author = $author" if defined $author;
#         say "DB Input year = $year" if defined $year;
#         say "DB Input bibtex_type = $bibtex_type" if defined $bibtex_type;
#         say "DB Input entry_type = $entry_type" if defined $entry_type;
#         say "DB Input tag = $tag" if defined $tag;
#         say "DB Input team = $team" if defined $team;
#         say "DB Input visible = $visible" if defined $visible;
#         say "DB Input permalink = $permalink" if defined $permalink;
#         say "DB Input hidden = $hidden" if defined $hidden;
#         say "DB Input debug = $debug" if defined $debug;
#         say "DB Found ".scalar(@entries)." entries";
#     }
#     return @entries;
# }
####################################################################################
