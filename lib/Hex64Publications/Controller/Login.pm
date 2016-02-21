package Hex64Publications::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';

use Hex64Publications::Controller::DB;
use Hex64Publications::Functions::LoginFunctions;

use Data::Dumper;

####################################################################################
# for _under_ -checking if user is logged in to access other pages
sub under_check_is_logged_in {
    my $self = shift;
    say "under_check_is_logged_in";

    return 1 if $self->session('user');
    $self->flash(msg => 'You need to login first');
    $self->redirect_to('youneedtologin');
    say "nope";
    return undef;
}
####################################################################################
# for _under_ -checking
sub under_check_is_manager {
    my $self = shift;
    say "under_check_is_manager";

    my $u = $self->app->db->resultset('Login')->search({ login => $self->session('user') })->first;
    return 1 if $u->is_manager();
    $self->render(text => 'Your need _manager_ rights to access this page.');
    return undef;
}
####################################################################################
# for _under_ -checking
sub under_check_is_admin {
    my $self = shift;
    say "under_check_is_admin";

    my $u = $self->app->db->resultset('Login')->search({ login => $self->session('user') })->first;
    return 1 if $u->is_admin();
    $self->render(text => 'Your need _admin_ rights to access this page.');
    return undef;
}

####################################################################################
####################################################################################
sub manage_users {
    my $self = shift;
    my $dbh = $self->app->db;

    my @user_objs = $dbh->resultset('Login')->all;

    $self->stash(user_objs => \@user_objs);
    $self->render(template => 'login/manage_users');
}
####################################################################################
sub make_user {
    my $self = shift;
    my $id = $self->param('id');
    my $dbh = $self->app->db;

    my $u = $dbh->resultset('Login')->search({ id => $id })->first;
    
    if($id > 1){
        $self->flash(msg => "User \`".$u->login."\` is now user.");
        $u->update({rank => 0});
    }
    else{
        $self->flash(msg => "User \`".$u->login."\` cannot become \`user\`.");
    }
    $self->redirect_to('manage_users');
}
####################################################################################
sub make_manager {
    my $self = shift;
    my $id = $self->param('id');
    my $dbh = $self->app->db;

    my $u = $dbh->resultset('Login')->search({ id => $id })->first;
    
    if($id > 1){
        $self->flash(msg => "User \`".$u->login."\` is now manager.");
        $u->update({rank => 1});
    }
    else{
        $self->flash(msg => "User \`".$u->login."\` cannot become \`manager\`.");
    }
    $self->redirect_to('manage_users');
}
####################################################################################
sub make_admin {
    my $self = shift;
    my $id = $self->param('id');
    my $dbh = $self->app->db;

    my $u = $dbh->resultset('Login')->search({ id => $id })->first;
    $self->flash(msg => "User \`".$u->login."\` is now admin.");
    $u->update({rank => 2});
    
    $self->redirect_to('manage_users');
}
####################################################################################
sub delete_user {
    my $self = shift;
    my $id = $self->param('id');
    my $dbh = $self->app->db;

    my $u = $dbh->resultset('Login')->search({ id => $id })->first;

    if($u->rank>1){
        $self->write_log("User \`$u->{login}\` ($u->{real_name}) cannot be deleted. Reason: the user has admin rank.");
        $self->stash(msg => "User \`$u->{login}\` ($u->{real_name}) cannot be deleted. Reason: the user has admin rank.");
    }
    else{
        $self->write_log("User \`$u->{login}\` ($u->{real_name}) has been deleted.");
        $self->stash(msg => "User \`$u->{login}\` ($u->{real_name}) has been deleted.");

        $u->delete;
    }
    
    $self->redirect_to('manage_users');
}
####################################################################################
sub foreign_profile {
    my $self = shift;
    my $id = $self->param('id');
    my $dbh = $self->app->db;

    my $u = $dbh->resultset('Login')->search({ id => $id })->first;
    $self->stash(user => $u);
    $self->render(template => 'login/profile');
}
####################################################################################
sub profile {
    my $self = shift;
    my $dbh = $self->app->db;

    my $login = $self->session('user');
    my $u = $dbh->resultset('Login')->search({ login => $login })->first;
    $self->stash(user => $u);
    $self->render(template => 'login/profile');
}
####################################################################################
sub index {
    my $self = shift;
    $self->render(template => 'login/index');
}
####################################################################################
sub youneedtologin {
    my $self = shift;

    $self->write_log("Calling a page that requires login but user is not logged in. Redirecting to login.");

    $self->flash(msg => 'You need to login first');
    $self->render(template => 'login/index');
}
####################################################################################
sub forgot {
    my $self = shift;
    $self->render(template => 'login/forgot_request');
}
####################################################################################
sub post_gen_forgot_token {
    my $self = shift;
    # this is called when a user fills the form called "Recovery of forgotten password"
    my $user = $self->param('user');
    my $email = $self->param('email');
    my $dbh = $self->app->db;

    my $do_gen = 0;
    my $final_email = "";

    my $u;
    if(defined $user){
        $u = $dbh->resultset('Login')->search({ login => $user })->first;
        $self->write_log("Forgot: requesting new password for user $user");
        $do_gen = 1;
    }
    elsif(defined $email){
        $u = $dbh->resultset('Login')->search({ email => $email })->first;
        $self->write_log("Forgot: requesting new password for email $email");
        $do_gen = 1;
    }


    if(defined $u){
        $final_email = $u->email;

        my $token = generate_token(); 
        $dbh->resultset('Token')->find_or_create({requested => undef, email => $final_email, token => $token});
        send_email($token, $u->email);

        $self->write_log("Forgot: reset token sent to $final_email");
        $self->flash(msg => 'Email with password reset instructions has been sent to \''.$u->email.'\'. Expect an email from \'Mailgun Sandbox\'.');
        $self->redirect_to('startpa');
    }
    else{
        $self->write_log("Forgot: user does not exist.");
        $self->flash(msg => 'User or email does not exists. Try again.');
        $self->render(template => 'login/forgot_request');
    }
}
####################################################################################
sub token_clicked {
    my $self = shift;
    my $token = $self->param('token');
    my $dbh = $self->app->db;

    say "call: token_clicked";

    $self->write_log("Forgot: reset token clicked ($token)");
    $self->stash(token => $token); 
    $self->render(template => 'login/set_new_password');
}

####################################################################################
sub store_password {
    my $self = shift;
    my $token = $self->param('token');
    my $pass1 = $self->param('pass1');
    my $pass2 = $self->param('pass2');
    my $dbh = $self->app->db;

    my $t = $dbh->resultset('Token')->search({token => $token})->first;

    my $email = $t->email if defined $t;

    my $final_error=1;

    if(!defined $t){

        $self->flash(msg => 'Reset password token is invalid! Abuse will be reported.');
        # $self->stash(msg => 'Reset password token is invalid! Abuse will be reported.');
        $self->write_log("Forgot: Reset password token is invalid! ($token)");
        $self->redirect_to('login_form');
        # $self->render(template => 'login/index');
        return;
    }

    if(defined $t and $pass1 eq $pass2){

        if(length($pass1)<4){
            $self->flash(msg => 'Password toos short. Try again.', token => $token);
            $self->write_log("Forgot: Chnage failed. Password toos short.");
            $self->redirect_to('token_clicked', token => $token);
            return;
        }

        if(set_new_password($email, $pass1, $dbh) == 1){

            $t->delete;
            $dbh->resultset('Token')->search({email => $email})->delete;
            
            $self->flash(msg => 'Password change successful. All your password reset tokens have been removed. You may login now.');
            $self->write_log("Forgot: Password change successful for token $token.");
            $self->redirect_to('login_form');
            return;
        }
        else{
            $t->delete;
            $self->write_log("Forgot: Chnage failed. Token deleted.");
            $self->stash(msg => 'Something went wrong. The password has not been changed. The reset token is no longer valid. You need to request a new one by clicking in \'I forgot my password\'.');
            $self->redirect_to('login_form');
        }
    }
    else{
        $self->flash(msg => 'Passwords are not same. Try again.', token => $token);
        $self->stash(msg => 'Passwords are not same. Try again.', token => $token);
        $self->write_log("Forgot: Chnage failed. Passwords are not same.");
        $final_error=0;
        $self->redirect_to('token_clicked', token => $token);
    }
}



####################################################################################
sub login {
    my $self = shift;
    my $user = $self->param('user');
    my $pass = $self->param('pass');
    my $dbh = $self->app->db;

    say "Login: trying to log in as user $user";

    if(defined $user and defined $pass){

        $self->write_log("Login: trying to log in as user $user");

        if(check($user, $pass, $dbh)){
            my $u = $dbh->resultset('Login')->search({ login => $user })->first;
            $self->session(user => $user);
            $self->session(user_name => $u->real_name);
            $dbh->resultset('Login')->search({ login => $user })->update({last_login => \"current_timestamp"});

            $self->write_log("Login success");
            $self->redirect_to('startpa');
        }
        else{
            $self->write_log("Login: Bad username or password for user $user");
            $self->flash(msg => 'Wrong username or password');
            $self->render(template => 'login/index');
        }
    }
    else{
        $self->flash(msg => 'Please login first!');
        $self->render(template => 'login/index');
    }
}
####################################################################################
sub login_form {
    my $self = shift;
    $self->render(template => 'login/index');
}
####################################################################################
sub bad_password{
    my $self = shift;

    $self->write_log("Login: Bad username or password!");
    $self->flash(msg => 'Wrong username or password');
    $self->render(template => 'login/index');
}

####################################################################################
sub logout {
    my $self = shift;
    $self->write_log("User logs out");

    $self->session(expires => 1);
    $self->redirect_to('startpa');
}

####################################################################################
sub register{
    my $self = shift;
    my $can_register = $self->app->config->{registration_enabled} || 0;

    my $is_admin = check_is_admin($self->session('user'), $self->app->db);
    
    if($can_register == 1 or (defined $is_admin and $is_admin==1)){

        $self->write_log("Login: displaying registration form.");
        $self->write_log("Login: displaying registration form for super admin!") if $is_admin==1;
        
        $self->stash(name => '', email => 'test@example.com', login => '', password1 => '', password2 => '');
        $self->render(template => 'login/register');
    }
    else{
        $self->redirect_to('/noregister');
    }
}
####################################################################################
sub register_disabled{
    my $self = shift;
    $self->write_log("Login: informing that registration is disabled.");
    $self->render(template => 'login/noregister');
}

####################################################################################
sub post_do_register{
    my $self = shift;
    my $dbh = $self->app->db;

    my $config = $self->app->config;
    my $can_register = $config->{registration_enabled} || 0;

    my $is_admin = check_is_admin($self->session('user'), $self->app->db);


    if($can_register == 0 and (!defined $is_admin or $is_admin == 0)){
        $self->redirect_to('/noregister');
        return;
    }
    else{
        
        my $login = $self->param('login');
        my $name = $self->param('name');
        my $email = $self->param('email');
        my $password1 = $self->param('password1');
        my $password2 = $self->param('password2');

        my $s = "Login: received registration data from login: $login, email: $email.";
        say "call: post_do_register: $s";
        say "call: post_do_register: $s"." password1 $password1 password2 $password2";

        $self->write_log($s);


        if(defined $login and length($login)>0 and defined $email and length($email)>0 and defined $password1 and defined $password2){

            if(length($password1) == length($password2) and  $password2 eq $password1){

                if(length($password1) >= 4){

                    my $u = $dbh->resultset('Login')->search({ login => $login })->first;

                    if(!defined $u){
                        add_new_user($login, $email, $name, $password1, 0, $dbh);

                        $self->flash(msg => "User created successfully! You may now login using login: $login.");
                        $self->write_log("Login: registration successful for login: $login.");
                        $self->redirect_to('startpa');
                    }
                    else{
                        $self->flash(msg => "This login is already taken", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
                        $self->write_log("Login: registration unsuccessful for login: $login. Login taken.");
                        $self->redirect_to('register');
                    }
                }
                else{
                    $self->flash(msg => "Password is too short, use minimum 4 symbols", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
                    $self->write_log("Login: registration unsuccessful for login: $login. Password too short.");
                    $self->redirect_to('register');
                }
            }
            else{
                $self->flash(msg => "Passwords don't match!", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
                $self->write_log("Login: registration unsuccessful for login: $login. Passwords don't match");
                $self->redirect_to('register');
            }
        }
        else{
            $self->flash(msg => "Some input is missing!", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
            $self->write_log("Login: registration unsuccessful for login: $login. Input missing.");
            $self->redirect_to('register', msg => "Some input is missing!", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
        }

    }
}


####################################################################################################

1;
