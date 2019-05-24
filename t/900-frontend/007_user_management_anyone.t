use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Functions::Core;
use BibSpace::Model::User;

### Problem with this test suite is that the token for mailgun returns error because it is not correct in the default config
### We need to find a method to test this without providing the real credentials

# # ############################ PREPARATION
my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;
$t_anyone->ua->max_redirects(10);

use BibSpace::TestManager;
TestManager->apply_fixture($t_anyone->app);

# # ############################ READY FOR TESTING

my $token = generate_token();
ok(defined $token);
is(length($token), 32);

subtest 'Requesting password reset' => sub {

  note "============ FORGOT GEN 1 ============";
  $t_anyone->post_ok(
    '/forgot/gen' => {Accept => '*/*'},
    form          => {user   => 'pub_admin'}
  )->status_isnt(404)->status_isnt(500)
    ->content_like(qr/Email with password reset instructions has been sent/i,
    "Filling forgot with login");

  note "============ FORGOT GEN 2 ============";
  $t_anyone->post_ok(
    '/forgot/gen' => {Accept => '*/*'},
    form          => {user   => '', email => 'pub_admin@example.com'}
  )->status_isnt(404)->status_isnt(500)
    ->content_like(qr/Email with password reset instructions has been sent/i,
    "Filling forgot with email");

  note "============ FORGOT GEN 3 ============";

  $t_anyone->post_ok(
    '/forgot/gen' => form => {user => 'qwerty1234', email => ''})
    ->status_isnt(404)->status_isnt(500)
    ->content_like(
    qr/User 'qwerty1234' or email '' does not exist. Try again./i,
    "Filling forgot with bad data");
};

note "============ SET NEW PW ============";

subtest 'Setting new password' => sub {

  #requesting new token in cas it does not exist
  $t_anyone->post_ok(
    '/forgot/gen' => {Accept => '*/*'},
    form          => {user   => 'pub_admin'}
  );

  my $user = $t_anyone->app->repo->users_find(sub { $_->login eq 'pub_admin' });
  my $token2 = $user->get_forgot_pass_token;

  ok($token2, "Checking token exists");
  is(length($token2), 32, "Checking token length");

  my $page = $t_anyone->app->url_for('token_clicked', token => $token2);
  $t_anyone->get_ok($page)->status_is(200);

  # not matching passwords
  $t_anyone->post_ok('/forgot/store' => form =>
      {token => $token2, pass1 => 'asdf', pass2 => 'qwerty'})->status_isnt(404)
    ->status_isnt(500)
    ->content_like(
    qr/Passwords are not same or do not obey the password policy./i,
    "Trying with non-matching passwords");

  # matching passwords
  $t_anyone->post_ok('/forgot/store' => form =>
      {token => $token2, pass1 => 'asdf', pass2 => 'asdf'})->status_isnt(404)
    ->status_isnt(500)->content_like(
    qr/Password change successful. All your password reset tokens have been removed. You may login now./i,
    "Trying with valid data"
    );

  # wrong token
  $t_anyone->post_ok('/forgot/store' => form =>
      {token => 'invalid_token', pass1 => 'asdf', pass2 => 'asdf'})
    ->status_isnt(404)->status_isnt(500)
    ->content_like(qr/Reset password token is invalid!/i,
    "Trying invalid token");
};

note "============ Registration anyone ============";

$t_anyone->get_ok($self->url_for('registration_disabled'))->status_is(200)
  ->content_like(qr/Registration is disabled/i);

subtest 'User management: public registration' => sub {
  if ($t_anyone->app->config->{registration_enabled} == 1) {

    my $token = generate_token;
    note "=== Registration anyone: using token $token";

    $t_anyone->get_ok("/register")->status_is(200)
      ->content_unlike(qr/Registration is disabled/i)
      ->text_is(label => "Login", "Admin is trying to register a user");

    $t_anyone->post_ok(
      '/register' => form => {
        login     => $token,
        name      => 'Henry',
        email     => 'h@example.com',
        password1 => 'asdf',
        password2 => 'qwerty'
      }
    )->status_isnt(404)->status_isnt(500)
      ->content_like(qr/Passwords don't match!/i,
      "Trying to register with non-matching passwords");

    $t_anyone->post_ok(
      '/register' => form => {
        login     => $token,
        name      => 'Henry',
        email     => 'h@example.com',
        password1 => 'a',
        password2 => 'a'
      }
    )->status_isnt(404)->status_isnt(500)->content_like(
      qr/Password is too short, use minimum 4 symbols/i,
      "Trying to register with too short password"
    );

    $t_anyone->post_ok(
      '/register' => form => {
        login     => '',
        name      => '',
        email     => 'h@example.com',
        password1 => 'a1234',
        password2 => 'a1234'
      }
    )->status_isnt(404)->status_isnt(500)->content_like(qr/Login is missing/i,
      "Trying to register with missing login and email");

    $t_anyone->post_ok(
      '/register' => form => {
        login     => 'Henry John',
        name      => '',
        email     => '',
        password1 => 'a1234',
        password2 => 'a1234'
      }
    )->status_isnt(404)->status_isnt(500)->content_like(qr/Email is missing/i,
      "Trying to register with missing login and email");

    $t_anyone->post_ok(
      '/register' => form => {
        login     => $token,
        name      => 'Henry John',
        email     => $token . '@example.com',
        password1 => 'qwerty',
        password2 => 'qwerty'
      }
    )->status_isnt(404)->status_isnt(500)
      ->content_like(
      qr/User created successfully! You may now login using login: $token/i,
      "Trying to register with valid data");

    $t_anyone->post_ok(
      '/register' => form => {
        login     => 'pub_admin',
        name      => 'Henry John',
        email     => $token . '@example.com',
        password1 => 'qwerty',
        password2 => 'qwerty'
      }
    )->status_isnt(404)->status_isnt(500)
      ->content_like(qr/This login is already taken/i,
      "Trying to register pub_admin");
  }
  else {
    ok(1);
  }
};

ok(1);

done_testing();

