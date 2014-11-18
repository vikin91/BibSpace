use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my $repo            = $self->app->repo;
my @all_memberships = $repo->memberships_all;

my $limit_num_tests = 200;

note "============ Testing "
  . scalar(@all_memberships)
  . " entries ============";

foreach my $membership (@all_memberships) {
  last if $limit_num_tests < 0;

  note "============ Testing Labeling ID " . $membership->id . ".";

  ok($membership->id, "id");

  lives_ok(sub { $membership->equals($membership) },
    'equals expecting to live');
  lives_ok(sub { $membership->equals_id($membership) },
    'equals_id expecting to live');
  dies_ok(sub { $membership->equals(undef) }, 'equals undef expecting to die');

  $limit_num_tests--;
}

subtest "Serializing to JSON should not remove fields from super-class" => sub {
  use JSON -convert_blessed_universally;
  my $l = $all_memberships[0];

  my $pre_1 = $l->team_id;
  my $pre_2 = $l->author_id;
  my $pre_3 = $l->start;
  my $pre_4 = $l->stop;

  my $json = JSON->new->convert_blessed->utf8->pretty->encode($l);
  chomp $json;
  cmp_ok($json, 'ne', "{}", "JSON representation should not be empty");

  my $post_1 = $l->team_id;
  my $post_2 = $l->author_id;
  my $post_3 = $l->start;
  my $post_4 = $l->stop;

  is($post_1, $pre_1,
    "Data field team_id should be identical before and after serialization");
  is($post_2, $pre_2,
    "Data field author_id should be identical before and after serialization");
  is($post_3, $pre_3,
    "Data field start should be identical before and after serialization");
  is($post_4, $pre_4,
    "Data field stop should be identical before and after serialization");
};

ok(1);
done_testing();
