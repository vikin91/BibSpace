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
# 	#$ENV{BIBSPACE_CONFIG}="lib/BibSpace/files/config/testing.conf";
#   say "BIBSPACE_CONFIG: ".$ENV{BIBSPACE_CONFIG};
#   my $a = Test::Mojo->new('BibSpace');
#   $ENV{BIBSPACE_CONFIG_HASH} = {
#     backups_dir         => './backups',  # $a->app->home->rel_dir('backups'),
#     upload_dir          => './public/uploads',  # $a->app->home->rel_dir('public/uploads'),
#     log_dir             => './log',  # $a->app->home->rel_dir('log'),
#     log_file            => './log/bibspace_test.log',  # $a->app->home->rel_file('log/my.log'),
#     key_cookie          => 'somesectretstring',
#     registration_enabled    => 1,

#     backup_age_in_days_to_delete_automatically    => 30,
#     allow_delete_backups_older_than => 7,

#     db_host         => "localhost",
#     db_user         => "bibspace_user",
#     db_database     => "bibspace",
#     db_pass         => "dupa",#"passw00rd",

#     cron_day_freq_lock => 1,
#     cron_night_freq_lock => 4, 
#     cron_week_freq_lock => 24, 
#     cron_month_freq_lock => 48,
    
#     demo_mode    => 0,
#     demo_msg    => '',
#     proxy_prefix        => '',
#     mailgun_key         => 'your-key',
#     mailgun_domain      => 'your-sandbox3534635643567808d.mailgun.org',
#     mailgun_from        => 'Mailgun Sandbox <postmaster@your-sandbox3534635643567808d.mailgun.org>',
#     footer_inject_code   =>  qq(
#     <!-- For example Google Analytics -->
#     ),
#     hypnotoad => {
#         listen  => ['http://*:8080'],
#         pid_file => './hypnotoad.pid',
#         workers => 1,
#         proxy => 1
#     }
#   };
#   say "BIBSPACE_CONFIG_HASH: ".$ENV{BIBSPACE_CONFIG_HASH};
#   say "MOJO_CONFIG after: ".$ENV{MOJO_CONFIG};
# }


my $t_anyone = Test::Mojo->new('BibSpace');
my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);

my $self = $t_logged_in->app;
my $dbh = $self->app->db;


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

