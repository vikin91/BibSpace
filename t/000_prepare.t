use Mojo::Base -strict;


use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use Try::Tiny;

use BibSpace;

use BibSpace::Model::Backup;

use BibSpace::Functions::BackupFunctions qw(restore_storable_backup);

use BibSpace::Functions::FDB; # TODO: purge DB etc.




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

my $fixture_name = "bibspace_fixture.dat";
my $fixture_dir = "./fixture/";

# TODO: Purge MySQL DB
# DONE: Apply storable fixture
# TODO: push fixture to DB

SKIP: {
	note "============ APPLY DATABASE FIXTURE ============";
	skip "Directory $fixture_dir does not exist", 1 if !-e $fixture_dir.$fixture_name;

  my $fixture = Backup->new(dir => $fixture_dir, filename =>$fixture_name);
  restore_storable_backup($fixture, $self->app);

}

ok(1);

done_testing();

