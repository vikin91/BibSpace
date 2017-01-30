# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package RepositoryLayer;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;
use Try::Tiny;

use BibSpace::Model::IUidProvider;
use BibSpace::Model::DAO::SmartArrayDAOFactory;
use BibSpace::Model::DAO::MySQLDAOFactory;
use BibSpace::Model::DAO::RedisDAOFactory;
use BibSpace::Model::SmartUidProvider;

has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );
has 'handle' => ( is => 'ro', isa => 'Maybe[Object]', required => 1 );

=item backendType
    Stores the name of the DAO Factory for this layer. E.g. SmartArrayDaoFactory
=cut
has 'backendFactoryName' => ( is => 'ro', isa => 'Str', required => 1);

has 'uidProvider' => ( is => 'rw', isa => 'Maybe[SmartUidProvider]', default => undef );




=item hardReset
    Hard reset removes all instances of repositories and resets all id providers. 
    Use only for overwriting whole data set, e.g., during backup restore.
=cut

sub hardReset {
    my $self = shift;
    $self->logger->warn( "Conducting HARD RESET of all repositories and ID Providers!",
        "" . __PACKAGE__ . "->hardReset" );
    $self->uidProvider->reset if defined $self->uidProvider;
}

sub dispatcher {
    my $self = shift;
    my $factory = shift;
    my $type = shift;

    $self->logger->debug("Dispatcher searches for: '$type' using factory '$factory'", "" . __PACKAGE__ . "->dispatcher");

    if( $type eq 'TagType' ) { 
        return $factory->getTagTypeDao($self->uidProvider->get_provider($type)); 
    }
    if( $type eq 'Team' ) { 
        return $factory->getTeamDao($self->uidProvider->get_provider($type)); 
    }
    if( $type eq 'Author' ) { 
        return $factory->getAuthorDao($self->uidProvider->get_provider($type)); 
    }
    if( $type eq 'Authorship' ) { 
        return $factory->getAuthorshipDao($self->uidProvider->get_provider($type)); 
    }
    if( $type eq 'Membership' ) { 
        return $factory->getMembershipDao($self->uidProvider->get_provider($type)); 
    }
    if( $type eq 'Entry' ) { 
        return $factory->getEntryDao($self->uidProvider->get_provider($type)); 
    }
    if( $type eq 'Labeling' ) { 
        return $factory->getLabelingDao($self->uidProvider->get_provider($type)); 
    }
    if( $type eq 'Tag' ) { 
        return $factory->getTagDao($self->uidProvider->get_provider($type)); 
    }
    if( $type eq 'Exception' ) { 
        return $factory->getExceptionDao($self->uidProvider->get_provider($type)); 
    }
    if( $type eq 'Type' ) { 
        return $factory->getTypeDao($self->uidProvider->get_provider($type)); 
    }
    $self->logger->error("Requested unknown entity type: '$type'", "" . __PACKAGE__ . "->dispatcher");
    die "Requested unknown type: '$type'";
}


sub getDao {
    my $self = shift;
    my $type = shift;
    my $daoAbstractFactory = DAOFactory->new(logger => $self->logger);
    my $daoFactory = $daoAbstractFactory->getInstance($self->backendFactoryName, $self->handle);
    return $self->dispatcher($daoFactory, $type);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
