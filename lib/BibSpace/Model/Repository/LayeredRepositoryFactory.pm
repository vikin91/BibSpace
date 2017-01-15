# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T14:12:39
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

has 'backendsConfigHash' => ( is => 'rw', isa => 'Maybe[HashRef]');
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);

# class_has = static field
# This is important to guanartee, that there is only one reposiotory per system.
# Method getxxxRepostory guarantees that defined field will not be overwritten
has 'instanceAuthorsRepo' => ( is => 'rw', does => 'Maybe[IRepository]', default => undef);
has 'instanceAuthorshipsRepo' => ( is => 'rw', does => 'Maybe[IRepository]', default => undef);
has 'instanceEntriesRepo' => ( is => 'rw', does => 'Maybe[IRepository]', default => undef);
has 'instanceExceptionsRepo' => ( is => 'rw', does => 'Maybe[IRepository]', default => undef);
has 'instanceLabellingsRepo' => ( is => 'rw', does => 'Maybe[IRepository]', default => undef);
has 'instanceMembershipsRepo' => ( is => 'rw', does => 'Maybe[IRepository]', default => undef);
has 'instanceTagsRepo' => ( is => 'rw', does => 'Maybe[IRepository]', default => undef);
has 'instanceTagTypesRepo' => ( is => 'rw', does => 'Maybe[IRepository]', default => undef);
has 'instanceTeamsRepo' => ( is => 'rw', does => 'Maybe[IRepository]', default => undef);
has 'idProviderAuthor' => ( is => 'rw', does => 'Maybe[IUidProvider]', default => undef);
has 'idProviderAuthorship' => ( is => 'rw', does => 'Maybe[IUidProvider]', default => undef);
has 'idProviderEntry' => ( is => 'rw', does => 'Maybe[IUidProvider]', default => undef);
has 'idProviderException' => ( is => 'rw', does => 'Maybe[IUidProvider]', default => undef);
has 'idProviderLabeling' => ( is => 'rw', does => 'Maybe[IUidProvider]', default => undef);
has 'idProviderMembership' => ( is => 'rw', does => 'Maybe[IUidProvider]', default => undef);
has 'idProviderTag' => ( is => 'rw', does => 'Maybe[IUidProvider]', default => undef);
has 'idProviderTagType' => ( is => 'rw', does => 'Maybe[IUidProvider]', default => undef);
has 'idProviderTeam' => ( is => 'rw', does => 'Maybe[IUidProvider]', default => undef);

=item getInstance 
    This is supposed to be static constructor (factory) method.
    Unfortunately, the default constructor has not been disabled yet.
=cut
sub getInstance {
    my $self            = shift;
    my $backendsConfigHash = shift;

    die "".__PACKAGE__."->getInstance: repo backends not provided or not of type 'Hash'." unless (ref $backendsConfigHash eq ref {} );
    if( !defined $self->backendsConfigHash){
        $self->backendsConfigHash($backendsConfigHash);
    }
    return $self;
}

sub getAuthorsRepository {
    my $self = shift;
    if( !defined $self->idProviderAuthor ){
        $self->logger->debug("Initializing instance of idProviderAuthor.", "".__PACKAGE__."->getAuthorsRepository");
        my $idProviderTypeClass = $self->backendsConfigHash->{'idProviderType'};
        try{
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->idProviderAuthor($providerInstance);
        }
        catch{
            $self->logger->error("Requested unknown type of IUidProvider : '$idProviderTypeClass'.", "".__PACKAGE__."->getAuthorsRepository");
            die "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if( !defined $self->instanceAuthorsRepo ){
        $self->logger->debug("Initializing field instanceAuthorsRepo.", "".__PACKAGE__."->getAuthorsRepository");
        $self->instanceAuthorsRepo(
            AuthorsLayeredRepository->new( 
                idProvider => $self->idProviderAuthor,
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceAuthorsRepo;
}
sub getAuthorshipsRepository {
    my $self = shift;
    if( !defined $self->idProviderAuthorship ){
        $self->logger->debug("Initializing instance of idProviderAuthorship.", "".__PACKAGE__."->getAuthorshipsRepository");
        my $idProviderTypeClass = $self->backendsConfigHash->{'idProviderType'};
        try{
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->idProviderAuthorship($providerInstance);
        }
        catch{
            $self->logger->error("Requested unknown type of IUidProvider : '$idProviderTypeClass'.", "".__PACKAGE__."->getAuthorshipsRepository");
            die "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if( !defined $self->instanceAuthorshipsRepo ){
        $self->logger->debug("Initializing field instanceAuthorshipsRepo.", "".__PACKAGE__."->getAuthorshipsRepository");
        $self->instanceAuthorshipsRepo(
            AuthorshipsLayeredRepository->new( 
                idProvider => $self->idProviderAuthorship,
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceAuthorshipsRepo;
}
sub getEntriesRepository {
    my $self = shift;
    if( !defined $self->idProviderEntry ){
        $self->logger->debug("Initializing instance of idProviderEntry.", "".__PACKAGE__."->getEntriesRepository");
        my $idProviderTypeClass = $self->backendsConfigHash->{'idProviderType'};
        try{
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->idProviderEntry($providerInstance);
        }
        catch{
            $self->logger->error("Requested unknown type of IUidProvider : '$idProviderTypeClass'.", "".__PACKAGE__."->getEntriesRepository");
            die "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if( !defined $self->instanceEntriesRepo ){
        $self->logger->debug("Initializing field instanceEntriesRepo.", "".__PACKAGE__."->getEntriesRepository");
        $self->instanceEntriesRepo(
            EntriesLayeredRepository->new( 
                idProvider => $self->idProviderEntry,
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceEntriesRepo;
}
sub getExceptionsRepository {
    my $self = shift;
    if( !defined $self->idProviderException ){
        $self->logger->debug("Initializing instance of idProviderException.", "".__PACKAGE__."->getExceptionsRepository");
        my $idProviderTypeClass = $self->backendsConfigHash->{'idProviderType'};
        try{
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->idProviderException($providerInstance);
        }
        catch{
            $self->logger->error("Requested unknown type of IUidProvider : '$idProviderTypeClass'.", "".__PACKAGE__."->getExceptionsRepository");
            die "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if( !defined $self->instanceExceptionsRepo ){
        $self->logger->debug("Initializing field instanceExceptionsRepo.", "".__PACKAGE__."->getExceptionsRepository");
        $self->instanceExceptionsRepo(
            ExceptionsLayeredRepository->new( 
                idProvider => $self->idProviderException,
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceExceptionsRepo;
}
sub getLabellingsRepository {
    my $self = shift;
    if( !defined $self->idProviderLabeling ){
        $self->logger->debug("Initializing instance of idProviderLabeling.", "".__PACKAGE__."->getLabellingsRepository");
        my $idProviderTypeClass = $self->backendsConfigHash->{'idProviderType'};
        try{
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->idProviderLabeling($providerInstance);
        }
        catch{
            $self->logger->error("Requested unknown type of IUidProvider : '$idProviderTypeClass'.", "".__PACKAGE__."->getLabellingsRepository");
            die "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if( !defined $self->instanceLabellingsRepo ){
        $self->logger->debug("Initializing field instanceLabellingsRepo.", "".__PACKAGE__."->getLabellingsRepository");
        $self->instanceLabellingsRepo(
            LabellingsLayeredRepository->new( 
                idProvider => $self->idProviderLabeling,
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceLabellingsRepo;
}
sub getMembershipsRepository {
    my $self = shift;
    if( !defined $self->idProviderMembership ){
        $self->logger->debug("Initializing instance of idProviderMembership.", "".__PACKAGE__."->getMembershipsRepository");
        my $idProviderTypeClass = $self->backendsConfigHash->{'idProviderType'};
        try{
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->idProviderMembership($providerInstance);
        }
        catch{
            $self->logger->error("Requested unknown type of IUidProvider : '$idProviderTypeClass'.", "".__PACKAGE__."->getMembershipsRepository");
            die "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if( !defined $self->instanceMembershipsRepo ){
        $self->logger->debug("Initializing field instanceMembershipsRepo.", "".__PACKAGE__."->getMembershipsRepository");
        $self->instanceMembershipsRepo(
            MembershipsLayeredRepository->new( 
                idProvider => $self->idProviderMembership,
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceMembershipsRepo;
}
sub getTagsRepository {
    my $self = shift;
    if( !defined $self->idProviderTag ){
        $self->logger->debug("Initializing instance of idProviderTag.", "".__PACKAGE__."->getTagsRepository");
        my $idProviderTypeClass = $self->backendsConfigHash->{'idProviderType'};
        try{
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->idProviderTag($providerInstance);
        }
        catch{
            $self->logger->error("Requested unknown type of IUidProvider : '$idProviderTypeClass'.", "".__PACKAGE__."->getTagsRepository");
            die "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if( !defined $self->instanceTagsRepo ){
        $self->logger->debug("Initializing field instanceTagsRepo.", "".__PACKAGE__."->getTagsRepository");
        $self->instanceTagsRepo(
            TagsLayeredRepository->new( 
                idProvider => $self->idProviderTag,
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceTagsRepo;
}
sub getTagTypesRepository {
    my $self = shift;
    if( !defined $self->idProviderTagType ){
        $self->logger->debug("Initializing instance of idProviderTagType.", "".__PACKAGE__."->getTagTypesRepository");
        my $idProviderTypeClass = $self->backendsConfigHash->{'idProviderType'};
        try{
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->idProviderTagType($providerInstance);
        }
        catch{
            $self->logger->error("Requested unknown type of IUidProvider : '$idProviderTypeClass'.", "".__PACKAGE__."->getTagTypesRepository");
            die "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if( !defined $self->instanceTagTypesRepo ){
        $self->logger->debug("Initializing field instanceTagTypesRepo.", "".__PACKAGE__."->getTagTypesRepository");
        $self->instanceTagTypesRepo(
            TagTypesLayeredRepository->new( 
                idProvider => $self->idProviderTagType,
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceTagTypesRepo;
}
sub getTeamsRepository {
    my $self = shift;
    if( !defined $self->idProviderTeam ){
        $self->logger->debug("Initializing instance of idProviderTeam.", "".__PACKAGE__."->getTeamsRepository");
        my $idProviderTypeClass = $self->backendsConfigHash->{'idProviderType'};
        try{
            Class::Load::load_class($idProviderTypeClass);
            my $providerInstance = $idProviderTypeClass->new();
            $self->idProviderTeam($providerInstance);
        }
        catch{
            $self->logger->error("Requested unknown type of IUidProvider : '$idProviderTypeClass'.", "".__PACKAGE__."->getTeamsRepository");
            die "Requested unknown type of IUidProvider : '$idProviderTypeClass'.";
        };
    }
    if( !defined $self->instanceTeamsRepo ){
        $self->logger->debug("Initializing field instanceTeamsRepo.", "".__PACKAGE__."->getTeamsRepository");
        $self->instanceTeamsRepo(
            TeamsLayeredRepository->new( 
                idProvider => $self->idProviderTeam,
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceTeamsRepo;
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
