use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;
use BibSpace::TestManager;
TestManager->apply_fixture($self->app);
my $repo = $self->app->repo;

my @all_tags = $repo->tags_all;
ok(scalar @all_tags > 0, "There should be some tags in the system");

my $tag = $all_tags[0];
ok($tag->repo, "Each tag should have ref to repo object");
my @entries = $tag->get_entries;
ok(scalar @entries > 0,
  "There should be some entries available for tag after linking");

ok($tag->equals($tag), "Tag is equal to itself");
dies_ok(sub { $tag->equals(undef) }, 'Tag equals undef expecting to die');

my @tags_w_entries = $repo->tags_filter(sub { scalar $_->get_entries > 0 });
ok(scalar @tags_w_entries,
  "There should be some tags in the system that have entries");

subtest "Entry-Labeling-Tag combination" => sub {

  my $tag     = $tags_w_entries[0];
  my @entries = $tag->get_entries;
  my $entry   = $entries[0];

  my $labeling = $self->app->repo->entityFactory->new_Labeling(
    entry_id => $entry->id,
    tag_id   => $tag->id
  );

  ok($entry->has_labeling($labeling), "Entry should have labeling");
  ok($tag->has_labeling($labeling),   "Tag should have the same labeling");
};

done_testing();
