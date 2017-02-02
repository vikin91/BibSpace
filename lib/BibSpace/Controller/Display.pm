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
