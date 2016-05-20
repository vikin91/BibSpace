package Hex64Publications::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Hex64Publications::Controller::DB;
use Hex64Publications::Functions::UserObj;

use Data::Dumper;

####################################################################################
# for _under_ -checking if user is logged in to access other pages
sub check_is_logged_in {
    my $self = shift;
    return 1 if $self->app->is_demo;

    return 1 if $self->session('user');
    $self->redirect_to('badpassword');
    return undef;
}
####################################################################################
# for _under_ -checking
sub under_check_is_manager {
    my $self = shift;
    my $dbh = $self->app->db;
    return 1 if $self->check_is_manager();
    $self->render(text => 'Your need _manager_ rights to access this page.');
    return undef;
}

sub check_is_manager {
    my $self = shift;
    return 1 if $self->app->is_demo;
    my $dbh = $self->app->db;
    my $rank = $self->users->get_rank($self->session('user'), $dbh);
    return 1 if $rank > 0;
    return 0;

}
####################################################################################
# for _under_ -checking
sub under_check_is_admin {
    my $self = shift;
    my $dbh = $self->app->db;
    return 1 if $self->check_is_admin();

    $self->render(text => 'Your need _admin_ rights to access this page.');
    return 0;
}

sub check_is_admin {
    my $self = shift;
    my $dbh = $self->app->db;
    return 1 if $self->app->is_demo;

    my $rank = $self->users->get_rank($self->session('user'), $dbh);
    return 1 if $rank > 1;
    return 0;
}

####################################################################################
####################################################################################
####################################################################################
sub manage_users {
    my $self = shift;
    my $dbh = $self->app->db;

    my @user_objs = Hex64Publications::Functions::UserObj->getAll($dbh);

    $self->stash(user_objs => \@user_objs);
    $self->render(template => 'login/manage_users');
}
####################################################################################
sub make_user {
    my $self = shift;
    my $profile_id = $self->param('id');
    my $dbh = $self->app->db;

    my $usr_obj = Hex64Publications::Functions::UserObj->new({id => $profile_id});
    $usr_obj->initFromDB($dbh);
    if($usr_obj->make_user($dbh)==0){
        $self->write_log("Setting user \`$usr_obj->{login}\` to rank user.");
    }
    else{
        $self->flash(msg => "User \`$usr_obj->{login}\` cannot become \`user\`.");
    }
    $self->redirect_to('manage_users');
}
####################################################################################
sub make_manager {
    my $self = shift;
    my $profile_id = $self->param('id');
    my $dbh = $self->app->db;

    my $usr_obj = Hex64Publications::Functions::UserObj->new({id => $profile_id});
    $usr_obj->initFromDB($dbh);
    if($usr_obj->make_manager($dbh)==0){
        $self->write_log("Setting user \`$usr_obj->{login}\` to rank manager.");
    }
    else{
        $self->flash(msg => "User \`$usr_obj->{login}\` cannot become \`manager\`.");
    }
    $self->redirect_to('manage_users');
}
####################################################################################
sub make_admin {
    my $self = shift;
    my $profile_id = $self->param('id');
    my $dbh = $self->app->db;

    my $usr_obj = Hex64Publications::Functions::UserObj->new({id => $profile_id});
    $usr_obj->initFromDB($dbh);
    if( $usr_obj->make_admin($dbh)==0 ){
        $self->write_log("Setting user \`$usr_obj->{login}\` to rank admin.");
    }
    else{
        $self->flash(msg => "User \`$usr_obj->{login}\` cannot become \`admin\`.");
    }
    $self->redirect_to('manage_users');
}
####################################################################################
sub delete_user {
    my $self = shift;
    my $profile_id = $self->param('id');
    my $dbh = $self->app->db;

    my $usr_obj = Hex64Publications::Functions::UserObj->new({id => $profile_id});
    $usr_obj->initFromDB($dbh);

    if($self->users->login_exists($usr_obj->{login}, $dbh) and $usr_obj->is_admin()){
        $self->write_log("User \`$usr_obj->{login}\` ($usr_obj->{real_name}) cannot be deleted. Reason: the user has admin rank.");
        $self->stash(msg => "User \`$usr_obj->{login}\` ($usr_obj->{real_name}) cannot be deleted. Reason: the user has admin rank.");
    }
    else{
        $self->write_log("User \`$usr_obj->{login}\` ($usr_obj->{real_name}) has been deleted.");
        $self->stash(msg => "User \`$usr_obj->{login}\` ($usr_obj->{real_name}) has been deleted.");
        $self->users->do_delete_user($profile_id, $dbh);    
    }
    
    # $self->redirect_to('manage_users');

    my @user_objs = Hex64Publications::Functions::UserObj->getAll($dbh);

    $self->stash(user_objs => \@user_objs);
    $self->render(template => 'login/manage_users');
}
####################################################################################
sub foreign_profile {
    my $self = shift;
    my $profile_id = $self->param('id');
    my $dbh = $self->app->db;

    my $login = $self->users->get_login_for_id($profile_id, $dbh);

    my $reg_time = $self->users->get_registration_time($login, $dbh);
    my $last_login_time = $self->users->get_last_login($login, $dbh);

    my $rank = $self->users->get_rank($login, $dbh);
    my $email = $self->users->get_email($login, $dbh);

    $self->stash(user => $self->users, reg_time => $reg_time, last_login_time => $last_login_time, rank => $rank, email => $email, login => $login);
    $self->render(template => 'login/foreign_profile');
}
####################################################################################
sub profile {
    my $self = shift;
    my $dbh = $self->app->db;

    my $login = $self->session('user');
    my $reg_time = $self->users->get_registration_time($login, $dbh);
    my $last_login_time = $self->users->get_last_login($login, $dbh);

    my $rank = $self->users->get_rank($login, $dbh);
    my $email = $self->users->get_email($login, $dbh);

    $self->stash(user => $self->users, reg_time => $reg_time, last_login_time => $last_login_time, rank => $rank, email => $email, login => $login);
    $self->render(template => 'login/profile');
}
####################################################################################
sub index {
    my $self = shift;
    $self->render(template => 'login/index');
}
####################################################################################
sub forgot {
    my $self = shift;
    $self->write_log("Login: fogot password form opened");
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

    # say "call: post_gen_forgot_token user $user, email $email";


    if($self->users->login_exists($user, $dbh)==1){
        $do_gen = 1;
        # get email of this user
        $final_email = $self->users->get_email_for_uname($user, $dbh);
        $self->write_log("Forgot: requesting new password for user $user");
    }
    elsif($self->users->email_exists($email, $dbh)==1){
        $do_gen = 1;
        $final_email = $email;
    }

    $self->write_log("Forgot: requesting new password for email $email");

    if($do_gen == 1 and $final_email ne ""){

        my $token = $self->users->generate_token(); 
        $self->users->save_token_email($token, $final_email, $dbh);
        $self->users->send_email($token, $final_email);

        $self->write_log("Forgot: reset token sent to $final_email");
        $self->flash(msg => 'Email with password reset instructions has been sent. Expect an email from \'Mailgun Sandbox\'.');
        $self->redirect_to('startpa');

    }
    else{

        $self->write_log("Forgot: user does not exist.");
        $self->stash(msg => 'User or email does not exists. Try again.');
        $self->render(template => 'login/forgot_request');
    }
}
####################################################################################
sub token_clicked {
    my $self = shift;
    my $token = $self->param('token');
    my $dbh = $self->app->db;

    say "call: token_clicked";

    # verify if token exists
    # display form for setting new password. 

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

    my $email = $self->users->get_email_for_token($token, $dbh); #get it out of the DB for the token

    my $final_error=1;

    if($self->users->email_exists($email, $dbh) == 0){

        $self->flash(msg => 'Reset password token is invalid! Abuse will be reported.');
        # $self->stash(msg => 'Reset password token is invalid! Abuse will be reported.');
        $self->write_log("Forgot: Reset password token is invalid! ($token)");
        $self->redirect_to('login_form');
        # $self->render(template => 'login/index');
        return;
    }

    if($pass1 eq $pass2){

        if($self->users->set_new_password($email, $pass1, $dbh) == 1){

            $self->users->remove_token($token, $dbh);
            $self->users->remove_all_tokens_for_email($email, $dbh);
            $self->flash(msg => 'Password change successful. All your password reset tokens have been removed. You may login now.');
            $self->write_log("Forgot: Password change successful for token $token.");
            $self->redirect_to('login_form');
            # $self->render(template => 'login/index');
            return;
        }
    }
    else{
        $self->flash(msg => 'Passwords are not same. Try again.', token => $token);
        $self->stash(msg => 'Passwords are not same. Try again.', token => $token);
        $self->write_log("Forgot: Chnage failed. Passwords are not same.");
        $final_error=0;
        $self->redirect_to('token_clicked', token => $token);
        # $self->render(template => 'login/set_new_password');    
        # return;
    }

    
    if($final_error==1){
        $self->users->remove_token($token, $dbh);
        $self->write_log("Forgot: Chnage failed. Token deleted.");
        $self->stash(msg => 'Something went wrong. The password has not been changed. The reset token is no longer valid. You need to request a new one by clicking in \'I forgot my password\'.');
        $self->redirect_to('login_form');
    }
    # $self->render(template => 'login/index');
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

        if($self->users->check($user, $pass, $dbh)){
            $self->session(user => $user);
            $self->session(user_name => $self->users->get_user_real_name($user, $dbh));
            $self->users->record_logging_in($user, $dbh);

            $self->write_log("Login success");
            $self->redirect_to('startpa');
            return;
        }
        else{
            $self->write_log("Login: Bad username or password for user $user");
            $self->flash(msg => 'Wrong username or password');
            $self->stash(msg => 'Wrong username or password');
            $self->render(template => 'login/index');
            return;
        }
    }
    else{
        $self->flash(msg => 'Please login first!');
        $self->stash(msg => 'Please login first!');
        $self->render(template => 'login/index');
        return;
    }
}
####################################################################################
sub login_form {
    my $self = shift;
    $self->write_log("Login: displaying login form.");
    $self->render(template => 'login/index');
}
####################################################################################
sub bad_password{
    my $self = shift;

    $self->write_log("Login: Bad username or password! (/badpassword)");

    $self->flash(msg => 'Wrong username or password');
    $self->stash(msg => 'Wrong username or password');
    $self->render(template => 'login/index');
}
####################################################################################
sub not_logged_in{
    my $self = shift;
    $self->write_log("Calling a page that requires login but user is not logged in. Redirecting to login.");

    $self->flash(msg => 'Wrong username or password');
    $self->stash(msg => 'Wrong username or password');
    $self->render(template => 'login/index');
}

####################################################################################
sub logout {
    my $self = shift;
    $self->write_log("User logs out");

    $self->session(expires => 1);
    $self->redirect_to($self->url_for('start'));
}

####################################################################################
sub register{
    my $self = shift;
    my $can_register = $self->app->config->{registration_enabled};

    # my $dbh = $self->app->db;

    # say "call: register check_is_admin: ".$self->check_is_admin();
    # say "call: register can_register : ".$can_register;

    
    if( (defined $self->check_is_admin() and $self->check_is_admin() == 1) or (defined $can_register and $can_register == 1) ){

        $self->write_log("Login: displaying registration form.");
        $self->write_log("Login: displaying registration form for super admin!") if $self->check_is_admin() == 1;
        
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
    my $can_register = $config->{registration_enabled};


    if( (!defined $self->check_is_admin() or $self->check_is_admin() == 0) and (!defined $can_register or $can_register == 0) ){
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
                    if($self->users->login_exists($login, $dbh) == 0){
                        $self->users->add_new_user($login,$email,$name,$password1,0,$dbh);

                        # $self->stash(msg => "User created successfully! You may now login using login: $login.");

                        $self->flash(msg => "User created successfully! You may now login using login: $login.");
                        $self->stash(msg => "User created successfully! You may now login using login: $login.");
                        $self->write_log("Login: registration successful for login: $login.");
                        $self->redirect_to('startpa');
                        # return;
                    }
                    else{
                        # $self->stash(msg => "This login is already taken");

                        $self->flash(msg => "This login is already taken", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
                        $self->stash(msg => "This login is already taken", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
                        $self->write_log("Login: registration unsuccessful for login: $login. Login taken.");
                        $self->redirect_to('register');
                        # $self->render(template => 'login/register');
                        # return;
                    }
                }
                else{
                    # $self->stash(msg => "Password is too short");

                    
                    $self->flash(msg => "Password is too short, use minimum 4 symbols", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
                    $self->stash(msg => "Password is too short, use minimum 4 symbols", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
                    $self->write_log("Login: registration unsuccessful for login: $login. Password too short.");
                    $self->redirect_to('register');
                    # $self->render(template => 'login/register');
                    # return;
                }
            }
            else{
                # $self->stash(msg => "Passwords don't match!");
                $self->flash(msg => "Passwords don't match!", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
                $self->stash(msg => "Passwords don't match!", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
                $self->write_log("Login: registration unsuccessful for login: $login. Passwords don't match");
                $self->redirect_to('register');
                # $self->render(template => 'login/register');
                # return;
            }
        }
        else{
            # $self->stash(msg => "Some input is missing!");
            $self->flash(msg => "Some input is missing!", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
            $self->stash(msg => "Some input is missing!", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
            $self->write_log("Login: registration unsuccessful for login: $login. Input missing.");
            $self->redirect_to('register', msg => "Some input is missing!", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
            # $self->render(template => 'login/register');
            # return;
        }

    }
}

1;