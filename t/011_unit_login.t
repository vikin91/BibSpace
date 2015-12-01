use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use Menry;
use Menry::Controller::Core;
use Menry::Controller::Login;
use Menry::Functions::MyUsers;


my $t_anyone = Test::Mojo->new('Menry');
my $t_logged_in = Test::Mojo->new('Menry');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);

my $self = $t_logged_in->app;
my $dbh = $self->db;
my $u = $self->users;


note "============ Unit tests for MyUsers.pm ============";

ok($u->insert_admin($dbh) == 1, "Inserting admin user");
ok($u->check('pub_admin', 'asdf', $dbh) == 1, "Checking user");
ok(!defined $u->check('pub_admin', 'aaaaa', $dbh), "Checking user using wrong pass");

ok($u->add_new_user("user2", 'e@e.com', "User2", "asdf", "1", $dbh) == 1, "Adding user user2");
ok($u->check('user2', 'asdf', $dbh) == 1, "Checking user2");
ok(!defined $u->check('user2', 'ASDF', $dbh), "Checking user2 using wrong pass");

TODO: { 
    local $TODO = "Email non testable!";

    ok( defined $u->send_email("token", 'your_email@email.com'), "Sending email with mailgun");
}

my $token = $u->generate_token(); 
ok(defined $token and $token =~ y===c = 32, "generating token");
ok($u->save_token_email($token, 'your_email@email.com', $dbh) == 1, "Saving token for email");

ok($u->get_token_for_email('your_email@email.com', $dbh) eq $token, "Getting token for email");

ok($u->remove_token('non-existing-token', $dbh), "Remove non-existing token");
ok($u->remove_token($token, $dbh), "Remove existing token");

# adding again
$u->save_token_email($token, 'your_email@email.com', $dbh);

ok($u->get_email_for_token($token, $dbh) eq 'your_email@email.com', "get_email_for_token");
ok(!defined $u->get_email_for_token('token', $dbh), "get_email_for_token for not existing token");

my $token2 = $u->generate_token(); 
$u->save_token_email($token2, 'your_email@email.com', $dbh);

my $token3 = $u->generate_token(); 
$u->save_token_email($token3, 'your_email@email.com', $dbh);

ok( defined $u->remove_all_tokens_for_email('your_email@email.com', $dbh), "Removing all tokens for email");
ok(!defined $u->get_email_for_token($token, $dbh), "get_email_for_token");
ok(!defined $u->get_email_for_token($token2, $dbh), "get_email_for_token2");
ok(!defined $u->get_email_for_token($token3, $dbh), "get_email_for_token3");


ok($u->get_login_for_id(1, $dbh) eq 'pub_admin');
ok(!defined $u->get_login_for_id(222, $dbh));

ok($u->get_registration_time('pub_admin', $dbh));
ok(!defined $u->get_registration_time('abc', $dbh));

ok($u->get_last_login('pub_admin', $dbh));
ok(!defined $u->get_last_login('abc', $dbh));

ok($u->login_exists('pub_admin', $dbh));
ok($u->login_exists('abc', $dbh) == 0);

ok($u->email_exists('your_email@email.com', $dbh));
ok($u->email_exists('abc', $dbh) == 0);

ok($u->get_rank('pub_admin', $dbh) == 3);
ok(!defined $u->get_rank('abc', $dbh));

ok($u->get_email('pub_admin', $dbh) eq 'your_email@email.com');
ok(!defined $u->get_email('abc', $dbh));

ok($u->get_email_for_uname('pub_admin', $dbh) eq 'your_email@email.com');
ok(!defined $u->get_email_for_uname('abc', $dbh));

###

ok($u->set_new_password('your_email@email.com', 'new_pass', $dbh) == 1, "Setting new pass for pub_admin");
ok($u->check('pub_admin', 'new_pass', $dbh) == 1, "Checking user");
ok($u->set_new_password('your_email@email.com', 'asdf', $dbh) == 1, "Setting new pass for pub_admin");
ok($u->check('pub_admin', 'asdf', $dbh) == 1, "Checking user");

ok($u->add_new_user("user3", 'e@e.com', "User3", "asdf", "0", $dbh) == 1, "Adding user user3");
ok($u->check('user3', 'asdf', $dbh) == 1, "Checking user3");

my $user = $dbh->resultset('Login')->find({ login => 'user3' });
ok(defined $user, "Finding the user in DB");
my $u_id = $user->id;
ok(defined $u->do_delete_user($u_id, $dbh), "Deleting user3");
ok(!defined $u->check('user3', 'asdf', $dbh), "Checking user3 afted deletion");
ok(!defined $u->do_delete_user(-333, $dbh), "Deleting non-existing user");


ok(!defined $u->get_user_hash('dummy_user', $dbh), "getting pw hash of non-exisiting user");
ok(defined $u->get_user_hash('pub_admin', $dbh), "getting pw hash of exisiting user");

ok(!defined $u->get_user_real_name('dummy_user', $dbh), "getting real name of non-exisiting user");
ok($u->get_user_real_name('pub_admin', $dbh) eq 'Admin', "getting real name of exisiting user");

ok($u->record_logging_in('pub_admin', $dbh), "recording logging in for admin");
ok($u->record_logging_in('abc', $dbh), "recording logging in for non-existing user");



my $user2_id = $dbh->resultset('Login')->search({ login => 'user2' })->get_column('id')->first;
ok(defined $user2_id, "Finding the user2 in DB");
ok(defined $u->promote_to_manager($user2_id, $dbh), "promoting user2 to be manager");
ok($u->get_rank('user2', $dbh) == 1);


done_testing();

