# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T14:12:39
package RepositoryFactory;
use namespace::autoclean;
use Moose;
use BibSpace::Model::ILogger;
require BibSpace::Model::Repository::LayeredRepositoryFactory;

# this class has logger, because it may want to log somethig as well 
# thic code forces to instantiate the abstract factory first and then calling getInstance
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);

=item _sortBackends 
    Sorts backends based on prio. Lower prio = more important for reading = probably faster backend.
    Perl Tip: The '_' means that the method is private.
=cut
sub _sortBackends {
    my $self = shift;
    my $backendsConfigHash = shift;

    my @sortedBackendConfigs = sort { $a->{'prio'} <=> $b->{'prio'}} @{ $backendsConfigHash->{'backends'} };
    $backendsConfigHash->{'backends'} = \@sortedBackendConfigs;
    return $backendsConfigHash;
}

sub getInstance {
    my $self        = shift;
    my $factoryType = shift;
    my $backendsConfigHash     = shift;

    die "Factory type not provided!" unless $factoryType;
    die "Repository backends not provided!" unless defined $backendsConfigHash;

    $backendsConfigHash = $self->_sortBackends($backendsConfigHash);

    my $concreteFactoryClass = $factoryType;
    try{
        Class::Load::load_class($concreteFactoryClass);
        return $concreteFactoryClass->new(logger=> $self->logger)->getInstance( $backendsConfigHash );
    }
    catch{
        die "Requested unknown type of RepositoryFactory: '$concreteFactoryClass'.";
    };
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
