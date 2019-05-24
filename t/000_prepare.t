use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use Try::Tiny;

use BibSpace;

use BibSpace::Model::Backup;
use BibSpace::Functions::BackupFunctions qw(restore_json_backup);
use BibSpace::Functions::FDB;

`rm log/*.log`;
`rm bibspace.dat`;

my $t_logged_in = Test::Mojo->new('BibSpace');

$t_logged_in->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);

my $self       = $t_logged_in->app;
my $dbh        = $self->app->db;
my $app_config = $t_logged_in->app->config;

my $db_host = $ENV{BIBSPACE_DB_HOST} || $self->app->config->{db_host};
my $db_user = $ENV{BIBSPACE_DB_USER} || $self->app->config->{db_user};
my $db_database
  = $ENV{BIBSPACE_DB_DATABASE} || $self->app->config->{db_database};
my $db_pass = $ENV{BIBSPACE_DB_PASS} || $self->app->config->{db_pass};

note "Check if we can talk to MySQL and proper database exists.";
ok(db_connect($db_host, $db_user, $db_database, $db_pass),
  "Can connect to database");
$dbh = $self->app->db;

my $fixture_file = $self->app->home->rel_file('fixture/bibspace_fixture.json');
my $fixture_name = '' . $fixture_file->basename;
my $fixture_dir  = '' . $fixture_file->dirname;

SKIP: {
  note "Drop database and recreate tables";
  skip "System is running in production mode!! Do not test on production!", 1
    if $self->mode eq 'production';
  ok(reset_db_data($dbh), "reset_db_data");
}

SKIP: {
  note "============ APPLY DATABASE FIXTURE ============";
  skip "Directory $fixture_dir does not exist", 1
    if !-e $fixture_dir . $fixture_name;

  note "Find backup file";
  my $fixture = Backup->new(dir => $fixture_dir, filename => $fixture_name);

  restore_json_backup($fixture, $self->app);

}

ok(1);

done_testing();
