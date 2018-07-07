use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my $repo          = $self->app->repo;
my @all_labelings = $repo->labelings_all;

my $limit_num_tests = 200;

note "============ Testing " . scalar(@all_labelings) . " entries ============";

foreach my $labeling (@all_labelings) {
  last if $limit_num_tests < 0;

  note "============ Testing Labeling ID " . $labeling->id . ".";

  ok($labeling->id, "id");

  lives_ok(sub { $labeling->validate },          'validate expecting to live');
  lives_ok(sub { $labeling->equals($labeling) }, 'equals expecting to live');
  lives_ok(sub { $labeling->equals_obj($labeling) },
    'equals_obj expecting to live');
  lives_ok(sub { $labeling->equals_id($labeling) },
    'equals_id expecting to live');
  dies_ok(sub { $labeling->equals(undef) }, 'equals undef expecting to die');

  $limit_num_tests--;
}

ok(1);
done_testing();
