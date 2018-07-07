# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package FlatRepository;
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

has 'logger'            => (is => 'ro', does => 'ILogger',     required => 1);
has 'preferences'       => (is => 'ro', isa  => 'Preferences', required => 1);
has 'id_provider_class' => (is => 'ro', isa  => 'Str',         required => 1);
has 'facade' =>
  (is => 'rw', isa => 'Maybe[FlatRepositoryFacade]', default => undef);

sub BUILD {
  my $self = shift;

  my $uidP = SmartUidProvider->new(
    logger              => $self->logger,
    idProviderClassName => $self->id_provider_class
  );
  $self->uidProvider($uidP);
  $self->layer->uidProvider($self->uidProvider);

  my $e_factory = EntityFactory->new(
    logger      => $self->logger,
    id_provider => $self->uidProvider,
    preferences => $self->preferences
  );
  $self->e_factory($e_factory);
  $self->layer->e_factory($e_factory);
}

sub set_facade {
  my $self   = shift;
  my $facade = shift;
  $self->facade($facade);
  $self->e_factory->facade($facade);
  $self->layer->e_factory->facade($facade);
}

# will be set in the post-construction routine BUILD
has 'uidProvider' => (is => 'rw', isa => 'SmartUidProvider');

# will be set in the post-construction routine BUILD
has 'e_factory' => (is => 'rw', isa => 'EntityFactory');

# layer_name => RepositoryLayer
has 'layer' => (
  is      => 'ro',
  isa     => 'RepositoryLayer',
  traits  => ['DoNotSerialize'],
  default => sub { {} }
);

# static methods
class_has 'entities' => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub {

    # ORDER IS IMPORTANT!!! TAG MUST BE AFTER TAGTYPE - it references it N:1!
    ['Author', 'Entry', 'TagType', 'Tag', 'Team', 'Type', 'User'];
  },
  traits  => ['Array'],
  handles => {get_entities => 'elements',},
);
class_has 'relations' => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub {
    ['Authorship', 'Exception', 'Labeling', 'Membership'];
  },
  traits  => ['Array'],
  handles => {get_relations => 'elements',},
);

class_has 'models' => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub {
    return [FlatRepository->get_entities, FlatRepository->get_relations];
  },
  traits  => ['Array'],
  handles => {get_models => 'elements',},
);

=item get_layer
    Returns the only layer
=cut

sub get_layer {
  my $self = shift;
  return $self->layer;
}

# For compatibility with LayeredRespository interface
sub get_all_layers {
  my $self = shift;
  return ($self->get_layer);
}

# For compatibility with LayeredRespository interface
sub get_read_layer {
  my $self = shift;
  return ($self->get_layer);
}

# For compatibility with LayeredRespository interface
sub replace_layer {
  my $self        = shift;
  my $name        = shift;
  my $input_layer = shift;

  my $destLayer = $self->get_layer($name);
  if (ref($destLayer) ne ref($input_layer)) {
    $self->logger->error(
      "Replacing layers with of different type, this will lead to a failure!");
    die "Replacing layers with of different type, this will lead to a failure!";
  }
  $self->{layer} = $input_layer;

  ## START TRANSACTION - you really need to do all of this together
  # $self->logger->debug("Replacing ID PROVIDER for all layers!");
  $self->replace_uid_provider($input_layer->uidProvider);

  # $self->logger->debug("Replacing E_FACTORY for all layers!");
  # e_factory has also id_providers, so it must be replaced
  $self->replace_e_factory($input_layer->e_factory);
  $self->e_factory->id_provider($input_layer->uidProvider);
  ## COMMIT TRANSACTION
}

# For compatibility with LayeredRespository interface
sub get_summary_table {
  my $self = shift;
  return $self->layer->get_summary_table;
}

=item replace_uid_provider
    Replaces main id provider (loacted in $self->uidProvider) state.
    This id provider is referenced by all layers!
=cut

sub replace_uid_provider {
  my $self              = shift;
  my $input_id_provider = shift;
  $self->uidProvider($input_id_provider);
  foreach my $layer ($self->get_all_layers) {
    $layer->uidProvider($input_id_provider);
  }
}

=item replace_uid_provider
    Replaces main id provider (loacted in $self->uidProvider) state.
    This id provider is referenced by all layers!
=cut

sub replace_e_factory {
  my $self            = shift;
  my $input_e_factory = shift;
  $self->e_factory($input_e_factory);
  $self->get_layer->e_factory($input_e_factory);
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

sub all {
  my $self = shift;
  my $type = shift;
  return $self->get_layer->all($type);
}

sub count {
  my ($self, $type) = @_;
  return $self->get_layer->count($type);
}

sub empty {
  my ($self, $type) = @_;
  return $self->get_layer->empty($type);
}

sub exists {
  my ($self, $type, $obj) = @_;
  return $self->get_layer->exists($type, $obj);
}

sub save {
  my ($self, $type, @objects) = @_;
  return $self->get_layer->save($type, @objects);
}

sub update {
  my ($self, $type, @objects) = @_;
  return $self->get_layer->update($type, @objects);
}

sub delete {
  my ($self, $type, @objects) = @_;
  return $self->get_layer->delete($type, @objects);
}

sub filter {
  my ($self, $type, $coderef) = @_;
  return $self->get_layer->filter($type, $coderef);
}

sub find {
  my ($self, $type, $coderef) = @_;
  return $self->get_layer->find($type, $coderef);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
