use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use BibSpace;
use BibSpace::Functions::Core;


my $admin_user = Test::Mojo->new('BibSpace');
$admin_user->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);


my $self = $admin_user->app;
my $app_config = $admin_user->app->config;
$admin_user->ua->max_redirects(3);

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);






my $page = $self->url_for('add_many_publications');
  $admin_user->get_ok($page, "Get for page $page")
      ->status_isnt(404, "Checking: 404 $page")
      ->status_isnt(500, "Checking: 500 $page");



ok(1);

done_testing();
