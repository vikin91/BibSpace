use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my $repo      = $self->app->repo;
my @all_teams = $repo->teams_all;

my $author  = ($repo->authors_all)[0];
my $author2 = ($repo->authors_all)[1];
my $entry   = ($repo->entries_all)[0];

my $limit_num_tests = 20;

note "============ Testing " . scalar(@all_teams) . " Teams ============";

foreach my $team (@all_teams) {
  last if $limit_num_tests < 0;

  note "============ Testing Team ID " . $team->id . ".";

  my @memberships = $team->get_memberships;
  ok(
    scalar @memberships ge 0,
    "Team should have 0 or more memberships and has "
      . (scalar @memberships) . "."
  );

  my $member_author = ($team->get_authors)[0];
  my $non_member    = $repo->authors_find(sub { !$_->has_team($team) });

  if ($member_author) {

    isnt($team->get_membership_end($member_author),       -1);
    isnt($team->get_membership_beginning($member_author), -1);
    ok(!$team->can_be_deleted, "can be deleted");

    my $mem = $repo->entityFactory->new_Membership(
      author_id => $member_author->get_master->id,
      team_id   => $team->id
    );

    my $mem2 = $repo->entityFactory->new_Membership(
      author_id => $member_author->get_master->id,
      team_id   => $team->id
    );

    ## testing membership actually...
    ok($mem->equals($mem2),    "mem equals");
    ok($mem->equals_id($mem2), "mem equals id");

    ok($member_author->update_membership($team, 0, 0), "update mem 0 0");
    ok($member_author->update_membership($team, 100, 200),
      "update mem 100 200");

    dies_ok { $member_author->update_membership($team, 200, 100) }
    "update mem bad 200 100";
    dies_ok { $member_author->update_membership($team, -100, 100) }
    "update mem bad 100 pne 100";
    dies_ok { $member_author->update_membership($team, 100, -100) }
    "update mem bad 100 100 pne";

    if ($non_member and !$author->equals($non_member)) {
      my $mem3 = $repo->entityFactory->new_Membership(
        author_id => $non_member->get_master->id,
        team_id   => $team->id
      );
      ok(!$mem->equals($mem3),    '!equals');
      ok(!$mem->equals_id($mem3), '!equals_id');

      ok(!$team->has_membership($mem3), '!has_membership');
    }

    $team->add_membership($mem);
    ok($team->has_membership($mem),     'has_membership');
    ok($team->remove_membership($mem),  'remove_membership');
    ok(!$team->remove_membership($mem), '!remove_membership');

  }
  else {
    ok($team->can_be_deleted, '!can_be_deleted');
  }

  if ($team->tags) {
    ok($team->tags,        'team has tags');
    ok($team->get_entries, 'team has entries');
  }

  if ($team->get_exceptions) {
    ok($team->get_exceptions, 'team has exceptions');
    ok($team->get_entries,    'team has entries from exceptions');
  }

  $limit_num_tests--;
}

ok(1);
done_testing();
