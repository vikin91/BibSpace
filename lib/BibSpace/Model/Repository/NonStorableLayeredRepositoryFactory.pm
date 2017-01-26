# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package NonStorableLayeredRepositoryFactory;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;
use Try::Tiny;

use BibSpace::Model::IUidProvider;
use BibSpace::Model::Repository::Interface::IRepository;
require BibSpace::Model::Repository::StorableLayeredRepositoryFactory;

extends 'RepositoryFactory';

has 'backendsConfigHash' => ( is => 'rw', isa => 'Maybe[HashRef]', traits => ['DoNotSerialize'], default => undef );
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );
has 'LRF' => ( is => 'ro', isa => 'StorableLayeredRepositoryFactory', builder => '_buildStorableLRF', lazy =>0 );

sub _buildStorableLRF {
    my $self = shift;
    return StorableLayeredRepositoryFactory->new(logger => SimpleLogger->new);
}

sub getInstance {
    my $self               = shift;
    my $backendsConfigHash = shift;


    die ""
        . __PACKAGE__
        . "->getInstance: repo backends not provided or not of type 'Hash', but '".ref($backendsConfigHash)."'"
        unless ( ref $backendsConfigHash eq ref {} );

    if ( !defined $self->backendsConfigHash ) {
        $self->backendsConfigHash($backendsConfigHash);
    }
    return $self;
}

sub hardReset {
    my $self = shift;
    return $self->LRF->hardReset($self->backendsConfigHash);
}

=item copy_data
    Copy data copies data between layers of repositories
=cut
sub copy_data {
    my $self = shift;
    my $config  = shift;
    $self->LRF->copy_data($self->backendsConfigHash, $config);
}
before 'copy_data' => sub { shift->logger->debug("entering","".__PACKAGE__."->copy_data"); };
after 'copy_data'  => sub { shift->logger->debug("exiting","".__PACKAGE__."->copy_data"); };

sub getAuthorsRepository {
    my $self = shift;
    use Data::Dumper;
    print "!!!!!!!!!!".Dumper $self->backendsConfigHash;
    return $self->LRF->getAuthorsRepository($self->backendsConfigHash);
}
before 'getAuthorsRepository' => sub { shift->logger->debug("entering","".__PACKAGE__."->getAuthorsRepository"); };
after 'getAuthorsRepository'  => sub { shift->logger->debug("exiting","".__PACKAGE__."->getAuthorsRepository"); };

sub getAuthorshipsRepository {
    my $self = shift;
    return $self->LRF->getAuthorshipsRepository($self->backendsConfigHash);
}

sub getEntriesRepository {
    my $self = shift;
    return $self->LRF->getEntriesRepository($self->backendsConfigHash);
}

sub getExceptionsRepository {
    my $self = shift;
    return $self->LRF->getExceptionsRepository($self->backendsConfigHash);
}

sub getLabelingsRepository {
    my $self = shift;
    return $self->LRF->getLabelingsRepository($self->backendsConfigHash);
}

sub getMembershipsRepository {
    my $self = shift;
    return $self->LRF->getMembershipsRepository($self->backendsConfigHash);
}

sub getTagsRepository {
    my $self = shift;
    return $self->LRF->getTagsRepository($self->backendsConfigHash);
}

sub getTagTypesRepository {
    my $self = shift;
    return $self->LRF->getTagTypesRepository($self->backendsConfigHash);
}

sub getTeamsRepository {
    my $self = shift;
    return $self->LRF->getTeamsRepository($self->backendsConfigHash);
}

sub getTypesRepository {
    my $self = shift;
    return $self->LRF->getTypesRepository($self->backendsConfigHash);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
