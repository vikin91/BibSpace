use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::IOLoop;

use BibSpace;
use BibSpace::Functions::Core;
use BibSpace::Controller::Cron;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;
$t_anyone->ua->inactivity_timeout(3600);
use BibSpace::TestManager;
TestManager->apply_fixture($t_anyone->app);

subtest "Run cron functions" => sub {
  is(BibSpace::Controller::Cron::do_cron_day($self),
    1, "Cron day should return 1");
  is(BibSpace::Controller::Cron::do_cron_night($self),
    1, "Cron night should return 1");
  is(BibSpace::Controller::Cron::do_cron_week($self),
    1, "Cron week should return 1");
  is(BibSpace::Controller::Cron::do_cron_month($self),
    1, "Cron month should return 1");
};

subtest "Test cron pages" => sub {
  $t_anyone->get_ok("/cron")->status_isnt(404)->status_isnt(500)
    ->content_like(qr/Cron day/)->content_like(qr/Cron night/)
    ->content_like(qr/Cron week/)->content_like(qr/Cron month/)
    ->content_like(qr/last run/);

  $t_anyone->get_ok("/cron/night")->status_isnt(404)->status_isnt(500)
    ->content_like(qr/Cron level 1/);

  $t_anyone->get_ok("/cron/week")->status_isnt(404)->status_isnt(500)
    ->content_like(qr/Cron level 2/);

  $t_anyone->get_ok("/cron/month")->status_isnt(404)->status_isnt(500)
    ->content_like(qr/Cron level 3/);
};

subtest "Test statistics function" => sub {
  ok($self->app->statistics->toLines);
};

done_testing();
