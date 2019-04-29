package BibSpace::Controller::Helpers;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;

# use File::Slurp;

use v5.16;           #because of ~~
use strict;
use warnings;

use List::MoreUtils qw(any uniq);

use BibSpace::Functions::Core;
use BibSpace::Controller::Publications;
use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Functions::FDB;

use BibSpace::Functions::FPublications;

use base 'Mojolicious::Plugin';

sub register {

  my ($self, $app) = @_;

# this must be a helper,
# because entityFactory can be exchanged during system lifetime (e.g. restore backup),
# so the reference must always point to the currently valid id provider
# entityFactory must be instantiated INSIDE flatRepository
  $app->helper(
    entityFactory => sub {
      my $self = shift;
      return $self->app->flatRepository->e_factory;
    }
  );

  $app->helper(
    is_demo => sub {
      my $self = shift;
      return 1 if $self->config->{demo_mode};

# say "helper->is_demo: run_in_demo_mode: ".$self->app->preferences->run_in_demo_mode;
      return 1 if $self->app->preferences->run_in_demo_mode == 1;
      return;
    }
  );

  $app->helper(
    db => sub {
      my $self    = shift;
      my $db_host = $ENV{BIBSPACE_DB_HOST} || $self->app->config->{db_host};
      my $db_user = $ENV{BIBSPACE_DB_USER} || $self->app->config->{db_user};
      my $db_database
        = $ENV{BIBSPACE_DB_DATABASE} || $self->app->config->{db_database};
      my $db_pass = $ENV{BIBSPACE_DB_PASS} || $self->app->config->{db_pass};
      return db_connect($db_host, $db_user, $db_database, $db_pass);
    }
  );

  $app->helper(
    bst => sub {
      my $self = shift;

      my $bst_candidate_file = $self->app->home . '/lib/descartes2.bst';

      if (defined $self->app->config->{bst_file}) {
        $bst_candidate_file = $self->app->config->{bst_file};
        return File::Spec->rel2abs($bst_candidate_file)
          if File::Spec->file_name_is_absolute($bst_candidate_file)
          and -e File::Spec->rel2abs($bst_candidate_file);

        $bst_candidate_file = $self->app->home . $self->app->config->{bst_file};

        return File::Spec->rel2abs($bst_candidate_file)
          if File::Spec->file_name_is_absolute($bst_candidate_file)
          and -e File::Spec->rel2abs($bst_candidate_file);
      }

      $bst_candidate_file = $self->app->home . '/lib/descartes2.bst';

      return File::Spec->rel2abs($bst_candidate_file)
        if -e File::Spec->rel2abs($bst_candidate_file);

      $self->app->logger->error("Cannot find any valid bst file!");
      return './bst-not-found.bst';
    }
  );

  $app->helper(
    bibtexConverter => sub {
      my $self = shift;
      try {
        my $class = $self->app->preferences->bibitex_html_converter;
        Class::Load::load_class($class);
        if ($class->does('IHtmlBibtexConverter')) {
          return $class->new(logger => $self->app->logger);
        }
        die
          "Requested class '$class' does not implement interface 'IHtmlBibtexConverter'";
      }
      catch {
        $self->logger->error(
              "Requested unknown type of bibitex_html_converter: '"
            . $self->app->preferences->bibitex_html_converter
            . "'. Error: $_.");
      }
      finally {
        return BibStyleConverter->new(logger => $self->app->logger);
      };
    }
  );

  $app->helper(
    get_referrer => sub {
      my $self = shift;
      return $self->get_referrer_old;
    }
  );

  $app->helper(
    get_referrer_new => sub {
      my $self = shift;
      my $ret  = $self->req->headers->referrer;

      # $ret //= $self->url_for('start');
      return $ret;
    }
  );
  $app->helper(
    get_referrer_old => sub {
      my $s   = shift;
      my $ret = $s->url_for('start');
      $ret = $s->req->headers->referrer
        if defined $s->req->headers->referrer
        and $s->req->headers->referrer ne '';
      return $ret;
    }
  );

  $app->helper(
    is_manager => sub {
      my $self = shift;
      return 1 if $self->app->is_demo;
      return   if !$self->session('user');
      my $me = $self->app->repo->users_find(
        sub { $_->login eq $self->session('user') });
      return if !$me;
      return $me->is_manager;
    }
  );

  $app->helper(
    is_admin => sub {
      my $self = shift;
      return 1 if $self->app->is_demo;
      return   if !$self->session('user');
      my $me = $self->app->repo->users_find(
        sub { $_->login eq $self->session('user') });
      return if !$me;
      return $me->is_admin;
    }
  );

  $app->helper(
    current_year => sub {
      return BibSpace::Functions::Core::get_current_year();
    }
  );
  $app->helper(
    current_month => sub {
      return BibSpace::Functions::Core::get_current_month();
    }
  );

  $app->helper(
    get_year_of_oldest_entry => sub {
      my $self   = shift;
      my $author = shift;

      my @entries = $self->app->repo->entries_all;

      if (defined $author) {

        my $author_obj = $self->app->repo->authors_find(
          sub { $_->get_master->uid eq $author });
        $author_obj ||= $self->app->repo->authors_find(
          sub { $_->get_master->id eq $author });
        if ($author_obj) {
          @entries = $author_obj->get_entries;
        }

      }

      my @entryYears = map { $_->year } grep { defined $_->year } @entries;
      @entryYears = uniq @entryYears;
      @entryYears = sort { $a <=> $b } @entryYears;
      return $entryYears[0];
    }
  );

  $app->helper(
    num_pubs => sub {
      my $self            = shift;
      my $type            = shift;
      my $year            = shift;
      my $entries_arr_ref = shift;

      my @entries;
      if ($entries_arr_ref) {
        @entries = @$entries_arr_ref;
      }
      else {
        @entries = $self->app->repo->entries_all;
      }

      if ($type) {
        @entries = grep { $_->entry_type eq $type } @entries;
      }
      if ($year) {
        @entries
          = grep { defined $_->year and $_->year == $year and $_->hidden == 0 }
          @entries;
      }
      return scalar @entries;

    }
  );

  $app->helper(
    get_important_tag_types => sub {
      my $self = shift;
      return $self->app->repo->tagTypes_filter(sub { $_->id < 4 });
    }
  );

  $app->helper(
    get_tag_type_obj => sub {
      my $self = shift;
      my $type = shift // 1;
      return $self->app->repo->tagTypes_find(sub { $_->id == $type });
    }
  );

  $app->helper(
    get_tags_of_type_for_paper => sub {
      my $self = shift;
      my $eid  = shift;
      my $type = shift // 1;

      my $paper = $self->app->repo->entries_find(sub { $_->id == $eid });
      my @tags  = $paper->get_tags_of_type($type);
      @tags = sort { $a->name cmp $b->name } @tags;
      return @tags;
    }
  );

  $app->helper(
    get_unassigned_tags_of_type_for_paper => sub {
      my $self = shift;
      my $eid  = shift;
      my $type = shift // 1;

      my $paper = $self->app->repo->entries_find(sub { $_->id == $eid });
      my %has_tags   = map { $_ => 1 } $paper->get_tags_of_type($type);
      my @all_tags   = $self->app->repo->tags_filter(sub { $_->type == $type });
      my @unassigned = grep { not $has_tags{$_} } @all_tags;
      @unassigned = sort { $a->name cmp $b->name } @unassigned;
      return @unassigned;
    }
  );

  $app->helper(
    num_authors => sub {
      my $self = shift;
      return $self->app->repo->authors_count;
    }
  );

  $app->helper(
    get_visible_authors => sub {
      my $self = shift;
      return $self->app->repo->authors_filter(sub { $_->is_visible });
    }
  );

  $app->helper(
    num_visible_authors => sub {
      my $self = shift;
      return scalar $self->get_visible_authors();
    }
  );

  $app->helper(
    get_num_teams => sub {
      my $self = shift;
      return $self->app->repo->teams_count;
    }
  );

  $app->helper(
    num_tags => sub {
      my $self = shift;
      my $type = shift // 1;
      return scalar $self->app->repo->tags_filter(sub { $_->type == $type });
    }
  );

  $app->helper(
    num_pubs_for_author_and_tag => sub {
      my $self   = shift;
      my $author = shift;
      my $tag    = shift;

      return scalar grep { $_->has_tag($tag) } $author->get_entries;
    }
  );

  $app->helper(
    num_pubs_for_tag => sub {
      my $self = shift;
      my $tag  = shift;
      return scalar $tag->get_entries // 0;
    }
  );

}

1;
