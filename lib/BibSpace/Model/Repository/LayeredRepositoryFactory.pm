# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package LayeredRepositoryFactory;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;
use Try::Tiny;

use BibSpace::Model::IUidProvider;
use BibSpace::Model::Repository::Interface::IRepository;
use BibSpace::Model::Repository::Layered::AuthorsLayeredRepository;
use BibSpace::Model::Repository::Layered::AuthorshipsLayeredRepository;
use BibSpace::Model::Repository::Layered::EntriesLayeredRepository;
use BibSpace::Model::Repository::Layered::ExceptionsLayeredRepository;
use BibSpace::Model::Repository::Layered::LabellingsLayeredRepository;
use BibSpace::Model::Repository::Layered::MembershipsLayeredRepository;
use BibSpace::Model::Repository::Layered::TagsLayeredRepository;
use BibSpace::Model::Repository::Layered::TagTypesLayeredRepository;
use BibSpace::Model::Repository::Layered::TeamsLayeredRepository;
require BibSpace::Model::Repository::RepositoryFactory;
extends 'RepositoryFactory';

has 'backendsConfigHash' => ( is => 'rw', isa => 'Maybe[HashRef]' );
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );

# class_has = static field
# This is important to guanartee, that there is only one reposiotory per system.
# Method getxxxRepostory guarantees that defined field will not be overwritten
has '_instanceAuthorsRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceAuthorshipsRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceEntriesRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceExceptionsRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceLabellingsRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceMembershipsRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceTagsRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceTagTypesRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceTeamsRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );

has '_idProviderAuthor' => (
    is      => 'rw',
    does    => 'Maybe[IUidProvider]',
    default => undef,
    reader  => 'idProviderAuthor'
);
has '_idProviderAuthorship' => (
    is      => 'rw',
    does    => 'Maybe[IUidProvider]',
    default => undef,
    reader  => 'idProviderAuthorship'
);
has '_idProviderEntry' => (
    is      => 'rw',
    does    => 'Maybe[IUidProvider]',
    default => undef,
    reader  => 'idProviderEntry'
);
has '_idProviderException' => (
    is      => 'rw',
    does    => 'Maybe[IUidProvider]',
    default => undef,
    reader  => 'idProviderException'
);
has '_idProviderLabeling' => (
    is      => 'rw',
    does    => 'Maybe[IUidProvider]',
    default => undef,
    reader  => 'idProviderLabeling'
);
has '_idProviderMembership' => (
    is      => 'rw',
    does    => 'Maybe[IUidProvider]',
    default => undef,
    reader  => 'idProviderMembership'
);
has '_idProviderTag' => (
    is      => 'rw',
    does    => 'Maybe[IUidProvider]',
    default => undef,
    reader  => 'idProviderTag'
);
has '_idProviderTagType' => (
    is      => 'rw',
    does    => 'Maybe[IUidProvider]',
    default => undef,
    reader  => 'idProviderTagType'
);
has '_idProviderTeam' => (
    is      => 'rw',
    does    => 'Maybe[IUidProvider]',
    default => undef,
    reader  => 'idProviderTeam'
);

=item getInstance 
    This is supposed to be static constructor (factory) method.
    Unfortunately, the default constructor has not been disabled yet.
=cut

sub getInstance {
    my $self               = shift;
    my $backendsConfigHash = shift;

    die ""
        . __PACKAGE__
        . "->getInstance: repo backends not provided or not of type 'Hash'."
        unless ( ref $backendsConfigHash eq ref {} );
    if ( !defined $self->backendsConfigHash ) {
        $self->backendsConfigHash($backendsConfigHash);
    }
    return $self;
}

sub getAuthorsRepository {
    my $self = shift;
    if ( !defined $self->{_idProviderAuthor} ) {
        $self->logger->debug(
            "Initializing instance of idProviderAuthor.",
            "" . __PACKAGE__ . "->getAuthorsRepository"
        );
        my $idProviderTypeClass
            = $self->backendsConfigHash->{'idProviderType'};
        try {
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->{_idProviderAuthor} = $providerInstance;
        }
        catch {
            $self->logger->error(
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.",
                "" . __PACKAGE__ . "->getAuthorsRepository"
            );
            die
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if ( !defined $self->{_instanceAuthorsRepo} ) {
        $self->logger->debug(
            "Initializing field instanceAuthorsRepo.",
            "" . __PACKAGE__ . "->getAuthorsRepository"
        );
        $self->{_instanceAuthorsRepo} = AuthorsLayeredRepository->new(
            _idProvider        => $self->{_idProviderAuthor},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
        );
    }
    return $self->{_instanceAuthorsRepo};
}

sub getAuthorshipsRepository {
    my $self = shift;
    if ( !defined $self->{_idProviderAuthorship} ) {
        $self->logger->debug(
            "Initializing instance of idProviderAuthorship.",
            "" . __PACKAGE__ . "->getAuthorshipsRepository"
        );
        my $idProviderTypeClass
            = $self->backendsConfigHash->{'idProviderType'};
        try {
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->{_idProviderAuthorship} = $providerInstance;
        }
        catch {
            $self->logger->error(
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.",
                "" . __PACKAGE__ . "->getAuthorshipsRepository"
            );
            die
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if ( !defined $self->{_instanceAuthorshipsRepo} ) {
        $self->logger->debug(
            "Initializing field instanceAuthorshipsRepo.",
            "" . __PACKAGE__ . "->getAuthorshipsRepository"
        );
        $self->{_instanceAuthorshipsRepo}
            = AuthorshipsLayeredRepository->new(
            _idProvider        => $self->{_idProviderAuthorship},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
            );
    }
    return $self->{_instanceAuthorshipsRepo};
}

sub getEntriesRepository {
    my $self = shift;
    if ( !defined $self->{_idProviderEntry} ) {
        $self->logger->debug(
            "Initializing instance of idProviderEntry.",
            "" . __PACKAGE__ . "->getEntriesRepository"
        );
        my $idProviderTypeClass
            = $self->backendsConfigHash->{'idProviderType'};
        try {
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->{_idProviderEntry} = $providerInstance;
        }
        catch {
            $self->logger->error(
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.",
                "" . __PACKAGE__ . "->getEntriesRepository"
            );
            die
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if ( !defined $self->{_instanceEntriesRepo} ) {
        $self->logger->debug(
            "Initializing field instanceEntriesRepo.",
            "" . __PACKAGE__ . "->getEntriesRepository"
        );
        $self->{_instanceEntriesRepo} = EntriesLayeredRepository->new(
            _idProvider        => $self->{_idProviderEntry},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
        );
    }
    return $self->{_instanceEntriesRepo};
}

sub getExceptionsRepository {
    my $self = shift;
    if ( !defined $self->{_idProviderException} ) {
        $self->logger->debug(
            "Initializing instance of idProviderException.",
            "" . __PACKAGE__ . "->getExceptionsRepository"
        );
        my $idProviderTypeClass
            = $self->backendsConfigHash->{'idProviderType'};
        try {
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->{_idProviderException} = $providerInstance;
        }
        catch {
            $self->logger->error(
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.",
                "" . __PACKAGE__ . "->getExceptionsRepository"
            );
            die
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if ( !defined $self->{_instanceExceptionsRepo} ) {
        $self->logger->debug(
            "Initializing field instanceExceptionsRepo.",
            "" . __PACKAGE__ . "->getExceptionsRepository"
        );
        $self->{_instanceExceptionsRepo} = ExceptionsLayeredRepository->new(
            _idProvider        => $self->{_idProviderException},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
        );
    }
    return $self->{_instanceExceptionsRepo};
}

sub getLabellingsRepository {
    my $self = shift;
    if ( !defined $self->{_idProviderLabeling} ) {
        $self->logger->debug(
            "Initializing instance of idProviderLabeling.",
            "" . __PACKAGE__ . "->getLabellingsRepository"
        );
        my $idProviderTypeClass
            = $self->backendsConfigHash->{'idProviderType'};
        try {
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->{_idProviderLabeling} = $providerInstance;
        }
        catch {
            $self->logger->error(
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.",
                "" . __PACKAGE__ . "->getLabellingsRepository"
            );
            die
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if ( !defined $self->{_instanceLabellingsRepo} ) {
        $self->logger->debug(
            "Initializing field instanceLabellingsRepo.",
            "" . __PACKAGE__ . "->getLabellingsRepository"
        );
        $self->{_instanceLabellingsRepo} = LabellingsLayeredRepository->new(
            _idProvider        => $self->{_idProviderLabeling},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
        );
    }
    return $self->{_instanceLabellingsRepo};
}

sub getMembershipsRepository {
    my $self = shift;
    if ( !defined $self->{_idProviderMembership} ) {
        $self->logger->debug(
            "Initializing instance of idProviderMembership.",
            "" . __PACKAGE__ . "->getMembershipsRepository"
        );
        my $idProviderTypeClass
            = $self->backendsConfigHash->{'idProviderType'};
        try {
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->{_idProviderMembership} = $providerInstance;
        }
        catch {
            $self->logger->error(
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.",
                "" . __PACKAGE__ . "->getMembershipsRepository"
            );
            die
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if ( !defined $self->{_instanceMembershipsRepo} ) {
        $self->logger->debug(
            "Initializing field instanceMembershipsRepo.",
            "" . __PACKAGE__ . "->getMembershipsRepository"
        );
        $self->{_instanceMembershipsRepo}
            = MembershipsLayeredRepository->new(
            _idProvider        => $self->{_idProviderMembership},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
            );
    }
    return $self->{_instanceMembershipsRepo};
}

sub getTagsRepository {
    my $self = shift;
    if ( !defined $self->{_idProviderTag} ) {
        $self->logger->debug(
            "Initializing instance of idProviderTag.",
            "" . __PACKAGE__ . "->getTagsRepository"
        );
        my $idProviderTypeClass
            = $self->backendsConfigHash->{'idProviderType'};
        try {
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->{_idProviderTag} = $providerInstance;
        }
        catch {
            $self->logger->error(
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.",
                "" . __PACKAGE__ . "->getTagsRepository"
            );
            die
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if ( !defined $self->{_instanceTagsRepo} ) {
        $self->logger->debug(
            "Initializing field instanceTagsRepo.",
            "" . __PACKAGE__ . "->getTagsRepository"
        );
        $self->{_instanceTagsRepo} = TagsLayeredRepository->new(
            _idProvider        => $self->{_idProviderTag},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
        );
    }
    return $self->{_instanceTagsRepo};
}

sub getTagTypesRepository {
    my $self = shift;
    if ( !defined $self->{_idProviderTagType} ) {
        $self->logger->debug(
            "Initializing instance of idProviderTagType.",
            "" . __PACKAGE__ . "->getTagTypesRepository"
        );
        my $idProviderTypeClass
            = $self->backendsConfigHash->{'idProviderType'};
        try {
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->{_idProviderTagType} = $providerInstance;
        }
        catch {
            $self->logger->error(
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.",
                "" . __PACKAGE__ . "->getTagTypesRepository"
            );
            die
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if ( !defined $self->{_instanceTagTypesRepo} ) {
        $self->logger->debug(
            "Initializing field instanceTagTypesRepo.",
            "" . __PACKAGE__ . "->getTagTypesRepository"
        );
        $self->{_instanceTagTypesRepo} = TagTypesLayeredRepository->new(
            _idProvider        => $self->{_idProviderTagType},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
        );
    }
    return $self->{_instanceTagTypesRepo};
}

sub getTeamsRepository {
    my $self = shift;
    if ( !defined $self->{_idProviderTeam} ) {
        $self->logger->debug(
            "Initializing instance of idProviderTeam.",
            "" . __PACKAGE__ . "->getTeamsRepository"
        );
        my $idProviderTypeClass
            = $self->backendsConfigHash->{'idProviderType'};
        try {
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->{_idProviderTeam} = $providerInstance;
        }
        catch {
            $self->logger->error(
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.",
                "" . __PACKAGE__ . "->getTeamsRepository"
            );
            die
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if ( !defined $self->{_instanceTeamsRepo} ) {
        $self->logger->debug(
            "Initializing field instanceTeamsRepo.",
            "" . __PACKAGE__ . "->getTeamsRepository"
        );
        $self->{_instanceTeamsRepo} = TeamsLayeredRepository->new(
            _idProvider        => $self->{_idProviderTeam},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
        );
    }
    return $self->{_instanceTeamsRepo};
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
