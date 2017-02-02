package BibSpace::Controller::Display;

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
sub index {
    my $self = shift;
    if ( $self->app->is_demo ) {
        $self->session( user      => 'demouser' );
        $self->session( user_name => 'demouser' );
    }
    $self->render( template => 'display/start' );
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

    $self->flash( msg_type=>'success', msg => "Fixture loaded into memory and mysql. Status: <pre>".$self->app->repo->lr->get_summary_string."</pre>" );
    $self->redirect_to('start');
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

    $self->flash( msg_type=>'success', msg => "Fixture stored to '".$backup->get_path."'. Status: <pre>".$self->app->repo->lr->get_summary_string."</pre>" );
    $self->redirect_to('start');
}
#################################################################################
sub copy_mysql_to_smart {
    my $self = shift;

    my @layers = $self->app->repo->lr->get_all_layers;
    foreach (@layers){ $_->hardReset };

    $self->app->repo->lr->copy_data( { from => 'mysql', to => 'smart' } );

    $self->flash( msg_type=>'success', msg => "Copied mysql => smart. Status: <pre>".$self->app->repo->lr->get_summary_string."</pre>" );
    $self->redirect_to('start');
}
#################################################################################
sub copy_smart_to_mysql {
    my $self = shift;

    my @layers = $self->app->repo->lr->get_all_layers;
    foreach (@layers){ $_->hardReset };

    $self->app->repo->lr->copy_data( { from => 'smart', to => 'mysql' } );

    $self->flash( msg_type=>'success', msg => "Copied smart => mysql. Status: <pre>".$self->app->repo->lr->get_summary_string."</pre>" );
    $self->redirect_to('start');
}
#################################################################################
sub test {
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
    $msg .= "<br/>" . "<pre>";
    $msg .= $self->app->repo->lr->get_summary_string;
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
sub test500 {
    my $self = shift;
    $self->render( text => 'Oops 500.', status => 500 );
}
#################################################################################
sub test404 {
    my $self = shift;
    $self->render( text => 'Oops 404.', status => 404 );
}
#################################################################################
sub show_log {
    my $self = shift;
    my $num  = $self->param('num');

    $num = 100 unless $num;

    my $filename = $self->app->config->{log_file};

    my @lines = ();

    try {
        @lines = read_file($filename);
        if ( $num > $#lines ) {
            $num = $#lines + 1;
        }
    }
    catch {
        say "Opening log failed!";
        $num = 5;
    };

    # @lines = reverse(@lines);
    @lines = @lines[ $#lines - $num .. $#lines ];
    chomp(@lines);

    $self->stash( lines => \@lines );
    $self->render( template => 'display/log' );
}

#################################################################################

1;
