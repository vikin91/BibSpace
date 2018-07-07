package SmartHash;

use v5.16;
use Try::Tiny;
use Data::Dumper;
use namespace::autoclean;

# for benchmarking
use Time::HiRes qw( gettimeofday tv_interval );

use Moose;
use Moose::Util::TypeConstraints;

use BibSpace::Backend::IBibSpaceBackend;

require BibSpace::Model::IEntity;
with 'IBibSpaceBackend';
use List::Util qw(first);
use List::MoreUtils qw(any uniq first_index);
use feature qw( say );

=item
    This is a in-memory data structure (hash) to hold all objects of BibSpace.
    It is build like this:
    String "TypeName" => Array of Objects with type TypeName.
    It could be improved for performance like this:
    String "TypeName" => { Integer UID => Object with type TypeName}.
=cut

has 'logger' => (is => 'ro', does => 'ILogger', required => 1);

has 'data' => (
  traits  => ['Hash'],
  is      => 'ro',
  isa     => 'HashRef[HashRef[BibSpace::Model::IEntity]]',
  default => sub { {} },
  handles => {
    set     => 'set',
    get     => 'get',
    has     => 'exists',
    defined => 'defined',
    keys    => 'keys',

    # values  => 'values',
    num    => 'count',
    pairs  => 'kv',
    _clear => 'clear',
  },
);

sub reset_data {
  my $self = shift;
  $self->logger->warn("Resetting SmartHash");
  $self->_clear;
}

sub dump {
  my $self = shift;
  $self->logger->debug("SmartHash keys: " . join(', ', $self->keys));
}

sub _init {
  my ($self, $type) = @_;
  die "_init requires a type!" unless $type;
  if (!$self->defined($type)) {
    $self->set($type, {});
  }

}

sub all {
  my ($self, $type) = @_;
  die "all requires a type!" unless $type;
  $self->_init($type);
  my $href = $self->get($type);

  my @result;
  if ($href) {
    @result = values %$href;
  }
  return @result;
}

sub _add {
  my ($self, @objects) = @_;
  return if scalar(@objects) == 0;

  my $type = ref($objects[0]);

  $self->_init($type);
  my $href = $self->get($type);

  my $num_added = 0;
  foreach my $obj (@objects) {
    $href->{$obj->id} = $obj;
    $num_added++;
  }
  return $num_added;
}

sub save {
  my ($self, @objects) = @_;
  return $self->_add(@objects);
}

sub count {
  my ($self, $type) = @_;
  die "all requires a type!" unless $type;
  return 0 if $self->empty($type);

  $self->_init($type);
  my $href = $self->get($type);
  return scalar keys %$href;
}

sub empty {
  my ($self, $type) = @_;
  $self->_init($type);
  my $href = $self->get($type);
  return scalar(keys %$href) == 0;
}

sub exists {
  my ($self, $object) = @_;
  my $type = ref($object);
  $self->logger->error(
    "SmartHash->exists requires a type! Object: '$object', type: '$type'.")
    unless $type;
  my $href = $self->get($type);
  return exists $href->{$object->id};
}

sub update {
  my ($self, @objects) = @_;
  return $self->_add(@objects);
}

sub delete {
  my ($self, @objects) = @_;
  my $type = ref($objects[0]);
  my $href = $self->get($type);

  my @removed;
  foreach my $obj (@objects) {
    push @removed, delete $href->{$obj->id};
  }

  return @removed;
}

sub filter {
  my ($self, $type, $coderef) = @_;

  return () if $self->empty($type);
  my @arr = grep &{$coderef}, $self->all($type);

  return @arr;
}

sub find {
  my ($self, $type, $coderef) = @_;

  return if $self->empty($type);
  my $obj = first \&{$coderef}, $self->all($type);

  return $obj;
}

# Moose::Meta::Attribute::Native::Trait::Array

__PACKAGE__->meta->make_immutable;
no Moose;
1;
