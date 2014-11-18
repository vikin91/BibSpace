package AdminApi::Login;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';



####################################################################################
# for _under_ -checking if user is logged in to access other pages
sub check_is_logged_in {
    my $self = shift;
    return 1 if $self->session('user');
    $self->redirect_to('badpassword');
    return undef;
}
####################################################################################
# for _under_ -checking
sub check_is_manager {
    my $self = shift;
    my $rank = $self->users->get_rank($self->session('user'));
    return 1 if $rank > 0;


    $self->render(text => 'Your need _manager_ rights to access this page.');
    return undef;
}
####################################################################################
# for _under_ -checking
sub check_is_admin {
    my $self = shift;

    my $rank = $self->users->get_rank($self->session('user'));
    return 1 if $rank > 1;

    $self->render(text => 'Your need _admin_ rights to access this page.');
    return undef;
}

####################################################################################
####################################################################################
####################################################################################
sub profile {
    my $self = shift;

    $self->stash(user => $self->users);
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

    my $do_gen = 0;
    my $final_email = "";

    if($self->users->login_exists($user)==1){
        $do_gen = 1;
        # get email of this user
        $final_email = $self->users->get_email_for_uname($user);
    }
    if($self->users->email_exists($email)==1){
        $do_gen = 1;
        $final_email = $email;
    }

    $self->write_log("Forgot: requesting new password for user $user or email $email");

    if($do_gen == 1 and $final_email ne ""){


        my $token = $self->users->generate_token(); 
        $self->users->save_token_email($token, $final_email);
        $self->users->send_email($token, $final_email);

        $self->write_log("Forgot: reset token sent to $final_email");

        $self->stash(msg => 'Email with password reset instructions has been sent.');
        $self->render(template => 'login/index');

    }
    else{

        $self->write_log("Forgot: user does not exist.");
        $self->stash(msg => 'User or email don\'t exists. Try again.');
        $self->render(template => 'login/forgot_request');
    }
}
####################################################################################
sub token_clicked {
    my $self = shift;
    my $token = $self->param('token');

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

    my $email = $self->users->get_email_for_token($token); #get it out of the DB for the token


    if($self->users->email_exists($email) == 0){

        $self->stash(msg => 'Token invalid! Abuse will be reported.');
        $self->write_log("Forgot: Token invalid! ($token)");
        $self->render(template => 'login/index');
        return;
    }

    if($pass1 eq $pass2){

        if($self->users->set_new_password($email, $pass1) == 1){

            $self->users->remove_token($token);
            $self->stash(msg => 'Change successuful. You may login now.');
            $self->write_log("Forgot: Change successful");
            $self->render(template => 'login/index');
            return;
        }
    }
    else{
        $self->stash(msg => 'Passwords are not same. Try again.', token => $token);
        $self->write_log("Forgot: Chnage failed. Passwords are not same.");
        $self->render(template => 'login/set_new_password');    
        return;
    }

    $self->users->remove_token($token);
    $self->write_log("Forgot: Chnage failed. Token deleted.");
    $self->stash(msg => 'Something went wrong. The password has not been changed. The reset token is no longer valid. You need to request a new one by clicking in \'I forgot my password\'.');
    $self->render(template => 'login/index');
}



####################################################################################
sub login {
    my $self = shift;
    my $user = $self->param('user');
    my $pass = $self->param('pass');

    

    if(defined $user and defined $pass){

        $self->write_log("Login: trying to log in as user $user");

        if($self->users->check($user, $pass)){
            $self->session(user => $user);
            $self->session(user_name => $self->users->get_user_real_name($user));
            $self->users->record_logging_in($user);

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
    $self->redirect_to('startpa');
}

####################################################################################
sub register{
    my $self = shift;
    my $config = $self->app->config;
    my $can_register = $config->{registration_enabled} ;

    
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

        $self->write_log("Login: received registration data from login: $login, email: $email.");


        if(defined $login and defined $email and defined $password1 and defined $password2){

            if(length($password1) == length($password2) and  $password2 eq $password1){

                if(length($password1) >= 4){
                    if($self->users->login_exists($login) == 0){
                        $self->users->add_new_user($login,$email,$name,$password1);

                        # $self->stash(msg => "User created successfully! You may now login using login: $login.");

                        $self->flash(msg => "User created successfully! You may now login using login: $login.");
                        $self->write_log("Login: registration successful for login: $login.");
                        $self->redirect_to('startpa');
                        return;
                    }
                    else{
                        # $self->stash(msg => "This login is already taken");

                        $self->flash(msg => "This login is already taken", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
                        $self->write_log("Login: registration unsuccessful for login: $login. Login taken.");
                        $self->redirect_to('register');
                        # $self->render(template => 'login/register');
                        return;
                    }
                }
                else{
                    # $self->stash(msg => "Password is too short");
                    
                    $self->flash(msg => "Password is too short, use minimum 4 symbols", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
                    $self->write_log("Login: registration unsuccessful for login: $login. Password too short.");
                    $self->redirect_to('register');
                    # $self->render(template => 'login/register');
                    return;
                }
            }
            else{
                # $self->stash(msg => "Passwords don't match!");
                $self->flash(msg => "Passwords don't match!", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
                $self->write_log("Login: registration unsuccessful for login: $login. Passwords don't match");
                $self->redirect_to('register');
                # $self->render(template => 'login/register');
                return;
            }
        }
        else{
            # $self->stash(msg => "Some input is missing!");
            $self->flash(msg => "Some input is missing!", name => $name, email => $email, login => $login, password1 => $password1, password2 => $password2);
            $self->write_log("Login: registration unsuccessful for login: $login. Input missing.");
            $self->redirect_to('register');
            # $self->render(template => 'login/register');
            return;
        }

    }
}

1;