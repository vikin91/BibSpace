# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package LayeredRepository;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;
use MooseX::StrictConstructor;
use Try::Tiny;
use List::Util qw(first);

use BibSpace::Model::IUidProvider;
use BibSpace::Model::SmartUidProvider;
use BibSpace::Model::Repository::RepositoryLayer;

has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );
# layer_name => RepositoryLayer
has 'layers' => ( is => 'ro', isa => 'HashRef[RepositoryLayer]', traits => ['DoNotSerialize'], default => sub{ {} } );
has 'uidProvider' => ( is => 'rw', isa => 'SmartUidProvider', required => 1 );

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
    die "Read layer in the repo not found!" if !defined $readLayer;
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
    return $self->layers->{$name};
}


=item replace_layer
    Replaces layer named $name in the repo with an input layer object (e.g., from backup).
    Sets all id providers (no copy, replace!) in all layers to the id provider of the input layer.
=cut
sub replace_layer {
    my $self = shift;
    my $name = shift;
    my $input_layer = shift;
    $self->layers->{$name} = $input_layer;
    $self->replace_uid_provider($input_layer->uidProvider);
}

=item add_layer
    Adds new layer to the layered repository.
    Sets id provider (no copy, replace!) to this layer
=cut
sub add_layer {
    my $self = shift;
    my $layer = shift;
    $layer->uidProvider($self->uidProvider);
    $self->layers->{$layer->name} = $layer;
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


=item reset_uid_providers
    Resets main id provider (loacted in $self->uidProvider) state.
    This id provider is referenced by all layers!
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
    my @layer_names;
    foreach my $layer ($self->get_all_layers){
        push @layer_names, "CNT_".$layer->name;
        push @layer_names, "ID_".$layer->name;
        $count_hash{"CNT_".$layer->name} = $layer->get_summary_hash;
        $count_hash{"ID_".$layer->name} = $layer->get_id_provider_summary_hash;
    }
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
    foreach my $entity (sort LayeredRepository->get_models ){
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

sub get_summary_string {
    my $self = shift;
    my $str = "\n";
    foreach my $layer ($self->get_all_layers){
        $str .= $layer->get_summary_string;
        $str .= "\n";
    }
    return $str;
}



=item copy_data
    Copies data between layers of repositories. 
    Does not change the uid_providers (there is one global)
=cut
sub copy_data {
    my $self = shift;
    my $config  = shift;

    my $backendFrom = $config->{from};
    my $backendTo = $config->{to};
    
    my $srcLayer = $self->get_layer($backendFrom);
    my $destLayer = $self->get_layer($backendTo);

    # this is probably not necessary
    my $src_uidProvider = $srcLayer->uidProvider;
    $destLayer->uidProvider($src_uidProvider);

    ## avoid data duplication in the destination layer!!
    $destLayer->reset_data; # this has unfortunately no meaning for mysql :( need to implement this
    
    # ALWAYS: first copy entities, then relations

    $self->logger->debug("Copying data from layer '$backendFrom' to layer '$backendTo'.","".__PACKAGE__."->copy_data");

    foreach my $type ( LayeredRepository->get_entities ){
        
        my @resultRead = $srcLayer->all($type);
        my $resultSave = $destLayer->save($type, @resultRead);
        
        $self->logger->debug("'$backendFrom'->read ".scalar(@resultRead)." objects '".$type."' ==> '$backendTo'->save $resultSave objects.","".__PACKAGE__."->copy_data");
        
    }
    foreach my $type ( LayeredRepository->get_relations ){
        my @resultRead = $srcLayer->all($type);
        my $resultSave = $destLayer->save($type, @resultRead);
        
        $self->logger->debug("'$backendFrom'->read ".scalar(@resultRead)." objects '".$type."' ==> '$backendTo'->save $resultSave objects.","".__PACKAGE__."->copy_data");
        
    }
}

# logic of the layered repository = read from one layer, write to all layer

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
