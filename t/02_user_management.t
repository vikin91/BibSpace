use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Hex64Publications;
use Hex64Publications::Controller::Core;
use Hex64Publications::Functions::EntryObj;
use Hex64Publications::Functions::MyUsers;

todo : {

############################ PREPARATION
my $t_anyone = Test::Mojo->new('Hex64Publications');
my $t_logged_in = Test::Mojo->new('Hex64Publications');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);

my $dbh = $t_logged_in->app->db;

############################ READY FOR TESTING

# GET ROUTES

# /forgot/reset/:token                         GET   forgotresettoken
#     +/log                                    GET   log
#     +/settings/clean_all                     GET   settingsclean_all
#     +/settings/regenerate_all_force          GET   settingsregenerate_all_force
#     +/restore/do/:id                         GET   restoredoid
#     +/backup/cleanup                         GET   backupcleanup
#     +/profile/:id                            GET   profileid
#     +/profile/delete/:id                     GET   profiledeleteid
#     +/profile/make_user/:id                  GET   profilemake_userid
#     +/profile/make_manager/:id               GET   profilemake_managerid
#     +/profile/make_admin/:id                 GET   profilemake_adminid
#     +/settings/fix_entry_types               GET   settingsfix_entry_types
#     +/settings/fix_months                    GET   settingsfix_months
#     +/restore/delete/:id                     GET   restoredeleteid
#   +/profile                                  GET   profile


# NON-GET ROUTES
# /register                                    POST  register

#   +/types/add                                POST  typesadd
#   +/types/store_description                  POST  typesstore_description
#   +/authors/add                              POST  authorsadd
#   +/authors/edit                             POST  authorsedit
#   +/authors/edit_membership_dates            POST  authorsedit_membership_dates
#   +/tagtypes/add                             POST  tagtypesadd
#   +/tagtypes/edit/:id                        *     tagtypeseditid
#   +/tags/add/:type                           POST  tagsaddtype
#   +/tags/add_and_assign/:eid                 *     tagsadd_and_assigneid
#   +/teams/add                                POST  teamsadd
#   +/publications/add/store                   POST  publicationsaddstore
#   +/publications/edit/store/:id              POST  publicationseditstoreid
#   +/publications/add_pdf/do/:id              POST  publicationsadd_pdfdoid


########################################################

my $token = Hex64Publications::Functions::MyUsers->generate_token();
ok(defined $token and $token =~ y===c = 32);

########################################################
$t_anyone->ua->max_redirects(10);
$t_logged_in->ua->max_redirects(10);

# subtest 'Requesting password reset' => sub {

# $t_anyone->post_ok('/forgot/gen' => { Accept => '*/*' }, form => { user   => 'pub_admin' })
#     ->status_isnt(404)
#     ->status_isnt(500)
#     ->content_like(qr/Email with password reset instructions has been sent/i);


# $t_anyone->post_ok('/forgot/gen' => { Accept => '*/*' }, form => { user   => '', email => 'your_email@email.com' })
#     ->status_isnt(404)
#     ->status_isnt(500)
#     ->content_like(qr/Email with password reset instructions has been sent/i);

              

# $t_anyone->post_ok('/forgot/gen' => form => { user   => 'qwerty1234', email => '' })
#     ->status_isnt(404)
#     ->status_isnt(500)
#     ->content_like(qr/User or email does not exists. Try again./i);
# };

# ########################################################

# subtest 'Setting new password' => sub {

#     #requesting new token in cas it does not exist
#     $t_anyone->post_ok('/forgot/gen' => { Accept => '*/*' }, form => { user   => 'pub_admin' });

#     my $token2 = $t_anyone->app->users->get_token_for_email("your_email\@email.com", $dbh);
#     ok(defined $token2 and $token2 =~ y===c = 32, "Chacking token length");

#     $t_anyone->get_ok("/forgot/reset/$token2")->status_is(200);


    
#     # requesting new token in cas it does not exist
#     $t_anyone->post_ok('/forgot/gen' => { Accept => '*/*' }, form => { user   => 'pub_admin' });
#     $token2 = $t_anyone->app->users->get_token_for_email("your_email\@email.com", $dbh);

#     # not matching passwords
#     $t_anyone->post_ok('/forgot/store' => form => { token  => $token2, pass1 => 'asdf', pass2 => 'qwerty' })
#         ->status_isnt(404)
#         ->status_isnt(500)
#         ->content_like(qr/Passwords are not same. Try again./i, "Trying with non-matching passwords");

#     # matching passwords
#     $t_anyone->post_ok('/forgot/store' => form => { token  => $token2, pass1 => 'asdf', pass2 => 'asdf' })
#             ->status_isnt(404)
#             ->status_isnt(500)
#             ->content_like(qr/Password change successful. All your password reset tokens have been removed. You may login now./i, "Trying with valid data");

#     # wrong token    
#     $t_anyone->post_ok('/forgot/store' => form => { token  => 'invalid_token', pass1 => 'asdf', pass2 => 'asdf' })
#             ->status_isnt(404)
#             ->status_isnt(500)
#             ->content_like(qr/Reset password token is invalid! Abuse will be reported/i, "Trying invalid token");
# };

# ########################################################
# note "============ Registration anyone ============";

# $t_anyone->get_ok("/noregister")
#     ->status_is(200)
#     ->content_like(qr/Registration is disabled/i);




# if( $t_anyone->app->config->{registration_enabled} == 1){

#     my $token = MyUsers->generate_token();
#     note "=== Registration anyone: using token $token";
    

#     $t_anyone->get_ok("/register")
#         ->status_is(200)
#         ->content_unlike(qr/Registration is disabled/i)
#         ->text_is(label => "Login", "Admin is trying to register a user");


#     $t_anyone->post_ok('/register' => form => { 
#                                             login  => $token, 
#                                             name  => 'Henry',
#                                             email  => 'h@example.com',
#                                             password1 => 'asdf', 
#                                             password2 => 'qwerty' })
#     ->status_isnt(404)
#     ->status_isnt(500)
#     ->content_like(qr/Passwords don't match!/i, "Trying to register with non-matching passwords");

#     $t_anyone->post_ok('/register' => form => { 
#                                             login  => $token, 
#                                             name  => 'Henry',
#                                             email  => 'h@example.com',
#                                             password1 => 'a', 
#                                             password2 => 'a' })
#     ->status_isnt(404)
#     ->status_isnt(500)
#     ->content_like(qr/Password is too short, use minimum 4 symbols/i, "Trying to register with too short password");

#     $t_anyone->post_ok('/register' => form => { 
#                                             login  => '', 
#                                             name  => '',
#                                             email  => 'h@example.com',
#                                             password1 => 'a1234', 
#                                             password2 => 'a1234' })
#     ->status_isnt(404)
#     ->status_isnt(500)
#     ->content_like(qr/Some input is missing!/i, "Trying to register with missing login and email");



#     $t_anyone->post_ok('/register' => form => { 
#                                             login  => $token, 
#                                             name  => 'Henry John',
#                                             email  => $token.'@example.com',
#                                             password1 => 'qwerty', 
#                                             password2 => 'qwerty' })
#     ->status_isnt(404)
#     ->status_isnt(500)
#     ->content_like(qr/User created successfully! You may now login using login: $token/i, "Trying to register with valid data");

#     $t_anyone->post_ok('/register' => form => { 
#                                             login  => 'pub_admin', 
#                                             name  => 'Henry John',
#                                             email  => $token.'@example.com',
#                                             password1 => 'qwerty', 
#                                             password2 => 'qwerty' })
#     ->status_isnt(404)
#     ->status_isnt(500)
#     ->content_like(qr/This login is already taken/i, "Trying to register pub_admin");
# }
# ########################################################
# note "============ Registration admin ============";


# $t_logged_in->get_ok("/noregister")
#     ->status_is(200)
#     ->content_like(qr/Registration is disabled/i);


# my $token = MyUsers->generate_token();
# note "=== Registration admin: using token $token";

# $t_logged_in->get_ok("/register")
#     ->status_is(200)
#     ->content_unlike(qr/Registration is disabled/i)
#     ->text_is(label => "Login", , "Admin is trying to register a user");


# $t_logged_in->post_ok('/register' => form => { 
#                                         login  => $token, 
#                                         name  => 'Henry',
#                                         email  => 'h@example.com',
#                                         password1 => 'asdf', 
#                                         password2 => 'qwerty' })
# ->status_isnt(404)
# ->status_isnt(500)
# ->content_like(qr/Passwords don't match!/i, "Trying to register with non-matching passwords");

# $t_logged_in->post_ok('/register' => form => { 
#                                         login  => $token, 
#                                         name  => 'Henry',
#                                         email  => 'h@example.com',
#                                         password1 => 'a', 
#                                         password2 => 'a' })
# ->status_isnt(404)
# ->status_isnt(500)
# ->content_like(qr/Password is too short, use minimum 4 symbols/i, "Trying to register with too short password");

# $t_logged_in->post_ok('/register' => form => { 
#                                         login  => '', 
#                                         name  => '',
#                                         email  => 'h@example.com',
#                                         password1 => 'a1234', 
#                                         password2 => 'a1234' })
# ->status_isnt(404)
# ->status_isnt(500)
# ->content_like(qr/Some input is missing!/i, "Trying to register with missing login and email");



# $t_logged_in->post_ok('/register' => form => { 
#                                         login  => $token, 
#                                         name  => 'Henry John',
#                                         email  => $token.'@example.com',
#                                         password1 => 'qwerty', 
#                                         password2 => 'qwerty' })
# ->status_isnt(404)
# ->status_isnt(500)
# ->content_like(qr/User created successfully! You may now login using login: $token/i, "Trying to register with valid data");

# $t_logged_in->post_ok('/register' => form => { 
#                                         login  => 'pub_admin', 
#                                         name  => 'Henry John',
#                                         email  => $token.'@example.com',
#                                         password1 => 'qwerty', 
#                                         password2 => 'qwerty' })
# ->status_isnt(404)
# ->status_isnt(500)
# ->content_like(qr/This login is already taken/i, "Trying to register pub_admin");







########################################################

# subtest 'Anyone' => sub {
#     my @pages = (
#                 "/pa",
#                 "/" ,
#                 "/start",
#                 "/forgot",
#                 "/youneedtologin",
#                 "/badpassword",
#                 "/logout",
#                 "/register",
#                 "/login_form",

#                  );
#     ok($t_anyone->get_ok($_)->status_isnt(404)->status_isnt(500) => "404 or 500 for $_") for @pages;
# };

# ########################################################

# note "============ Testing 404 and 500 ============";
# $t_anyone->get_ok("/test/500")->status_is(500);
# $t_anyone->get_ok("/test/404")->status_is(404);

# ########################################################

# subtest 'Logged in' => sub {
#     my @pages = (
#                 "/pa",
#                 "/" ,
#                 "/start",
#                 "/forgot",
#                 "/youneedtologin",
#                 "/badpassword",
#                 "/logout",
#                 "/register",
#                 "/login_form",
#                 "/profile",
#                 "/manage_users",
#                  );
#     ok($t_logged_in->get_ok($_)->status_isnt(404)->status_isnt(500) => "404 or 500 for $_") for @pages;
# };
 
}

done_testing();

