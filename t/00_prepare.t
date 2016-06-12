use Mojo::Base -strict;


use Test::More;
use Test::Mojo;
use Mojo::IOLoop;

use BibSpace;
use BibSpace::Controller::Core;
use BibSpace::Controller::Cron;
use BibSpace::Controller::Backup;
use BibSpace::Controller::BackupFunctions;

# BEGIN{
# 	$ENV{BIBSPACE_CONFIG}="lib/BibSpace/files/config/testing.conf";
# }


my $t_anyone = Test::Mojo->new('BibSpace');
my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);

my $dbh = $t_logged_in->app->db;
my $self = $t_logged_in->app;

my $fixture_dir = "./fixture/";

note "============ BACKING UP THE DATABASE ============";
my $db_backup_file = $t_logged_in->app->do_mysql_db_backup("basic_backup_testing");
note "============ BACKING FILE: $db_backup_file ============";



SKIP: {
	note "============ APPLY DATABASE FIXTURE ============";
	skip "Directory $fixture_dir does not exist", 1 if !-e $fixture_dir."db.sql";

	my $status = 0;
	$status = $t_logged_in->app->do_restore_backup_from_file("./fixture/db.sql");
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

