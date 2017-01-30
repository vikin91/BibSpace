# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package LayeredRepository;
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;
use Try::Tiny;

use BibSpace::Model::IUidProvider;
use BibSpace::Model::SmartUidProvider;

has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );
# layer_name => RepositoryLayer
has 'layers' => ( is => 'rw', isa => 'Maybe[HashRef[Str]]', traits => ['DoNotSerialize'], default => sub{ {} } );
has 'uidProvider' => ( is => 'rw', isa => 'SmartUidProvider', required => 1 );




=item get_read_layer
    Returns layer designated for reading
=cut
sub get_read_layer {
    my $self = shift;
    return $self->layers->{'read'};
}

=item get_all_layers
    Returns layers(!) designated for writing
=cut
sub get_all_layers {
    my $self = shift;
    return values $self->layers;
}

=item get_write_layers
    Returns layers(!) designated for writing
=cut
sub get_write_layers {
    my $self = shift;
    return values $self->layers;
}

sub add_read_layer {
    my $self = shift;
    my $layer = shift;
    $layer->uidProvider($self->uidProvider);
    $self->layers->{'read'} = $layer;
}

sub replace_layer {
    my $self = shift;
    my $layer_name = shift;
    my $layer = shift;
    $self->layers->{$layer_name} = $layer;
}

sub add_write_layer {
    my $self = shift;
    my $layer = shift;
    $layer->uidProvider($self->uidProvider);
    my $layer_name = $self->generate_write_layer_key;
    $self->layers->{$layer_name} = $layer;
}

sub generate_write_layer_key {
    my $self = shift;
    my $layer_id = 1;
    my $layer_name = "write_$layer_id";
    while( exists($self->layers->{$layer_name}) ){
        ++$layer_id;
        $layer_name = "write_$layer_id";
    }
    return $layer_name;
}

sub set_uid_provider {
    my $self = shift;
    my $uidProvider = shift;
    $self->uidProvider($uidProvider);
}

=item hardReset
    Hard reset removes all instances of repositories and resets all id providers. 
    Use only for overwriting entire data set, e.g., during backup restore.
=cut

sub hardReset {
    my $self = shift;
    $self->read->hardReset if defined $self->read;
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

sub all {
    my $self = shift;
    my $type = shift;

    return $self->get_read_layer->getDao($type)->all;
}



__PACKAGE__->meta->make_immutable;
no Moose;
1;
