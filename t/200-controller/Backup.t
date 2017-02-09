use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Functions::BackupFunctions;

my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);
my $self = $t_logged_in->app;
$t_logged_in->ua->max_redirects(5);

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my @pages;
my $page = "";

my $backup_id = 1;

# $logged_user->get('/backups')->to('backup#index')->name('backup_index');
# $anyone->put('/backups')->to('backup#save')->name('backup_do');
# $logged_user->get('/backups/:id')->to('backup#backup_download')->name('backup_download');
# $superadmin->delete('/backups/:id')->to('backup#delete_backup')->name('backup_delete');
# $manager->put('/backups/:id')->to('backup#restore_backup')->name('backup_restore');
# $manager->delete('/backups')->to('backup#cleanup')->name('backup_cleanup');

####################################################################
subtest 'backup_index' => sub {
    $page = $t_logged_in->app->url_for('backup_index');
    $t_logged_in->get_ok($page)->status_isnt( 404, "Checking: 404 $page" )
        ->status_isnt( 500, "Checking: 500 $page" );
};

####################################################################
subtest 'backup_do' => sub {
    $page = $t_logged_in->app->url_for('backup_do');
    $t_logged_in->put_ok($page)->status_isnt( 404, "Checking: 404 $page" )
        ->status_isnt( 500, "Checking: 500 $page" );
};

my @backups = read_backups($self->app->backup_dir);
ok( scalar(@backups) > 0 );
my $backup = shift @backups;
$backup_id = $backup->uuid;
####################################################################
subtest 'backup_index again' => sub {
    $page = $t_logged_in->app->url_for('backup_index');
    $t_logged_in->get_ok($page)->status_isnt( 404, "Checking: 404 $page" )
        ->status_isnt( 500, "Checking: 500 $page" );
};
####################################################################
subtest 'backup_download' => sub {

$page = $t_logged_in->app->url_for( 'backup_download', id => $backup_id );
$t_logged_in->get_ok($page)->status_isnt( 404, "Checking: 404 $page" )
    ->status_isnt( 500, "Checking: 500 $page" );
};

####################################################################
subtest 'backup_delete' => sub {

	my $page = $t_logged_in->app->url_for( 'backup_delete', id => $backup_id );

	$t_logged_in->delete_ok($page)->status_isnt( 404, "Checking: 404 $page" )
	    ->status_isnt( 500, "Checking: 500 $page" );

	$page = $t_logged_in->app->url_for( 'backup_delete', id => -222 );
	$t_logged_in->delete_ok($page)->status_isnt( 404, "Checking: 404 $page" )
	    ->status_isnt( 500, "Checking: 500 $page" );
};



# you need to get a valid ID first!
# $page = $t_logged_in->app->url_for('backup_restore', id=>2);
# $t_logged_in->put_ok($page)->status_isnt( 404, "Checking: 404 $page" )
#     ->status_isnt( 500, "Checking: 500 $page" );

####################################################################
subtest 'backup_cleanup' => sub {
    $page = $t_logged_in->app->url_for('backup_cleanup');
    $t_logged_in->delete_ok($page)->status_isnt( 404, "Checking: 404 $page" )
        ->status_isnt( 500, "Checking: 500 $page" );
};
done_testing();
