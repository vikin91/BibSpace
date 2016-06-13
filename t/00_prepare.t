use Mojo::Base -strict;


use Test::More;
use Test::Mojo;
use Mojo::IOLoop;

use BibSpace;
use BibSpace::Controller::Core;
use BibSpace::Controller::Cron;
use BibSpace::Controller::Backup;
use BibSpace::Controller::BackupFunctions;

use BibSpace::Functions::FDB;

BEGIN{
  my $a = Test::Mojo->new('BibSpace');
  $ENV{BIBSPACE_CONFIG} = $a->app->home->rel_dir('fixture/default.conf');
}


my $t_anyone = Test::Mojo->new('BibSpace');
my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);

my $self = $t_logged_in->app;
my $dbh = $self->app->db;
my $app_config = $t_logged_in->app->config;


####################################################################
subtest '00: checking if DB runs' => sub {
  my $db_host     = $self->config->{db_host};
  my $db_user     = $self->config->{db_user};
  my $db_database = $self->config->{db_database};
  my $db_pass     = $self->config->{db_pass};
  my $is_up       = db_is_up($db_host, $db_user, $db_database, $db_pass);
  is($is_up, 1, "MySQL Server is up and the credentials are ok");
  ok(db_connect($db_host, $db_user, $db_database, $db_pass), "Can connect to database");
};

my $fixture_dir = "./fixture/";

note "============ BACKING UP THE DATABASE ============";
my $db_backup_file = $t_logged_in->app->do_mysql_db_backup("basic_backup_testing");
note "============ BACKING FILE: $db_backup_file ============";



SKIP: {
	note "============ APPLY DATABASE FIXTURE ============";
	skip "Directory $fixture_dir does not exist", 1 if !-e $fixture_dir."db.sql";

	my $status = 0;
	$status = do_restore_backup_from_file($dbh, "./fixture/db.sql", $app_config);
	is($status, 1, "preparing DB for test");
}

note "============ CHECK /cron/night ============";

# my $c = BibSpace::Controller::Cron->new(app => Mojolicious->new);
$t_anyone->ua->inactivity_timeout(3600);
# Mojo::IOLoop->stream($self->tx->connection)->timeout(3600);
$t_anyone->get_ok("/cron/night")->status_isnt(404, "Checking: 404 /cron/night")->status_isnt(500, "Checking: 500 /cron/night");

note "============ Testing cron day ============";
BibSpace::Controller::Cron::do_cron_day($self);
note "============ Testing cron night ============";
BibSpace::Controller::Cron::do_cron_night($self);
note "============ Testing cron week ============";
BibSpace::Controller::Cron::do_cron_week($self);
note "============ Testing cron month ============";
BibSpace::Controller::Cron::do_cron_month($self);


note "============ END OF TEST 00 ============";

done_testing();

