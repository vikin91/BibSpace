use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use BibSpace::Functions::MySqlBackupFunctions;

my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);
my $self = $t_logged_in->app;
$t_logged_in->ua->max_redirects(5);

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);


$t_logged_in->post_ok('/register' => form => {
    login     => "HenryJohnTester",
    name      => 'Henry John',
    email     => 'HenryJohnTester@example.com',
    password1 => 'qwerty',
    password2 => 'qwerty'
});

$t_logged_in->post_ok('/register' => form => {
    login     => "HenryJohnTester2",
    name      => 'Henry John2',
    email     => 'HenryJohnTester2@example.com',
    password1 => 'qwerty2',
    password2 => 'qwerty2'
});

my $me = $t_logged_in->app->repo->users_find(sub{$_->login eq 'pub_admin'});
my $user = $t_logged_in->app->repo->users_find(sub{$_->login eq 'HenryJohnTester'});
my $user2 = $t_logged_in->app->repo->users_find(sub{$_->login eq 'HenryJohnTester2'});

ok($me);
ok($user);
ok($user2);

#  $logged_user->get('/profile')->to('login#profile');
#  $admin_user->get('/manage_users')->to('login#manage_users')->name('manage_users');
#  $admin_user->get('/profile/:id')->to('login#foreign_profile')->name('show_user_profile');
#  $admin_user->get('/profile/delete/:id')->to('login#delete_user')->name('delete_user');

#  $admin_user->get('/profile/make_user/:id')->to('login#make_user')->name('make_user');
#  $admin_user->get('/profile/make_manager/:id')->to('login#make_manager')->name('make_manager');
#  $admin_user->get('/profile/make_admin/:id')->to('login#make_admin')->name('make_admin');
#  $anyone->get('/forgot')->to('login#forgot');
#  $anyone->post('/forgot/gen')->to('login#post_gen_forgot_token');
#  $anyone->get('/forgot/reset/:token')->to('login#token_clicked')->name("token_clicked");
#  $anyone->post('/forgot/store')->to('login#store_password');
#  $anyone->get('/login_form')->to('login#login_form')->name('login_form');
#  $anyone->post('/do_login')->to('login#login')->name('do_login');
#  $anyone->get('/youneedtologin')->to('login#not_logged_in')->name('youneedtologin');
#  $anyone->get('/badpassword')->to('login#bad_password')->name('badpassword');
#  $anyone->get('/logout')->to('login#logout')->name('logout');

my @pages = (
    '/profile',
    $t_logged_in->app->url_for('manage_users'),
    $t_logged_in->app->url_for('show_user_profile', id => $user->id),
    $t_logged_in->app->url_for('show_user_profile', id => $user2->id),
    $t_logged_in->app->url_for('delete_user', id => $user2->id), # delete ok
    $t_logged_in->app->url_for('make_user', id => $user->id),
    $t_logged_in->app->url_for('make_manager', id => $user->id),
    $t_logged_in->app->url_for('make_admin', id => $user->id),
    $t_logged_in->app->url_for('delete_user', id => $user->id), # shall not be deleted - is admin
    $t_logged_in->app->url_for('delete_user', id => $me->id), # shall not be deleted - is me
    $t_logged_in->app->url_for('make_user', id => $me->id), # shall not be degraded - is me & admin
);


for my $page (@pages){
  note "============ Testing page $page ============";
  $t_logged_in->get_ok($page, "Get for page $page")
    ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");
}


ok(1);
done_testing();
