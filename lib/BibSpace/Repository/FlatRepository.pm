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
use BibSpace::Repository::RepositoryLayer;
use BibSpace::Util::EntityFactory;

has 'logger'      => (is => 'ro', does => 'ILogger',     required => 1);
has 'preferences' => (is => 'ro', isa  => 'Preferences', required => 1);
has 'facade' =>
  (is => 'rw', isa => 'Maybe[FlatRepositoryFacade]', default => undef);

sub BUILD {
  my $self      = shift;
  my $e_factory = EntityFactory->new(
    logger      => $self->logger,
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

sub get_summary_table {
  my $self = shift;
  return $self->get_layer->get_summary_table;
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
