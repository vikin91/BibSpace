use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use Menry;
use Menry::Controller::Core;
use Menry::Controller::Backup;
use Menry::Functions::BackupFunctions;
use Menry::Functions::EntryObj;


my $t_anyone = Test::Mojo->new('Menry');
my $t_logged_in = Test::Mojo->new('Menry');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);

my $dbh = $t_logged_in->app->db;
my $self = $t_logged_in->app;



done_testing();

