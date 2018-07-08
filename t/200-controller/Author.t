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
my @authors = $admin_user->app->repo->authors_all;
my $author  = $authors[0];
my @teams   = $admin_user->app->repo->teams_all;
my $team    = shift @teams;
my @tags    = $admin_user->app->repo->tags_all;
my $tag     = shift @tags;

my @tagTypes = $admin_user->app->repo->tagTypes_all;
my $tagType  = shift @tagTypes;

my $page;

ok($author,             "There should be at least one author in the system");
ok(scalar @authors > 1, "There should be at least one author in the system");

my @visible_authors
  = $admin_user->app->repo->authors_filter(sub { $_->is_visible });
ok(scalar @visible_authors > 1,
  "There should be at least one visible author in the system");
my @visible_authors_helper = $admin_user->app->get_visible_authors();
is(
  scalar @visible_authors,
  scalar @visible_authors_helper,
  "Helper should return the same number of visible authors as repo filter"
);
is(
  scalar @visible_authors,
  $admin_user->app->num_visible_authors(),
  "Helper should return the same number of visible authors as repo filter"
);

foreach my $a (@visible_authors_helper) {
  ok($a,                     "Author should be defined");
  ok($a->id >= 1,            "Author id should be >= 1");
  ok($a->get_master_id >= 1, "master_id should be >= 1");
  isnt($a->get_master, undef, "MasterObj should never be undef");

  if ($a->is_master) {
    isnt($a->master, undef);
    is($a->master, $a->uid);
  }
  else {
    isnt($a->master, $a->uid);
    is($a->get_master, $a);
  }
}

ok(1);
done_testing();
