package BibSpace::Controller::Display;

use strict;
use warnings;
use utf8;
use 5.010;    #because of ~~
# use File::Slurp;
use Try::Tiny;
use List::Util qw(first);

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
    my $num  = $self->param('num') // 100;
    my $type = $self->param('type');

    my $log_dir = Path::Tiny->new( $self->app->config->{log_dir} );

    my @file_list = $log_dir->children(qr/\.log$/);
    my @log_names = map { $_->basename('.log') } @file_list;


    my $log_2_read;
    $log_2_read = $log_dir->child( $type . ".log" ) if defined $type;
    $log_2_read = $log_dir->child("info.log") if !$log_2_read or !$log_2_read->exists;
    $log_2_read = shift @file_list            if !$log_2_read or !$log_2_read->exists;

    my @lines;
    try {
        # read $num lines from the end
        @lines = $log_2_read->lines( {count => -1*$num} ); 
        @lines
            = ( $num >= @lines )
            ? reverse @lines
            : reverse @lines[ -$num .. -1 ];
        chomp(@lines);
    }
    catch {
        $self->app->logger->error("Cannot find log '$type'. Error: $_.");
        $self->stash(
            msg_type => 'danger',
            msg      => "Cannot find log '$type'."
        );
    };


    $self->stash(
        files     => \@file_list,
        lines     => \@lines,
        curr_file => $log_2_read
    );
    $self->render( template => 'display/log' );
}

#################################################################################

1;
