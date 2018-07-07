use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Functions::Core;
use BibSpace::Model::User;

### Problem with this test suite is that the token for mailgun returns error because it is not correct in the default config
### We need to find a method to test this without providing the real credentials

# # ############################ PREPARATION
my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);
my $self = $t_logged_in->app;
$t_logged_in->ua->max_redirects(10);

use BibSpace::TestManager;
TestManager->apply_fixture($t_logged_in->app);

# # ############################ READY FOR TESTING

my $token = generate_token();
ok(defined $token);
is(length($token), 32);

subtest 'User management: noregister' => sub {
  $t_logged_in->get_ok("/noregister")->status_is(200)
    ->content_like(qr/Registration is disabled/i);
};

subtest 'User management: admin registration' => sub {

  my $token = generate_token;
  note "=== Registration admin: using token $token";

  $t_logged_in->get_ok("/register")->status_is(200)
    ->content_unlike(qr/Registration is disabled/i)
    ->text_is(label => "Login", "Admin is trying to register a user");

  $t_logged_in->post_ok(
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

  $t_logged_in->post_ok(
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

  $t_logged_in->post_ok(
    '/register' => form => {
      login     => '',
      name      => '',
      email     => 'h@example.com',
      password1 => 'a1234',
      password2 => 'a1234'
    }
    )->status_isnt(404)->status_isnt(500)->content_like(qr/Login is missing/i,
    "Trying to register with missing login and email");

  $t_logged_in->post_ok(
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

  $t_logged_in->post_ok(
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

};

ok(1);
done_testing();

