# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T22:33:39
package LayeredRepositoryFactory;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;

use BibSpace::Model::Repository::Interface::IAuthorsRepository;
use BibSpace::Model::Repository::Interface::IAuthorshipsRepository;
use BibSpace::Model::Repository::Interface::IEntriesRepository;
use BibSpace::Model::Repository::Interface::IExceptionsRepository;
use BibSpace::Model::Repository::Interface::ILabellingsRepository;
use BibSpace::Model::Repository::Interface::IMembershipsRepository;
use BibSpace::Model::Repository::Interface::ITagsRepository;
use BibSpace::Model::Repository::Interface::ITagTypesRepository;
use BibSpace::Model::Repository::Interface::ITeamsRepository;
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
class_has 'instanceAuthorsRepo' => ( is => 'rw', does => 'Maybe[IAuthorsRepository]', default => undef);
class_has 'instanceAuthorshipsRepo' => ( is => 'rw', does => 'Maybe[IAuthorshipsRepository]', default => undef);
class_has 'instanceEntriesRepo' => ( is => 'rw', does => 'Maybe[IEntriesRepository]', default => undef);
class_has 'instanceExceptionsRepo' => ( is => 'rw', does => 'Maybe[IExceptionsRepository]', default => undef);
class_has 'instanceLabellingsRepo' => ( is => 'rw', does => 'Maybe[ILabellingsRepository]', default => undef);
class_has 'instanceMembershipsRepo' => ( is => 'rw', does => 'Maybe[IMembershipsRepository]', default => undef);
class_has 'instanceTagsRepo' => ( is => 'rw', does => 'Maybe[ITagsRepository]', default => undef);
class_has 'instanceTagTypesRepo' => ( is => 'rw', does => 'Maybe[ITagTypesRepository]', default => undef);
class_has 'instanceTeamsRepo' => ( is => 'rw', does => 'Maybe[ITeamsRepository]', default => undef);

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

    if( !defined $self->instanceAuthorsRepo ){
        $self->logger->debug("Initializing filed instanceAuthorsRepo.", "".__PACKAGE__."->");
        $self->instanceAuthorsRepo(
            AuthorsLayeredRepository->new( 
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceAuthorsRepo;
}
sub getAuthorshipsRepository {
    my $self = shift;

    if( !defined $self->instanceAuthorshipsRepo ){
        $self->logger->debug("Initializing filed instanceAuthorshipsRepo.", "".__PACKAGE__."->");
        $self->instanceAuthorshipsRepo(
            AuthorshipsLayeredRepository->new( 
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceAuthorshipsRepo;
}
sub getEntriesRepository {
    my $self = shift;

    if( !defined $self->instanceEntriesRepo ){
        $self->logger->debug("Initializing filed instanceEntriesRepo.", "".__PACKAGE__."->");
        $self->instanceEntriesRepo(
            EntriesLayeredRepository->new( 
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceEntriesRepo;
}
sub getExceptionsRepository {
    my $self = shift;

    if( !defined $self->instanceExceptionsRepo ){
        $self->logger->debug("Initializing filed instanceExceptionsRepo.", "".__PACKAGE__."->");
        $self->instanceExceptionsRepo(
            ExceptionsLayeredRepository->new( 
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceExceptionsRepo;
}
sub getLabellingsRepository {
    my $self = shift;

    if( !defined $self->instanceLabellingsRepo ){
        $self->logger->debug("Initializing filed instanceLabellingsRepo.", "".__PACKAGE__."->");
        $self->instanceLabellingsRepo(
            LabellingsLayeredRepository->new( 
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceLabellingsRepo;
}
sub getMembershipsRepository {
    my $self = shift;

    if( !defined $self->instanceMembershipsRepo ){
        $self->logger->debug("Initializing filed instanceMembershipsRepo.", "".__PACKAGE__."->");
        $self->instanceMembershipsRepo(
            MembershipsLayeredRepository->new( 
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceMembershipsRepo;
}
sub getTagsRepository {
    my $self = shift;

    if( !defined $self->instanceTagsRepo ){
        $self->logger->debug("Initializing filed instanceTagsRepo.", "".__PACKAGE__."->");
        $self->instanceTagsRepo(
            TagsLayeredRepository->new( 
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceTagsRepo;
}
sub getTagTypesRepository {
    my $self = shift;

    if( !defined $self->instanceTagTypesRepo ){
        $self->logger->debug("Initializing filed instanceTagTypesRepo.", "".__PACKAGE__."->");
        $self->instanceTagTypesRepo(
            TagTypesLayeredRepository->new( 
                logger => $self->logger,
                backendsConfigHash => $self->backendsConfigHash 
            )
        );
    }
    return $self->instanceTagTypesRepo;
}
sub getTeamsRepository {
    my $self = shift;

    if( !defined $self->instanceTeamsRepo ){
        $self->logger->debug("Initializing filed instanceTeamsRepo.", "".__PACKAGE__."->");
        $self->instanceTeamsRepo(
            TeamsLayeredRepository->new( 
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
