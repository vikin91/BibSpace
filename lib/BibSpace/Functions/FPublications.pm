package BibSpace::Functions::FPublications;

use v5.16;    #because of ~~
use strict;
use warnings;
use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;

use BibSpace::Functions::Core qw( sort_publications );
use Scalar::Util qw(looks_like_number);
use List::Util qw(first);

use BibSpace::Functions::Core;

use Exporter;
our @ISA = qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
  Freassign_authors_to_entries_given_by_array
  Fregenerate_html_for_array
  FprintBibtexWarnings
  Fhandle_add_edit_publication
  Fget_publications_main_hashed_args_only
  Fget_publications_main_hashed_args
  Fget_publications_core
);

sub Freassign_authors_to_entries_given_by_array {
  my $app             = shift;
  my $create_new      = shift // 0;
  my $entries_arr_ref = shift;

  my @all_entries         = @{$entries_arr_ref};
  my $num_authors_created = 0;
  foreach my $entry (@all_entries) {
    next unless defined $entry;

    my @bibtex_author_name = $entry->author_names_from_bibtex;

    for my $author_name (@bibtex_author_name) {

      my $author = $app->repo->authors_find(sub { $_->uid eq $author_name });
      if (($create_new == 1) and (!defined $author)) {
        $author = $app->entityFactory->new_Author(uid => $author_name);
        $app->repo->authors_save($author);
        ++$num_authors_created;
      }
      if ($create_new == 1 or defined $author) {

        my $authorship = $app->entityFactory->new_Authorship(
          author    => $author->get_master,
          entry     => $entry,
          author_id => $author->get_master->id,
          entry_id  => $entry->id
        );
        $app->repo->authorships_save($authorship);
        $entry->add_authorship($authorship);
        $author->add_authorship($authorship);
      }
    }
  }
  return $num_authors_created;
}

sub Fregenerate_html_for_array {
  my $app             = shift;
  my $force           = shift // 0;
  my $converter       = shift;
  my $entries_arr_ref = shift;

  die "Converter is required!" unless $converter;

  my @entries = @{$entries_arr_ref};

  my $num_done = 0;
  for my $entry (@entries) {
    next unless $entry;

    $num_done
      = $num_done + $entry->regenerate_html($force, $app->bst, $converter);
    $app->repo->entries_save($entry);
  }

  return $num_done;
}

sub FprintBibtexWarnings {
  my $str = shift;

  my $msg = '';
  if ($str ne '') {

    $str =~ s/Warning/<br\/>Warning/g;

    $msg .= "<br/>";
    $msg .= "<strong>BibTeX Warnings</strong>: $str";
  }
  return $msg;
}

sub Fhandle_add_edit_publication {
  my ($app, $new_bib, $id, $action, $bst_file) = @_;
  my $repo = $app->repo;

  # var that will be returned
  my $mentry;         # the entry object
  my $status_code;    # the status code
  my $existing_id    = -1;    # id of exiting enrty having the same bibtex key
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

  my $new_entry;

  if ($id > 0) {
    $new_entry = $repo->entries_find(sub { $_->id == $id });
  }
  if (($id < 0) or (!$new_entry)) {
    $new_entry = $app->entityFactory->new_Entry(bib => $new_bib);
  }
  $new_entry->bib($new_bib);

  my $bibtex_code_valid = $new_entry->populate_from_bib();

  # We check Bibtex errors for all requests
  if (!$bibtex_code_valid) {
    $status_code_str = 'ERR_BIBTEX';
    return ($new_entry, $status_code_str, -1, -1);
  }

  my $conflicting_entry
    = $repo->entries_find(sub { $_->bibtex_key eq $new_entry->bibtex_key });

# grep { $_->{bibtex_key} eq $new_entry->{bibtex_key} } MEntry->static_all( $dbh );
  $existing_id = $conflicting_entry->id if defined $conflicting_entry;

  if ($id > 0 and $existing_id == $new_entry->id)
  {    # editing mode, key ok, the user will update entry but not the key
    $status_code_str = 'KEY_OK';
  }
  elsif ($id < 0 and $existing_id < 0) {    # adding mode and key ok
    $status_code_str = 'KEY_OK';
  }
  elsif ($id > 0 and $existing_id < 0)
  {    # editing mode, key ok, the user will update the entry including the key
    $status_code_str = 'KEY_OK';
  }
  else {
    $status_code_str = 'KEY_TAKEN';
    $new_entry->generate_html($bst_file, $app->bibtexConverter);
    return ($new_entry, $status_code_str, $existing_id, -1);
  }
  if ($action eq 'check_key' or $action eq 'preview')
  {    # user wanted only to check key - we give him the preview as well
    $new_entry->generate_html($bst_file, $app->bibtexConverter);
    $new_entry->populate_from_bib();
    return ($new_entry, $status_code_str, $existing_id, -1);
  }

  if ($action eq 'save') {
    if ($id > 0) {    #editing
      $status_code_str = 'EDIT_OK';
    }
    else {            #adding
      $status_code_str = 'ADD_OK';
    }
    $new_entry->generate_html($bst_file, $app->bibtexConverter);
    $new_entry->fix_month();
    $repo->entries_save($new_entry);
    ## !!! the entry must be added before executing Freassign_authors_to_entries_given_by_array
    ## why? beacuse authorship will be unable to map existing entry to the author
    Freassign_authors_to_entries_given_by_array($app, 1, [$new_entry]);

    $added_under_id = $new_entry->id;
  }
  else {
    warn
      "Fhandle_add_edit_publication_repo action $action does not match the known actions: save, preview, check_key.";
  }    # action save
  return ($new_entry, $status_code_str, $existing_id, $added_under_id);
}

# this function ignores the parameters given in the $self object
sub Fget_publications_main_hashed_args_only {
  my ($self, $args, $publications) = @_;

  my @dbg = Fget_publications_core(
    $self,                $args->{author},     $args->{year},
    $args->{bibtex_type}, $args->{entry_type}, $args->{tag},
    $args->{team},        $args->{visible},    $args->{permalink},
    $args->{hidden},      $args->{debug},      $publications,
  );
  return @dbg;
}

sub Fget_publications_main_hashed_args {    #
  my ($self, $args, $publications) = @_;

  $args->{author} = $self->param('author') if !exists $args->{author};
  $args->{year}   = $self->param('year')   if !exists $args->{year};
  $args->{bibtex_type} = $self->param('bibtex_type')
    if !exists $args->{bibtex_type};
  $args->{entry_type} = $self->param('entry_type')
    if !exists $args->{entry_type};
  $args->{tag}       = $self->param('tag')       if !exists $args->{tag};
  $args->{team}      = $self->param('team')      if !exists $args->{team};
  $args->{permalink} = $self->param('permalink') if !exists $args->{permalink};
  $args->{visible}   = 0                         if !exists $args->{visible};

  return Fget_publications_core(
    $self,            $publications,        $args->{author},
    $args->{year},    $args->{bibtex_type}, $args->{entry_type},
    $args->{tag},     $args->{team},        $args->{permalink},
    $args->{visible}, $args->{hidden},      $args->{debug},
  );
}

sub Fget_publications_core {
  my $self              = shift;
  my $publications      = shift;
  my $query_author      = shift;
  my $query_year        = shift;
  my $query_bibtex_type = shift;
  my $query_entry_type  = shift;
  my $query_tag         = shift;
  my $query_team        = shift;
  my $query_permalink   = shift;
  #<<< no perltidy here
  my $query_visible     = shift // 0;  # value can be set only from code (not from browser)
  my $query_hidden      = shift;       # value can be set only from code (not from browser)
  my $debug             = shift // 0;  # value can be set only from code (not from browser)

  # catch bad urls like: ...&entry_type=&tag=&author=
  $query_author      = undef if defined $query_author      and length( "".$query_author      ) < 1;
  $query_year        = undef if defined $query_year        and length( "".$query_year        ) < 1;
  $query_bibtex_type = undef if defined $query_bibtex_type and length( "".$query_bibtex_type ) < 1;
  $query_entry_type  = undef if defined $query_entry_type  and length( "".$query_entry_type  ) < 1;
  $query_tag         = undef if defined $query_tag         and length( "".$query_tag         ) < 1;
  $query_team        = undef if defined $query_team        and length( "".$query_team        ) < 1;
  $query_permalink   = undef if defined $query_permalink   and length( "".$query_permalink   ) < 1;
  #>>>

  if ($debug == 1) {
    $self->app->logger->debug(Dumper $self->req->params);

    $self->app->logger->debug(
      "Fget_publications_core Input author = '$query_author'")
      if defined $query_author;
    $self->app->logger->debug(
      "Fget_publications_core Input year = '$query_year'")
      if defined $query_year;
    $self->app->logger->debug(
      "Fget_publications_core Input bibtex_type = '$query_bibtex_type'")
      if defined $query_bibtex_type;
    $self->app->logger->debug(
      "Fget_publications_core Input entry_type = '$query_entry_type'")
      if defined $query_entry_type;
    $self->app->logger->debug("Fget_publications_core Input tag = '$query_tag'")
      if defined $query_tag;
    $self->app->logger->debug(
      "Fget_publications_core Input team = '$query_team'")
      if defined $query_team;
    $self->app->logger->debug(
      "Fget_publications_core Input visible = '$query_visible'")
      if defined $query_visible;
    $self->app->logger->debug(
      "Fget_publications_core Input permalink = '$query_permalink'")
      if defined $query_permalink;
    $self->app->logger->debug(
      "Fget_publications_core Input hidden = '$query_hidden'")
      if defined $query_hidden;
  }

  my $team_obj;
  if (defined $query_team) {
    if (Scalar::Util::looks_like_number($query_team)) {
      $team_obj = $self->app->repo->teams_find(sub { $_->id == $query_team });
    }
    else {
      $team_obj = $self->app->repo->teams_find(sub { $_->name eq $query_team });
    }
  }
  my $author_obj;
  if (defined $query_author) {
    if (Scalar::Util::looks_like_number($query_author)) {
      $author_obj
        = $self->app->repo->authors_find(sub { $_->master->id == $query_author }
        );
      $author_obj
        ||= $self->app->repo->authors_find(sub { $_->id == $query_author });
    }
    else {
      $author_obj = $self->app->repo->authors_find(
        sub { $_->master->name eq $query_author });
      $author_obj
        ||= $self->app->repo->authors_find(sub { $_->uid eq $query_author });
    }
  }
  my $tag_obj;
  if (defined $query_tag) {
    if (Scalar::Util::looks_like_number($query_tag)) {
      $tag_obj = $self->app->repo->tags_find(sub { $_->id == $query_tag });
    }
    else {
      $tag_obj = $self->app->repo->tags_find(sub { $_->name eq $query_tag });
    }
  }
  my $tag_obj_perm;
  if (defined $query_permalink) {
    if (Scalar::Util::looks_like_number($query_permalink)) {
      $tag_obj_perm
        = $self->app->repo->tags_find(sub { $_->id == $query_permalink });
    }
    else {
      my @tags_having_permalink
        = grep { defined $_->permalink } $self->app->repo->tags_all;
      $tag_obj_perm
        = first { $_->permalink eq $query_permalink } @tags_having_permalink;
    }
  }

  ## $self->app->logger->debug("==== START new Filtering ====", "Fget_publications_core" );

  my @entries;
  if (defined $publications) {
    @entries = @{$publications};
  }
  else {
    @entries = $self->app->repo->entries_all;
  }

  ###### filtering

  ## WARNING: this overwrites all entries - this filtering must be done as first!
  if (defined $query_author) {
    if ($author_obj) {
      @entries = grep { $_->has_author($author_obj) } @entries;
    }
    else {
      # searched for author, but not found any = immediate return empty array
      return ();
    }
  }

  # simple filters
  if (defined $query_year) {
    @entries = grep { (defined $_->year and $_->year == $query_year) } @entries;
  }

  # $bibtex_type - is in fact query for OurType
  if (defined $query_bibtex_type) {
    @entries
      = grep { $_->matches_our_type($query_bibtex_type, $self->app->repo) }
      @entries;
  }
  if (defined $query_entry_type) {
    @entries = grep { $_->entry_type eq $query_entry_type } @entries;
  }
  if (defined $query_permalink) {
    if (defined $tag_obj_perm) {
      @entries = grep { $_->has_tag($tag_obj_perm) } @entries;
    }
    else {
      return ();
    }
  }

  # All entries = hidden + unhidden entries
  # by default, we return all (e.g., for admin interface)
  if (defined $query_hidden) {
    @entries = grep { $_->hidden == $query_hidden } @entries;
  }

  # Entries of visible authors
  # by default, we return entries of all authors
  if (defined $query_visible and $query_visible == 1) {
    @entries = grep { $_->belongs_to_visible_author } @entries;
  }

  ######## complex filters

  if (defined $query_tag) {
    if (defined $tag_obj) {
      @entries = grep { $_->has_tag($tag_obj) } @entries;
    }
    else {
      return ();
    }
  }
  if (defined $query_team) {
    if (defined $team_obj) {
      @entries = grep { $_->has_team($team_obj) } @entries;
    }
    else {
      return ();
    }
  }

  @entries = sort_publications(@entries);

  if ($debug == 1) {
    $self->app->logger->debug(
      "Fget_publications_core Found '" . scalar(@entries) . "' entries");
  }

  return @entries;
}

