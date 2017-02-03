# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package RepositoryLayer;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;
use MooseX::StrictConstructor;
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




=item reset_data
    Hard reset removes all instances of repositories and resets all id providers. 
    Use only for overwriting whole data set, e.g., during backup restore.
=cut

sub reset_data {
    my $self = shift;
    $self->logger->warn( "Conducting HARD RESET of data in layer '".$self->name."'!",
        "" . __PACKAGE__ . "->reset_data" );
    try{
        $self->handle->reset_data;
    }
    catch{
        # Only SmartArray supports direct reset
        if( ref($self->handle) eq 'SmartArray'){
            $self->logger->error( "Reset of ".ref($self->handle)." failed. Error $_","" . __PACKAGE__ . "->hardReset" );    
        }
        
        # we ignore if the handle cannot be reset 
        # e.g. MySQL database should not be reset - it does persistence, 
        # but our SmartArray should - it does caching
    };
}

sub daoDispatcher {
    my $self = shift;
    my $factory = shift;
    my $entity_type = shift;

    # $self->logger->debug("Dispatcher searches for: '$entity_type' using factory '$factory'", "" . __PACKAGE__ . "->daoDispatcher");

    if( $entity_type eq 'TagType' ) { 
        return $factory->getTagTypeDao($self->uidProvider->get_provider($entity_type)); 
    }
    if( $entity_type eq 'Team' ) { 
        return $factory->getTeamDao($self->uidProvider->get_provider($entity_type)); 
    }
    if( $entity_type eq 'Author' ) { 
        return $factory->getAuthorDao($self->uidProvider->get_provider($entity_type)); 
    }
    if( $entity_type eq 'Authorship' ) { 
        return $factory->getAuthorshipDao($self->uidProvider->get_provider($entity_type)); 
    }
    if( $entity_type eq 'Membership' ) { 
        return $factory->getMembershipDao($self->uidProvider->get_provider($entity_type)); 
    }
    if( $entity_type eq 'Entry' ) { 
        return $factory->getEntryDao($self->uidProvider->get_provider($entity_type)); 
    }
    if( $entity_type eq 'Labeling' ) { 
        return $factory->getLabelingDao($self->uidProvider->get_provider($entity_type)); 
    }
    if( $entity_type eq 'Tag' ) { 
        return $factory->getTagDao($self->uidProvider->get_provider($entity_type)); 
    }
    if( $entity_type eq 'Exception' ) { 
        return $factory->getExceptionDao($self->uidProvider->get_provider($entity_type)); 
    }
    if( $entity_type eq 'Type' ) { 
        return $factory->getTypeDao($self->uidProvider->get_provider($entity_type)); 
    }
    if( $entity_type eq 'User' ) { 
        return $factory->getUserDao($self->uidProvider->get_provider($entity_type)); 
    }
    $self->logger->error("Requested unknown entity_type: '$entity_type'", "" . __PACKAGE__ . "->daoDispatcher");
    die "Requested unknown entity_type: '$entity_type'";
}

=item getDao
    Returns Data Access Object (DAO) for given entity_type and backend used by layer
=cut
sub getDao {
    my $self = shift;
    my $entity_type = shift;
    my $daoAbstractFactory = DAOFactory->new(logger => $self->logger);
    my $daoFactory = $daoAbstractFactory->getInstance($self->backendFactoryName, $self->handle);
    return $self->daoDispatcher($daoFactory, $entity_type);
}

=item get_summary_hash
    Provides a summary of a layer in form of a hash.
    Has is build like this: entity_name => number of stored objects
=cut
sub get_summary_hash {
    my $self = shift;
    my %hash = map{$_ => $self->count($_)} LayeredRepository->get_models;
    return \%hash;
}

=item get_id_provider_summary_hash
    Provides a summary of a layer in form of a hash.
    Has is build like this: entity_name => last_id of idProvider
=cut
sub get_id_provider_summary_hash {
    my $self = shift;
    my %hash = map{$_ => $self->uidProvider->get_provider($_)->last_id} LayeredRepository->get_models;
    return \%hash;
}

=item get_summary_table
    Prints nice summary table for all layers. 
    Example:
    ID_X  = last id of the id_provider in layer X
    CNT_X = number of entities in layer X
    ___________________________________________________________________
    | entity          | ID_smart  | ID_mysql  | CNT_smart | CNT_mysql |
    -------------------------------------------------------------------
    | Author          |      1296 |      1296 |        74 |        74 |
    | Authorship      |         1 |         1 |       696 |       696 |
    | Entry           |      1117 |      1117 |       379 |       379 |
    | Exception       |         1 |         1 |         2 |         2 |
    | Labeling        |         1 |         1 |         6 |         6 |
    | Membership      |         1 |         1 |        27 |        27 |
    | Tag             |       231 |       231 |        50 |        50 |
    | TagType         |         4 |         4 |         4 |         4 |
    | Team            |         6 |         6 |         4 |         4 |
    | Type            |        18 |        18 |        17 |        24 |
    | User            |         1 |         1 |         1 |         1 |
    -------------------------------------------------------------------
=cut
sub get_summary_table {
    my $self = shift;
    my $str = "\n";

    my %count_hash; #layer_name => summary_hash
    my @layer_names;
    push @layer_names, "CNT_".$self->name;
    push @layer_names, "ID_".$self->name;
    $count_hash{"CNT_".$self->name} = $self->get_summary_hash;
    $count_hash{"ID_".$self->name} = $self->get_id_provider_summary_hash;
    
    my $tab_width = 67;
    
    for (1..$tab_width) { $str .= "_"; } 
    $str .= "\n";
    $str .= sprintf "| %-15s |", 'entity';
    foreach my $ln (reverse sort @layer_names){
        $str .= sprintf " %-9s |", $ln;
    }
    $str .= "\n";
    for (1..$tab_width) { $str .= "-"; }
    $str .= "\n";
    foreach my $entity (sort LayeredRepository->get_models){
        $str .= sprintf "| %-15s |", $entity;
        foreach my $ln (reverse sort @layer_names){
            $str .= sprintf " %9s |", $count_hash{$ln}->{$entity};
        }
        $str .= "\n";
    }
    for (1..$tab_width) { $str .= "-"; }
    $str .= "\n";
    return $str;
}

=item get_summary_string
    Provides a summary of a layer in form of a string.
    Similar output to get_summary_hash
=cut
sub get_summary_string {
    my $self = shift;

    my $str;
    $str .= "Layer '".$self->name."'->";
    foreach my $type ( LayeredRepository->get_models ){
        my $cnt = $self->count($type);
        $str .= "'$type'";
        $str .= sprintf "#'%-5s',", $cnt;
    }
    return $str;
}

=item all
    Returns all objects of a $type stored in this layer
=cut
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
