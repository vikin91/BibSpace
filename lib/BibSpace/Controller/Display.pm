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
    $msg .= "<br/>" . "Writing backup dir: ";
    my $bfname = "";
    try {
        $bfname = $self->do_mysql_db_backup_silent("can-be-deleted-test");
        say "Creating: $bfname ";
        $msg .= "OK ";
    }
    catch {
        $msg .= "ERROR: $_";
        $errored = 1;
    };
    #### only one location is the correct one!
    my $test_backup_path = $bfname;
    # if ( -e $bfname ) {
    #     $test_backup_path = $bfname;
    # }
    # elsif ( -e $backup_dir_absolute . $test_backup_path ) {
    #     $test_backup_path = $backup_dir_absolute . $test_backup_path;
    # }
    # elsif ( -e $backup_dir_absolute . "\\" . $test_backup_path ) {
    #     $test_backup_path = $backup_dir_absolute . "\\" . $test_backup_path;
    # }
    # else {
    #     $msg .= "WARNING: test backup file cannot be removed: Wrong path.";
    # }

    try {
        say "Removing: $test_backup_path ";
        unlink $test_backup_path;
    }
    catch {
        $msg .= "WARNING: test backup file cannot be removed. Error: $_.";
    };
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
