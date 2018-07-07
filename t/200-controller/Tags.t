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

# $logged_user->get('/tags/:type')->to( 'tags#index', type => 1 )->name('all_tags');
# $admin_user->get('/tags/add/:type')->to( 'tags#add', type => 1 )->name('add_tag_get');
# $admin_user->post('/tags/add/:type')->to( 'tags#add_post', type => 1 )->name('add_tag_post');
# $logged_user->get('/tags/authors/:tid/:type')->to( 'tags#get_authors_for_tag', type => 1 )
#   ->name('get_authors_for_tag');
# $admin_user->get('/tags/delete/:id')->to('tags#delete')->name('delete_tag');
# $manager_user->get('/tags/edit/:id')->to('tags#edit')->name('edit_tag');

my @entries = $admin_user->app->repo->entries_all;
my $entry   = shift @entries;
my $author  = ($admin_user->app->repo->authors_all)[0];
my @teams   = $admin_user->app->repo->teams_all;
my $team    = shift @teams;
my @tags    = $admin_user->app->repo->tags_all;
my $tag     = shift @tags;

my @tagTypes = $admin_user->app->repo->tagTypes_all;
my $tagType  = shift @tagTypes;

my $page;

foreach my $type (@tagTypes) {

  my $typeID = $type->id;

  $page = $self->url_for('all_tags', type => $typeID);
  note "============ Testing page $page ============";
  $admin_user->get_ok($page, "Get for page $page")
    ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");

  $page = $self->url_for('add_tag_get', type => $typeID);
  note "============ Testing page $page ============";
  $admin_user->get_ok($page, "Get for page $page")
    ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");

# calling this like:
# $admin_user->post_ok(
#   $self->url_for('add_tag_post', type=>$typeID) => form => {type => $typeID, new_tag => "test_tag_type_$typeID" }
# );
# causes to use totally wrong id provider!
  $admin_user->post_ok(
    $self->url_for('add_tag_post', type => $typeID) => form =>
      {new_tag => "test_tag_type_$typeID"});
  $admin_user->post_ok(
    $self->url_for('add_tag_post', type => $typeID) => form =>
      {new_tag => "zz_$typeID;aa_$typeID;;test_tag2_type_$typeID"});

}

foreach my $tag (@tags) {

  $page = $self->url_for('get_authors_for_tag', id => $tag->id, type => 1);
  note "============ Testing page $page ============";
  $admin_user->get_ok($page, "Get for page $page")

    # ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");

  $page = $self->url_for(
    'get_authors_for_tag_and_team',
    tag_id  => $tag->id,
    team_id => $team->id,
    type    => 1
  );
  note "============ Testing page $page ============";
  $admin_user->get_ok($page, "Get for page $page")

    # ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");

  $page = $self->url_for('edit_tag', id => $tag->id);
  note "============ Testing page $page ============";
  $admin_user->get_ok($page, "Get for page $page")
    ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");

}

my $tag_del = shift @tags;

$page = $self->url_for('delete_tag', id => $tag_del->id);
note "============ Testing page $page ============";
$admin_user->get_ok($page, "Get for page $page")
  ->status_isnt(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

# subtest 'aaa' => sub {
# };

ok(1);
done_testing();
