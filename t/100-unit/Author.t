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

my $other_author = $self->app->entityFactory->new_Author(uid => "Henry");

subtest 'Author constructor' => sub {

  is($other_author->master,    $other_author->uid, "master name same as uid");
  is($other_author->master_id, $other_author->id,  "master_id name same as id");
  is($other_author->masterObj, undef,              "masterObj empty");
};

subtest 'Alone author functions' => sub {

  is($other_author->can_be_deleted, 1, "can_be_deleted");
};

note "============ Testing " . scalar(@all_authors) . " Authors ============";

foreach my $author (@all_authors) {
  last if $limit_test_objects < 0;
  note "============ Testing Author ID " . $author->id . ".";

  ok($author,             "author defined");
  ok($author->toString,   "author->toString defined");
  ok($author->get_master, "author->get_master defined");

  $author->set_master($other_author);
  isnt($author->is_master, 1, "isnt master");
  is($author->is_minion,                   1, "is minion");
  is($author->is_minion_of($other_author), 1, "is_minion_of");
  isnt($author->is_minion_of($author), 1, "isnt_minion_of");
  is($author->get_master, $other_author, "get_master");

  is($author->update_master_name("John"), 1, "update master name");
  isnt($author->master, "John");
  is($author->uid, "John", "uid is John");
  ok($author->remove_master, "remove master");
  is($author->update_master_name("John"), 1);
  is($author->master, "John", "master is John");
  is($author->uid,    "John", "uid is John");

  ok($other_author->add_minion($author), "add minion");
  isnt($author->is_master, 1, "isnt master");
  is($author->is_minion,                   1, "is minion");
  is($author->is_minion_of($other_author), 1, "is_minion_of");
  isnt($author->is_minion_of($author), 1, "isnt_minion_of");
  is($author->get_master, $other_author, "get_master");

  is($other_author->can_merge_authors($author), 1, "can_merge_authors");
  is($author->can_merge_authors($other_author), 1, "can_merge_authors");
  isnt($author->can_merge_authors($author),             1, "can_merge_authors");
  isnt($other_author->can_merge_authors($other_author), 1, "can_merge_authors");

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

    my $au = Authorship->new(
      author    => $author,
      entry     => $entry,
      author_id => $author->id,
      entry_id  => $entry->id
    );

    ok($au->validate,        'validate');
    ok($au->toString,        'toString');
    ok($au->equals($au),     'equals');
    ok($au->equals_id($au),  'equals_id');
    ok($au->equals_obj($au), 'equals_obj');

    if (!$author->has_authorship($au)) {
      ok($author->add_authorship($au), 'add_authorship');
    }
    else {
      ok(!$author->add_authorship($au), 'cant add_authorship');
    }
    ok($author->has_entry($entry),   'has_entry');
    ok($author->has_authorship($au), 'has_authorship');
    is($author->remove_authorship($au), 1, 'remove authorship');
    ok(!$author->has_authorship($au),    'hasnt authorship');
    ok(!$author->remove_authorship($au), 'cant remove authorship');
    ok(!$author->has_authorship($au),    'hasnt authorship');
    ok(!$author->has_entry($entry),      "hasn't entry");

  }

  $limit_test_objects--;
}

ok(1);
done_testing();

