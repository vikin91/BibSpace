use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my $repo           = $self->app->repo;
my @all_exceptions = $repo->exceptions_all;

my $limit_num_tests = 200;

note "============ Testing "
  . scalar(@all_exceptions)
  . " entries ============";

foreach my $exception (@all_exceptions) {
  last if $limit_num_tests < 0;

  note "============ Testing Exception ID " . $exception->id . ".";

  ok($exception->id, "id");

  # lives_ok( sub { $exception->validate }, 'validate expecting to live' );
  lives_ok(sub { $exception->equals($exception) }, 'equals expecting to live');
  lives_ok(sub { $exception->equals_obj($exception) },
    'equals_obj expecting to live');
  lives_ok(sub { $exception->equals_id($exception) },
    'equals_id expecting to live');
  dies_ok(sub { $exception->equals(undef) }, 'equals undef expecting to die');

  $limit_num_tests--;
}

ok(1);
done_testing();
