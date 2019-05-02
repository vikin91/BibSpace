use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use BibSpace::Functions::MySqlBackupFunctions;

my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);
my $self = $t_logged_in->app;
$t_logged_in->ua->max_redirects(5);

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

$t_logged_in->post_ok(
  '/register' => form => {
    login     => "HenryJohnTester",
    name      => 'Henry John',
    email     => 'HenryJohnTester@example.com',
    password1 => 'qwerty',
    password2 => 'qwerty'
  }
);

$t_logged_in->post_ok(
  '/register' => form => {
    login     => "HenryJohnTester2",
    name      => 'Henry John2',
    email     => 'HenryJohnTester2@example.com',
    password1 => 'qwerty2',
    password2 => 'qwerty2'
  }
);

my $me = $t_logged_in->app->repo->users_find(sub { $_->login eq 'pub_admin' });
my $user
  = $t_logged_in->app->repo->users_find(sub { $_->login eq 'HenryJohnTester' });
my $user2
  = $t_logged_in->app->repo->users_find(sub { $_->login eq 'HenryJohnTester2' }
  );

ok($me,    "Admin user exists");
ok($user,  "A test user (1) exists");
ok($user2, "A test user (2) exists");

my @pages = (
  '/profile', $t_logged_in->app->url_for('manage_users'),
  $t_logged_in->app->url_for('show_user_profile', id => $user->id),
  $t_logged_in->app->url_for('show_user_profile', id => $user2->id),
  $t_logged_in->app->url_for('delete_user',       id => $user2->id), # delete ok
  $t_logged_in->app->url_for('make_user',         id => $user->id),
  $t_logged_in->app->url_for('make_manager',      id => $user->id),
  $t_logged_in->app->url_for('make_admin',        id => $user->id),
  $t_logged_in->app->url_for('delete_user',       id => $user->id)
  ,    # shall not be deleted - is admin
  $t_logged_in->app->url_for('delete_user', id => 99999)
  ,    # shall not be deleted - does not exist
  $t_logged_in->app->url_for('delete_user', id => $me->id)
  ,    # shall not be deleted - is me
  $t_logged_in->app->url_for('make_user', id => $me->id)
  ,    # shall not be degraded - is me & admin
);

for my $page (@pages) {
  note "============ Testing page $page ============";
  $t_logged_in->get_ok($page, "Get for page $page")
    ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");
}

ok(1);
done_testing();
