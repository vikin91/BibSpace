package BibSpace::Controller::Publications;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use Mojo::IOLoop;

# use File::Slurp;     # should be replaced in the future
use Path::Tiny;      # for creating directories
use Try::Tiny;

use v5.16;           #because of ~~
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

use TeX::Encode;
use Encode;

use BibSpace::Functions::Core;
use BibSpace::Functions::FPublications;


use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::UserAgent;
use Mojo::Log;

our %mons = (
    1  => 'January',
    2  => 'February',
    3  => 'March',
    4  => 'April',
    5  => 'May',
    6  => 'June',
    7  => 'July',
    8  => 'August',
    9  => 'September',
    10 => 'October',
    11 => 'November',
    12 => 'December'
);
####################################################################################
# work, but not for now
# sub all_ajax {
#   my $self = shift;
#   my $entry_type = undef;
#   $entry_type = $self->param('entry_type') // undef;
#   my @objs = Fget_publications_main_hashed_args( $self, { entry_type => $entry_type } );
#   $self->stash( entries => \@objs );
#   my $html = $self->render_to_string( template => 'publications/all_table' );
#   $self->render( text => $html );
# }
####################################################################################
sub all {
    my $self = shift;

    my @all = Fget_publications_main_hashed_args( $self, {year=>undef});
    my @filtered = Fget_publications_main_hashed_args( $self, {}, \@all);

    $self->stash( entries => \@filtered, all_entries => \@all);
    my $html = $self->render_to_string( template => 'publications/all' );
    $self->render( data => $html );
}
####################################################################################
sub all_recently_added {
    my $self = shift;
    my $num = $self->param('num') // 10;

    $self->app->logger->info("Displaying recently added entries.");

    my @all = Fget_publications_main_hashed_args( $self, {year=>undef});
    my @added_entries = sort { $b->creation_time cmp $a->creation_time } @all;
    @added_entries = @added_entries[ 0 .. $num - 1 ];

    my @filtered = Fget_publications_main_hashed_args( $self, {}, \@added_entries);
    # special sorting here
    @filtered = sort { $b->creation_time cmp $a->creation_time } @filtered;

    $self->stash( entries => \@filtered, all_entries => \@added_entries );
    $self->render( template => 'publications/all' );
}
####################################################################################

sub all_recently_modified {
    my $self = shift;
    my $num = $self->param('num') // 10;

    $self->app->logger->info("Displaying recently modified entries.");

    
    my @all = Fget_publications_main_hashed_args( $self, {year=>undef});
    my @modified_entries = sort { $b->modified_time cmp $a->modified_time } @all;
    @modified_entries = @modified_entries[ 0 .. $num - 1 ];

    my @filtered = Fget_publications_main_hashed_args( $self, {}, \@modified_entries);
    # special sorting here
    @filtered = sort { $b->modified_time cmp $a->modified_time } @filtered;


    $self->stash( entries => \@filtered, all_entries => \@modified_entries );
    $self->render( template => 'publications/all' );
}

####################################################################################
sub all_without_tag {
    my $self         = shift;
    my $tagtype      = $self->param('tagtype') // 1;

    # this will filter entries based on query
    my @all = Fget_publications_main_hashed_args( $self, {year=>undef} );
    
    my @untagged_entries = grep { scalar $_->get_tags($tagtype) == 0 } @all;
    my @filtered = Fget_publications_main_hashed_args( $self, {}, \@untagged_entries);


    my $msg
        = "This list contains papers that have no tags of type '$tagtype'. Use this list to tag the untagged papers! ";
    $self->stash( msg_type => 'info', msg => $msg );
    $self->stash( entries => \@filtered, all_entries => \@untagged_entries );
    $self->render( template => 'publications/all'  );
}
####################################################################################
sub all_orphaned {
    my $self = shift;

    my @all = Fget_publications_main_hashed_args( $self, {year=>undef} );
    my @entries = grep { scalar( $_->get_authors ) == 0 } @all;
    my @filtered = Fget_publications_main_hashed_args( $self, {}, \@entries);

    my $msg
        = "This list contains papers, that are currently not assigned to any of authors.";
    $msg .= '<a href="' . $self->url_for('delete_all_without_author') .'"> Click to delete </a>';

    $self->stash( msg_type => 'info', msg => $msg );
    $self->stash(entries  => \@filtered, all_entries => \@entries);
    $self->render( template => 'publications/all' );
}
####################################################################################
sub show_unrelated_to_team {
    my $self    = shift;
    my $team_id = $self->param('teamid');

    $self->app->logger->info(
        "Displaying entries unrelated to team '$team_id'.");


    my $team_name = "";
    my $team = $self->app->repo->teams_find( sub { $_->id == $team_id } );
    $team_name = $team->name if defined $team;


    my @all = Fget_publications_main_hashed_args( $self, {year=>undef} );
    my @teamEntres = $team->get_entries;

    my %inTeam = map { $_ => 1 } @teamEntres;
    my @entriesUnrelated = grep { not $inTeam{$_} } @all;

    # hash destroys order!
    @entriesUnrelated = sort_publications(@entriesUnrelated);
    my @filtered = Fget_publications_main_hashed_args( $self, {}, \@entriesUnrelated);

    my $msg = "This list contains papers, that are:
        <ul>
            <li>Not assigned to the team "
        . $team_name . "</li>
            <li>Not assigned to any author (former or actual) of the team "
        . $team_name . "</li>
        </ul>";

    $self->stash( msg_type => 'info', msg => $msg );
    $self->stash( entries  => \@filtered, all_entries => \@entriesUnrelated);
    $self->render( template => 'publications/all'  );
}
####################################################################################
sub all_with_missing_month {
    my $self = shift;

    $self->app->logger->info("Displaying entries without month");


    my @all = Fget_publications_main_hashed_args( $self, {year=>undef} );
    my @entries = grep { !defined $_->month or $_->month < 1 or $_->month > 12 } @all;

    my @filtered = Fget_publications_main_hashed_args( $self, {}, \@entries);

    my $msg
        = "This list contains entries with missing BibTeX field 'month'. ";
    $msg .= "Add this data to get the proper chronological sorting.";

    $self->stash( msg_type => 'info', msg => $msg );
    $self->stash( entries => \@filtered, all_entries => \@entries );
    $self->render( template => 'publications/all'  );
}
####################################################################################
sub all_candidates_to_delete {
    my $self = shift;

    $self->app->logger->info(
        "Displaying entries that are candidates_to_delete");


    my @all = Fget_publications_main_hashed_args( $self, {year=>undef} );
    my @entries = grep { scalar $_->get_tags == 0 } @all;    # no tags
    @entries = grep { scalar $_->get_teams == 0 } @entries;   # no relation to teams
    @entries = grep { scalar $_->get_exceptions == 0 } @entries;    # no exceptions
    my @filtered = Fget_publications_main_hashed_args( $self, {}, \@entries);


    my $msg = "<p>This list contains papers, that are:</p>
      <ul>
          <li>Not assigned to any team AND</li>
          <li>have exactly 0 tags AND</li>
          <li>not assigned to any author that is (or was) a member of any team AND </li>
          <li>have exactly 0 exceptions assigned.</li>
      </ul>
      <p>Such entries may wanted to be removed form the system or serve as a help with configuration.</p>";

    $self->stash( msg_type => 'info', msg => $msg );
    $self->stash( entries => \@filtered, all_entries => \@entries );
    $self->render( template => 'publications/all'  );
}
####################################################################################
####################################################################################
####################################################################################
sub all_bibtex {
    my $self       = shift;

    my @objs = Fget_publications_main_hashed_args( $self, { hidden => 0 } );

    my $big_str = "<pre>\n";
    foreach my $obj (@objs) {
        $big_str .= $obj->{bib};
        $big_str .= "\n";
    }
    $big_str .= "\n</pre>";
    $self->render( text => $big_str );
}
####################################################################################

sub all_read {
    my $self = shift;

    # this function does filtering !
    my @objs = Fget_publications_main_hashed_args( $self, { hidden => 0 } );

    $self->stash( entries => \@objs );
    my $html = $self->render_to_string( template => 'publications/all_read' );
    $self->render( data => $html );
}

####################################################################################

sub single {
    my $self = shift;
    my $id   = $self->param('id');

    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );

    my @objs;
    if ( defined $entry ) {
        push @objs, $entry;
    }
    else {
        $self->stash(
            msg_type => 'danger',
            msg      => "Entry $id does not exist."
        );
    }
    $self->stash( entries => \@objs );
    $self->render( template => 'publications/all' );
}

####################################################################################

sub single_read {
    my $self = shift;
    my $id   = $self->param('id');

    my @objs = ();

    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );

    if ( defined $entry and $entry->is_hidden == 0 ) {
        push @objs, $entry;
    }
    $self->stash( entries => \@objs );
    $self->render( template => 'publications/all_read' );
}
####################################################################################
sub fixMonths {
    my $self = shift;

    $self->app->logger->info("Fix months in all entries.");

    my @entries = $self->app->repo->entries_all;

    foreach my $entry (@entries) {
        $entry->fix_month();
    }
    $self->app->repo->entries_save(@entries);

    $self->flash(
        msg      => 'Fixing entries month field finished.',
        msg_type => 'info'
    );
    $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub toggle_hide {
    my $self = shift;
    my $id   = $self->param('id');

    $self->app->logger->info("Toggle hide entry '$id'.");

    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );

    if ( defined $entry ) {
        $entry->toggle_hide;
        $self->app->repo->entries_update($entry);
    }
    else {
        $self->flash( msg => "There is no entry with id $id" );
    }


    $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub make_paper {
    my $self = shift;
    my $id   = $self->param('id');

    $self->app->logger->info("Make entry '$id' 'paper'.");

    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );

    if ( defined $entry ) {
        $entry->make_paper();
        $self->app->repo->entries_update($entry);
    }
    else {
        $self->flash( msg => "There is no entry with id $id" );
    }


    $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub make_talk {
    my $self = shift;
    my $id   = $self->param('id');

    $self->app->logger->info("Make entry '$id' 'talk'.");

    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );

    if ( defined $entry ) {
        $entry->make_talk();
        $self->app->repo->entries_update($entry);
    }
    else {
        $self->flash( msg => "There is no entry with id $id" );
    }


    $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub delete_all_without_author {
    my $self = shift;

    my @entries = $self->app->repo->entries_filter(
        sub { scalar( $_->get_authors ) == 0 } );

    foreach my $entry (@entries){
        my @au = $entry->authorships_all;
        $self->app->repo->authorships_delete(@au);
        my @ex = $entry->exceptions_all;
        $self->app->repo->exceptions_delete(@ex);
        my @la = $entry->labelings_all;
        $self->app->repo->labelings_delete(@la);
    }

    my $num_deleted = $self->app->repo->entries_delete(@entries);

    my $msg
        = "$num_deleted entries have been removed";
    $self->flash( msg => $msg, msg_type => 'info' );
    $self->redirect_to( 'all_orphaned' );
    
}


####################################################################################
sub fix_file_urls {
    my $self = shift;
    my $id   = $self->param('id');

    $self->app->logger->info("Fixing file urls for all entries.");

    my @all_entries;

    if ($id) {
        my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );
        push @all_entries, $entry if $entry;
    }
    else {
        @all_entries = $self->app->repo->entries_all;
    }

    my $big_str    = ".\n";
    my $num_fixes  = 0;
    my $num_checks = 0;

    for my $entry (@all_entries) {

        ++$num_checks;
        my $str;
        $str .= "Entry " . $entry->id . ": ";
        $entry->discover_attachments( $self->app->get_upload_dir );
        my @discovered_types = $entry->attachments_keys;

        

        $str .= "has types: (";
        foreach (@discovered_types) {
            $str .= " $_, ";
        }
        $str .= "). Fixed: ";

        # say $str;
        my $fixed;
        my $file     = $entry->get_attachment('paper');
        my $file_url = $self->url_for(
            'download_publication_pdf',
            filetype => "paper",
            id       => $entry->id
        )->to_abs;

        if ( $file and $file->exists ) {
            $entry->remove_bibtex_fields( ['pdf'] );
            $str .= "\n\t";
            $entry->add_bibtex_field( "pdf", "$file_url" );
            $fixed = 1;
            $str .= "Added Bibtex filed PDF " . $file_url;
        }

        $file     = $entry->get_attachment('slides');
        $file_url = $self->url_for(
            'download_publication',
            filetype => "slides",
            id       => $entry->id
        )->to_abs;

        if ( $file and $file->exists ) {
            $entry->remove_bibtex_fields( ['slides'] );
            $str .= "\n\t";
            $entry->add_bibtex_field( "slides", "$file_url" );
            $fixed = 1;
            $str .= "Added Bibtex filed SLIDES " . $file_url;
        }
        $str .= "\n";

        if ($fixed) {
            $big_str .= $str;
            ++$num_fixes;
            $entry->regenerate_html( 0, $self->app->bst,
                $self->app->bibtexConverter );
        }
    }

    $self->app->logger->info("Url fix results $big_str.");

    $self->flash(
        msg_type => 'info',
        msg =>
            "Checked $num_checks and regenerated $num_fixes entries. You may need to run regenerate HTML force now. Detailed fix results have been saved to log."
    );
    $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub remove_attachment {
    my $self     = shift;
    my $id       = $self->param('id');                     # entry ID
    my $filetype = $self->param('filetype') // 'paper';    # paper, slides

    $self->app->logger->info(
        "Requested to remove attachment of type '$filetype'.");

    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );
    my ( $msg, $msg_type );

    $entry->discover_attachments( $self->app->get_upload_dir );


    if ( $entry->attachments_has($filetype) ) {
        $self->app->logger->debug(
            "Entry has attachment of type '$filetype'.");

        if ( $filetype eq 'paper' ) {
            $entry->remove_bibtex_fields( ['pdf'] );
        }
        elsif ( $filetype eq 'slides' ) {
            $entry->remove_bibtex_fields( ['slides'] );
        }
        $entry->delete_attachment($filetype);

        $entry->regenerate_html( 1, $self->app->bst,
            $self->app->bibtexConverter );
        $self->app->repo->entries_save($entry);

        $msg      = "The attachment has been removed for entry '$id'.";
        $msg_type = 'success';
        $self->app->logger->info($msg);
    }
    else {
        $self->app->logger->debug(
            "Entry has NO attachment of type '$filetype'.");

        $msg
            = "File not found. Cannot remove attachment. Filetype '$filetype', entry '$id'.";
        $msg_type = 'danger';
        $self->app->logger->error($msg);
    }

    $self->flash( msg_type => $msg_type, msg => $msg );
    $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub discover_attachments {
    my $self = shift;
    my $id   = $self->param('id');
    my $do   = $self->param('do');


    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );
    $self->app->logger->info("Discovery of attachments for entry ID '$id'." );

    my $msg;
    my $msg_type = 'info';
    if ( $entry and $do and $do == 1 ) {
        $entry->discover_attachments( $self->app->get_upload_dir );
        $msg .= "Discovery was run for dir '"
            . $self->app->get_upload_dir . "'.";
    }
    elsif( $entry ) {
        $msg .= "Just displaying information. ";
        $msg
        .= "Attachments debug: <pre style=\"font-family:monospace;\">"
        . $entry->get_attachments_debug_string
        . "</pre>";
    }
    else{
        $msg = "Cannot discover, entry '$id' not found."; 
        $msg_type = 'danger';
        $self->app->logger->error( $msg );
    }
    

    $self->flash( msg_type => $msg_type, msg => $msg );
    $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub download {
    my $self     = shift;
    my $id       = $self->param('id');                     # entry ID
    my $filetype = $self->param('filetype');

    $self->app->logger->info(
        "Requested to download attachment of type '$filetype' for entry ID '"
            . $id
            . "'." );

    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );
    my $file;

    if ($entry) {
        $entry->discover_attachments( $self->app->get_upload_dir );
        $file = $entry->get_attachment($filetype);
    }
    else {
        $self->app->logger->error("Cannot download - entry '$id' not found.");
        $self->render( status => 404, text => "File not found." );
        return;
    }

    if ( $file and -e $file ) {
        $self->app->logger->info(
            "Downloading file download '$filetype' for entry '$id'.");
        $self->render_file( 'filepath' => $file );
        return;
    }
    $self->app->logger->error(
        "File not found. Requested download for entry '$id', filetype '$filetype'."
    );
    $self->render( text => "File not found.", status => 404 );
}
####################################################################################

sub add_pdf {
    my $self  = shift;
    my $id    = $self->param('id');
    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );

    if ( !defined $entry ) {
        $self->flash( msg_type => 'danger', msg => "Entry '$id' not found." );
        $self->redirect_to( $self->get_referrer );
        return;
    }
    $entry->populate_from_bib();
    $entry->generate_html( $self->app->bst, $self->app->bibtexConverter );

    $self->stash( mentry => $entry );
    $self->render( template => 'publications/pdf_upload' );
}
####################################################################################
sub add_pdf_post {
    my $self          = shift;
    my $id            = $self->param('id');
    my $filetype      = $self->param('filetype');
    my $uploaded_file = $self->param('uploaded_file');

    my $uploads_directory
        = Path::Tiny->new( $self->app->get_upload_dir );

    $self->app->logger->info("Saving attachment for entry '$id'");

    # Check file size
    if ( $self->req->is_limit_exceeded ) {
        my $curr_limit_B = $ENV{MOJO_MAX_MESSAGE_SIZE};
        $curr_limit_B ||= 16777216;
        my $curr_limit_MB = $curr_limit_B / 1024 / 1024;
        $self->app->logger->info(
            "Saving attachment for paper id '$id': limit exceeded. Current limit: $curr_limit_MB MB."
        );
        $self->flash(
            msg      => "The File is too big and cannot be saved!",
            msg_type => "danger"
        );
        $self->redirect_to( $self->get_referrer );
        return;
    }


    if ( !$uploaded_file ) {
        $self->flash(
            msg      => "File upload unsuccessful!",
            msg_type => "danger"
        );
        $self->app->logger->info(
            "Saving attachment for paper id '$id' FAILED. Unknown reason");
        $self->redirect_to( $self->get_referrer );
        return;
    }

    my $size   = $uploaded_file->size;
    my $sizeKB = int( $size / 1024 );
    if ( $size == 0 ) {
        $self->flash(
            msg => "No file was selected or file has 0 bytes! Not saving!",
            msg_type => "danger"
        );
        $self->app->logger->info(
            "Saving attachment for paper id '$id' FAILED. File size is 0.");
        $self->redirect_to( $self->get_referrer );
        return;
    }

    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );

    if ( !defined $entry ) {
        $self->flash(
            msg_type => 'danger',
            msg      => "Entry '$id' does not exist."
        );
        $self->redirect_to( $self->get_referrer );
        return;
    }


    my $name      = $uploaded_file->filename;
    my @dot_arr   = split( /\./, $name );
    my $extension = $dot_arr[-1];


    my $file_url;
    my $destination;

    if ( $filetype eq 'paper' ) {
        $entry->delete_attachment('paper');
        $destination
            = $uploads_directory->path( "papers", "paper-$id.$extension" );
        $uploaded_file->move_to($destination);
        $self->app->logger->debug(
            "Attachments file has been moved to: $destination.");

        $entry->add_attachment( 'paper', $destination );
        $file_url = $self->url_for(
            'download_publication_pdf',
            filetype => "paper",
            id       => $entry->id
        )->to_abs;
        $entry->add_bibtex_field( 'pdf', "$file_url" );
    }
    elsif ( $filetype eq 'slides' ) {
        $entry->delete_attachment('slides');
        $destination = $uploads_directory->path( "slides",
            "slides-paper-$id.$extension" );
        $uploaded_file->move_to($destination);
        $self->app->logger->debug(
            "Attachments file has been moved to: $destination.");

        $entry->add_attachment( 'slides', $destination );
        $file_url = $self->url_for(
            'download_publication',
            filetype => "slides",
            id       => $entry->id
        )->to_abs;
        $entry->add_bibtex_field( 'slides', "$file_url" );
    }
    else {
        # ignore - we support only pdf and slides so far
    }

    $self->app->logger->info(
        "Saving attachment for entry '$id' under: '$destination'.");

    my $msg
        = "Successfully uploaded the $sizeKB KB file as <strong><em>$filetype</em></strong>.
      The file was renamed to:  <a href=\""
        . $file_url . "\">"
        . $destination->basename . "</a>";

    $entry->regenerate_html( 1, $self->app->bst,
        $self->app->bibtexConverter );
    $self->app->repo->entries_save($entry);

    $self->flash( msg_type => 'success', msg => $msg );
    $self->redirect_to( $self->get_referrer );
}

####################################################################################
sub mark_author_to_regenerate {
    my $self      = shift;
    my $author_id = $self->param('author_id');
    my $converter = $self->app->bibtexConverter;

    my $author = $self->app->repo->authors_find( sub{$_->id == $author_id} );

    my @entries;

    if($author){
        $self->app->logger->info("Marking entries of author '".$author->uid."' for HTML regeneration.");

        @entries = $author->get_entries;
        foreach my $entry (@entries){
            $entry->need_html_regen(1);
        }
        $self->app->repo->entries_save(@entries);
    }

    my $msg = "".scalar(@entries). " entries have been MARKED for regeneration. ";
    $msg .= "Now you may run 'regenerate all' or 'regenerate in chunks'. ";
    $msg .= "Regenration in chunks is useful for large set of entries. ";

    $self->app->logger->info($msg);
    $self->flash( msg_type => 'info', msg => $msg );
    $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub regenerate_html_for_all {
    my $self      = shift;
    my $converter = $self->app->bibtexConverter;

    $self->inactivity_timeout(3000);

    $self->app->logger->info("regenerate_html_for_all is running");

    my @entries   = $self->app->repo->entries_filter( sub{$_->need_html_regen == 1} );
    my $num_regen = Fregenerate_html_for_array($self->app, 0, $converter, \@entries);
    my $left_todo = scalar(@entries) - $num_regen;

    my $msg = "$num_regen entries have been regenerated. ";
    $msg .= "$left_todo furter entries still require regeneration.";
    $self->app->logger->info($msg);
    $self->flash( msg_type => 'info', msg => $msg );
    $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub regenerate_html_in_chunk {
    my $self      = shift;
    my $chunk_size = $self->param('chunk_size') // 30;

    my $converter = $self->app->bibtexConverter;

    $self->inactivity_timeout(3000);

    $self->app->logger->info("regenerate_html_in_chunk is running, chunk size $chunk_size ");

    my @entries   = $self->app->repo->entries_filter( sub{ $_->need_html_regen == 1} );

    my $last_entry_index = $chunk_size-1;
    $last_entry_index = scalar(@entries)-1 if scalar(@entries) < $chunk_size;

    my @portion_of_entries = @entries[ 0 .. $last_entry_index ];
    @portion_of_entries = grep {defined $_} @portion_of_entries;

    my $num_regen = Fregenerate_html_for_array($self->app, 1, $converter, \@portion_of_entries);
    my $left_todo = scalar(@entries) - $num_regen;

    my $msg = "$num_regen entries have been regenerated. ";
    $msg .= "$left_todo furter entries still require regeneration.";
    $self->app->logger->info($msg);
    $self->flash( msg_type => 'info', msg => $msg );
    $self->redirect_to( $self->get_referrer() );
}
####################################################################################
sub mark_all_to_regenerate {
    my $self      = shift;
    my $converter = $self->app->bibtexConverter;

    $self->app->logger->info("Marking all entries for HTML regeneration.");

    my @entries   = $self->app->repo->entries_all;
    foreach my $entry (@entries){
        $entry->need_html_regen(1);
        # $self->app->repo->entries_save($entry);
    }
    $self->app->repo->entries_save(@entries);

    my $msg = "".scalar(@entries). " entries have been MARKED for regeneration. ";
    $msg .= "Now you may run 'regenerate all' or 'regenerate in chunks'. ";
    $msg .= "Regenration in chunks is useful for large set of entries. ";
    $self->app->logger->info($msg);
    $self->flash( msg_type => 'info', msg => $msg );
    $self->redirect_to( $self->get_referrer() );

}

####################################################################################
sub regenerate_html {
    my $self      = shift;
    my $converter = $self->app->bibtexConverter;
    my $id        = $self->param('id');


    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );

    if ( !defined $entry ) {
        $self->flash(
            msg      => "There is no entry with id $id",
            msg_type => 'danger'
        );
        $self->redirect_to( $self->get_referrer );
        return;
    }
    my @entries   = ($entry);
    my $num_regen = Fregenerate_html_for_array($self->app, 1, $converter, \@entries);

    my $msg;
    if($num_regen == 1){
        $msg = "$num_regen entry has been regenerated.";
    }
    else{
        $msg = "$num_regen entries have been regenerated.";   
    }
    $self->app->logger->info($msg);
    $self->flash( msg_type => 'info', msg => $msg );

    $self->redirect_to( $self->get_referrer );
}
####################################################################################

sub delete_sure {
    my $self = shift;
    my $id   = $self->param('id');

    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );

    if ( !defined $entry ) {
        $self->app->logger->warn(
            "Entry '$id' does not exist and thus can't be deleted.");
        $self->flash(
            mgs_type => 'danger',
            msg      => "There is no entry with id $id"
        );
        $self->redirect_to( $self->get_referrer );
        return;
    }

    $entry->delete_all_attachments;
    my @entry_authorships = $entry->authorships_all;
    my @entry_labelings = $entry->labelings_all;
    my @entry_exceptions = $entry->exceptions_all;
    $self->app->repo->authorships_delete(@entry_authorships);
    $self->app->repo->labelings_delete(@entry_labelings);
    $self->app->repo->exceptions_delete(@entry_exceptions);
    $self->app->repo->entries_delete($entry);

    $self->app->logger->info("Entry '$id' has been deleted.");
    $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub show_authors_of_entry {
    my $self = shift;
    my $id   = $self->param('id');
    $self->app->logger->info("Showing authors of entry id $id");


    my $entry = $self->app->repo->entries_find( sub { $_->{id} == $id } );

    if ( !defined $entry ) {
        $self->flash( msg => "There is no entry with id $id" );
        $self->redirect_to( $self->get_referrer );
        return;
    }


    my @authors = map { $_->author } $entry->authorships_all;
    my @teams = $entry->get_teams;

    $self->stash( entry => $entry, authors => \@authors, teams => \@teams );
    $self->render( template => 'publications/show_authors' );
}
####################################################################################
####################################################################################
####################################################################################
sub manage_tags {
    my $self = shift;
    my $id   = $self->param('id');

    $self->app->logger->info("Manage tags of entry id $id");


    my $entry = $self->app->repo->entries_find( sub { $_->{id} == $id } );

    if ( !defined $entry ) {
        $self->flash( msg => "There is no entry with id $id" );
        $self->redirect_to( $self->get_referrer );
        return;
    }


    my @tags      = $entry->get_tags;
    my @tag_types = $self->app->repo->tagTypes_all;


    $self->stash( entry => $entry, tags => \@tags, tag_types => \@tag_types );
    $self->render( template => 'publications/manage_tags' );
}
####################################################################################

sub remove_tag {
    my $self     = shift;
    my $entry_id = $self->param('eid');
    my $tag_id   = $self->param('tid');

    my $entry = $self->app->repo->entries_find( sub { $_->id == $entry_id } );
    my $tag   = $self->app->repo->tags_find( sub    { $_->id == $tag_id } );

    if ( defined $entry and defined $tag ) {

        my $search_label = Labeling->new(
            entry    => $entry,
            tag      => $tag,
            entry_id => $entry->id,
            tag_id   => $tag->id
        );

        my $label = $self->app->repo->labelings_find(
            sub { $_->equals($search_label) } );

        if ($label) {

            ## you should always execute all those three commands together - smells like command pattern...
            $entry->remove_labeling($label);
            $tag->remove_labeling($label);
            $self->app->repo->labelings_delete($label);


            $self->app->logger->info( "Removed tag "
                    . $tag->name
                    . " from entry ID "
                    . $entry->id
                    . ". " );
        }
        else {
            # this paper does not have this tag - do nothing
            $self->app->logger->warn( "Cannot remove tag "
                    . $tag->name
                    . " from entry ID "
                    . $entry->id
                    . " - reason: labeling not found. " );
        }

    }
    

    $self->redirect_to( $self->get_referrer );

}
####################################################################################
sub add_tag {
    my $self     = shift;
    my $entry_id = $self->param('eid');
    my $tag_id   = $self->param('tid');

    my $entry = $self->app->repo->entries_find( sub { $_->id == $entry_id } );
    my $tag   = $self->app->repo->tags_find( sub    { $_->id == $tag_id } );

    if ( defined $entry and defined $tag ) {
        my $label = Labeling->new(
            entry    => $entry,
            tag      => $tag,
            entry_id => $entry->id,
            tag_id   => $tag->id
        );
        ## you should always execute all those three commands together - smells like command pattern...
        
        $self->app->repo->labelings_save($label);
        $entry->add_labeling($label);
        $tag->add_labeling($label);
    }
    else {
        # this paper does not have this tag - do nothing
        $self->app->logger->warn(
            "Cannot add tag $tag_id to entry ID $entry_id - reason: tag or entry not found. "
        );
    }

    $self->redirect_to( $self->get_referrer );
}
####################################################################################
####################################################################################
####################################################################################
sub manage_exceptions {
    my $self = shift;
    my $id   = $self->param('id');


    my $entry = $self->app->repo->entries_find( sub { $_->{id} == $id } );

    if ( !defined $entry ) {
        $self->flash( msg => "There is no entry with id $id" );
        $self->redirect_to( $self->get_referrer );
        return;
    }


    my @exceptions = $entry->exceptions_all;
    my @all_teams  = $self->app->repo->teams_all;
    my @teams      = $entry->get_teams;
    my @authors    = $entry->get_authors;

    # cannot use objects as keysdue to stringification!
    my %exceptions_hash = map { $_->team->id => 1 } @exceptions;
    my @unassigned_teams = grep { not $exceptions_hash{ $_->id } } @all_teams;


    $self->stash(
        entry            => $entry,
        exceptions       => \@exceptions,
        teams            => \@teams,
        all_teams        => \@all_teams,
        authors          => \@authors,
        unassigned_teams => \@unassigned_teams
    );
    $self->render( template => 'publications/manage_exceptions' );
}
####################################################################################
sub add_exception {
    my $self     = shift;
    my $entry_id = $self->param('eid');
    my $team_id  = $self->param('tid');


    my $msg;
    my $entry = $self->app->repo->entries_find( sub { $_->id == $entry_id } );
    my $team  = $self->app->repo->teams_find( sub   { $_->id == $team_id } );

    if ( defined $entry and defined $team ) {

        my $exception = Exception->new(
            entry    => $entry,
            team     => $team,
            entry_id => $entry->id,
            team_id  => $team->id
        );

        $entry->add_exception($exception);
        $team->add_exception($exception);
        $self->app->repo->exceptions_save($exception);

        $msg
            = "Exception added! Entry ID "
            . $entry->id
            . " will be now listed under team '"
            . $team->name . "'.";
    }
    else {
        $msg
            = "Cannot find entry or team to create exception. Searched team ID: "
            . $team_id
            . " entry ID: "
            . $entry_id . ".";
    }

    $self->flash( msg => $msg );
    $self->app->logger->info($msg);
    $self->redirect_to( $self->get_referrer );

}
####################################################################################

sub remove_exception {
    my $self     = shift;
    my $entry_id = $self->param('eid');
    my $team_id  = $self->param('tid');


    my $entry = $self->app->repo->entries_find( sub { $_->id == $entry_id } );
    my $team  = $self->app->repo->teams_find( sub   { $_->id == $team_id } );

    my $msg;

    if ( defined $entry and defined $team ) {

        my $ex = Exception->new(
            team_id  => $team_id,
            entry_id => $entry_id,
            team     => $team,
            entry    => $entry
        );

        my $exception
            = $self->app->repo->exceptions_find( sub { $_->equals($ex) } );

        if ( defined $exception ) {
            $entry->remove_exception($exception);
            $team->remove_exception($exception);
            $self->app->repo->exceptions_delete($exception);

            $msg
                = "Removed exception team '"
                . $team->name
                . "' from entry ID "
                . $entry->id . ". ";
        }
        else {
            $msg
                = "Cannot find exception to remove. Searched team '"
                . $team->name
                . "' entry ID: "
                . $entry->id . ".";
        }
    }
    else {
        $msg
            = "Cannot find exception to remove. Searched team ID: "
            . $team_id
            . " entry ID: "
            . $entry_id . ".";
    }

    $self->flash( msg => $msg );
    $self->app->logger->info($msg);

    $self->redirect_to( $self->get_referrer );

}
####################################################################################
####################################################################################
####################################################################################
sub get_adding_editing_message_for_error_code {
    my $self        = shift;
    my $exit_code   = shift;
    my $existing_id = shift || -1;

    # -1 You have bibtex errors! Not saving!";
    # -2 Displaying preview';
    # 0 Entry added successfully';
    # 1 Entry updated successfully';
    # 2 The proposed key is OK.
    # 3 Proposed key exists already - HTML message

    if ( $exit_code eq 'ERR_BIBTEX' ) {
        return
            "You have bibtex errors! No changes were written to the database.";
    }
    elsif ( $exit_code eq 'PREVIEW' ) {
        return 'Displaying preview. No changes were written to the database.';
    }
    elsif ( $exit_code eq 'ADD_OK' ) {
        return 'Entry added successfully. Switched to editing mode.';
    }
    elsif ( $exit_code eq 'EDIT_OK' ) {
        return 'Entry updated successfully.';
    }
    elsif ( $exit_code eq 'KEY_OK' ) {
        return
            'The proposed key is OK. You may continue with your edits. No changes were written to the database.';
    }
    elsif ( $exit_code eq 'KEY_TAKEN' ) {
        return
            'The proposed key exists already in DB under ID <button class="btn btn-danger btn-xs" tooltip="Entry ID"> <span class="glyphicon glyphicon-barcode"></span> '
            . $existing_id
            . '</button>.
                  <br>
                  <a class="btn btn-info btn-xs" href="'
            . $self->url_for( 'edit_publication', id => $existing_id )
            . '" target="_blank"><span class="glyphicon glyphicon-search"></span>Show me the existing entry ID '
            . $existing_id
            . ' in a new window</a>
                  <br>
                  Entry has not been saved. Please pick another BibTeX key. No changes were written to the database.';
    }
    elsif ( defined $exit_code and $exit_code ne '' ) {
        return "Unknown exit code: $exit_code";
    }

}


####################################################################################
sub publications_add_get {
    my $self = shift;
    $self->app->logger->info("Open Add Publication");

    my $msg = "<strong>Adding mode</strong> You operate on an unsaved entry!";

    my $bib = '@article{key' . get_current_year() . ',
      author = {Johny Example},
      journal = {Journal of this and that},
      publisher = {Printer-at-home publishing},
      title = {{Selected aspects of some methods}},
      year = {' . get_current_year() . '},
      month = {' . $mons{ get_current_month() } . '},
      day = {1--31},
    }';

    my $e_dummy = $self->app->entityFactory->new_Entry( bib => $bib );

    $e_dummy->populate_from_bib();
    $e_dummy->generate_html( $self->app->bst, $self->app->bibtexConverter );

    $self->stash( entry => $e_dummy, msg => $msg );
    $self->render( template => 'publications/add_entry' );
}
####################################################################################
sub publications_add_post {
    my $self            = shift;
    my $new_bib         = $self->param('new_bib');
    my $param_prev      = $self->param('preview');
    my $param_save      = $self->param('save');
    my $param_check_key = $self->param('check_key');

    my $action = 'default';
    $action = 'save'      if $param_save;         # user clicks save
    $action = 'preview'   if $param_prev;         # user clicks preview
    $action = 'check_key' if $param_check_key;    # user clicks check key

    $self->app->logger->info("Adding publication. Action: > $action <.");

    $new_bib =~ s/^\s+|\s+$//g;
    $new_bib =~ s/^\t//g;

    my $status_code_str;
    my $existing_id    = -1;
    my $added_under_id = -1;

    # status_code_strings
    # -2 => PREVIEW
    # -1 => ERR_BIBTEX
    # 0 => ADD_OK
    # 1 => EDIT_OK
    # 2 => KEY_OK
    # 3 => KEY_TAKEN


    my $entry = $self->app->entityFactory->new_Entry( bib => $new_bib );

    # any action
    if ( !$entry->has_valid_bibtex ) {
        $status_code_str = 'ERR_BIBTEX';
        my $msg = get_adding_editing_message_for_error_code( $self,
            $status_code_str, $existing_id );
        my $msg_type = 'danger';

        $self->app->logger->info(
            "Adding publication. Action: > $action <. Status code: $status_code_str."
        );
        $self->stash( entry => $entry, msg => $msg, msg_type => $msg_type );
        $self->render( template => 'publications/add_entry' );
        return;
    }

    $entry->generate_html( $self->app->bst, $self->app->bibtexConverter );
    my $bibtex_warnings = FprintBibtexWarnings( $entry->warnings );

    # any action
    my $existing_entry = $self->app->repo->entries_find(
        sub { $_->bibtex_key eq $entry->bibtex_key } );
    if ($existing_entry) {
        $status_code_str = 'KEY_TAKEN';
        my $msg_type = 'danger';
        $existing_id = $existing_entry->id;
        my $msg = get_adding_editing_message_for_error_code( $self,
            $status_code_str, $existing_id );

        $self->app->logger->info(
            "Adding publication. Action: > $action <. Status code: $status_code_str."
        );
        $self->stash( entry => $entry, msg => $msg, msg_type => $msg_type );
        $self->render( template => 'publications/add_entry' );
        return;
    }


    if ( $action eq 'preview' or $action eq 'check_key' ) {
        my $status_code_str = 'PREVIEW';
        my $msg_type        = 'info';
        $msg_type = 'warning' if $bibtex_warnings;
        my $msg = get_adding_editing_message_for_error_code( $self,
            $status_code_str, $existing_id );
        $msg .= $bibtex_warnings;

        $self->app->logger->info(
            "Adding publication. Action: > $action <. Status code: $status_code_str."
        );
        $self->stash( entry => $entry, msg => $msg, msg_type => $msg_type );
        $self->render( template => 'publications/add_entry' );
        return;
    }


    if ( $action eq 'save' ) {

        $status_code_str = 'ADD_OK';
        $entry->fix_month();
        $entry->generate_html( $self->app->bst, $self->app->bibtexConverter );

        $self->app->repo->entries_save($entry);
        $added_under_id = $entry->id;

        ## !!! the entry must be added before executing Freassign_authors_to_entries_given_by_array
        ## why? beacuse authorship will be unable to map existing entry to the author
        Freassign_authors_to_entries_given_by_array( $self->app, 1,
            [$entry] );


        my $msg_type = 'success';
        $msg_type = 'warning' if $bibtex_warnings;
        my $msg = get_adding_editing_message_for_error_code( $self,
            $status_code_str, $existing_id );
        $msg .= $bibtex_warnings;

        $self->app->logger->info(
            "Adding publication. Action: > $action <. Status code: $status_code_str."
        );
        $self->flash( msg => $msg, msg_type => $msg_type );
        $self->redirect_to(
            $self->url_for( 'edit_publication', id => $added_under_id ) );
        return;
    }


}
####################################################################################
sub publications_edit_get {
    my $self = shift;
    my $id = $self->param('id') || -1;

    $self->app->logger->info("Editing publication entry id $id");

    my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );

    if ( !defined $entry ) {
        $self->flash( msg => "There is no entry with id $id" );
        $self->redirect_to( $self->get_referrer );
        return;
    }
    $entry->populate_from_bib();
    $entry->generate_html( $self->app->bst, $self->app->bibtexConverter );

    $self->stash( entry => $entry );
    $self->render( template => 'publications/edit_entry' );
}
####################################################################################
sub publications_edit_post {
    my $self            = shift;
    my $id              = $self->param('id') // -1;
    my $new_bib         = $self->param('new_bib');
    my $param_prev      = $self->param('preview');
    my $param_save      = $self->param('save');
    my $param_check_key = $self->param('check_key');

    my $action = 'save';    # user clicks save
    $action = 'preview' if $self->param('preview');    # user clicks preview
    $action = 'check_key'
        if $self->param('check_key');                  # user clicks check key

    $self->app->logger->info(
        "Editing publication id $id. Action: > $action <.");

    $new_bib =~ s/^\s+|\s+$//g;
    $new_bib =~ s/^\t//g;


    my ( $mentry, $status_code_str, $existing_id, $added_under_id )
        = Fhandle_add_edit_publication( $self->app, $new_bib, $id, $action,
        $self->app->bst );
    my $adding_msg
        = get_adding_editing_message_for_error_code( $self, $status_code_str,
        $existing_id );

    $self->app->logger->info(
        "Editing publication id $id. Action: > $action <. Status code: $status_code_str."
    );

    # status_code_strings
    # -2 => PREVIEW
    # -1 => ERR_BIBTEX
    # 0 => ADD_OK
    # 1 => EDIT_OK
    # 2 => KEY_OK
    # 3 => KEY_TAKEN

    my $bibtex_warnings = FprintBibtexWarnings( $mentry->warnings );
    my $msg             = $adding_msg . $bibtex_warnings;
    my $msg_type        = 'success';
    $msg_type = 'warning' if $bibtex_warnings =~ m/Warning/;
    $msg_type = 'danger'
        if $status_code_str eq 'ERR_BIBTEX'
        or $status_code_str eq 'KEY_TAKEN'
        or $bibtex_warnings =~ m/Error/;

    $self->stash( entry => $mentry, msg => $msg, msg_type => $msg_type );
    $self->render( template => 'publications/edit_entry' );
}
####################################################################################
sub clean_ugly_bibtex {
    my $self = shift;

    # TODO: put this into config or preferences!
    my @fields_to_clean
        = qw(bdsk-url-1 bdsk-url-2 bdsk-url-3 date-added date-modified owner tags);

    $self->app->logger->info("Cleaning ugly bibtex fields for all entries");

    my @entries     = $self->app->repo->entries_all;
    my $num_removed = 0;
    foreach my $entry (@entries) {
        $num_removed = $num_removed
            + $entry->clean_ugly_bibtex_fields( \@fields_to_clean );
    }

    $self->flash(
        msg_type => 'info',
        msg =>
            "All entries have now their Bibtex cleaned. I have removed $num_removed fields."
    );

    $self->redirect_to( $self->get_referrer );
}
####################################################################################
1;
