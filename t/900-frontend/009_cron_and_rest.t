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

$t_anyone->get_ok("/cron/night")->status_isnt(404, "Checking: 404 /cron/night")
  ->status_isnt(500, "Checking: 500 /cron/night");

note "============ Testing cron day ============";
BibSpace::Controller::Cron::do_cron_day($self);
note "============ Testing cron night ============";
BibSpace::Controller::Cron::do_cron_night($self);
note "============ Testing cron week ============";
BibSpace::Controller::Cron::do_cron_week($self);
note "============ Testing cron month ============";
BibSpace::Controller::Cron::do_cron_month($self);

note "============ Testing statistics output ============";
ok($self->app->statistics->toLines);
ok($self->app->statistics->toString);

note "============ Leftovers... ============";

use BibSpace::Util::DummyUidProvider;

my $duip
  = DummyUidProvider->new(for_type => 'Dummy', logger => $self->app->logger);
ok($duip);
ok($duip->reset);
ok($duip->registerUID);
ok($duip->generateUID);

use BibSpace::Util::SmartUidProvider;

my $suip = SmartUidProvider->new(
  idProviderClassName => 'IntegerUidProvider',
  logger              => $self->app->logger
);
ok($suip->_init('Entry'));
ok($suip->generateUID('Entry'));
ok($suip->generateUID('Entry'));
ok($suip->registerUID('Entry', 999999));

ok(1);
done_testing();

