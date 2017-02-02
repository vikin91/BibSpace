package BibSpace::Controller::Backup;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; 
use Try::Tiny;
use strict;
use warnings;
use DBI;
use DBIx::Connector;
use File::Copy qw(copy);
use List::MoreUtils qw(any uniq);
use List::Util qw(first);

use BibSpace::Functions::Core;
use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Functions::FDB;

use BibSpace::Model::Backup;
use Storable;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;


## Trivial DAO FIND
####################################################################################
sub find_backup {
    my $uuid = shift;
    my $dir = shift;

    my @file_list;
    try{
        opendir(D, "$dir") or die;
        @file_list = readdir(D);
        closedir(D);
    }
    catch{
        warn;
    };

    my @backups;

    foreach my $file (@file_list){
        next unless $file =~ /^backup/;
        next unless $file =~ /\.dat$/;
        next unless $file =~ /$uuid/;

        my $backup = Backup->parse($file);
        $backup->dir($dir);
        return $backup;
    }
    return;
}
## Trivial DAO ALL
####################################################################################
sub read_backups {
    my $dir = shift;

    my @file_list;
    try{
        opendir(D, "$dir") or die;
        @file_list = readdir(D);
        closedir(D);
    }
    catch{
        warn;
    };

    my @backups;

    foreach my $file (@file_list){
        next unless $file =~ /^backup/;
        next unless $file =~ /\.dat$/;

        my $backup = Backup->parse($file);
        $backup->dir($dir);
        push @backups, $backup;
    }
    return @backups;
}

####################################################################################

sub index {
    my $self       = shift;
    my $dbh = $self->app->db;

    my $backup_dir_absolute = $self->config->{backups_dir};
    # makes sure that there is exactly one / at the end
    $backup_dir_absolute =~ s!/*$!/!;    
    my $dir_size = get_dir_size($backup_dir_absolute);
    $dir_size = $dir_size >> 20;

    my @backups_arr = sort {$b->date cmp $a->date} read_backups($backup_dir_absolute);

    $self->stash(
        backups_arr => \@backups_arr,
        dir_size    => $dir_size
    );
    $self->render( template => 'backup/backup' );
}

####################################################################################
####################################################################################
sub save {
    my $self = shift;

    my $backup_dir_absolute = $self->config->{backups_dir};
    $backup_dir_absolute =~ s!/*$!/!;  

    my $backup = Backup->create("normal");
    $backup->dir($backup_dir_absolute);

    $self->app->logger->info("Creating backup ".$backup->uuid);

    my $layer = $self->app->repo->lr->get_read_layer;
    my $path = "".$backup->get_path;

    $Storable::forgive_me = "do store regexp";

    Storable::store $layer, $path;

    # create old-mysql backup for double safety
    # do_backup_current_state( $self, "normal" );

    if ( $backup->is_healthy ) {
        $self->flash( msg_type=>'success', msg => "Backup created successfully" );
    }
    else {
        $self->flash(msg_type=>'danger',  msg => "Backup create failed!" );
    }
    $self->redirect_to( 'backup_index' );
}

####################################################################################
sub cleanup {
    my $self        = shift;
    my $num_deleted = do_delete_broken_or_old_backup($self);

    $self->flash( msg_type=>'success', msg => "$num_deleted backups have been cleaned." );

    # redirecting to referrer here breaks the test if the test supports redirects! why?
    # disabling redirects for test and putting here referrer allows test to pass
    $self->redirect_to( 'backup_index' );
}

####################################################################################

sub backup_download {
    my $self       = shift;
    my $uuid  = $self->param('id');

    my $backup_dir_absolute = $self->config->{backups_dir};
    $backup_dir_absolute =~ s!/*$!/!;

    my $backup =  find_backup($uuid, $backup_dir_absolute);

    if ( $backup and $backup->is_healthy ) {
        $self->app->logger->info("Downloading backup ".$backup->uuid);
        $self->render_file( 'filepath' => $backup->get_path );
    }
    else {
        $self->flash( msg_type=>'danger', msg => "Cannot download backup $uuid - backup not healthy." );
        $self->redirect_to( $self->get_referrer );
    }
}

####################################################################################
sub delete_backup {
    my $self       = shift;
    my $uuid  = $self->param('id');

    my $backup_dir_absolute = $self->config->{backups_dir};
    $backup_dir_absolute =~ s!/*$!/!;

    my $backup =  find_backup($uuid, $backup_dir_absolute);

    if ( $backup and $backup->is_healthy ) {
        try{
            unlink $backup->get_path;
            $self->app->logger->info("Deleting backup ".$backup->uuid);
            $self->flash( msg_type=>'success', msg => "Backup id $uuid deleted!" );
        }
        catch{
            $self->flash( msg_type=>'danger', msg => "Exception during deleting backup '$uuid': $_." );
        };
        
    }
    else{
        $self->flash( msg_type=>'danger', msg => "Cannot delete backup $uuid - need to do this manually." );
    }

    # redirecting to referrer here breaks the test if the test supports redirects! why?
    # disabling redirects for test and putting here referrer allows test to pass
    $self->res->code(303);
    $self->redirect_to($self->url_for('backup_index'));
}

####################################################################################
sub restore_backup {
    my $self = shift;
    my $dbh  = $self->app->db;
    my $uuid = $self->param('id');

    my $backup_dir_absolute = $self->app->config->{backups_dir};
    $backup_dir_absolute =~ s!/*$!/!;
    my $backup =  find_backup($uuid, $backup_dir_absolute);

    if($backup->is_healthy){

        ### WARNING : Smart array and MySQL DB are not in sync now!!!
        my $layer = retrieve($backup->get_path);
        $self->app->repo->lr->replace_layer('smart', $layer);

        $self->app->logger->info("Restoring backup ".$backup->uuid);

        $self->flash( msg_type=>'warning', msg => "Backup restored successfully. WARNING: SYSTEM NOT IN SYNC!" );
    }
    else {
        $self->flash( msg_type=>'danger', msg => "Cannot restore - backup not healthy!" );
    }
    $self->redirect_to('backup_index');
}

####################################################################################

1;
