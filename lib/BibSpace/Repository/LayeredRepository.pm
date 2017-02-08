# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package LayeredRepository;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;
use feature qw( state say );
use MooseX::StrictConstructor;
use Try::Tiny;
use List::Util qw(first);
use Scalar::Util qw( refaddr );

use BibSpace::Util::IUidProvider;
use BibSpace::Util::SmartUidProvider;
use BibSpace::Repository::RepositoryLayer;
use BibSpace::Util::EntityFactory;

# logic of the layered repository = read from one layer, write to all layers

has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );
has 'preferences' => ( is => 'ro', isa => 'Preferences', required => 1);

sub BUILD {
    my $self = shift;

    my $uidP = SmartUidProvider->new(
        logger              => $self->logger,
        idProviderClassName => 'IntegerUidProvider'
    );
    $self->uidProvider($uidP);

    my $e_factory = EntityFactory->new(
            logger => $self->logger, 
            id_provider => $self->uidProvider,
            preferences => $self->preferences 
    );
    $self->e_factory($e_factory);
}
# will be set in the post-construction routine BUILD
has 'uidProvider' => ( is => 'rw', isa => 'SmartUidProvider');
# will be set in the post-construction routine BUILD
has 'e_factory' => ( is => 'rw', isa => 'EntityFactory');





# layer_name => RepositoryLayer
has 'layers' => ( 
        is => 'ro', 
        isa => 'HashRef[RepositoryLayer]', 
        traits => ['DoNotSerialize'], 
        default => sub{ {} } 
);


# static methods
class_has 'entities' => (
        is => 'ro', 
        isa => 'ArrayRef[Str]', 
        default => sub{
            ['TagType', 'Team', 'Author', 'Entry', 'Tag', 'Type', 'User']
        },
        traits  => ['Array'],
        handles => {
          get_entities    => 'elements',
      },
);
class_has 'relations' => (
        is => 'ro', 
        isa => 'ArrayRef[Str]', 
        default => sub{
            ['Authorship', 'Membership', 'Labeling', 'Exception']
        },
        traits  => ['Array'],
        handles => {
          get_relations    => 'elements',
      },
);

class_has 'models' => (
        is => 'ro', 
        isa => 'ArrayRef[Str]', 
        default => sub {
            return [ LayeredRepository->get_entities, LayeredRepository->get_relations];
        },
        traits  => ['Array'],
        handles => {
          get_models  => 'elements',
      },
);


=item get_read_layer
    Returns layer designated for reading. Throws exception if no read layer found
=cut
sub get_read_layer {
    my $self = shift;
    my $readLayer = first {$_->is_read} $self->get_all_layers;
    return $readLayer;
}

=item get_all_layers
    Returns all layers
=cut
sub get_all_layers {
    my $self = shift;
    return sort {$a->priority <=> $b->priority} values %{ $self->layers };
}

=item get_layer
    Searches for layer named $name in the repo and returs it.
=cut
sub get_layer {
    my $self = shift;
    my $name = shift;
    if( exists $self->layers->{$name} ){
        return $self->layers->{$name};
    }
    return;
}


=item replace_layer
    Replaces layer named $name in the repo with an input_layer object (e.g., from backup).
    Sets id providers (no copy, replace!) in all layers to the id provider of the input layer.
=cut
sub replace_layer {
    my $self = shift;
    my $name = shift;
    my $input_layer = shift;

    my $destLayer = $self->get_layer($name);
    if( ref($destLayer) ne ref($input_layer) ){
        $self->logger->error("Replacing layers with of different type, this will lead to a failure!");
        die "Replacing layers with of different type, this will lead to a failure!";
    }
    if($destLayer and $input_layer->is_read != $destLayer->is_read){
        $self->logger->warn("Replacing layers with different is_read value! This is experimental!");
    }
    delete $self->layers->{$name};
    $self->layers->{$name} = $input_layer;

    ## START TRANSACTION - you really need to do all of this together
    $self->logger->debug("Replacing ID PROVIDER for all layers!");
    $self->replace_uid_provider($input_layer->uidProvider);
    $self->logger->debug("Replacing E_FACTORY for all layers!");
    # e_factory has also id_providers, so it must be replaced
    # I am 95% sure that the id_providers form e_factory are references to $input_layer->uidProvider;
    # if this is not the case, then we will encounter errors by restoring backups
    $self->replace_e_factory($input_layer->e_factory); 
    $self->e_factory->id_provider($input_layer->uidProvider);
    ## COMMIT TRANSACTION
}

=item replace_uid_provider
    Replaces main id provider (loacted in $self->uidProvider) state.
    This id provider is referenced by all layers!
=cut
sub replace_uid_provider {
    my $self = shift;
    my $input_id_provider = shift;
    $self->uidProvider($input_id_provider);
    foreach my $layer ($self->get_all_layers){
        $layer->uidProvider($input_id_provider);
    }
}

=item replace_uid_provider
    Replaces main id provider (loacted in $self->uidProvider) state.
    This id provider is referenced by all layers!
=cut
sub replace_e_factory {
    my $self = shift;
    my $input_e_factory = shift;
    $self->e_factory($input_e_factory);
    foreach my $layer ($self->get_all_layers){
        $layer->e_factory($input_e_factory);
    }
}


=item add_layer
    Adds new layer to the layered repository.
    Sets id provider (no copy, replace!) to this layer
=cut
sub add_layer {
    my $self = shift;
    my $layer = shift;

    if(exists $self->layers->{$layer->name}){
        die "Layer with such name already exist.";
    }
    if($layer->is_read and $self->get_read_layer){
        die "There can be only one read layer.";
    }
    $layer->e_factory($self->e_factory);
    $layer->uidProvider($self->uidProvider);
    $self->layers->{$layer->name} = $layer;
}




=item reset_uid_providers
    Resets main id provider (loacted in $self->uidProvider) state.
    This id provider is referenced by all layers! 
    You reset here, and all id_provider references in the layers will be reset as well.
=cut
sub reset_uid_providers {
    my $self = shift;
    # $self->uidProvider is a container that is referenced directly by all layers!
    $self->uidProvider->reset;
}

sub get_summary_table {
    my $self = shift;
    my $str = "\n";
    # get_id_provider_summary_hash

    my %count_hash; #layer_name => summary_hash
    my @prefixes = qw(CNT_ ID_);
    my @column_name = map{$_."OK"} @prefixes;
    foreach my $layer ($self->get_all_layers){
        push @column_name, "CNT_".$layer->name;
        push @column_name, "ID_".$layer->name;
        $count_hash{"CNT_".$layer->name} = $layer->get_summary_hash;
        $count_hash{"ID_".$layer->name} = $layer->get_id_provider_summary_hash;
    }

    my $tab_width = 91;

    # calc CHECK status
    foreach my $entity (sort LayeredRepository->get_models ){
        foreach my $prefix (@prefixes){
            $count_hash{$prefix.'OK'}->{$entity} = 'y';
            my $val;
            foreach my $ln (reverse sort map {$_->name} $self->get_all_layers){
                if( !defined $val ){
                    $val = "".$count_hash{$prefix.$ln}->{$entity};
                }
                if($count_hash{$prefix.$ln}->{$entity} ne $val){
                    $count_hash{$prefix.'OK'}->{$entity} = 'NO';
                }
            }
        }
    }
    
    # print column names
    for (1..$tab_width) { $str .= "-"; } 
    $str .= "\n";
    $str .= sprintf "| %-15s |", 'entity';
    foreach my $ln (reverse sort @column_name){
        $str .= sprintf " %-9s |", $ln;
    }
    $str .= "\n";
    for (1..$tab_width) { $str .= "-"; }
    $str .= "\n";
    # print data
    foreach my $entity (sort LayeredRepository->get_models ){
        $str .= sprintf "| %-15s |", $entity;
        foreach my $ln (reverse sort @column_name){
            $str .= sprintf " %9s |", $count_hash{$ln}->{$entity};
        }
        $str .= "\n";
    }
    for (1..$tab_width) { $str .= "-"; }
    $str .= "\n";
    $str .= "IF YOU SEE ANY 'NO' IN ANY '_OK' COLUMN THEN MANIPULATING DATA IN THE SYSTEM MAY LEAD TO DATA LOSS OR EXCEPTIONS!";
    return $str;
}





=item copy_data
    Copies data between layers of repositories. 
    Does not change the uid_providers (there is one global)
    Remember: If you move data FROM layer, which creates_on_read==true,
        then you need to reset id_providers.
=cut

# refactor this nicely into a single function - load dump fixture or so...
# IMPORTANT FIXME: this should be always called when entire dataset in smart array is replaced!!
# $self->app->repo->lr->get_read_layer->reset_data;
# $self->app->repo->lr->reset_uid_providers;
# $self->repo->lr->copy_data( { from => 'mysql', to => 'smart' } );

sub copy_data {
    my $self = shift;
    my $config  = shift;

    my $backendFrom = $config->{from};
    my $backendTo = $config->{to};
    
    my $srcLayer = $self->get_layer($backendFrom);
    my $destLayer = $self->get_layer($backendTo);

    if(!$srcLayer or !$destLayer){
        $self->logger->error("Cannot copy data from layer '$backendFrom' to layer '$backendTo' - one or more layers do not exist.");
        return;
    }


    # $self->logger->debug("State before reset_uid_providers: ".$self->get_summary_table);

    if( $srcLayer->creates_on_read ){
        $self->logger->warn("Resetting all uid providers during copy from layer '$backendFrom' to layer '$backendTo'.");
        $self->reset_uid_providers;
    }

    # # Copy uid_provider from srcLayer to all layers
    # # A) smart -> mysql
    # # B) mysql -> smart
    # $self->replace_uid_provider($srcLayer->uidProvider);

    # $self->logger->debug("State before reset data:".$self->get_summary_table);
    ## avoid data duplication in the destination layer!!
    $destLayer->reset_data; # this has unfortunately no meaning for mysql :( need to implement this
    
    # ALWAYS: first copy entities, then relations

    $self->logger->debug("Copying data from layer '$backendFrom' to layer '$backendTo'.");

    # $self->logger->debug("State before copying:".$self->get_summary_table);

    foreach my $type ( LayeredRepository->get_entities ){
        
        # $self->logger->debug("reading from '$backendFrom'.");

        my @resultRead = $srcLayer->all($type);

        # $self->logger->debug("saving to '$backendTo'.");
        
        my $resultSave = $destLayer->save($type, @resultRead);
        
        $self->logger->debug("'$backendFrom'-read ".scalar(@resultRead)." objects '".$type."' ==> '$backendTo'-write $resultSave objects.");
        
    }
    foreach my $type ( LayeredRepository->get_relations ){

        my @resultRead = $srcLayer->all($type);
        my $resultSave = $destLayer->save($type, @resultRead);
        
        $self->logger->debug("'$backendFrom'-read ".scalar(@resultRead)." objects '".$type."' ==> '$backendTo'-write $resultSave objects.");
        
    }
}



sub all {
    my $self = shift;
    my $type = shift;
    return $self->get_read_layer->all($type);
}

sub count {
    my ($self, $type) = @_;
    return $self->get_read_layer->count($type);
}

sub empty {
    my ($self, $type) = @_;
    return $self->get_read_layer->empty($type);
}

sub exists {
    my ($self, $type, $obj) = @_;
    return $self->get_read_layer->exists($type, $obj);
}

sub save {
    my ($self, $type, @objects) = @_;
    foreach my $layer ($self->get_all_layers){
        $layer->save($type, @objects);
    }
}

sub update {
    my ($self, $type, @objects) = @_;
    foreach my $layer ($self->get_all_layers){
        $layer->update($type, @objects);
    }
}

sub delete {
    my ($self, $type, @objects) = @_;
    foreach my $layer ($self->get_all_layers){
        $layer->delete($type, @objects);
    }
}


sub filter {
    my ($self, $type, $coderef) = @_;
    return $self->get_read_layer->filter($type, $coderef);
}

sub find {
    my ($self, $type, $coderef) = @_;
    return $self->get_read_layer->find($type, $coderef);
}



__PACKAGE__->meta->make_immutable;
no Moose;
1;
