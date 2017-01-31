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

sub Fget_publications_core {
    my $self        = shift;
    my $query_author      = shift;
    my $query_year        = shift;
    my $query_bibtex_type = shift;
    my $query_entry_type  = shift;
    my $query_tag         = shift;
    my $query_team        = shift;
    my $query_visible     = shift // 0; # value cannot be set by the end-user
    my $query_permalink   = shift;
    my $query_hidden      = shift;  # value cannot be set by the end-user
    my $debug       = shift // 0;   # value cannot be set by the end-user


    my $team_obj;     
    if(defined $query_team){
        $team_obj = $self->app->repo->teams_find( sub{ $_->name eq $query_team } );
        if( !$team_obj ){
            $team_obj = $self->app->repo->teams_find( sub{ $_->id == $query_team } );
        }
    }
    my $author_obj;
    if(defined $query_author){
        if( Scalar::Util::looks_like_number($query_author) ){
            $author_obj   = $self->app->repo->authors_find(sub{ $_->master_id == $query_author });
            $author_obj ||= $self->app->repo->authors_find(sub{ $_->id == $query_author });
        }
        else{
            $author_obj = $self->app->repo->authors_find(sub{ $_->master eq $query_author });
            $author_obj ||= $self->app->repo->authors_find(sub{ $_->uid eq $query_author });
        }
    }   
    my $tag_obj;
    if(defined $query_tag){
        $tag_obj = $self->app->repo->tags_find( sub{ $_->name eq $query_tag } );
        if( !$tag_obj ){
            $tag_obj = $self->app->repo->tags_find( sub{ $_->id == $query_tag } );    
        }
    }
    my $tag_obj_perm;
    if(defined $query_permalink){
        $tag_obj_perm = $self->app->repo->tags_find( sub{ $_->permalink eq $query_permalink } );
        if( !$tag_obj_perm ){
            $self->app->repo->tags_find( sub{ $_->id == $query_permalink } );
        }
    }

    # $self->app->logger->debug("==== START new Filtering ====", "Fget_publications_core" );


    my @entries = $self->app->repo->entries_all;

    ###### filtering

    
    

    # WARNING: this overwrites all entries - this filtering must be done as first!
    if($query_author){
        if($author_obj){
            @entries = $author_obj->get_entries; 
        }
        else{
            # searched for author, but not found any = immediate return empty array
            return ();
        }
    }
     

    # simple filters
    if( defined $query_year ){
        @entries = grep { (defined $_->year and $_->year == $query_year) } @entries;
    }

    # $bibtex_type - is in fact query for OurType
    if(defined $query_bibtex_type){
        @entries = grep { $_->matches_our_type($query_bibtex_type, $self->app->repo) } @entries;
    }
    if(defined $query_entry_type){
        @entries = grep { $_->entry_type eq $query_entry_type } @entries;
    }
    if(defined $query_permalink){
        if(defined $tag_obj_perm){
            @entries = grep { $_->has_tag($tag_obj_perm) } @entries;
        }
        else{
            return ();
        }
    }
    # All entries = hidden + unhidden entries
    # by default, we return all (e.g., for admin interface)
    if(defined $query_hidden){
        @entries = grep { $_->hidden == $query_hidden } @entries;
    }
    # Entries of visible authors
    # by default, we return entries of all authors
    if(defined $query_visible and $query_visible == 1){
        @entries = grep { $_->is_visible } @entries;
    }

    ######## complex filters
    
    if(defined $query_tag){
        if(defined $tag_obj){
            @entries = grep { $_->has_tag($tag_obj) } @entries;
        }
        else{
            return ();
        }
    }
    if(defined $query_team){
        if(defined $team_obj){
            @entries = grep { $_->has_team($team_obj) } @entries;
        }
        else{
            return ();
        }
    } 
    if($debug == 1){
        $self->app->logger->debug("Fget_publications_core Input author = $query_author") if defined $query_author;
        $self->app->logger->debug("Fget_publications_core Input year = $query_year") if defined $query_year;
        $self->app->logger->debug("Fget_publications_core Input bibtex_type = $query_bibtex_type") if defined $query_bibtex_type;
        $self->app->logger->debug("Fget_publications_core Input entry_type = $query_entry_type") if defined $query_entry_type;
        $self->app->logger->debug("Fget_publications_core Input tag = $query_tag") if defined $query_tag;
        $self->app->logger->debug("Fget_publications_core Input team = $query_team") if defined $query_team;
        $self->app->logger->debug("Fget_publications_core Input visible = $query_visible") if defined $query_visible;
        $self->app->logger->debug("Fget_publications_core Input permalink = $query_permalink") if defined $query_permalink;
        $self->app->logger->debug("Fget_publications_core Input hidden = $query_hidden") if defined $query_hidden;
        $self->app->logger->debug("Fget_publications_core Input debug = $debug") if defined $debug;
        $self->app->logger->debug("Fget_publications_core Found ".scalar(@entries)." entries");
    }

    return @entries;
}
####################################################################################
