use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Controller::Core;
use BibSpace::Controller::Backup;
use BibSpace::Controller::BackupFunctions;
use BibSpace::Functions::EntryObj;

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





done_testing();

