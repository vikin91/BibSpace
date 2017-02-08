package ILogger;
use namespace::autoclean;
use DateTime;

use Moose::Role;

sub log{
    my $self=shift;
    my $type = shift; # info, warn, error, debug
    my $msg = shift; # text to log
    my $origin = shift // "unknown"; # method from where the msg originates
    my $time = DateTime->now();
    print "\t[$time] $type: $msg (Origin: $origin).\n";
}

sub debug{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    $self->log('debu', $msg, $origin);
}

sub lowdebug{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    $self->log('lowdebu', $msg, $origin);
}

sub entering{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    $self->log('ente', $msg, $origin);
}
sub exiting{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    $self->log('exit', $msg, $origin);
}
sub info{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    $self->log('info', $msg, $origin);
}
sub warn{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    $self->log('warn', $msg, $origin);
}
sub error{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    $self->log('erro', $msg, $origin);
}

1;