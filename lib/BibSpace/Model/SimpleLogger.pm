package SimpleLogger;
use namespace::autoclean;


use DateTime;
use Term::ANSIColor;
use Moose;
require Bibspace::Model::ILogger;
with 'ILogger';


sub log{
    my $self=shift;
    my $type = shift; # info, warn, error, debug
    my $msg = shift; # text to log
    my $origin = shift // "unknown"; # method from where the msg originates
    my $time = DateTime->now();
    print "[$time] $type: $msg (Origin: $origin).";
    print color('reset');
    print "\n";
}

sub debug{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    print color('yellow on_blue');
    $self->log('DEBUG', $msg, $origin);
}
sub entering{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    print color('black on_yellow');
    $self->log('ENTER', $msg, $origin);
}
sub exiting{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    print color('black on_yellow');
    $self->log('EXIT', $msg, $origin);
}
sub info{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    print color('bright_blue');
    $self->log('INFO', $msg, $origin);
}
sub warn{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    print color('yellow');
    $self->log('WARNING', $msg, $origin);
}
sub error{
    my $self=shift;
    my $msg = shift;
    my $origin = shift // 'unknown';
    print color('bright_red');
    $self->log('ERROR', $msg, $origin);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;