use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use BibSpace;
use BibSpace::Functions::Core;

my $admin_user = Test::Mojo->new('BibSpace');
$admin_user->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);

my $self       = $admin_user->app;
my $app_config = $admin_user->app->config;
$admin_user->ua->max_redirects(3);

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my @entries = $admin_user->app->repo->entries_all;
my $entry   = shift @entries;
my $author  = ($admin_user->app->repo->authors_all)[0];
my @teams   = $admin_user->app->repo->teams_all;
my $team    = shift @teams;
my @tags    = $admin_user->app->repo->tags_all;
my $tag     = shift @tags;

my $page;

$page = $self->url_for('all_teams');
note "============ Testing page $page ============";
$admin_user->get_ok($page, "Get for page $page")
  ->status_isnt(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

$page = $self->url_for('add_team_get');
note "============ Testing page $page ============";
$admin_user->get_ok($page, "Get for page $page")
  ->status_isnt(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

# Not-existing team should return 404
$page = $self->url_for('edit_team', id => -1);
note "============ Testing page $page ============";

# This does not return 404 if not found.
# It redirects to the previous page (Status 301 - but gets 200 due to allow_redirects) and displays error buble
$admin_user->get_ok($page, "Get for page $page")
  ->status_isnt(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

foreach my $team (@teams) {

  $page = $self->url_for('edit_team', id => $team->id);
  note "============ Testing page $page ============";
  $admin_user->get_ok($page, "Get for page $page")
    ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");

  $page = $self->url_for('unrelated_papers_for_team', teamid => $team->id);
  note "============ Testing page $page ============";
  $admin_user->get_ok($page, "Get for page $page")
    ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");
}

$admin_user->post_ok(
  $self->url_for('add_team_post') => form => {new_team => "test-team-1"});

# Try to add another team which name already exists
$admin_user->post_ok(
  $self->url_for('add_team_post') => form => {new_team => "test-team-1"});

$admin_user->post_ok(
  $self->url_for('add_team_post') => form => {new_team => "test-team-2"});

my $team1 = $self->app->repo->teams_find(sub { $_->name eq "test-team-1" });
my $team2 = $self->app->repo->teams_find(sub { $_->name eq "test-team-2" });

# FIXME: delete is done with verb GET
$admin_user->get_ok($self->url_for('delete_team', id => $team1->id));

# FIXME: delete is done with verb GET
$admin_user->get_ok($self->url_for('delete_team_force', id => $team2->id));

ok(1);
done_testing();
