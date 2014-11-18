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
$t_logged_in->ua->inactivity_timeout(300);

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my @pages = (
  $t_logged_in->app->url_for('system_status'),
  $t_logged_in->app->url_for('reset_all'),
  $t_logged_in->app->url_for('load_fixture'),
  $t_logged_in->app->url_for('save_fixture')
  ,    # saving test fixture shall not be tested!
);

for my $page (@pages) {
  note "============ Testing page $page ============";
  $t_logged_in->get_ok($page, "Get for page $page")
    ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");
}

ok(1);
done_testing();
