package BibSpace::Controller::Helpers;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010;           #because of ~~
use strict;
use warnings;
use DBI;

use List::MoreUtils qw(any uniq);

use BibSpace::Controller::Core;
use BibSpace::Controller::Publications;
use BibSpace::Controller::BackupFunctions;

use BibSpace::Functions::FPublications;


use base 'Mojolicious::Plugin';

sub register {

  my ( $self, $app ) = @_;

  $app->helper(
    storage => sub {
      StorageBase->get();
    }
  );

  $app->helper(
    get_dbh => sub {
      my $self = shift;
      return $self->app->db;
    }
  );
  $app->helper(
    bst => sub {
      my $self = shift;

      my $bst_candidate_file = $self->app->home . '/lib/descartes2.bst';

      if ( defined $self->app->config->{bst_file} ) {
        $bst_candidate_file = $self->app->config->{bst_file};
        say "BST candidate 1: $bst_candidate_file";
        return File::Spec->rel2abs($bst_candidate_file)
          if File::Spec->file_name_is_absolute($bst_candidate_file)
          and -e File::Spec->rel2abs($bst_candidate_file);

        $bst_candidate_file = $self->app->home . $self->app->config->{bst_file};
        say "BST candidate 2: $bst_candidate_file";

        return File::Spec->rel2abs($bst_candidate_file)
          if File::Spec->file_name_is_absolute($bst_candidate_file)
          and -e File::Spec->rel2abs($bst_candidate_file);
      }

      $bst_candidate_file = $self->app->home . '/lib/descartes2.bst';
      say "BST candidate 3: $bst_candidate_file";

      return File::Spec->rel2abs($bst_candidate_file) if -e File::Spec->rel2abs($bst_candidate_file);

      say "All BST candidates failed";
      return './bst-not-found.bst';
    }
  );


  $app->helper(
    current_year => sub {
      return BibSpace::Controller::Core::get_current_year();
    }
  );
  $app->helper(
    current_month => sub {
      return BibSpace::Controller::Core::get_current_month();
    }
  );

  $app->helper(
    get_year_of_oldest_entry => sub {
      my $self = shift;

      my @entryYears = map { $_->year } grep { defined $_->year } $self->storage->entries_all;
      @entryYears = uniq @entryYears;
      @entryYears = sort { $a <=> $b } @entryYears;
      return $entryYears[0];

    }
  );


  $app->helper(
    can_delete_backup_helper => sub {
      my $self = shift;
      my $bid  = shift;

      return can_delete_backup( $self->app->db, $bid, $self->app->config );
    }
  );

  $app->helper(
    num_pubs => sub {
      my $self = shift;
      return $self->app->repo->getEntriesRepository->all;
    }
  );

  $app->helper(
    get_all_tag_types => sub {
      my $self = shift;
      return $self->app->repo->getTagTypesRepository->all;
    }
  );

  $app->helper(
    get_tag_type_obj => sub {
      my $self = shift;
      my $type = shift || 1;
      return $self->app->repo->getTagTypesRepository->find( sub { $_->id == $type } );
    }
  );

  $app->helper(
    get_tags_of_type_for_paper => sub {
      my $self = shift;
      my $eid  = shift;
      my $type = shift || 1;

      return MTag->static_get_all_of_type_for_paper( $self->app->db, $eid, $type );
    }
  );

  $app->helper(
    get_unassigned_tags_of_type_for_paper => sub {
      my $self = shift;
      my $eid  = shift;
      my $type = shift || 1;

      return MTag->static_get_unassigned_of_type_for_paper( $self->app->db, $eid, $type );
    }
  );

  $app->helper(
    num_authors => sub {
      my $self = shift;
      return $self->app->repo->getAuthorsRepository()->all();

      # return $self->storage->authors_all;

    }
  );

  $app->helper(
    get_visible_authors => sub {
      my $self = shift;
      return $self->app->repo->getAuthorsRepository->filter( sub { $_->is_visible } );
    }
  );

  $app->helper(
    num_visible_authors => sub {
      my $self = shift;
      return scalar $self->get_visible_authors();
    }
  );

  $app->helper(
    get_num_members_for_team => sub {
      my $self   = shift;
      my $id     = shift;
      my $author = $self->storage->authors_find( sub { $_->id == $id } );
      return scalar $author->teams_count;
    }
  );

  $app->helper(
    get_num_teams => sub {
      my $self = shift;
      return $self->app->repo->getTeamsRepository()->count();
    }
  );


  $app->helper(
    num_tags => sub {
      my $self = shift;
      my $type = shift || 1;
      return scalar $self->app->repo->getTagsRepository->filter( sub { $_->type == $type } );
    }
  );

  $app->helper(
    num_pubs_for_year => sub {
      my $self = shift;
      my $year = shift;

      return
        scalar grep { defined $_->year and $_->year == $year and $_->hidden == 0 }
        $self->app->repo->getEntriesRepository()->all();
    }
  );

  $app->helper(
    get_bibtex_types_aggregated_for_type => sub {
      my $self = shift;
      my $type = shift;

      return get_bibtex_types_for_our_type( $self->app->db, $type );
    }
  );

  $app->helper(
    helper_get_description_for_our_type => sub {
      my $self = shift;
      my $type = shift;
      return get_description_for_our_type( $self->app->db, $type );
    }
  );

  $app->helper(
    helper_get_landing_for_our_type => sub {
      my $self = shift;
      my $type = shift;
      return get_landing_for_our_type( $self->app->db, $type );
    }
  );


  $app->helper(
    num_bibtex_types_aggregated_for_type => sub {
      my $self = shift;
      my $type = shift;
      return scalar $self->get_bibtex_types_aggregated_for_type($type);
    }
  );

  $app->helper(
    num_pubs_for_author_and_tag => sub {
      my $self   = shift;
      my $author = shift;
      my $tag    = shift;

      return
        scalar $author->authorships_filter( sub { defined $_ and defined $_->entry and $_->entry->has_tag($tag) } );
    }
  );

  $app->helper(
    get_recent_years_arr => sub {
      my $self = shift;

      my @arr = map { $_->year } grep { defined $_->year } $self->app->repo->getEntriesRepository()->all();
      @arr = uniq @arr;
      @arr = sort { $b <=> $a } @arr;
      my $max = scalar @arr;
      $max = 10 if $max > 10;
      return @arr[ 0 .. $max ];
    }
  );

  $app->helper(
    num_entries_for_author => sub {
      my $self   = shift;
      my $author = shift;

      return $author->authorships_count;
    }
  );

  $app->helper(
    num_talks_for_author => sub {
      my $self   = shift;
      my $author = shift;

      return scalar $author->authorships_filter( sub { $_->entry->is_talk } ) // 0;
    }
  );

  $app->helper(
    num_papers_for_author => sub {
      my $self   = shift;
      my $author = shift;
      return scalar $author->authorships_filter( sub { $_->entry->is_paper } ) // 0;
    }
  );


  $app->helper(
    num_pubs_for_tag => sub {
      my $self = shift;
      my $tag  = shift;
      return $tag->labelings_count // 0;
    }
  );

}

1;
