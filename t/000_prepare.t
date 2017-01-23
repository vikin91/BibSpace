use Mojo::Base -strict;


use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use Try::Tiny;

use BibSpace;
use BibSpace::Controller::Core;
use BibSpace::Controller::Cron;
use BibSpace::Controller::Backup;
use BibSpace::Controller::BackupFunctions;

use BibSpace::Functions::FDB;




my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);

my $self = $t_logged_in->app;
my $dbh = $self->app->db;
my $app_config = $t_logged_in->app->config;


my $db_host     = $self->config->{db_host};
my $db_user     = $self->config->{db_user};
my $db_database = $self->config->{db_database};
my $db_pass     = $self->config->{db_pass};

ok(db_connect($db_host, $db_user, $db_database, $db_pass), "Can connect to database");
$dbh = $self->app->db;



note "============ BACKING UP THE DATABASE ============";
my $db_backup_file = $t_logged_in->app->do_mysql_db_backup("basic_backup_testing");
note "============ BACKING FILE: $db_backup_file ============";


my $fixture_name = "db_new.sql";
my $fixture_dir = "./fixture/";
SKIP: {
	note "============ APPLY DATABASE FIXTURE ============";
	skip "Directory $fixture_dir does not exist", 1 if !-e $fixture_dir.$fixture_name;

  try{
	 ok(do_restore_backup_from_file($self, $dbh, "./fixture/".$fixture_name, $app_config), "preparing DB for test");
  }
  catch{
    my $db_host     = $self->config->{db_host};
    my $db_user     = $self->config->{db_user};
    my $db_database = $self->config->{db_database};
    my $db_pass     = $self->config->{db_pass};

    ok(db_connect($db_host, $db_user, $db_database, $db_pass), "Can connect to database");
    $dbh = $self->app->db;
  };
}

done_testing();

