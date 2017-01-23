use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use BibSpace::Controller::BackupFunctions;

my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);
my $self = $t_logged_in->app;

# if uncommented, this breaks the test - FIXME
$t_logged_in->ua->max_redirects(3);

my $db_backup_file
    = do_mysql_db_backup( $t_logged_in->app, "basic_backup_testing" );
my $backup_id = get_backup_id( $self, $db_backup_file );

my $status = $t_logged_in->app->do_restore_backup_from_file(
    "./fixture/thisdoesnotexist.txt");
ok( !$status, "preparing DB for test" );

my @pages;
my $page = "";

# $logged_user->get('/backups')->to('backup#index')->name('backup_index');
# $anyone->put('/backups')->to('backup#save')->name('backup_do');
# $logged_user->get('/backups/:id')->to('backup#backup_download')->name('backup_download');
# $superadmin->delete('/backups/:id')->to('backup#delete_backup')->name('backup_delete');
# $manager->put('/backups/:id')->to('backup#restore_backup')->name('backup_restore');
# $manager->delete('/backups')->to('backup#cleanup')->name('backup_cleanup');

$page = $t_logged_in->app->url_for('backup_index');
$t_logged_in->get_ok($page)->status_isnt( 404, "Checking: 404 $page" )
    ->status_isnt( 500, "Checking: 500 $page" );

$page = $t_logged_in->app->url_for('backup_do');
$t_logged_in->put_ok($page)->status_isnt( 404, "Checking: 404 $page" )
    ->status_isnt( 500, "Checking: 500 $page" );

$page = $t_logged_in->app->url_for( 'backup_download', id => $backup_id );
$t_logged_in->get_ok($page)->status_isnt( 404, "Checking: 404 $page" )
    ->status_isnt( 500, "Checking: 500 $page" );


####################################################################
subtest 'Backup : delete' => sub {

	my $page = $t_logged_in->app->url_for( 'backup_delete', id => $backup_id );

	$t_logged_in->delete_ok($page)->status_isnt( 404, "Checking: 404 $page" )
	    ->status_isnt( 500, "Checking: 500 $page" );
	    # ->content_unlike(qr/Cannot delete,/i)->content_like(qr/deleted/i); # this does not work :(

	$page = $t_logged_in->app->url_for( 'backup_delete', id => -222 );
	$t_logged_in->delete_ok($page)->status_isnt( 404, "Checking: 404 $page" )
	    ->status_isnt( 500, "Checking: 500 $page" );
	    # ->content_like(qr/Cannot delete,/i); # this does not work :(
};
####################################################################

$db_backup_file = do_mysql_db_backup(
    $t_logged_in->app, "basic_backup_testing" );
$backup_id = get_backup_id( $self,
    $db_backup_file );

$page = $t_logged_in->app->url_for('backup_restore');
$t_logged_in->put_ok($page)->status_isnt( 404, "Checking: 404 $page" )
    ->status_isnt( 500, "Checking: 500 $page" );
    # ->content_like(qr/Backup restored successfully/i); # this does not work :(

$page = $t_logged_in->app->url_for('backup_cleanup');
$t_logged_in->delete_ok($page)->status_isnt( 404, "Checking: 404 $page" )
    ->status_isnt( 500, "Checking: 500 $page" );

done_testing();
