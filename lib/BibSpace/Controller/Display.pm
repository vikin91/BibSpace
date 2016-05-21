package BibSpace::Controller::Display;

use BibSpace::Controller::Core qw(get_all_entry_ids);
use BibSpace::Controller::BackupFunctions;


use Data::Dumper;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; #because of ~~
use strict;
use warnings;
use DBI;
use Try::Tiny;

use Mojo::Base 'Mojolicious::Controller';


sub index {
    my $self = shift;
    if($self->app->is_demo){
        $self->session(user => 'demouser');
        $self->session(user_name => 'demouser');
        $self->users->record_logging_in('demouser', $self->app->db);
    }

   $self->render(template => 'display/start');
 }
 #################################################################################
sub test {
    my $self = shift;

    my $msg = "";
    my $filename = $self->app->config->{log_file};

    my $errored = 0;

    ###################
    $msg .= "<br/>"."Opening log: ";
    try{
        read_file($filename);
        $msg .= "OK ";
    }
    catch{
        $msg .= "ERROR ";
        $errored = 1;
    };

    ###################
    $msg .= "<br/>"."Connecting to DB: ";
    try{
        $self->app->db;
        $msg .= "OK ";
    }
    catch{
        $msg .= "ERROR ";
        $errored = 1;
    };
    ###################
    $msg .= "<br/>"."Reading backup dir: ";
    try{
        get_dir_size("backups");
        $msg .= "OK ";
    }
    catch{
        $msg .= "ERROR ";
        $errored = 1;
    };
    ###################
    $msg .= "<br/>"."Writing backup dir: ";
    try{
        my $bfname = $self->do_mysql_db_backup_silent("test");
        say "Creating: $bfname ";
        unlink $bfname;
        $msg .= "OK ";
    }
    catch{
        $msg .= "ERROR ";
        $errored = 1;
    };
    ###################
    

    $msg .= "<br/>"."End.";


    if($errored){
        $self->render(text => $msg, status => 500);
        return;
    }
    else{
        $self->render(text => $msg, status => 200);
    }
}
#################################################################################
sub test500 {
    my $self = shift;
    $self->render(text => 'Oops 500.', status => 500);
}
#################################################################################
sub test404 {
    my $self = shift;
    $self->render(text => 'Oops 404.', status => 404);
}
#################################################################################
sub show_log {
    my $self = shift;
    my $num = $self->param('num');

    $num = 100 unless $num;

    my $filename = $self->app->config->{log_file};

    my @lines = ();

    try{
        @lines = read_file($filename);
        if($num > $#lines){
            $num = $#lines + 1;
        }
    }
    catch{
        say "Opening log failed!"; 
        $num = 5;   
    };

    
    # @lines = reverse(@lines);
    @lines = @lines[ $#lines-$num .. $#lines ];
    chomp(@lines);

    $self->stash(lines => \@lines);
    $self->render(template => 'display/log');
}

#################################################################################

1;