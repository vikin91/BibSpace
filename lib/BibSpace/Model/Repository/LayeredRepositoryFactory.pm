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
use BibSpace::Model::Repository::Layered::LabelingsLayeredRepository;
use BibSpace::Model::Repository::Layered::MembershipsLayeredRepository;
use BibSpace::Model::Repository::Layered::TagsLayeredRepository;
use BibSpace::Model::Repository::Layered::TagTypesLayeredRepository;
use BibSpace::Model::Repository::Layered::TeamsLayeredRepository;
use BibSpace::Model::Repository::Layered::TypesLayeredRepository;
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
has '_instanceLabelingsRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceMembershipsRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceTagsRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceTagTypesRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceTeamsRepo' =>
    ( is => 'rw', does => 'Maybe[IRepository]', default => undef );
has '_instanceTypesRepo' =>
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
has '_idProviderType' => (
    is      => 'rw',
    does    => 'Maybe[IUidProvider]',
    default => undef,
    reader  => 'idProviderType'
);

=item hardReset
    Hard reset removes all instances of repositories and resets all id providers. 
    Use only for overwriting whole data set, e.g., during backup restore.
=cut

sub hardReset {
    my $self = shift;
    $self->logger->warn( "Conducting HARD RESET of all repositories and ID Providers!",
        "" . __PACKAGE__ . "->hardReset" );
    $self->_idProviderAuthor->reset if defined $self->_idProviderAuthor;
    $self->_idProviderAuthorship->reset if defined $self->_idProviderAuthorship;
    $self->_idProviderEntry->reset if defined $self->_idProviderEntry;
    $self->_idProviderException->reset if defined $self->_idProviderException;
    $self->_idProviderLabeling->reset if defined $self->_idProviderLabeling;
    $self->_idProviderMembership->reset if defined $self->_idProviderMembership;
    $self->_idProviderTag->reset if defined $self->_idProviderTag;
    $self->_idProviderTagType->reset if defined $self->_idProviderTagType;
    $self->_idProviderTeam->reset if defined $self->_idProviderTeam;
    $self->_idProviderType->reset if defined $self->_idProviderType;
    $self->{_instanceAuthorsRepo} = undef;
    $self->{_instanceAuthorshipsRepo} = undef;
    $self->{_instanceEntriesRepo} = undef;
    $self->{_instanceExceptionsRepo} = undef;
    $self->{_instanceLabelingsRepo} = undef;
    $self->{_instanceMembershipsRepo} = undef;
    $self->{_instanceTagsRepo} = undef;
    $self->{_instanceTagTypesRepo} = undef;
    $self->{_instanceTeamsRepo} = undef;
    $self->{_instanceTypesRepo} = undef;
}

=item copy_data
    Copy data copies data between layers of repositories
=cut
sub copy_data {
    my $self = shift;
    my $config  = shift;

    my $backendFrom = $config->{from};
    my $backendTo = $config->{to};

    ## TODO: check if backends with given prios exist

    $self->hardReset;
    $self->getAuthorsRepository->copy( $backendFrom, $backendTo );
    $self->getAuthorshipsRepository->copy( $backendFrom, $backendTo );
    $self->getEntriesRepository->copy( $backendFrom, $backendTo );
    $self->getExceptionsRepository->copy( $backendFrom, $backendTo );
    $self->getLabelingsRepository->copy( $backendFrom, $backendTo );
    $self->getMembershipsRepository->copy( $backendFrom, $backendTo );
    $self->getTagsRepository->copy( $backendFrom, $backendTo );
    $self->getTagTypesRepository->copy( $backendFrom, $backendTo );
    $self->getTeamsRepository->copy( $backendFrom, $backendTo );
    $self->getTypesRepository->copy( $backendFrom, $backendTo );
}

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
        $self->{_instanceExceptionsRepo} = ExceptionsLayeredRepository->new(
            _idProvider        => $self->{_idProviderException},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
        );
    }
    return $self->{_instanceExceptionsRepo};
}

sub getLabelingsRepository {
    my $self = shift;
    if ( !defined $self->{_idProviderLabeling} ) {
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
                "" . __PACKAGE__ . "->getLabelingsRepository"
            );
            die
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if ( !defined $self->{_instanceLabelingsRepo} ) {
        $self->{_instanceLabelingsRepo} = LabelingsLayeredRepository->new(
            _idProvider        => $self->{_idProviderLabeling},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
        );
    }
    return $self->{_instanceLabelingsRepo};
}

sub getMembershipsRepository {
    my $self = shift;
    if ( !defined $self->{_idProviderMembership} ) {
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
        $self->{_instanceTeamsRepo} = TeamsLayeredRepository->new(
            _idProvider        => $self->{_idProviderTeam},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
        );
    }
    return $self->{_instanceTeamsRepo};
}

sub getTypesRepository {
    my $self = shift;
    if ( !defined $self->{_idProviderTeam} ) {
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
                "" . __PACKAGE__ . "->getTypesRepository"
            );
            die
                "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if ( !defined $self->{_instanceTypesRepo} ) {
        $self->{_instanceTypesRepo} = TypesLayeredRepository->new(
            _idProvider        => $self->{_idProviderTeam},
            logger             => $self->logger,
            backendsConfigHash => $self->backendsConfigHash
        );
    }
    return $self->{_instanceTypesRepo};
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
