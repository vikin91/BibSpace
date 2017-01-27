# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package NonStorableLayeredRepositoryFactory;
use namespace::autoclean;
use Moose;
# use MooseX::ClassAttribute;
use Try::Tiny;

use BibSpace::Model::IUidProvider;
use BibSpace::Model::Repository::Interface::IRepository;
require BibSpace::Model::Repository::StorableLayeredRepositoryFactory;

# extends 'RepositoryFactory';

has 'backendsConfigHash' => ( is => 'ro', isa => 'HashRef', traits => ['DoNotSerialize'], required => 1);
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );
has '_LRF' => ( is => 'rw', isa => 'StorableLayeredRepositoryFactory', builder => '_buildStorableLRF', lazy =>0 );

sub get_storable{
    return shift->{_LRF};
}

sub set_storable{
    my ($self, $storable) = @_;
    $self->{_LRF} = $storable;
}

sub _buildStorableLRF {
    my $self = shift;
    return StorableLayeredRepositoryFactory->new(logger => SimpleLogger->new);
}


sub hardReset {
    my $self = shift;
    return $self->get_storable->hardReset($self->backendsConfigHash);
}

=item copy_data
    Copy data copies data between layers of repositories
=cut
sub copy_data {
    my $self = shift;
    my $config  = shift;
    $self->get_storable->copy_data($self->backendsConfigHash, $config);
}
# before 'copy_data' => sub { shift->logger->debug("entering","".__PACKAGE__."->copy_data"); };
# after 'copy_data'  => sub { shift->logger->debug("exiting","".__PACKAGE__."->copy_data"); };

sub getAuthorsRepository {
    my $self = shift;
    return $self->get_storable->getAuthorsRepository($self->backendsConfigHash);
}
# before 'getAuthorsRepository' => sub { shift->logger->debug("entering","".__PACKAGE__."->getAuthorsRepository"); };
# after 'getAuthorsRepository'  => sub { shift->logger->debug("exiting","".__PACKAGE__."->getAuthorsRepository"); };

sub getAuthorshipsRepository {
    my $self = shift;
    return $self->get_storable->getAuthorshipsRepository($self->backendsConfigHash);
}

sub getEntriesRepository {
    my $self = shift;
    return $self->get_storable->getEntriesRepository($self->backendsConfigHash);
}

sub getExceptionsRepository {
    my $self = shift;
    return $self->get_storable->getExceptionsRepository($self->backendsConfigHash);
}

sub getLabelingsRepository {
    my $self = shift;
    return $self->get_storable->getLabelingsRepository($self->backendsConfigHash);
}

sub getMembershipsRepository {
    my $self = shift;
    return $self->get_storable->getMembershipsRepository($self->backendsConfigHash);
}

sub getTagsRepository {
    my $self = shift;
    return $self->get_storable->getTagsRepository($self->backendsConfigHash);
}

sub getTagTypesRepository {
    my $self = shift;
    return $self->get_storable->getTagTypesRepository($self->backendsConfigHash);
}

sub getTeamsRepository {
    my $self = shift;
    return $self->get_storable->getTeamsRepository($self->backendsConfigHash);
}

sub getTypesRepository {
    my $self = shift;
    return $self->get_storable->getTypesRepository($self->backendsConfigHash);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
