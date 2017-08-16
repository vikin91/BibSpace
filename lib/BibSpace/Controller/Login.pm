package BibSpace::Controller::Login;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';

use BibSpace::Model::User;

use BibSpace::Functions::Core
  qw(send_email generate_token salt encrypt_password check_password_policy validate_registration_data);

use Data::Dumper;
use Try::Tiny;

# for _under_ -checking if user is logged in to access other pages
sub check_is_logged_in {
  my $self = shift;
  return 1 if $self->app->is_demo;

  # no session
  if (!defined $self->session('user')) {
    $self->redirect_to('youneedtologin');
    return;
  }

  # session exists, but user unknown
  my $me
    = $self->app->repo->users_find(sub { $_->login eq $self->session('user') });
  if (!defined $me) {
    $self->session(expires => 1);
    $self->redirect_to('youneedtologin');
    return;
  }

  return 1;
}

# for _under_ -checking
sub under_check_is_manager {
  my $self = shift;
  return 1 if $self->app->is_demo;
  return $self->under_check_has_rank(User->manager_rank);
}

# for _under_ -checking
sub under_check_is_admin {
  my $self = shift;
  return 1 if $self->app->is_demo;
  return $self->under_check_has_rank(User->admin_rank);
}

# for _under_ -checking
sub under_check_has_rank {
  my $self          = shift;
  my $required_rank = shift;

  return 1 if $self->app->is_demo;

  my $me
    = $self->app->repo->users_find(sub { $_->login eq $self->session('user') });

  if ($me and $me->rank >= $required_rank) {
    return 1;
  }

  my $your_rank = 'undefined';
  $your_rank = $me->rank if $me;

  $self->flash(
    msg_type => 'danger',
    msg      => "You need to have rank '"
      . $required_rank
      . "' to access this page! "
      . "Your rank is: '"
      . $your_rank . "'"
      . " <br/> You have tried to access: "
      . $self->url_for('current')->to_abs
  );

  my $redirect_to = $self->get_referrer;

  if ($self->get_referrer eq $self->url_for('current')->to_abs) {
    $redirect_to = $self->url_for('/');
  }
  $self->redirect_to($redirect_to);
  return;

}

sub manage_users {
  my $self = shift;
  my $dbh  = $self->app->db;

  my @user_objs = $self->app->repo->users_all;
  $self->stash(user_objs => \@user_objs);
  $self->render(template => 'login/manage_users');
}

sub promote_to_rank {
  my $self = shift;
  my $rank = shift;

  my $profile_id = $self->param('id');
  my $user_obj = $self->app->repo->users_find(sub { $_->id == $profile_id });

  my $me
    = $self->app->repo->users_find(sub { $_->login eq $self->session('user') });

  if ($me->is_admin) {
    if ($me->equals($user_obj)) {
      $self->flash(msg_type => 'danger', msg => "You cannot degrade yourself!");
    }
    else {
      $user_obj->rank($rank);
      $self->app->repo->users_update($user_obj);

      my $msg = "User '" . $user_obj->login . "'' has now rank '$rank'.";
      $self->app->logger->info($msg);
      $self->flash(msg_type => 'success', msg => $msg);
    }
  }
  else {
    $self->flash(
      msg_type => 'danger',
      msg      => "Only admins can promote/degrade users!"
    );
  }
  $self->redirect_to('manage_users');
}

sub make_user {
  my $self = shift;
  return $self->promote_to_rank(User->user_rank);
}

sub make_manager {
  my $self = shift;
  return $self->promote_to_rank(User->manager_rank);
}

sub make_admin {
  my $self = shift;
  return $self->promote_to_rank(User->admin_rank);
}

sub delete_user {
  my $self       = shift;
  my $profile_id = $self->param('id');

  my $user_obj = $self->app->repo->users_find(sub { $_->id == $profile_id });
  my $me
    = $self->app->repo->users_find(sub { $_->login eq $self->session('user') });

  if ($me and (!$me->is_admin)) {
    $self->flash(msg_type => 'danger', msg => 'You are not admin!');
    $self->redirect_to('manage_users');
    return;
  }
  if ($user_obj and $user_obj->is_admin) {
    $self->flash(msg_type => 'danger', msg => 'You cannot delete admin user!');
    $self->redirect_to('manage_users');
    return;
  }
  if ($user_obj and $user_obj->equals($me)) {
    $self->flash(msg_type => 'danger', msg => 'You cannot delete yourself!');
    $self->redirect_to('manage_users');
    return;
  }
  if ($user_obj) {
    $self->app->repo->users_delete($user_obj);
    my $msg
      = "User '$user_obj->{login}' real name: '$user_obj->{real_name}' has been deleted.";
    $self->app->logger->info($msg);
    $self->flash(msg_type => 'success', msg => $msg);
  }
  else {
    my $msg
      = "Cannot delete user. Reason: cannot find user with ID '$profile_id'.";
    $self->app->logger->info($msg);
    $self->flash(msg_type => 'danger', msg => $msg);
  }

  $self->redirect_to('manage_users');
}

sub foreign_profile {
  my $self       = shift;
  my $profile_id = $self->param('id');
  my $user_obj   = $self->app->repo->users_find(sub { $_->id == $profile_id });

  $self->stash(usrobj => $user_obj);
  $self->render(template => 'login/profile');
}

sub profile {
  my $self = shift;
  my $me
    = $self->app->repo->users_find(sub { $_->login eq $self->session('user') });

  $self->stash(usrobj => $me);
  $self->render(template => 'login/profile');
}

sub index {
  my $self = shift;
  $self->render(template => 'login/index');
}

sub forgot {
  my $self = shift;
  $self->app->logger->info("Forgot password form opened");
  $self->render(template => 'login/forgot_request');
}

sub post_gen_forgot_token {
  my $self = shift;

# this is called when a user fills the form called "Recovery of forgotten password"
  my $login = $self->param('user');
  my $email = $self->param('email');

  my $user;
  if ($login) {
    $self->app->logger->info(
      "Request to generate forgot-password-token for login '$login'.");
    $user = $self->app->repo->users_find(sub { $_->login eq $login });
  }
  if ($email) {
    $self->app->logger->info(
      "Request to generate forgot-password-token for email '$email'.");
    $user = $self->app->repo->users_find(sub { $_->email eq $email });
  }

  if (!$user) {
    $self->app->logger->warn(
      "Cannot find user '$login' nor email '$email' to generate forgot-password-token."
    );
    $self->flash(
      msg_type => 'warning',
      msg      => "User '$login' or email '$email' does not exist. Try again."
    );
    $self->redirect_to('forgot');
    return;
  }
  else {
    # store token in the user object
    $user->forgot_token(generate_token);

    my $email_content = $self->render_to_string('email_forgot_password',
      token => $user->forgot_token);
    try {
      my %email_config = (
        mailgun_domain => $self->app->config->{mailgun_domain},
        mailgun_key    => $self->app->config->{mailgun_key},
        from           => $self->app->config->{mailgun_from},
        to             => $user->email,
        content        => $email_content,
        subject        => 'BibSpace password reset request'
      );
      send_email(\%email_config);
    }
    catch {
      $self->app->logger->warn(
        "Could not sent Email with Mailgun. This is okay for test, but not for production. Error: $_ ."
      );
    };

    $self->app->logger->info("Forgot-password-token '"
        . $user->forgot_token
        . "' sent to '"
        . $user->email
        . "'.");

    $self->flash(
      msg_type => 'info',
      msg =>
        "Email with password reset instructions has been sent. Expect an email from "
        . $self->app->config->{mailgun_from}
    );
    $self->redirect_to('/');

  }

  $self->redirect_to('forgot');
}

sub token_clicked {
  my $self  = shift;
  my $token = $self->param('token');

  $self->app->logger->info("Reset token clicked '$token'");
  $self->stash(token => $token);
  $self->render(template => 'login/set_new_password');
}

sub store_password {
  my $self  = shift;
  my $token = $self->param('token');
  my $pass1 = $self->param('pass1');
  my $pass2 = $self->param('pass2');

  # search for user that has this token
  my $user;
  if ($token) {
    $user = $self->app->repo->users_find(
      sub { defined $_->forgot_token and $_->forgot_token eq $token });
  }

  if (!$user) {
    $self->app->logger->warn(
      "Forgot: Reset password token is invalid! Token: '$token'");
    $self->flash(
      msg_type => 'danger',
      msg =>
        'Reset password token is invalid! Make sure you click the newest token that you requested.'
    );
    $self->redirect_to('login_form');
    return;
  }

  if ($pass1 eq $pass2 and check_password_policy($pass1)) {

    my $salt = salt();
    my $hash = encrypt_password($pass1, $salt);
    $user->pass($pass1);
    $user->pass2($salt);
    $user->forgot_token("");
    $self->flash(
      msg_type => 'success',
      msg =>
        'Password change successful. All your password reset tokens have been removed. You may login now.'
    );
    $self->app->logger->info(
      "Forgot: Password change successful for token $token.");
    $self->redirect_to('login_form');
    return;
  }

  my $msg
    = 'Passwords are not same or do not obey the password policy. Please try again.';
  $self->flash(msg => $msg, msg_type => 'warning');
  $self->app->logger->info($msg);
  $self->stash(token => $token);
  $self->redirect_to('token_clicked', token => $token);

}

sub login {
  my $self        = shift;
  my $input_login = $self->param('user');
  my $input_pass  = $self->param('pass');

  if ((!$input_login) or (!$input_pass)) {
    $self->flash(
      msg_type => 'warning',
      msg      => 'Please provide user-name and password.'
    );
    $self->redirect_to($self->url_for('login_form'));
    return;
  }

  $self->app->logger->info("Trying to login as user '$input_login'");

  # get the user with login
  my $user = $self->app->repo->users_find(sub { $_->login eq $input_login });

  my $auth_result;
  if (defined $user) {
    $self->app->logger->info("User '$input_login' exists.");
    $auth_result = $user->authenticate($input_pass);
  }

  if (defined $user and $auth_result and $auth_result == 1) {
    $self->session(user        => $user->login);
    $self->session(user_name   => $user->real_name);
    $self->session(url_history => []);

    $user->record_logging_in;

    $self->app->logger->info("Login as '$input_login' success.");
    $self->redirect_to('/');
    return;
  }
  else {
    $self->app->logger->info("User '$input_login' does not exist.");
    $self->app->logger->info("Wrong user name or password for '$input_login'.");
    $self->flash(msg_type => 'danger', msg => 'Wrong user name or password');
    $self->redirect_to($self->url_for('login_form'));
    return;
  }

}

sub login_form {
  my $self = shift;
  $self->app->logger->info("Displaying login form.");
  $self->render(template => 'login/index');
}

sub bad_password {
  my $self = shift;

  $self->app->logger->info("Bad user name or password! (/badpassword)");

  $self->flash(msg_type => 'danger', msg => 'Wrong user name or password');
  $self->redirect_to($self->url_for('login_form'));
}

sub not_logged_in {
  my $self = shift;

  $self->app->logger->info(
    "Called a page that requires login but user is not logged in. Redirecting to login."
  );

  $self->flash(msg_type => 'danger', msg => 'You need to login first.');
  $self->redirect_to($self->url_for('login_form'));
}

sub logout {
  my $self = shift;
  $self->app->logger->info("User logs out");

  $self->session(expires => 1);
  $self->redirect_to($self->url_for('start'));
}

sub register_disabled {
  my $self = shift;
  $self->app->logger->info("Login: informing that registration is disabled.");
  $self->render(template => 'login/noregister');
}

sub can_register {
  my $self                 = shift;
  my $registration_enabled = $self->app->config->{registration_enabled};

  return 1 if $registration_enabled == 1;
  my $me;
  if ($self->session('user')) {
    $me
      = $self->app->repo->users_find(sub { $_->login eq $self->session('user') }
      );
  }
  return 1 if $me and $me->is_admin;
  return;
}

sub register {
  my $self = shift;

  if ($self->can_register) {
    $self->stash(
      name      => 'James Bond',
      email     => 'test@example.com',
      login     => 'j.bond007',
      password1 => '',
      password2 => ''
    );
    $self->render(template => 'login/register');
    return;
  }
  else {
    $self->redirect_to('/noregister');
  }
}

sub post_do_register {
  my $self      = shift;
  my $config    = $self->app->config;
  my $login     = $self->param('login');
  my $name      = $self->param('name');
  my $email     = $self->param('email');
  my $password1 = $self->param('password1');
  my $password2 = $self->param('password2');

  if (!$self->can_register) {
    $self->redirect_to('/noregister');
    return;
  }

  $self->app->logger->info(
    "Received registration data. Login: '$login', email: '$email'.");

  try {
    # this throws on failure
    validate_registration_data($login, $email, $password1, $password2);
    my $existing_user
      = $self->app->repo->users_find(sub { $_->login eq $login });
    die "This login is already taken.\n" if $existing_user;

    my $salt     = salt();
    my $hash     = encrypt_password($password1, $salt);
    my $new_user = $self->app->entityFactory->new_User(
      login     => $login,
      email     => $email,
      real_name => $name,
      pass      => $hash,
      pass2     => $salt
    );
    $self->app->repo->users_save($new_user);

    $self->flash(
      msg_type => 'success',
      msg => "User created successfully! You may now login using login: $login."
    );
    $self->redirect_to('/');
  }
  catch {
    my $failure_reason = $_;
    $self->app->logger->warn($failure_reason);
    $self->flash(msg_type => 'danger', msg => $failure_reason);
    $self->stash(
      name      => $name,
      email     => $email,
      login     => $login,
      password1 => $password1,
      password2 => $password2
    );
    $self->redirect_to('register');
  };
}

1;
