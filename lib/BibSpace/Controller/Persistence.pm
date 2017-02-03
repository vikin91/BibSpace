package BibSpace::Controller::Persistence;

use strict;
use warnings;
use utf8;
use 5.010;    #because of ~~
use File::Slurp;
use Try::Tiny;

use Data::Dumper;


use Mojo::Base 'Mojolicious::Controller';
use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Functions::Core;

#################################################################################
sub persistence_status {
    my $self = shift;

    my $status = "Status: <pre style=\"font-family:monospace;\">".$self->app->repo->lr->get_summary_table."</pre>";
    $self->flash( msg_type=>'success', msg => $status );
    $self->redirect_to( $self->get_referrer );
}
#################################################################################
sub load_fixture {
    my $self = shift;

    use BibSpace::Model::Backup;
    use BibSpace::Functions::BackupFunctions qw(restore_storable_backup);
    use BibSpace::Functions::FDB;


    my $fixture_name = "bibspace_fixture.dat";
    my $fixture_dir = "./fixture/";

    my $fixture = Backup->new(dir => $fixture_dir, filename =>$fixture_name);
  
    restore_storable_backup($fixture, $self->app);

    my $status = "Status: <pre style=\"font-family:monospace;\">".$self->app->repo->lr->get_summary_table."</pre>";
    $self->flash( msg_type=>'success', msg => "Fixture loaded into memory and mysql. $status" );
    $self->redirect_to( $self->get_referrer );
}
#################################################################################
sub save_fixture {
    my $self = shift;

    use BibSpace::Model::Backup;
    use BibSpace::Functions::BackupFunctions qw(restore_storable_backup);
    use BibSpace::Functions::FDB;

    my $fixture_name = "bibspace_fixture.dat";
    my $fixture_dir = "./fixture/";
    my $backup = Backup->create('dummy', "storable");
    $backup->dir($fixture_dir);
    $backup->filename($fixture_name);

    my $layer = $self->app->repo->lr->get_read_layer;
    my $path = "".$backup->get_path;

    $Storable::forgive_me = "do store regexp please";
    Storable::store $layer, $path;

    my $status = "Status: <pre style=\"font-family:monospace;\">".$self->app->repo->lr->get_summary_table."</pre>";
    $self->flash( msg_type=>'success', msg => "Fixture stored to '".$backup->get_path."'. $status" );
    $self->redirect_to( $self->get_referrer );
}
#################################################################################
sub copy_mysql_to_smart {
    my $self = shift;

    # my $smart_layer = $self->app->repo->lr->get_layer('smart');
    # # reading from mysql registers UIDs - all uid providers must be reset!
    # $self->app->repo->lr->reset_uid_providers;
    # $smart_layer->reset_data;

    $self->app->repo->lr->copy_data( { from => 'mysql', to => 'smart' } );

    my $status = "Status: <pre style=\"font-family:monospace;\">".$self->app->repo->lr->get_summary_table."</pre>";
    $self->flash( msg_type=>'success', msg => "Copied mysql => smart. $status" );
    $self->redirect_to( $self->get_referrer );
}
#################################################################################
sub copy_smart_to_mysql {
    my $self = shift;


    $self->app->repo->lr->copy_data( { from => 'smart', to => 'mysql' } );

    my $status = "Status: <pre style=\"font-family:monospace;\">".$self->app->repo->lr->get_summary_table."</pre>";
    $self->flash( msg_type=>'success', msg => "Copied smart => mysql. $status" );
    $self->redirect_to( $self->get_referrer );
}
#################################################################################
sub reset_smart {
    my $self = shift;

    my $layer = $self->app->repo->lr->get_layer('smart');
    $layer->reset_data;

    # no pub_admin user would lock the whole system
    $self->app->insert_admin;

    my $status = "Status: <pre style=\"font-family:monospace;\">".$self->app->repo->lr->get_summary_table."</pre>";
    $self->flash( msg_type=>'success', msg => $status );
    $self->redirect_to( $self->get_referrer );
}
#################################################################################
sub reset_mysql {
    my $self = shift;

    my $layer = $self->app->repo->lr->get_layer('mysql');
    $layer->reset_data;

    # purge_and_create_db($self->app->db, 
    #     $self->app->config->{db_host},
    #     $self->app->config->{db_user},
    #     $self->app->config->{db_database},
    #     $self->app->config->{db_pass}
    # );

    my $status = "Status: <pre style=\"font-family:monospace;\">".$self->app->repo->lr->get_summary_table."</pre>";
    $self->flash( msg_type=>'success', msg => $status );
    $self->redirect_to( $self->get_referrer );
}
#################################################################################
sub system_status {
    my $self = shift;

    my $msg      = "";
    my $log_file = $self->app->config->{log_file};

    my $backup_dir_absolute = $self->config->{backups_dir};
    $backup_dir_absolute
        =~ s!/*$!/!;    # makes sure that there is exactly one / at the end

    my $errored = 0;


    ###################
    $msg .= "<br/>" . "Connecting to DB: ";
    try {
        $self->app->db;
        $msg .= "OK ";
    }
    catch {
        $msg .= "ERROR: $_";
        $errored = 1;
    };
    ###################
    $msg .= "<br/>" . "Reading backup dir: ";
    try {
        get_dir_size("backups");
        $msg .= "OK ";
    }
    catch {
        $msg .= "ERROR: $_";
        $errored = 1;
    };
    ###################
    $msg .= "<br/>" . "Current state of persistence backends:";
    $msg .= "<br/>" . "<pre style=\"font-family:monospace;\">";
    $msg .= $self->app->repo->lr->get_summary_table;
    $msg .= "</pre>";
    ###################
    $msg .= "<br/>" . "End.";

    if ($errored) {
        $self->render( text => $msg, status => 500 );
        return;
    }
    else {
        $self->render( text => $msg, status => 200 );
    }
}
#################################################################################

1;
