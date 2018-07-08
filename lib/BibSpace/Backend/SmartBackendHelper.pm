package BibSpace::Backend::SmartBackendHelper;

use v5.16;
use Try::Tiny;
use namespace::autoclean;

sub linkData {
  my $app = shift;

  $app->logger->info("Linking Authors (N) to (1) Authors.");
  foreach
    my $author ($app->repo->authors_filter(sub { $_->id != $_->get_master_id }))
  {
    my $master
      = $app->repo->authors_find(sub { $_->id == $author->get_master_id });
    if ($master and $author) {
      $author->set_master($master);
    }
  }

  $app->logger->info("Linking Authors (N) to (M) Entries.");
  foreach my $auth ($app->repo->authorships_all) {
    my $entry  = $app->repo->entries_find(sub { $_->id == $auth->entry_id });
    my $author = $app->repo->authors_find(sub { $_->id == $auth->author_id });
    if ($entry and $author) {
      $auth->entry($entry);
      $auth->author($author);
      $entry->authorships_add($auth);
      $author->authorships_add($auth);
    }
  }

  $app->app->logger->info("Linking Tags (N) to (M) Entries.");
  foreach my $labeling ($app->repo->labelings_all) {
    my $entry = $app->repo->entries_find(sub { $_->id == $labeling->entry_id });
    my $tag   = $app->repo->tags_find(sub    { $_->id == $labeling->tag_id });
    if ($entry and $tag) {
      $labeling->entry($entry);
      $labeling->tag($tag);
      $entry->labelings_add($labeling);
      $tag->labelings_add($labeling);
    }
  }

  $app->app->logger->info("Linking Teams (Exceptions) (N) to (M) Entries.");
  foreach my $exception ($app->repo->exceptions_all) {
    my $entry
      = $app->repo->entries_find(sub { $_->id == $exception->entry_id });
    my $team = $app->repo->teams_find(sub { $_->id == $exception->team_id });
    if ($entry and $team) {
      $exception->entry($entry);
      $exception->team($team);
      $entry->exceptions_add($exception);
      $team->exceptions_add($exception);
    }
  }

  $app->app->logger->info("Linking Teams (N) to (M) Authors.");
  foreach my $membership ($app->repo->memberships_all) {
    my $author
      = $app->repo->authors_find(sub { $_->id == $membership->author_id });
    my $team = $app->repo->teams_find(sub { $_->id == $membership->team_id });
    if (defined $author and defined $team) {
      $membership->author($author);
      $membership->team($team);
      $author->memberships_add($membership);
      $team->memberships_add($membership);
    }
  }

  $app->app->logger->info("Linking TagTypes (N) to (1) Tags.");
  foreach my $tag ($app->repo->tags_all) {
    my $tagtype = $app->repo->tagTypes_find(sub { $_->id == $tag->type });
    if ($tag and $tagtype) {
      $tag->tagtype($tagtype);
    }
  }

  $app->app->logger->info("TODO: Linking OurTypes (N) to (1) Entries.");
}

1;
