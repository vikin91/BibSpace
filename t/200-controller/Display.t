use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use BibSpace::Functions::MySqlBackupFunctions;

my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);
my $self = $t_logged_in->app;
$t_logged_in->ua->max_redirects(5);

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my $page;

subtest 'start' => sub {
  $page = $t_logged_in->app->url_for('start');
  $t_logged_in->get_ok($page)->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");
};

subtest 'show_log' => sub {
  $page = $t_logged_in->app->url_for('show_log', num => 10);
  $t_logged_in->get_ok($page)->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");

  $page = $t_logged_in->app->url_for('show_log', num => -10);
  $t_logged_in->get_ok($page)->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");

  $page = $t_logged_in->app->url_for('show_log', num => 10)
    ->query(type => "notexisting");
  $t_logged_in->get_ok($page)->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");
};

$page = $t_logged_in->app->url_for('error500');
$t_logged_in->get_ok($page)->status_isnt(404, "Checking: 404 $page")
  ->status_is(500, "Checking: 500 $page");

$page = $t_logged_in->app->url_for('error404');
$t_logged_in->get_ok($page)->status_is(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

ok(1);
done_testing();
