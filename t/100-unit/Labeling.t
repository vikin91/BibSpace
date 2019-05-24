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

my $limit_num_tests = 50;

note "============ Testing " . scalar(@all_labelings) . " entries ============";

foreach my $labeling (@all_labelings) {
  last if $limit_num_tests < 0;

  note "============ Testing Labeling ID " . $labeling->id . ".";

  ok($labeling->id, "id");

  lives_ok(sub { $labeling->equals($labeling) }, 'equals expecting to live');
  lives_ok(sub { $labeling->equals_id($labeling) },
    'equals_id expecting to live');
  dies_ok(sub { $labeling->equals(undef) }, 'equals undef expecting to die');

  $limit_num_tests--;
}

subtest "Serializing to JSON should not remove fields from super-class" => sub {
  use JSON -convert_blessed_universally;
  my $l = $all_labelings[0];

  my $pre_1 = $l->entry_id;
  my $pre_2 = $l->tag_id;

  my $json = JSON->new->convert_blessed->utf8->pretty->encode($l);
  chomp $json;
  cmp_ok($json, 'ne', "{}", "JSON representation should not be empty");

  my $post_1 = $l->entry_id;
  my $post_2 = $l->tag_id;

  is($post_1, $pre_1,
    "Data field entry_id should be identical before and after serialization");
  is($post_2, $pre_2,
    "Data field tag_id should be identical before and after serialization");
};

ok(1);
done_testing();
