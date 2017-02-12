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
$t_logged_in->ua->inactivity_timeout(300);

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);



# 'system_status'
# 'load_fixture'
# 'save_fixture'
# 'copy_mysql_to_smart'
# 'copy_smart_to_mysql'
# 'persistence_status'
# 'reset_mysql'
# 'reset_smart'
# 'reset_all'
# 'insert_random_data'

my @pages = (
    $t_logged_in->app->url_for('system_status'),
    $t_logged_in->app->url_for('reset_smart'),
    $t_logged_in->app->url_for('copy_mysql_to_smart'),
    $t_logged_in->app->url_for('reset_mysql'),
    $t_logged_in->app->url_for('copy_smart_to_mysql'),
    $t_logged_in->app->url_for('persistence_status'),
    $t_logged_in->app->url_for('reset_all'),
    $t_logged_in->app->url_for('load_fixture'),
    # $t_logged_in->app->url_for('save_fixture'), # saving test fixture shall not be tested!
    $t_logged_in->app->url_for('insert_random_data', num => 50),
);


for my $page (@pages){
  note "============ Testing page $page ============";
  $t_logged_in->get_ok($page, "Get for page $page")
    ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");
}


ok(1);
done_testing();
