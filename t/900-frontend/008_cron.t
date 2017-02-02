use Mojo::Base -strict;


use Test::More;
use Test::Mojo;
use Mojo::IOLoop;

use BibSpace;
use BibSpace::Functions::Core;
use BibSpace::Controller::Cron;

my $t_anyone    = Test::Mojo->new('BibSpace');
my $self       = $t_anyone->app;


$t_anyone->ua->inactivity_timeout(3600);

## THIS SHOULD BE REPEATED FOR EACH TEST!
my $fixture_name = "bibspace_fixture.dat";
my $fixture_dir = "./fixture/";
use BibSpace::Model::Backup;
use BibSpace::Functions::BackupFunctions qw(restore_storable_backup);
my $fixture = Backup->new(dir => $fixture_dir, filename =>$fixture_name);
restore_storable_backup($fixture, $t_anyone->app);


$t_anyone->get_ok("/cron/night")
    ->status_isnt( 404, "Checking: 404 /cron/night" )
    ->status_isnt( 500, "Checking: 500 /cron/night" );

note "============ Testing cron day ============";
BibSpace::Controller::Cron::do_cron_day($self);
note "============ Testing cron night ============";
BibSpace::Controller::Cron::do_cron_night($self);
note "============ Testing cron week ============";
BibSpace::Controller::Cron::do_cron_week($self);
note "============ Testing cron month ============";
BibSpace::Controller::Cron::do_cron_month($self);


done_testing();

