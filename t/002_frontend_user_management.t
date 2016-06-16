use Mojo::Base -strict;


use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Controller::Core;
use BibSpace::Functions::MyUsers;

ok(1);


### Problem with this test suite is that the token for mailgun returns error because it is not correct in the default config
### We need to find a method to test this without providing the real credentials



# # DO NOT RUN THE CODE BELOW - it is not ready


# # ############################ PREPARATION
my $t_anyone = Test::Mojo->new('BibSpace');
my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);

my $dbh = $t_logged_in->app->db;

# # ############################ READY FOR TESTING


my $token = BibSpace::Functions::MyUsers->generate_token();
ok(defined $token and $token =~ y===c = 32);

########################################################
$t_anyone->ua->max_redirects(10);
$t_logged_in->ua->max_redirects(10);

subtest 'Requesting password reset' => sub {

note "============ FORGOT GEN 1 ============";
$t_anyone->post_ok('/forgot/gen' => { Accept => '*/*' }, form => { user   => 'pub_admin' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/Email with password reset instructions has been sent/i);

note "============ FORGOT GEN 2 ============";
$t_anyone->post_ok('/forgot/gen' => { Accept => '*/*' }, form => { user   => '', email => 'your_email@email.com' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/Email with password reset instructions has been sent/i);

note "============ FORGOT GEN 3 ============";

$t_anyone->post_ok('/forgot/gen' => form => { user   => 'qwerty1234', email => '' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/User or email does not exists. Try again./i);
};

note "============ SET NEW PW ============";

########################################################

subtest 'Setting new password' => sub {

    #requesting new token in cas it does not exist
    $t_anyone->post_ok('/forgot/gen' => { Accept => '*/*' }, form => { user   => 'pub_admin' });

    my $token2 = $t_anyone->app->users->get_token_for_email("your_email\@email.com", $dbh);
    ok(defined $token2 and $token2 =~ y===c = 32, "Chacking token length");

    $t_anyone->get_ok("/forgot/reset/$token2")->status_is(200);


    
    # requesting new token in cas it does not exist
    $t_anyone->post_ok('/forgot/gen' => { Accept => '*/*' }, form => { user   => 'pub_admin' });
    $token2 = $t_anyone->app->users->get_token_for_email("your_email\@email.com", $dbh);

    # not matching passwords
    $t_anyone->post_ok('/forgot/store' => form => { token  => $token2, pass1 => 'asdf', pass2 => 'qwerty' })
        ->status_isnt(404)
        ->status_isnt(500)
        ->content_like(qr/Passwords are not same. Try again./i, "Trying with non-matching passwords");

    # matching passwords
    $t_anyone->post_ok('/forgot/store' => form => { token  => $token2, pass1 => 'asdf', pass2 => 'asdf' })
            ->status_isnt(404)
            ->status_isnt(500)
            ->content_like(qr/Password change successful. All your password reset tokens have been removed. You may login now./i, "Trying with valid data");

    # wrong token    
    $t_anyone->post_ok('/forgot/store' => form => { token  => 'invalid_token', pass1 => 'asdf', pass2 => 'asdf' })
            ->status_isnt(404)
            ->status_isnt(500)
            ->content_like(qr/Reset password token is invalid! Abuse will be reported/i, "Trying invalid token");
};

########################################################
note "============ Registration anyone ============";

$t_anyone->get_ok("/noregister")
    ->status_is(200)
    ->content_like(qr/Registration is disabled/i);




####################################################################
subtest 'User management: public registration' => sub {
  if( $t_anyone->app->config->{registration_enabled} == 1){

    my $token = BibSpace::Functions::MyUsers->generate_token();
    note "=== Registration anyone: using token $token";


    $t_anyone->get_ok("/register")
        ->status_is(200)
        ->content_unlike(qr/Registration is disabled/i)
        ->text_is(label => "Login", "Admin is trying to register a user");


    $t_anyone->post_ok('/register' => form => { 
                                            login  => $token, 
                                            name  => 'Henry',
                                            email  => 'h@example.com',
                                            password1 => 'asdf', 
                                            password2 => 'qwerty' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/Passwords don't match!/i, "Trying to register with non-matching passwords");

    $t_anyone->post_ok('/register' => form => { 
                                            login  => $token, 
                                            name  => 'Henry',
                                            email  => 'h@example.com',
                                            password1 => 'a', 
                                            password2 => 'a' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/Password is too short, use minimum 4 symbols/i, "Trying to register with too short password");

    $t_anyone->post_ok('/register' => form => { 
                                            login  => '', 
                                            name  => '',
                                            email  => 'h@example.com',
                                            password1 => 'a1234', 
                                            password2 => 'a1234' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/Some input is missing!/i, "Trying to register with missing login and email");



    $t_anyone->post_ok('/register' => form => { 
                                            login  => $token, 
                                            name  => 'Henry John',
                                            email  => $token.'@example.com',
                                            password1 => 'qwerty', 
                                            password2 => 'qwerty' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/User created successfully! You may now login using login: $token/i, "Trying to register with valid data");

    $t_anyone->post_ok('/register' => form => { 
                                            login  => 'pub_admin', 
                                            name  => 'Henry John',
                                            email  => $token.'@example.com',
                                            password1 => 'qwerty', 
                                            password2 => 'qwerty' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/This login is already taken/i, "Trying to register pub_admin");
  }
};


####################################################################
subtest 'User management: noregister' => sub {
  $t_logged_in->get_ok("/noregister")
    ->status_is(200)
    ->content_like(qr/Registration is disabled/i);
};


####################################################################
subtest 'User management: admin registration' => sub {


    my $token = BibSpace::Functions::MyUsers->generate_token();
    note "=== Registration admin: using token $token";

    $t_logged_in->get_ok("/register")
        ->status_is(200)
        ->content_unlike(qr/Registration is disabled/i)
        ->text_is(label => "Login", , "Admin is trying to register a user");


    $t_logged_in->post_ok('/register' => form => { 
                                            login  => $token, 
                                            name  => 'Henry',
                                            email  => 'h@example.com',
                                            password1 => 'asdf', 
                                            password2 => 'qwerty' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/Passwords don't match!/i, "Trying to register with non-matching passwords");

    $t_logged_in->post_ok('/register' => form => { 
                                            login  => $token, 
                                            name  => 'Henry',
                                            email  => 'h@example.com',
                                            password1 => 'a', 
                                            password2 => 'a' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/Password is too short, use minimum 4 symbols/i, "Trying to register with too short password");

    $t_logged_in->post_ok('/register' => form => { 
                                            login  => '', 
                                            name  => '',
                                            email  => 'h@example.com',
                                            password1 => 'a1234', 
                                            password2 => 'a1234' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/Some input is missing!/i, "Trying to register with missing login and email");



    $t_logged_in->post_ok('/register' => form => { 
                                            login  => $token, 
                                            name  => 'Henry John',
                                            email  => $token.'@example.com',
                                            password1 => 'qwerty', 
                                            password2 => 'qwerty' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/User created successfully! You may now login using login: $token/i, "Trying to register with valid data");

    $t_logged_in->post_ok('/register' => form => { 
                                            login  => 'pub_admin', 
                                            name  => 'Henry John',
                                            email  => $token.'@example.com',
                                            password1 => 'qwerty', 
                                            password2 => 'qwerty' })
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/This login is already taken/i, "Trying to register pub_admin");

};

 
done_testing();

