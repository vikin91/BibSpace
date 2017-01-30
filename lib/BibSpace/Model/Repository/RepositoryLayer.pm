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

has 'name' => ( is => 'ro', isa => 'Str', required => 1 );

# lower number = higher priority = will be saved before layers with lower priority
has 'priority' => ( is => 'ro', isa => 'Int', default => 99 );
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );
has 'handle' => ( is => 'ro', isa => 'Object', required => 1 );
has 'is_read' => ( is => 'ro', isa => 'Bool', default => undef );

=item backendFactoryName
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
    try{
        $self->handle->hardReset;
    }
    catch{
        # we ignore if the handle cannot be reset 
        # e.g. MySQL database should not be reset - it does persistence, 
        # but our SmartArray should - it does caching
    };
}

sub dispatcher {
    my $self = shift;
    my $factory = shift;
    my $type = shift;

    # $self->logger->debug("Dispatcher searches for: '$type' using factory '$factory'", "" . __PACKAGE__ . "->dispatcher");

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

sub get_summary_string {
    my $self = shift;

    # TODO: this line is duplicated code
    my @types = qw(TagType Team Author Authorship Membership Entry Labeling Tag Exception Type);
    my $str;
    $str .= "Layer '".$self->name."'->";
    foreach my $type (@types){
        my $cnt = $self->count($type);
        $str .= "'$type'";
        $str .= sprintf "#'%-5s',", $cnt;
    }
    return $str;
}


sub all {
    my ($self, $type) = @_;
    # $self->logger->debug("Calling all for type '$type' on layer '".$self->name."'", "".__PACKAGE__."->all");
    return $self->getDao($type)->all;
}

sub count {
    my ($self, $type) = @_;
    return $self->getDao($type)->count;
}

sub empty {
    my ($self, $type) = @_;
    return $self->getDao($type)->empty;
}

sub exists {
    my ($self, $type, $obj) = @_;
    return $self->getDao($type)->exists($obj);
}

sub save {
    my ($self, $type, @objects) = @_;
    # $self->logger->debug("Calling save for type '$type' on layer '".$self->name."'", "".__PACKAGE__."->save");
    # $self->logger->debug("Calling save for objects '@objects' on layer '".$self->name."'", "".__PACKAGE__."->save");
    return $self->getDao($type)->save(@objects);
}

sub update {
    my ($self, $type, @objects) = @_;
    return $self->getDao($type)->update(@objects);
}

sub delete {
    my ($self, $type, @objects) = @_;
    return $self->getDao($type)->delete(@objects);
}

sub filter {
    my ($self, $type, $coderef) = @_;
    return $self->getDao($type)->filter($coderef);
}

sub find {
    my ($self, $type, $coderef) = @_;
    return $self->getDao($type)->find($coderef);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
