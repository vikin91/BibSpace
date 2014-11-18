use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

use Data::Dumper;
use Array::Utils qw(:all);

use BibSpace::Model::Author;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my $repo = $self->app->repo;

my @all_authors = $repo->authors_all;

my $limit_test_objects = 30;

sub aDump {
  JSON->new->convert_blessed->utf8->pretty->encode(shift);
}

ok($self->app->repo->lr->facade, "Repository layer has facade set");

my $au = $self->app->entityFactory->new_Author(uid => "Henry");
is($au->id, undef, "Unsaved Authors have no ID. Dump:" . aDump $au);
is($au->get_master_id, undef,
  "Unsaved Authors have no master_ID. Dump:" . aDump $au);
$repo->authors_save($au);
isnt($au->id, undef, "Saved Authors have ID. Dump:" . aDump $au);
isnt($au->get_master_id, undef,
  "Saved Authors have master_ID. Dump:" . aDump $au);

subtest 'Author constructor' => sub {

  ok($au->id >= 1,            "id should be >= 1. Dump: " . aDump $au);
  ok($au->get_master_id >= 1, "master_id should be >= 1. Dump: " . aDump $au);
  is($au->name, $au->uid, "name should be same as uid. Dump: " . aDump $au);
  is($au->get_master_id, $au->id, "master_id name same as id");
  isnt($au->get_master, undef, "masterObj should never be empty");
  is($au->get_master, $au, "get_master should return self");
};

subtest 'Alone author functions' => sub {

  is($au->can_be_deleted, 1, "can_be_deleted");
};

note "============ Testing " . scalar(@all_authors) . " Authors ============";

foreach my $author (@all_authors) {
  last if $limit_test_objects < 0;
  next if $author->id == $au->id;
  note "============ Testing Author ID " . $author->id . ".";

  ok($author,             "author should be defined");
  ok($author->get_master, "author->get_master should be defined");
  is($author->get_master, $author, "get_master should return self");

  note "============ Setting master "
    . aDump($au)
    . " to author "
    . aDump($author)
    . "============";

  $author->set_master($au);
  isnt($author->is_master, 1, "isnt master");
  is($author->get_master, $au,
    "get_master should return master. Dump: " . aDump $author);
  is($author->is_minion,         1, "is minion");
  is($author->is_minion_of($au), 1, "is_minion_of");
  isnt($author->is_minion_of($author), 1, "isnt_minion_of");

  is($author->update_name("John"),
    1, "update master name should succeed. Dump: " . aDump $author);
  isnt($author->master->name,
    "New master name should be John. Dump: " . aDump $author);
  is($author->uid, "John", "New uid should be John. Dump: " . aDump $author);
  ok($author->remove_master, "remove master should succeed");
  is($author->update_name("John"), 1,      "update_name should return 1");
  is($author->master->name,        "John", "New master name should be John");
  is($author->uid,                 "John", "New uid should be John");

  ok($au->add_minion($author), "add minion");
  isnt($author->is_master, 1, "isnt master");
  is($author->is_minion,         1, "is minion");
  is($author->is_minion_of($au), 1, "is_minion_of");
  isnt($author->is_minion_of($author), 1, "isnt_minion_of");
  is($author->get_master, $au, "get_master");

  is($au->can_merge_authors($author), 1, "can_merge_authors");
  is($author->can_merge_authors($au), 1, "can_merge_authors");
  isnt($author->can_merge_authors($author), 1, "can_merge_authors");
  isnt($au->can_merge_authors($au),         1, "can_merge_authors");

  if ($author->is_visible) {
    $author->toggle_visibility;
    ok(!$author->is_visible, "is not visible");
    $author->toggle_visibility;
    ok($author->is_visible, "is visible");
  }
  else {
    $author->toggle_visibility;
    ok($author->is_visible, "is visible");
    $author->toggle_visibility;
    ok(!$author->is_visible, "is not visible");
  }

  my @teams = $author->get_teams;
  foreach my $team (@teams) {
    ok($author->has_team($team), "has_team");
  }

  if ($author->get_entries) {
    my $entry = ($author->get_entries)[0];

    note "Checking entry " . $entry->id;

    my $au = $self->app->entityFactory->new_Authorship(
      author_id => $author->id,
      entry_id  => $entry->id
    );

    ok($au->equals($au),    'equals');
    ok($au->equals_id($au), 'equals_id');

    if (!$author->has_authorship($au)) {
      ok($author->add_authorship($au), 'add_authorship');
    }
    else {
      ok(!$author->add_authorship($au), 'cant add_authorship');
    }
    ok($author->has_entry($entry),   'has_entry');
    ok($author->has_authorship($au), 'has_authorship');
    is($author->remove_authorship($au),
      1, 'Authorship should be removed with result 1');
    ok(!$author->has_authorship($au),
      'Author should no longer have authorship');
    is($author->remove_authorship($au),
      undef, 'Removal of non-existing authorship removal should return undef');
    ok(!$author->has_authorship($au), 'hasnt authorship');
    ok(!$author->has_entry($entry),
          "Author should not have entry "
        . aDump($author)
        . " Entry: "
        . aDump($entry));

  }

  $limit_test_objects--;
}

ok(1);
done_testing();

