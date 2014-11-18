use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::IOLoop;

use BibSpace;
use BibSpace::Functions::Core;
use BibSpace::Controller::Cron;

my $op   = Test::Mojo->new('BibSpace');
my $self = $op->app;
use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

$op->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);

$self = $op->app;
my $app_config = $op->app->config;
$op->ua->max_redirects(10);

subtest 'Persistence Status Ajax' => sub {
  my $page = $self->url_for('persistence_status_ajax');

  $op->get_ok($page)->status_isnt(404)->status_isnt(500)
    ->text_like('pre' => qr/CNT_mysql/)->text_unlike('pre' => qr/CNT_smart/)
    ->text_like('pre' => qr/entity/);
};

done_testing();
