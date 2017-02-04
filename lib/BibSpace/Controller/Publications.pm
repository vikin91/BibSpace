package BibSpace::Controller::Publications;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;     # should be replaced in the future
use Path::Tiny;      # for creating directories
use Try::Tiny;
use Time::Piece;
use 5.010;           #because of ~~
use strict;
use warnings;
use DBI;
use DBIx::Connector;

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
sub all {
  my $self = shift;

  my $entry_type = undef;
  $entry_type = $self->param('entry_type') // undef;

  my @objs = Fget_publications_main_hashed_args( $self, { entry_type => $entry_type } );

  $self->stash( entries => \@objs );
  my $html = $self->render_to_string( template => 'publications/all' );
  $self->render( data => $html );
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
    $self->stash( msg_type => 'danger', msg => "Entry $id does not exist." );
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

  my @entries = $self->app->repo->entries_all;

  foreach my $entry(@entries){
    $entry->fix_month();
  }
  $self->app->repo->entries_save(@entries);

  $self->flash(
    msg => 'Fixing entries month field finished.',
    msg_type => 'info'
  );
  $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub unhide {
  my $self = shift;
  my $id   = $self->param('id');

  my $entry = $self->app->repo->entries_find( sub { $_->{id} == $id } );

  if ( defined $entry ) {

    $entry->unhide();
    $self->app->repo->entries_update($entry);
  }
  else {
    $self->flash( msg => "There is no entry with id $id" );
  }


  $self->redirect_to( $self->get_referrer );
}

####################################################################################
sub hide {
  my $self = shift;
  my $id   = $self->param('id');

  my $entry = $self->app->repo->entries_find( sub { $_->{id} == $id } );

  if ( defined $entry ) {
    $entry->hide();
    $self->app->repo->entries_update($entry);
  }
  else {
    $self->flash( msg => "There is no entry with id $id" );
  }
  $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub toggle_hide {
  my $self = shift;
  my $id   = $self->param('id');

  my $entry = $self->app->repo->entries_find( sub { $_->{id} == $id } );

  if ( defined $entry ) {
    $entry->toggle_hide();
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

  my $entry = $self->app->repo->entries_find( sub { $_->{id} == $id } );

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

  my $entry = $self->app->repo->entries_find( sub { $_->{id} == $id } );

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
sub all_recently_added {
  my $self = shift;
  my $num  = $self->param('num') // 10;

  my @objs = $self->app->repo->entries_all;
  @objs = sort { $b->creation_time cmp $a->creation_time } @objs;
  @objs = @objs[ 0 .. $num-1 ];

  # map {say $_->{creation_time}} @objs;

  $self->stash( entries => \@objs );
  $self->render( template => 'publications/all' );
}
####################################################################################

sub all_recently_modified {
  my $self = shift;
  my $num = $self->param('num') // 10;

  my @objs = $self->app->repo->entries_all;
  @objs = sort { $b->modified_time cmp $a->modified_time } @objs;
  @objs = @objs[ 0 .. $num-1 ];

  # map {say $_->{modified_time}} @objs;

  $self->stash( entries => \@objs );
  $self->render( template => 'publications/all' );
}

####################################################################################
sub all_without_tag {
  my $self    = shift;
  my $tagtype = $self->param('tagtype') || 1;

  my @all = $self->app->repo->entries_all;
  my @objs = grep { scalar $_->get_tags( $tagtype ) == 0 } @all;


  my $msg = "This list contains papers that have no tags of type $tagtype. Use this list to tag the untagged papers! ";
  $self->stash( msg_type => 'info', msg => $msg );
  $self->stash( entries => \@objs );
  $self->render( template => 'publications/all' );
}
####################################################################################
sub all_without_tag_for_author {
  my $self        = shift;
  my $master_name = $self->param('author');
  my $tagtype     = $self->param('tagtype');

  my $author;
  if( Scalar::Util::looks_like_number($master_name) ){
    $author = $self->app->repo->authors_find( sub { $_->master_id == $master_name } );
  }
  else{
    $author = $self->app->repo->authors_find( sub { $_->master eq $master_name } );  
  }
  

  if ( !defined $author ) {
    $self->flash( msg => "Author $master_name does not exist!", msg_type => "danger" );
    $self->redirect_to( $self->get_referrer );
    return;
  }

  # no such master. Assume, that author id was given

  my @all_author_entries = $author->get_entries;                                    
  my @objs = grep { scalar $_->get_tags( $tagtype ) == 0 } @all_author_entries;


  my $msg = "This list contains papers of $author->{master} that miss tags of type $tagtype. ";
  $self->stash( entries => \@objs, msg_type => 'info', msg => $msg );
  $self->render( template => 'publications/all' );
}
####################################################################################
sub all_without_author {
  my $self = shift;

  my @objs = $self->app->repo->entries_filter( sub { scalar($_->get_authors) == 0 } );


  my $msg = "This list contains papers, that are currently not assigned to any of authors.";
  $self->stash( entries => \@objs, msg => $msg, msg_type => 'info' );
  $self->render( template => 'publications/all' );
}

####################################################################################
sub show_unrelated_to_team {
  my $self    = shift;
  my $team_id = $self->param('teamid');


  my $team_name = "";
  my $team = $self->app->repo->teams_find( sub { $_->id == $team_id } );
  $team_name = $team->name if defined $team;


  my @allEntres  = $self->app->repo->entries_all;
  my @teamEntres = $team->entries;

  my %inTeam = map { $_ => 1 } @teamEntres;
  my @entriesUnrelated = grep { not $inTeam{$_} } @allEntres;


  my $msg = "This list contains papers, that are:
        <ul>
            <li>Not assigned to the team "
    . $team_name . "</li>
            <li>Not assigned to any author (former or actual) of the team "
    . $team_name . "</li>
        </ul>";

  $self->stash( msg_type => 'info', msg => $msg, entries => \@entriesUnrelated );
  $self->render( template => 'publications/all' );
}
####################################################################################
sub all_with_missing_month {
  my $self = shift;

  $self->app->logger->info("Displaying entries without month");


  my @objs
    = grep { !defined $_->{month} or $_->{month} < 1 or $_->{month} > 12 } $self->app->repo->entries_all;

  my $msg = "This list contains entries with missing BibTeX field 'month'. ";
  $msg .= "Add this data to get the proper chronological sorting.";

  $self->stash( msg_type => 'info', msg => $msg );
  $self->stash( entries => \@objs );
  $self->render( template => 'publications/all' );
}
####################################################################################
sub all_candidates_to_delete {
  my $self = shift;
  my $dbh  = $self->app->db;

  $self->app->logger->info("Displaying entries that are candidates_to_delete");


  my @objs = $self->app->repo->entries_all;
  @objs = grep { scalar $_->get_tags($dbh) == 0 } @objs;          # no tags
  @objs = grep { scalar $_->get_teams($dbh) == 0 } @objs;         # no relation to teams
  @objs = grep { scalar $_->get_exceptions($dbh) == 0 } @objs;    # no exceptions


  my $msg = "<p>This list contains papers, that are:</p>
      <ul>
          <li>Not assigned to any team AND</li>
          <li>have exactly 0 tags AND</li>
          <li>not assigned to any author that is (or was) a member of any team AND </li>
          <li>have exactly 0 exceptions assigned.</li>
      </ul>
      <p>Such entries may wanted to be removed form the system or serve as a help with configuration.</p>";

  $self->stash( msg_type => 'info', msg => $msg );
  $self->stash( entries => \@objs );
  $self->render( template => 'publications/all' );
}

####################################################################################

sub all_bibtex {
  my $self = shift;

  my $entry_type = undef;

  # this includes papers+talks by default
  $entry_type = $self->param('entry_type');


  my @objs = $self->app->repo->entries_filter( sub { $_->{hidden} == 0 } );

  @objs = grep { ( $_->{entry_type} cmp $entry_type ) == 0 } @objs if defined $entry_type;

  # my @objs = Fget_publications_main_hashed_args( $self,
  #     { hidden => 0, entry_type => $entry_type } );

  my $big_str = "<pre>\n";
  foreach my $obj (@objs) {
    $big_str .= $obj->{bib};
    $big_str .= "\n";
  }
  $big_str .= "\n</pre>";
  $self->render( text => $big_str );
}


############################################################################################################

#here was landing

####################################################################################
sub fix_file_urls {

  ##
  # http://127.0.0.1:3000/publications/download/paper/4/pdf

  my $self = shift;
  my $dbh  = $self->app->db;


  my @all_entries = $self->app->repo->entries_all;

  my $str = "";

  for my $e (@all_entries) {

    my $url_pdf    = $self->url_for( 'download_publication_pdf', filetype => 'paper',  id => $e->{id} )->to_abs;
    my $url_slides = $self->url_for( 'download_publication',     filetype => 'slides', id => $e->{id} )->to_abs;

    # check if the entry has pdf
    my $pdf_path = $self->get_paper_pdf_path( $e->id, "paper" );
    if ( $pdf_path ) {    # this means that file exists locally
      if ( $e->has_bibtex_field("pdf") ) {
        $e->add_bibtex_field( "pdf", "$url_pdf" );
        $str .= "id $e->{id}, PDF: " . $url_pdf;
        $str .= '<br/>';
      }
    }
    my $slides_path = $self->get_paper_pdf_path( $e->id, "slides" );
    if ( $slides_path ) {    # this means that file exists locally
      if ( $e->has_bibtex_field("slides") ) {
        $e->add_bibtex_field( "slides", "$url_slides" );
        $str .= "id $e->{id}, SLI: " . $url_slides;
        $str .= '<br/>';
      }
    }
  }

  $self->flash( msg => 'The following urls are now fixed: <br/>' . $str );
  $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub remove_attachment {
  my $self     = shift;
  my $id       = $self->param('id');                     # entry ID
  my $filetype = $self->param('filetype') // 'paper';    # paper, slides

  my $entry = $self->app->repo->entries_find( sub { $_->{id} == $id } );

  # no check as we want to have the files deleted anyway!

  my $file_path = get_paper_pdf_path( $self, $id, "$filetype" );

  $self->app->logger->debug("File_path '$file_path'", __PACKAGE__."->remove_attachment");

  my $num_deleted_files = 0;
  my $msg;
  my $msg_type;

  if ( !defined $file_path ) {
    $msg      = "File not found. Cannot remove attachment. Filetype $filetype or entry id $id.";
    $msg_type = 'danger';
  }
  else {    # file exists

    $num_deleted_files = $self->remove_attachment_do( $id, $filetype );
    if ( defined $entry and $num_deleted_files > 0 ) {
      $entry->remove_bibtex_fields( ['pdf'] )    if $filetype eq 'paper';
      $entry->remove_bibtex_fields( ['slides'] ) if $filetype eq 'slides';
      $entry->regenerate_html( 0, $self->app->bst, $self->app->bibtexConverter );
      $self->app->repo->entries_save($entry);
    }

    $msg      = "There were $num_deleted_files attachments removed for id $id.";
    $msg_type = 'success';
  }

  $self->app->logger->info($msg);
  $self->flash( msg_type => $msg_type, msg => $msg );
  $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub remove_attachment_do {    # refactor this - this is clutter
  my $self     = shift;
  my $id       = shift;
  my $filetype = shift;
  my $dbh      = $self->app->db;

  my $mentry = $self->app->repo->entries_find( sub { $_->{id} == $id } );

  my $file_path = get_paper_pdf_path( $self, $id, "$filetype" );
  my $num_deleted_files = 0;

  if ( !defined $mentry or !defined $file_path or $file_path eq 0 ) {
    return;
  }

  try {
    unlink $file_path;
    $num_deleted_files = $num_deleted_files + 1;
  }
  catch { };

  # make sure that there is no file
  my $file_path_after_delete = get_paper_pdf_path( $self, $id, "$filetype" );
  # if there is something left, try again
  if( defined $file_path_after_delete ) {
    try {
      unlink $file_path;
      $num_deleted_files = $num_deleted_files + 1;
    }
    catch { };
    $file_path_after_delete = get_paper_pdf_path( $self, $id, "$filetype" );
  }

  return $num_deleted_files;
}
####################################################################################
sub download {
  my $self     = shift;
  my $id       = $self->param('id');                     # entry ID
  my $filetype = $self->param('filetype') // 'paper';    # paper, slides

  my $file_path = $self->get_paper_pdf_path( $id, "$filetype" );
  
  if( $file_path and -e $file_path ){
    $self->app->logger->debug("Found paper type '$filetype': '$file_path'", __PACKAGE__."->download");
    $self->app->logger->info("Downloading file download '$filetype' for entry '$id'.");
    $self->render_file( 'filepath' => $file_path );
    return;
  }
  $self->app->logger->error("Requested download for entry $id, filetype $filetype but file is missing!");
  $self->app->logger->info("Unsuccessful download filetype '$filetype', id '$id'.");
  $self->render(status => 404, text => "File not found. Unsuccessful download filetype $filetype, id $id.");
}
####################################################################################

sub add_pdf {
  my $self = shift;
  my $id   = $self->param('id');
  my $dbh  = $self->app->db;


  my $entry = $self->app->repo->entries_find( sub { $_->{id} == $id } );

  if ( !defined $entry ) {
    $self->flash( msg => "There is no entry with id $id" );
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
  my $self     = shift;
  my $id       = $self->param('id') // "unknown";
  my $filetype = $self->param('filetype');
  my $dbh      = $self->app->db;

  my $uploads_directory = $self->config->{upload_dir};
  $uploads_directory =~ s!/*$!/!;    # makes sure that there is exactly one / at the end

  my $extension;

  $self->app->logger->info("Saving attachment for paper id $id");

  # Check file size
  if ( $self->req->is_limit_exceeded ) {
    my $curr_limit_B = $ENV{MOJO_MAX_MESSAGE_SIZE};
    $curr_limit_B ||= 16777216;
    my $curr_limit_MB = $curr_limit_B / 1024 / 1024;
    $self->app->logger->info("Saving attachment for paper id '$id': limit exceeded. Current limit: $curr_limit_MB MB.");
    $self->flash( msg => "The File is too big and cannot be saved!", msg_type => "danger" );
    $self->redirect_to( $self->get_referrer );
    return;
  }

  # Process uploaded file
  my $uploaded_file = $self->param('uploaded_file');

  if( !$uploaded_file ) {
    $self->flash( msg => "File upload unsuccessful!", msg_type => "danger" );
    $self->app->logger->info("Saving attachment for paper id '$id' FAILED. Unknown reason");
    $self->redirect_to( $self->get_referrer );
    return;
  }

  my $size = $uploaded_file->size;
  if ( $size == 0 ) {
    $self->flash( msg => "No file was selected or file has 0 bytes! Not saving!", msg_type => "danger" );
    $self->app->logger->info("Saving attachment for paper id '$id' FAILED. File size is 0.");
    $self->redirect_to( $self->get_referrer );
    return;
  }
  else {
    my $sizeKB = int( $size / 1024 );
    my $name   = $uploaded_file->filename;

    my @dot_arr = split( /\./, $name );
    my $arr_size = scalar @dot_arr;
    $extension = $dot_arr[ $arr_size - 1 ];

    my $fname;
    my $fname_no_ext;
    my $file_path;
    my $bibtex_field;
    my $directory;

    if ( $filetype eq 'paper' ) {
      $fname_no_ext = "paper-" . $id . ".";
      $fname        = $fname_no_ext . $extension;

      $directory    = "papers/";
      $bibtex_field = "pdf";
    }
    elsif ( $filetype eq 'slides' ) {
      $fname_no_ext = "slides-paper-" . $id . ".";
      $fname        = $fname_no_ext . $extension;
      $directory    = "slides/";
      $bibtex_field = "slides";
    }
    else {
      $fname_no_ext = "unknown-" . $id . ".";
      $fname        = $fname_no_ext . $extension;
      $directory    = "unknown/";

      $bibtex_field = "pdf2";
    }
    try {
      path( $uploads_directory . $directory )->mkpath;
    }
    catch {
      $self->app->logger->warn("Cannot create directory '$directory'. Msg: '$_'.", __PACKAGE__."->add_pdf_post");
    };

    $file_path = $directory . $fname;

    # remove old file that would match the patterns
    my $old_file = $self->get_paper_pdf_path( $id, "$filetype" );
    if ( $old_file and -e $old_file ) {
      # old file exists and must be deleted!
      try {
        unlink $old_file;
      }
      catch { };
    }

    $uploaded_file->move_to( $uploads_directory . $file_path );

    my $new_file = $self->get_paper_pdf_path( $id, "$filetype" );

    my $file_url = $self->url_for( 'download_publication', filetype => "$filetype", id => $id )->to_abs;
    if ( $filetype eq 'paper' ) {    # so that the link looks nicer
      $file_url = $self->url_for( 'download_publication_pdf', filetype => "paper", id => $id )->to_abs;
    }

    $self->app->logger->info("Saving attachment for paper id $id under: $file_url");


    my $msg = "Successfully uploaded the $sizeKB KB file <em>$name</em> as <strong><em>$filetype</em></strong>.
        The file was renamed to: <em>$fname</em>. URL <a href=\""
      . $file_url . "\">$name</a>";


    my $mentry = $self->app->repo->entries_find( sub { $_->{id} == $id } );
    $mentry->add_bibtex_field( $bibtex_field, "$file_url" );

    if ( !defined $mentry ) {
      $self->flash( msg_type=> 'danger', msg => "There is no entry with id $id" );
      $self->redirect_to( $self->get_referrer );
      return;
    }
    $mentry->regenerate_html(0, $self->app->bst, $self->app->bibtexConverter);
    $self->app->repo->entries_save($mentry);

    $self->flash( msg_type=> 'success', msg => $msg );
    $self->redirect_to( $self->get_referrer );
  }
}

####################################################################################
####################################################################################
sub regenerate_html_for_all {
  my $self = shift;
  my $converter = $self->app->bibtexConverter;

  $self->inactivity_timeout(3000);

  $self->app->logger->info("regenerate_html_for_all is running");

  my @entries   = $self->app->repo->entries_all;
  my $num_fixes = 0;
  for my $entry (@entries) {
    $entry->bst_file( $self->app->bst );
    $entry->regenerate_html( 0, $self->app->bst, $converter );
  }
  $self->app->repo->entries_save(@entries);

  $self->app->logger->info("regenerate_html_for_all has finished");

  my $msg = 'Regeneration of HTML code is complete.';
  $self->flash( msg_type => 'info', msg => $msg );
  $self->redirect_to( $self->get_referrer() );
}
####################################################################################
sub regenerate_html_for_all_force {
  my $self = shift;
  my $converter = $self->app->bibtexConverter;

  $self->inactivity_timeout(3000);

  $self->app->logger->info("regenerate_html_for_all_force is running");


  my @entries   = $self->app->repo->entries_all;
  my $num_fixes = 0;
  for my $entry (@entries) {
    $entry->bst_file( $self->app->bst );
    $entry->regenerate_html( 1, $self->app->bst, $converter );
  }
  $self->app->repo->entries_save(@entries);


  $self->app->logger->info("regenerate_html_for_all_force has finished");

  my $msg = 'Regeneration of HTML code is complete.';
  $self->flash( msg_type => 'info', msg => $msg );
  $self->redirect_to( $self->get_referrer() );

}

####################################################################################
sub regenerate_html {
  my $self = shift;
  my $converter = $self->app->bibtexConverter;
  my $id   = $self->param('id');


  my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );

  if ( !defined $entry ) {
    $self->flash( msg => "There is no entry with id $id", msg_type => 'danger' );
    $self->redirect_to( $self->get_referrer );
    return;
  }
  $entry->bst_file($self->app->bst);
  $entry->regenerate_html(1, $self->app->bst, $self->app->bibtexConverter);
  $self->app->repo->entries_save($entry);

  $self->redirect_to( $self->get_referrer );
}
####################################################################################

sub delete_sure {
  my $self = shift;
  my $id   = $self->param('id');
  my $dbh  = $self->app->db;

  my $entry = $self->app->repo->entries_find( sub { $_->id == $id } );

  if ( !defined $entry ) {
    $self->flash( mgs_type => 'danger', msg => "There is no entry with id $id" );
    $self->redirect_to( $self->get_referrer );
    return;
  }

  remove_attachment_do( $self, $id, 'paper' );
  remove_attachment_do( $self, $id, 'slides' );
  $self->app->repo->entries_delete($entry);

  $self->app->logger->info("Entry id $id has been deleted.");

  $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub show_authors_of_entry {
  my $self = shift;
  my $id   = $self->param('id');
  my $dbh  = $self->app->db;
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
  my $dbh  = $self->app->db;

  $self->app->logger->info("Manage tags of entry id $id");


  my $entry = $self->app->repo->entries_find( sub { $_->{id} == $id } );

  if ( !defined $entry ) {
    $self->flash( msg => "There is no entry with id $id" );
    $self->redirect_to( $self->get_referrer );
    return;
  }



  my @tags = $entry->get_tags;
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

    my $search_label = Labeling->new( entry => $entry, tag => $tag, entry_id => $entry->id, tag_id => $tag->id );
    my $label = $self->app->repo->labelings_find( sub { $_->equals($search_label) } );

    if($label){
      # you should always execute all those three commands together - smells like command pattern...
      $entry->remove_labeling($label);
      $tag->remove_labeling($label);
      $self->app->repo->labelings_delete($label);

      $self->app->logger->info( "Removed tag " . $tag->name . " from entry ID " . $entry->id . ". " );
    }
    else{
      # this paper does not have this tag - do nothing
      $self->app->logger->warn( "Cannot remove tag " . $tag->name . " from entry ID " . $entry->id . " - reason: labeling not found. " );
    }

  }

  $self->redirect_to( $self->get_referrer );

}
####################################################################################
sub add_tag {
  my $self     = shift;
  my $entry_id = $self->param('eid');
  my $tag_id   = $self->param('tid');
  my $dbh      = $self->app->db;


  my $entry = $self->app->repo->entries_find( sub { $_->id == $entry_id } );
  my $tag   = $self->app->repo->tags_find( sub    { $_->id == $tag_id } );

  if ( defined $entry and defined $tag ) {

    my $label = Labeling->new( entry => $entry, tag => $tag, entry_id => $entry->id, tag_id => $tag->id );

    # you should always execute all those three commands together - smells like command pattern...
    $self->app->repo->labelings_save($label);
    $entry->add_labeling($label);
    $tag->add_labeling($label);
  }
  else{
      # this paper does not have this tag - do nothing
      $self->app->logger->warn( "Cannot add tag $tag_id to entry ID $entry_id - reason: tag or entry not found. " );
    }
  $self->redirect_to( $self->get_referrer );
}
####################################################################################
####################################################################################
####################################################################################
sub manage_exceptions {
  my $self = shift;
  my $id   = $self->param('id');
  my $dbh  = $self->app->db;


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
  my $team  = $self->app->repo->teams_find(   sub { $_->id == $team_id } );

  if ( defined $entry and defined $team ) {

    my $exception = Exception->new( entry => $entry, team => $team, entry_id => $entry->id, team_id => $team->id );

    $entry->add_exception($exception);
    $team->add_exception($exception);
    $self->app->repo->exceptions_save($exception);

    $msg = "Exception added! Entry ID ".$entry->id." will be now listed under team '".$team->name."'.";
  }
  else{
    $msg = "Cannot find entry or team to create exception. Searched team ID: ".$team_id." entry ID: ".$entry_id.".";
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
  my $dbh      = $self->app->db;


  my $entry = $self->app->repo->entries_find( sub { $_->id == $entry_id } );
  my $team  = $self->app->repo->teams_find( sub   { $_->id == $team_id } );

  my $msg;

  if ( defined $entry and defined $team ) {

    my $ex = Exception->new(team_id => $team_id, entry_id => $entry_id, team => $team, entry=> $entry);

    my $exception = $self->app->repo->exceptions_find( sub{ $_->equals($ex) } );

    if(defined $exception){
      $entry->remove_exception($exception);
      $team->remove_exception($exception);
      $self->app->repo->exceptions_delete($exception); 

      $msg = "Removed exception team '".$team->name."' from entry ID ".$entry->id.". ";
    }
    else{
      $msg = "Cannot find exception to remove. Searched team '".$team->name."' entry ID: ".$entry->id.".";
    }
  }
  else{
    $msg = "Cannot find exception to remove. Searched team ID: ".$team_id." entry ID: ".$entry_id.".";
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
    return "You have bibtex errors! No changes were written to the database.";
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
    return 'The proposed key is OK. You may continue with your edits. No changes were written to the database.';
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
  my $dbh = $self->app->db;


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
  my $e_dummy = Entry->new( idProvider => $self->app->repo->entries_idProvider, bib => $bib );

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
  my $dbh             = $self->app->db;

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


  my $entry = Entry->new( idProvider => $self->app->repo->entries_idProvider, bib => $new_bib );


  my $bibtex_code_valid = $entry->populate_from_bib();

  if ( !$bibtex_code_valid ) {
    $status_code_str = 'ERR_BIBTEX';
  }
  elsif ( $action eq 'preview' ) {
    $status_code_str = 'PREVIEW';
    $entry->generate_html( $self->app->bst, $self->app->bibtexConverter );
  }
  elsif ( $action eq 'check_key' ) {
    $status_code_str = 'KEY_OK';
    $entry->generate_html( $self->app->bst, $self->app->bibtexConverter );

    my $entry_conflicting_key
      = $self->app->repo->entries_find( sub { ( $_->bibtex_key cmp $entry->bibtex_key ) == 0 } );
    if ( defined $entry_conflicting_key ) {
      $status_code_str = 'KEY_TAKEN';
      $existing_id     = $entry_conflicting_key->id;
    }
  }
  elsif ( $action eq 'save' ) {

    $entry->generate_html( $self->app->bst, $self->app->bibtexConverter );

    # TODO: duplicated code
    my $entry_conflicting_key
      = $self->app->repo->entries_find( sub { ( $_->bibtex_key cmp $entry->bibtex_key ) == 0 } );
    if ( defined $entry_conflicting_key ) {
      $status_code_str = 'KEY_TAKEN';
      $existing_id     = $entry_conflicting_key->id;
    }
    else {
      $status_code_str = 'ADD_OK';
      $entry->fix_month();
      $self->app->repo->entries_save($entry);

      $added_under_id = $entry->id;
    }
  }

  my $adding_msg = get_adding_editing_message_for_error_code( $self, $status_code_str, $existing_id );


  $self->app->logger->info("Adding publication. Action: > $action <. Status code: $status_code_str.");

  # status_code_strings
  # -2 => PREVIEW
  # -1 => ERR_BIBTEX
  # 0 => ADD_OK
  # 1 => EDIT_OK
  # 2 => KEY_OK
  # 3 => KEY_TAKEN
  my $bibtex_warnings = FprintBibtexWarnings( $entry->warnings );
  my $msg             = $adding_msg . $bibtex_warnings;
  my $msg_type        = 'success';
  $msg_type = 'warning' if $bibtex_warnings =~ m/Warning/;
  $msg_type = 'danger'
    if $status_code_str eq 'ERR_BIBTEX'
    or $status_code_str eq 'KEY_TAKEN'
    or $bibtex_warnings =~ m/Error/;

  $self->stash( entry => $entry, msg => $msg, msg_type => $msg_type );

  if ( $status_code_str eq 'ADD_OK' ) {
    $self->flash( msg => $msg, msg_type => $msg_type );
    $self->redirect_to( $self->url_for( 'edit_publication', id => $added_under_id ) );
  }
  else {
    $self->render( template => 'publications/add_entry' );
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
  my $param_check_key = my $dbh = $self->app->db;

  my $action = 'save';    # user clicks save
  $action = 'preview'   if $self->param('preview');      # user clicks preview
  $action = 'check_key' if $self->param('check_key');    # user clicks check key

  $self->app->logger->info("Editing publication id $id. Action: > $action <.");

  $new_bib =~ s/^\s+|\s+$//g;
  $new_bib =~ s/^\t//g;


  my ( $mentry, $status_code_str, $existing_id, $added_under_id )
    = Fhandle_add_edit_publication( $self->app, $new_bib, $id, $action,
    $self->app->bst );
  my $adding_msg = get_adding_editing_message_for_error_code( $self, $status_code_str, $existing_id );

  $self->app->logger->info("Editing publication id $id. Action: > $action <. Status code: $status_code_str.");

  # status_code_strings
  # -2 => PREVIEW
  # -1 => ERR_BIBTEX
  # 0 => ADD_OK
  # 1 => EDIT_OK
  # 2 => KEY_OK
  # 3 => KEY_TAKEN

  my $bibtex_warnings = FprintBibtexWarnings( $mentry->{warnings} );
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

  $self->app->logger->info("Cleaning ugly bibtex fields for all entries");

  my @entries = $self->app->repo->entries_all;
  foreach my $e (@entries) {
    $e->clean_ugly_bibtex_fields();
  }

  $self->flash( msg_type => 'info', msg => 'All entries have now their Bibtex cleaned.' );

  $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub get_paper_pdf_path {
  my $self = shift;
  my $id   = shift;
  my $type = shift || "paper";

  my $upload_dir = $self->config->{upload_dir};
  $upload_dir =~ s!/*$!/!;    # makes sure that there is exactly one / at the end

  my $filequery = "";
  $filequery .= "paper-" . $id . "."        if $type eq "paper";
  $filequery .= "slides-paper-" . $id . "." if $type eq "slides";

  my $directory = $upload_dir;
  $directory .= "papers/" if $type eq "paper";
  $directory .= "slides/" if $type eq "slides";
  my $filename = undef;

  # make sure that the directories exist
  try {
    path($directory)->mkpath;
  }
  catch {
    $self->app->logger->warn("Cannot create directory '$directory'. Msg: '$_'.", __PACKAGE__."->get_paper_pdf_path");
  };

  opendir( DIR, $directory ) or die "Cannot open directory $directory :" . $!;
  while ( my $file = readdir(DIR) ) {

    # Use a regular expression to ignore files beginning with a period
    next if ( $file =~ m/^\./ );
    if ( $file =~ /^$filequery.*/ ) {    # filequery contains the dot!
      $self->app->logger->debug("Found match file: '$file', query: '$filequery'.", __PACKAGE__."->get_paper_pdf_path");
      $filename = $file;
    }
  }
  closedir(DIR);
  if ( !defined $filename ) {
    return;
  }

  my $file_path = $directory . $filename;
  return $file_path;
}
####################################################################################
1;
