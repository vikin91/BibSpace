package BibSpace::Controller::Login;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';

use BibSpace::Functions::FDB;
use BibSpace::Model::MUser;

use WWW::Mechanize;
use Data::Dumper;
use Try::Tiny;

our $admin_rank   = 2;
our $manager_rank = 1;

####################################################################################
# for _under_ -checking if user is logged in to access other pages
sub check_is_logged_in {
    my $self = shift;
    return 1 if $self->app->is_demo;

    return 1 if $self->session('user');
    $self->redirect_to('badpassword');
    return 0;
}
####################################################################################
# for _under_ -checking
sub under_check_is_manager {
    my $self = shift;
    my $dbh  = $self->app->db;

    my $me = MUser->static_get_by_login($self->app->db, $self->session('user'));
    return 1 if $me->is_manager();

    my $rank = $me->{rank};

    $self->flash(
        msg_type => 'danger',
        msg =>
            "You need to have manager rights (rank $admin_rank) to access this page! "
            . "Your rank is: $rank."
            . " <br/> You have just tried to access: "
            . $self->url_for('current')->to_abs
    );
    my $redirect_to = $self->get_referrer;
    $redirect_to = $self->url_for('/')
        if $self->get_referrer eq $self->url_for('current')->to_abs
        or !defined $self->get_referrer;
    $self->redirect_to($redirect_to);
    return 0;
}
####################################################################################
# for _under_ -checking
sub under_check_is_admin {
    my $self = shift;
    my $dbh  = $self->app->db;

    my $me = MUser->static_get_by_login($self->app->db, $self->session('user'));
    return 1 if $me->is_admin();

    my $rank = $me->{rank};

    $self->flash(
        msg_type => 'danger',
        msg =>
            "You need to have admin rights (rank ".MUser->admin_rank.") to access this page! "
            . "Your rank is: $rank."
            . " <br/> You have just tried to access: "
            . $self->url_for('current')->to_abs
    );
    my $redirect_to = $self->get_referrer;
    $redirect_to = $self->url_for('/')
        if $self->get_referrer eq $self->url_for('current')->to_abs
        or !defined $self->get_referrer;
    $self->redirect_to($redirect_to);
    return 0;
}

####################################################################################
####################################################################################
####################################################################################
sub manage_users {
    my $self = shift;
    my $dbh  = $self->app->db;

    my @user_objs = MUser->static_all($dbh);
    $self->stash( user_objs => \@user_objs );
    $self->render( template => 'login/manage_users' );
}
####################################################################################
sub make_user {
    my $self       = shift;
    my $profile_id = $self->param('id');
    my $dbh        = $self->app->db;

    my $usr_obj = MUser->static_get( $dbh, $profile_id );

    if ( $usr_obj->make_user($dbh) == 1 ) {
        $self->write_log("Setting user \`$usr_obj->{login}\` to rank user.");
    }
    else {
        $self->flash(
            msg_type => 'danger',
            msg      => "User \`$usr_obj->{login}\` cannot become \`user\`."
        );
    }
    $self->redirect_to('manage_users');
}
####################################################################################################
sub can_be_manager {
    my $self = shift;
    my $user = shift;

    # pub_admin must remain admin
    return 0 if $user->{login} eq 'pub_admin';

    my $me = MUser->static_get_by_login($self->app->db, $self->session('user'));
    
    # cannot promote yourself
    # cannot degrade admin
    return 1
        if defined $user
        and $user->{login} ne $me->{login};
    return 0;
}
####################################################################################################
sub can_be_admin {
    my $self = shift;
    my $user = shift;
    return 1 if $user->{login} eq 'pub_admin';
    return $self->can_be_manager($user);
}
####################################################################################
sub make_manager {
    my $self       = shift;
    my $profile_id = $self->param('id');
    my $dbh        = $self->app->db;


    my $user    = MUser->static_get( $dbh, $profile_id );

    if ( $self->can_be_manager($user) == 1 ) {
        $user->make_manager($dbh);
        $self->write_log(
            "Setting user \`$user->{login}\` to rank manager.");
    }
    else {
        $self->flash(
            msg_type => 'danger',
            msg => "User \`$user->{login}\` cannot become \`manager\`."
        );
    }
    $self->redirect_to('manage_users');
}
####################################################################################
sub make_admin {
    my $self       = shift;
    my $profile_id = $self->param('id');
    my $dbh        = $self->app->db;

    my $user = MUser->static_get( $dbh, $profile_id );

    if ( $self->can_be_admin($user) == 1 ) {
        $user->make_admin($dbh);
        $self->write_log("Setting user \`$user->{login}\` to rank admin.");
    }
    else {
        $self->flash(
            msg_type => 'danger',
            msg      => "User \`$user->{login}\` cannot become \`admin\`."
        );
    }
    $self->redirect_to('manage_users');
}
####################################################################################
sub delete_user {
    my $self       = shift;
    my $profile_id = $self->param('id');
    my $dbh        = $self->app->db;

    my $usr_obj = MUser->static_get( $dbh, $profile_id );

    my $message      = "";
    my $message_type = "";

    if ( defined $usr_obj and $usr_obj->is_admin() == 1 )
    {
        $message
            = "User \`$usr_obj->{login}\` ($usr_obj->{real_name}) cannot be deleted. Reason: the user has admin rank.";
        $message_type = 'danger';
    }
    else {

        if ( $self->users->do_delete_user( $profile_id, $dbh ) ) {
            $message
                = "User \`$usr_obj->{login}\` ($usr_obj->{real_name}) has been deleted.";
            $message_type = 'success';
        }
        else {
            $message
                = "User \`$usr_obj->{login}\` ($usr_obj->{real_name}) could not been deleted.";
            $message_type = 'danger';
        }

    }
    $self->write_log($message);
    $self->flash( msg_type => $message_type, msg => $message );

    # $self->redirect_to('manage_users');

    my @user_objs = MUser->static_all($dbh);

    $self->stash( user_objs => \@user_objs );
    $self->redirect_to('manage_users');

    # $self->render(template => 'login/manage_users');
}
####################################################################################
sub foreign_profile {
    my $self       = shift;
    my $profile_id = $self->param('id');
    my $dbh        = $self->app->db;

    my $usrobj = MUser->static_get($dbh, $profile_id);
    $self->stash(usrobj => $usrobj);
    $self->render( template => 'login/profile' );
}
####################################################################################
sub profile {
    my $self = shift;
    my $dbh  = $self->app->db;

    my $usrobj = MUser->static_get_by_login($dbh, $self->session('user'));
    $self->stash(usrobj => $usrobj);
    $self->render( template => 'login/profile' );
}
####################################################################################
sub index {
    my $self = shift;
    $self->render( template => 'login/index' );
}
####################################################################################
sub forgot {
    my $self = shift;
    $self->write_log("Login: forgot password form opened");
    $self->render( template => 'login/forgot_request' );
}
####################################################################################
sub post_gen_forgot_token {
    my $self = shift;

# this is called when a user fills the form called "Recovery of forgotten password"
    my $login = $self->param('user');
    my $email = $self->param('email');
    my $dbh   = $self->app->db;

    my $do_gen      = 0;
    my $final_email = "";

    my $existing_user =  MUser->static_get_by_login($dbh, $login);

    if ( defined $existing_user ) {
        $do_gen = 1;

        # get email of this user
        $final_email = $existing_user->{email};
        $self->write_log("requesting new password for user $login");
    }
    elsif ( $self->users->email_exists( $email, $dbh ) == 1 ) {
        $do_gen      = 1;
        $final_email = $email;
        $self->write_log("requesting new password for email $email");
    }
    else {
        $do_gen = 0;
    }

    $self->write_log(
        "requested new password for user $login or email $email but none of them found in the database."
    );

    if ( $do_gen == 1 and $final_email ne "" ) {

        my $token = $self->users->generate_token();
        $self->users->save_token_email( $token, $final_email, $dbh );

        my $email_content = $self->render_to_string( 'email_forgot_password',
            token => $token );
        $self->send_email( $token, $final_email, $email_content );

        $self->write_log("reset token sent to $final_email");
        $self->flash(
            msg_type => 'info',
            msg =>
                "Email with password reset instructions has been sent. Expect an email from "
                . $self->app->config->{mailgun_from}
        );
        $self->redirect_to('/');

    }
    else {

        $self->write_log(
            "Cannot reset password: user $login or email $email do not exist."
        );
        $self->flash(
            msg_type => 'warning',
            msg      => 'User or email does not exists. Try again.'
        );
        $self->redirect_to('forgot');
    }
}
####################################################################################################
sub send_email {    #NON_CONTROLLER FUNCTION, but it is usable here
    my $self          = shift;
    my $token         = shift;
    my $email_address = shift;
    my $email_content = shift;

    my $subject = 'BibSpace password reset request';

    my $uri
        = "https://api.mailgun.net/v3/"
        . $self->app->config->{mailgun_domain}
        . "/messages";
    my $from = $self->app->config->{mailgun_from};
    my $to   = $email_address;

    my $mech = WWW::Mechanize->new( ssl_opts => { SSL_version => 'TLSv1' } );
    $mech->credentials( api => $self->app->config->{mailgun_key} );
    $mech->ssl_opts( verify_hostname => 0 );
    try {
        $mech->post(
            $uri,
            [   from    => $from,
                to      => $to,
                subject => $subject,
                html    => $email_content
            ]
        );
    }
    catch {
        warn
            "Could not sent Email with Mailgun. This is okay for test, but not for production. Error: $_ .";
    };

    # say "Mailgun response: ".$mech->response->as_string;
}
####################################################################################
sub token_clicked {
    my $self  = shift;
    my $token = $self->param('token');
    my $dbh   = $self->app->db;


    # verify if token exists
    # display form for setting new password.

    $self->write_log("Forgot: reset token clicked ($token)");
    $self->stash( token => $token );
    $self->render( template => 'login/set_new_password' );
}

####################################################################################
sub store_password {
    my $self  = shift;
    my $token = $self->param('token');
    my $pass1 = $self->param('pass1');
    my $pass2 = $self->param('pass2');
    my $dbh   = $self->app->db;

    my $email = $self->users->get_email_for_token( $token, $dbh )
        ;    #get it out of the DB for the token

    my $final_error = 1;

    if ( $self->users->email_exists( $email, $dbh ) == 0 ) {

        $self->flash(
            msg_type => 'danger',
            msg =>
                'Reset password token is invalid! Make sure you click the newest token that you requested.'
        );

# $self->stash(msg => 'Reset password token is invalid! Abuse will be reported.');
        $self->write_log("Forgot: Reset password token is invalid! ($token)");
        $self->redirect_to('login_form');

        # $self->render(template => 'login/index');
        return;
    }

    if ( $pass1 eq $pass2 ) {

        if ( $self->users->set_new_password( $email, $pass1, $dbh ) == 1 ) {

            $self->users->remove_token( $token, $dbh );
            $self->users->remove_all_tokens_for_email( $email, $dbh );
            $self->flash(
                msg_type => 'success',
                msg =>
                    'Password change successful. All your password reset tokens have been removed. You may login now.'
            );
            $self->write_log(
                "Forgot: Password change successful for token $token.");
            $self->redirect_to('login_form');

            # $self->render(template => 'login/index');
            return;
        }
    }
    else {
        $self->flash(
            msg      => 'Passwords are not same. Try again.',
            msg_type => 'danger'
        );
        $self->stash( token => $token );
        $self->write_log("Forgot: Change failed. Passwords are not same.");
        $final_error = 0;
        $self->redirect_to( 'token_clicked', token => $token );

        # $self->render(template => 'login/set_new_password');
        # return;
    }

    if ( $final_error == 1 ) {
        $self->users->remove_token( $token, $dbh );
        $self->write_log("Forgot: Change failed. Token deleted.");
        $self->flash(
            msg_type => 'danger',
            msg =>
                'Something went wrong. The password has not been changed. The reset token is no longer valid. You need to request a new one by clicking in \'I forgot my password\'.'
        );
        $self->redirect_to('login_form');
    }

    # $self->render(template => 'login/index');
}

####################################################################################
sub login {
    my $self = shift;
    my $user = $self->param('user');
    my $pass = $self->param('pass');
    my $dbh  = $self->app->db;

    if ( defined $user and defined $pass ) {

        $self->write_log("Login: trying to log in as user $user");

        if ( $self->users->check( $user, $pass, $dbh ) ) {
            $self->session( user => $user );
            $self->session(
                user_name => $self->users->get_user_real_name( $user, $dbh )
            );
            $self->users->record_logging_in( $user, $dbh );

            $self->write_log("Login success");
            $self->redirect_to('/');
            return;
        }
        else {
            $self->write_log(
                "Login: Bad user name or password for user $user");
            $self->flash(
                msg_type => 'danger',
                msg      => 'Wrong user name or password'
            );
            $self->redirect_to( $self->url_for('login_form') );
            return;
        }
    }
    else {
        $self->flash( msg_type => 'info', msg => 'Please login first!' );
        $self->redirect_to( $self->url_for('login_form') );
        return;
    }
}
####################################################################################
sub login_form {
    my $self = shift;
    $self->write_log("Login: displaying login form.");
    $self->render( template => 'login/index' );
}
####################################################################################
sub bad_password {
    my $self = shift;

    $self->write_log("Login: Bad user name or password! (/badpassword)");

    $self->flash(
        msg_type => 'danger',
        msg      => 'Wrong user name or password'
    );
    $self->redirect_to( $self->url_for('login_form') );
}
####################################################################################
sub not_logged_in {
    my $self = shift;
    $self->write_log(
        "Calling a page that requires login but user is not logged in. Redirecting to login."
    );

    $self->flash( msg_type => 'danger', msg => 'Wrong username or password' );
    $self->redirect_to( $self->url_for('login_form') );
}

####################################################################################
sub logout {
    my $self = shift;
    $self->write_log("User logs out");

    $self->session( expires => 1 );
    $self->redirect_to( $self->url_for('start') );
}

####################################################################################
sub register {
    my $self                 = shift;
    my $registration_enabled = $self->app->config->{registration_enabled};

    my $me = MUser->static_get_by_login($self->app->db, $self->session('user'));
    

    if ( defined $me and $me->is_admin() == 1 ) {
        $self->stash(
            name      => 'Jonh New',
            email     => 'test@example.com',
            login     => 'new_user_000',
            password1 => 'password1',
            password2 => 'password1'
        );
        $self->render( template => 'login/register' );
        return 0;
    }
    elsif ( defined $registration_enabled and $registration_enabled == 1 ) {
        $self->stash(
            name      => 'James Bond',
            email     => 'test@example.com',
            login     => 'james',
            password1 => '',
            password2 => ''
        );
        $self->render( template => 'login/register' );
        return 0;
    }
    else {
        $self->redirect_to('/noregister');
    }
}
####################################################################################
sub register_disabled {
    my $self = shift;
    $self->write_log("Login: informing that registration is disabled.");
    $self->render( template => 'login/noregister' );
}

####################################################################################
sub post_do_register {
    my $self = shift;
    my $dbh  = $self->app->db;

    my $config               = $self->app->config;
    my $registration_enabled = $config->{registration_enabled};
    my $me = MUser->static_get_by_login($self->app->db, $self->session('user'));

    if ( defined $me 
        and $me->is_admin() == 1
        and ( !defined $registration_enabled or $registration_enabled == 0 ) )
    {
        $self->redirect_to('/noregister');
        return;
    }
    else {

        my $login     = $self->param('login');
        my $name      = $self->param('name');
        my $email     = $self->param('email');
        my $password1 = $self->param('password1');
        my $password2 = $self->param('password2');

        my $s
            = "Login: received registration data from login: $login, email: $email.";

        $self->write_log($s);

        if (    defined $login
            and length($login) > 0
            and defined $email
            and length($email) > 0
            and defined $password1
            and defined $password2 )
        {

            if ( length($password1) == length($password2)
                and $password2 eq $password1 )
            {

                if ( length($password1) >= 4 ) {
                    my $existing_user =  MUser->static_get_by_login($dbh, $login);
                    if ( !defined $existing_user ) {
                        $self->users->add_new_user( $login, $email, $name,
                            $password1, 0, $dbh );

                        $self->flash(
                            msg_type => 'success',
                            msg =>
                                "User created successfully! You may now login using login: $login."
                        );
                        $self->write_log(
                            "Login: registration successful for login: $login."
                        );
                        $self->redirect_to('/');
                    }
                    else {
                        # $self->stash(msg => "This login is already taken");

                        $self->flash(
                            msg_type => 'danger',
                            msg      => "This login is already taken"
                        );
                        $self->stash(
                            name      => $name,
                            email     => $email,
                            login     => $login,
                            password1 => $password1,
                            password2 => $password2
                        );
                        $self->write_log(
                            "Login: registration unsuccessful for login: $login. Login taken."
                        );
                        $self->redirect_to('register');
                    }
                }
                else {
                    # $self->stash(msg => "Password is too short");

                    $self->flash(
                        msg_type => 'danger',
                        msg => "Password is too short, use minimum 4 symbols"
                    );
                    $self->stash(
                        name      => $name,
                        email     => $email,
                        login     => $login,
                        password1 => $password1,
                        password2 => $password2
                    );
                    $self->write_log(
                        "Login: registration unsuccessful for login: $login. Password too short."
                    );
                    $self->redirect_to('register');
                }
            }
            else {
                # $self->stash(msg => "Passwords don't match!");
                $self->flash(
                    msg_type  => 'danger',
                    msg       => "Passwords don't match!",
                    name      => $name,
                    email     => $email,
                    login     => $login,
                    password1 => $password1,
                    password2 => $password2
                );
                $self->write_log(
                    "Login: registration unsuccessful for login: $login. Passwords don't match"
                );
                $self->redirect_to('register');
            }
        }
        else {
            # $self->stash(msg => "Some input is missing!");
            $self->flash(
                msg_type  => 'danger',
                msg       => "Some input is missing!",
                name      => $name,
                email     => $email,
                login     => $login,
                password1 => $password1,
                password2 => $password2
            );
            $self->stash(
                name      => $name,
                email     => $email,
                login     => $login,
                password1 => $password1,
                password2 => $password2
            );
            $self->write_log(
                "Login: registration unsuccessful for login: $login. Input missing."
            );
            $self->redirect_to(
                'register',
                msg_type  => 'danger',
                msg       => "Some input is missing!",
                name      => $name,
                email     => $email,
                login     => $login,
                password1 => $password1,
                password2 => $password2
            );
        }

    }
}

1;
