package BibSpace::Controller::Backup;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010;           #because of ~~
use strict;
use warnings;
use DBI;
use File::Copy qw(copy);

use BibSpace::Controller::Core;
use BibSpace::Controller::BackupFunctions;
use BibSpace::Functions::FDB;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;

####################################################################################
sub save {
    my $self = shift;
    my $return_value = do_backup_current_state( $self, "normal" );

    if ( defined $return_value ) {
        $self->flash( msg => "Backup created successfully" );
    }
    else {
        $self->flash( msg => "Backup create failed!" );
    }
    $self->redirect_to( 'backup_index' );
}

####################################################################################
sub cleanup {
    my $self        = shift;
    my $num_deleted = do_delete_broken_or_old_backup($self);

    $self->flash( msg => "$num_deleted backups have been cleaned." );

    # redirecting to referrer here breaks the test if the test supports redirects! why?
    # disabling redirects for test and putting here referrer allows test to pass
    $self->redirect_to( 'backup_index' );
}

####################################################################################

sub index {
    my $self       = shift;
    my $backup_dbh = $self->app->db;
    say "call: Backup::backup";

    my $sth
        = $backup_dbh->prepare(
        "SELECT id, creation_time, filename FROM Backup ORDER BY creation_time DESC"
        );
    $sth->execute();

    my $dir_size            = 0;
    my $backup_dir_absolute = $self->config->{backups_dir};
    $backup_dir_absolute
        =~ s!/*$!/!;    # makes sure that there is exactly one / at the end
    $dir_size = get_dir_size($backup_dir_absolute);
    $dir_size = $dir_size >> 20;

    my @ctime_arr;
    my @fname_arr;
    my @id_arr;
    my @exists_arr;

    my $i = 1;
    while ( my $row = $sth->fetchrow_hashref() ) {
        my $id = $row->{id};

        $self->can_delete_backup($id);

        my $backup_file_name = $row->{filename};
        my $exists           = 0;
        my $backup_file_path = $backup_dir_absolute . $backup_file_name;
        $exists = 1 if -e $backup_file_path;

        my $ctime = $row->{creation_time};
        push @exists_arr, $exists;
        push @ctime_arr,  $ctime;
        push @fname_arr,  $backup_file_name;
        push @id_arr,     $id;
    }

    $self->stash(
        ids      => \@id_arr,
        fnames   => \@fname_arr,
        ctimes   => \@ctime_arr,
        exists   => \@exists_arr,
        dir_size => $dir_size
    );
    $self->render( template => 'backup/backup' );
}

####################################################################################

sub backup_download {
    my $self       = shift;
    my $backup_dbh = $self->app->db;
    my $backup_id  = $self->param('id');

    my $sth = $backup_dbh->prepare(
        "SELECT id, creation_time, filename FROM Backup WHERE Backup.id=?");
    $sth->execute($backup_id);

    my $backup_dir_absolute = $self->config->{backups_dir};
    $backup_dir_absolute
        =~ s!/*$!/!;    # makes sure that there is exactly one / at the end

    my $row      = $sth->fetchrow_hashref();
    my $filename = $row->{filename};

    my $file_path = $backup_dir_absolute . $filename;

    my $exists = 0;
    $exists = 1 if -e $file_path;

    if ( $exists == 1 ) {
        $self->write_log("downloading backup $file_path");
        $self->render_file( 'filepath' => $file_path );
    }
    else {
        $self->redirect_to( $self->get_referrer );
    }
}

####################################################################################
sub delete_backup {
    my $self       = shift;
    my $backup_dbh = $self->app->db;
    my $id         = $self->param('id');


    if ( $self->can_delete_backup($id) == 1 ) {
        do_delete_backup( $self, $id );
        $self->flash( msg => "Backup id $id deleted!" );
    }
    else{
        $self->flash( msg => "Cannot delete, backup id $id not found!" );   
    }

    # redirecting to referrer here breaks the test if the test supports redirects! why?
    # disabling redirects for test and putting here referrer allows test to pass
    $self->redirect_to($self->url_for('backup_index'));
}

####################################################################################
sub restore_backup {
    my $self = shift;
    my $dbh  = $self->app->db;
    my $id   = $self->param('id');

    say "CALL: restore_backup";

    my $backup_filename = get_backup_filename_by_id( $dbh, $id );

    my $backup_dir_absolute = $self->app->config->{backups_dir};
    $backup_dir_absolute
        =~ s!/*$!/!;    # makes sure that there is exactly one / at the end
    my $backup_file_path = $backup_dir_absolute . $backup_filename;

    do_backup_current_state( $self, "pre-restore" );
    $self->write_log("Restoring backup from file $backup_file_path");
    my $return_value = do_restore_backup_from_file( $dbh, $backup_file_path,
        $self->app->config );

    if ( $return_value == 1 ) {
        $self->flash( msg => "Backup restored successfully" );
    }
    else {
        $self->flash( msg => "Backup restore failed!" );
    }
    $self->redirect_to('backup_index');
}

####################################################################################

1;
