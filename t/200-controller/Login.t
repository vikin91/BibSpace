use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use BibSpace::Functions::MySqlBackupFunctions;

my $t_anyone = Test::Mojo->new('BibSpace');
$t_anyone->ua->max_redirects(5);

my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);
my $self = $t_logged_in->app;
$t_logged_in->ua->max_redirects(5);

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

subtest "Registration disabled page" => sub {
  $t_anyone->app->config->{registration_enabled} = 0;
  is($t_anyone->app->config->{registration_enabled},
    0, "Registration setting should be 0");

  $t_anyone->app->config->{registration_enabled} = 1;
  is($t_anyone->app->config->{registration_enabled},
    1, "Registration setting should be 1");

  $t_anyone->get_ok($self->url_for('registration_disabled'))->status_isnt(404)
    ->status_isnt(500)->element_exists('p')
    ->content_like(qr/Registration is disabled/,
    "Info about disabled registration is visible");
};

subtest "Registration disabled for not logged-in users" => sub {
  $t_anyone->app->config->{registration_enabled} = 0;
  is($t_anyone->app->config->{registration_enabled},
    0, "Registration setting should be 0");

  $t_anyone->get_ok($self->url_for('logout'))->status_isnt(404)
    ->status_isnt(500)->element_exists('div[class$=jumbotron]')
    ->content_unlike(qr/Nice to see you here/)
    ->content_like(qr/Please login or register/, "Proper content after logout");

  $t_anyone->get_ok($self->url_for('register'))->status_isnt(404)
    ->status_isnt(500)
    ->element_exists_not('input[name=login][type=text][value*="j.bond007"]',
    "There should be no registartion form")
    ->element_exists_not('input[name=email][type=text][value*="@example.com"]',
    "There should be no registartion form")
    ->content_like(qr/Registration is disabled/,
    "Info about disabled registration is visible");

  $t_anyone->post_ok(
    $self->url_for('post_do_register') => form => {
      login     => "HenryJohnTester",
      name      => 'Henry John',
      email     => 'HenryJohnTester@example.com',
      password1 => 'qwerty',
      password2 => 'qwerty'
    }
  )->status_isnt(404)->status_isnt(500)
    ->element_exists_not('input[name=login][type=text][value*="j.bond007"]',
    "There should be no registartion form")
    ->element_exists_not('input[name=email][type=text][value*="@example.com"]',
    "There should be no registartion form")
    ->content_like(qr/Registration is disabled/,
    "Info about disabled registration is visible");
};

subtest "Register users" => sub {
  $t_logged_in->post_ok(
    $self->url_for('post_do_register') => form => {
      login     => "HenryJohnTester",
      name      => 'Henry John',
      email     => 'HenryJohnTester@example.com',
      password1 => 'qwerty',
      password2 => 'qwerty'
    }
    )
    ->content_like(
    qr/User created successfully! You may now login using login: HenryJohnTester./
    );

  $t_logged_in->post_ok(
    $self->url_for('post_do_register') => form => {
      login     => "HenryJohnTester2",
      name      => 'Henry John2',
      email     => 'HenryJohnTester2@example.com',
      password1 => 'qwerty2',
      password2 => 'qwerty2'
    }
    )
    ->content_like(
    qr/User created successfully! You may now login using login: HenryJohnTester2./
    );

  my $me
    = $t_logged_in->app->repo->users_find(sub { $_->login eq 'pub_admin' });
  my $user1
    = $t_logged_in->app->repo->users_find(sub { $_->login eq 'HenryJohnTester' }
    );
  my $user2 = $t_logged_in->app->repo->users_find(
    sub { $_->login eq 'HenryJohnTester2' });

  ok($me,    "Admin user1 exists");
  ok($user1, "A test user (1) exists");
  ok($user2, "A test user (2) exists");
};

subtest "Pages for logged-in users" => sub {
  my $me
    = $t_logged_in->app->repo->users_find(sub { $_->login eq 'pub_admin' });
  my $user1
    = $t_logged_in->app->repo->users_find(sub { $_->login eq 'HenryJohnTester' }
    );
  my $user2 = $t_logged_in->app->repo->users_find(
    sub { $_->login eq 'HenryJohnTester2' });

  my @pages = (
    $t_logged_in->app->url_for('manage_users'),
    $t_logged_in->app->url_for('show_my_profile'),
    $t_logged_in->app->url_for('registration_disabled'),
    $t_logged_in->app->url_for('show_user_profile', id => $user1->id),
    $t_logged_in->app->url_for('show_user_profile', id => $user2->id),
    $t_logged_in->app->url_for('delete_user',  id => $user2->id),    # delete ok
    $t_logged_in->app->url_for('make_user',    id => $user1->id),
    $t_logged_in->app->url_for('make_manager', id => $user1->id),
    $t_logged_in->app->url_for('make_admin',   id => $user1->id),
    $t_logged_in->app->url_for('delete_user',  id => $user1->id)
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
};

done_testing();
