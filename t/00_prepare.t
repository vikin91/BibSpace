use Mojo::Base -strict;


BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
}

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Controller::Core;
use BibSpace::Controller::Backup;
use BibSpace::Controller::BackupFunctions;

use BibSpace::Functions::EntryObj;


my $t_anyone = Test::Mojo->new('BibSpace');
my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);

my $dbh = $t_logged_in->app->db;
my $self = $t_logged_in->app;


# ok($t_logged_in->get_ok("/backup/do")->status_isnt(404)->status_isnt(500) => "404 or 500 for $_");
my $db_backup_file = do_mysql_db_backup($t_logged_in->app, "testing");
my $backup_id = get_backup_id($self, $db_backup_file);
do_restore_backup($self, $backup_id);


done_testing();

