use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

sub aDump {
  JSON->new->convert_blessed->utf8->pretty->encode(shift);
}

my $repo           = $self->app->repo;
my @all_exceptions = $repo->exceptions_all;

my $limit_num_tests = 200;

note "============ Testing "
  . scalar(@all_exceptions)
  . " exceptions ============";

foreach my $exception (@all_exceptions) {
  last if $limit_num_tests < 0;

  note "============ Testing Exception ID " . aDump($exception) . ".";

  ok($exception->id, "Exception id should be defined");

  lives_ok(sub { $exception->equals($exception) },
    'equals sub should not throw');
  lives_ok(sub { $exception->equals_id($exception) },
    'equals_id sub should not thorw');
  dies_ok(sub { $exception->equals(undef) }, 'equals undef expecting to die');

  $limit_num_tests--;
}

ok(1);
done_testing();
