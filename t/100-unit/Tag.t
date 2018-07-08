use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

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

my @tags_w_entries = $repo->tags_filter(sub { scalar $_->get_entries > 0 });
ok(scalar @tags_w_entries,
  "There should be some tags in the system that have entries");

ok(1);
done_testing();
