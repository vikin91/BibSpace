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

subtest "Serializing to JSON should not remove fields from super-class" => sub {
  use JSON -convert_blessed_universally;
  my $l = $all_exceptions[0];

  my $pre_1 = $l->entry_id;
  my $pre_2 = $l->team_id;

  my $json = JSON->new->convert_blessed->utf8->pretty->encode($l);
  chomp $json;
  cmp_ok($json, 'ne', "{}", "JSON representation should not be empty");

  my $post_1 = $l->entry_id;
  my $post_2 = $l->team_id;

  is($post_1, $pre_1,
    "Data field entry_id should be identical before and after serialization");
  is($post_2, $pre_2,
    "Data field team_id should be identical before and after serialization");
};

ok(1);
done_testing();
