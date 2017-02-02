# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package LayeredRepository;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;
use Try::Tiny;
use List::Util qw(first);

use BibSpace::Model::IUidProvider;
use BibSpace::Model::SmartUidProvider;
use BibSpace::Model::Repository::RepositoryLayer;

has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );
# layer_name => RepositoryLayer
has 'layers' => ( is => 'ro', isa => 'HashRef[RepositoryLayer]', traits => ['DoNotSerialize'], default => sub{ {} } );
has 'uidProvider' => ( is => 'rw', isa => 'SmartUidProvider', required => 1 );




=item get_read_layer
    Returns layer designated for reading
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

=item get_write_layers
    Returns layers(!) designated for writing
=cut
sub get_write_layers {
    my $self = shift;
    my @all = $self->get_all_layers;
    my @writeLayers = sort {$a->priority <=> $b->priority} grep {not $_->is_read} @all;
    return @writeLayers;
}

sub get_layer {
    my $self = shift;
    my $name = shift;
    return $self->layers->{$name};
}


sub replace_layer {
    my $self = shift;
    my $name = shift;
    my $layer = shift;
    $self->layers->{$name} = $layer;
}


sub add_layer {
    my $self = shift;
    my $layer = shift;
    $layer->uidProvider($self->uidProvider);
    $self->layers->{$layer->name} = $layer;
}


sub set_uid_provider {
    my $self = shift;
    my $uidProvider = shift;
    $self->uidProvider($uidProvider);
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

=item hardReset
    Hard reset removes all instances of repositories and resets all id providers. 
    Use only for overwriting entire data set, e.g., during backup restore.
=cut

sub hardReset {
    my $self = shift;
    $self->get_read_layer->hardReset if defined $self->get_read_layer;
}

=item copy_data
    Copy data copies data between layers of repositories
=cut
sub copy_data {
    my $self = shift;
    my $config  = shift;

    my $backendFrom = $config->{from};
    my $backendTo = $config->{to};

    my @types = qw(TagType Team Author Authorship Membership Entry Labeling Tag Exception Type User);

    $self->hardReset;
    my $srcLayer = $self->get_layer($backendFrom);
    my $destLayer = $self->get_layer($backendTo);
    foreach my $type (@types){
        $self->logger->info("Copying all objects of type '".$type."' from layer '$backendFrom' to layer '$backendTo'.","".__PACKAGE__."->copy_data");
        my @resultRead = $srcLayer->all($type);
        $self->logger->info("Read ".scalar(@resultRead)." objects of type '".$type."' from layer '$backendFrom'.","".__PACKAGE__."->copy_data");
        my $resultSave = $destLayer->save($type, @resultRead);
        $self->logger->info("Saved $resultSave objects of type '".$type."' to layer '$backendTo'.","".__PACKAGE__."->copy_data");
        
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
