package BibSpace::Model::SimpleLogger;
use Moose;
with 'BibSpace::Model::ILogger';

sub debug{
    my $self=shift;
    my $msg = shift;
    my $time = DateTime->now();
    print "[$time] DEBU: $msg\n";
}

__PACKAGE__->meta->make_immutable;
no Moose;