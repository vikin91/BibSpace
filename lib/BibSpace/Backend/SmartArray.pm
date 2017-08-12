package SmartArray;

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
use List::MoreUtils qw(first_index);
use feature qw( say );

use MooseX::Storage;
with Storage(format => 'JSON', 'io' => 'File');

=item
    This is a in-memory data structure (hash) to hold all objects of BibSpace.
    It is build like this:
    String "TypeName" => Array of Objects with type TypeName.
    It could be improved for performance like this:
    String "TypeName" => { Integer UID => Object with type TypeName}.
=cut

has 'logger' =>
  (is => 'ro', does => 'ILogger', required => 1, traits => ['DoNotSerialize']);

has 'data' => (
  traits  => ['Hash'],
  is      => 'ro',
  isa     => 'HashRef[ArrayRef[BibSpace::Model::IEntity]]',
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
  $self->logger->warn("Resetting SmartArray");
  $self->_clear;
}

sub dump {
  my $self = shift;
  $self->logger->debug("SmartArray keys: " . join(', ', $self->keys));
}

sub _init {
  my ($self, $type) = @_;
  die "_init requires a type!" unless $type;
  if (!$self->defined($type)) {
    $self->set($type, []);
  }
}

sub all {
  my ($self, $type) = @_;

  $self->logger->error("SmartArray->all requires a type! Type: $type.")
    unless $type;
  $self->_init($type);
  my $aref = $self->get($type);
  return @{$aref};
}

sub _add {
  my ($self, @objects) = @_;
  my $type = ref($objects[0]);
  $self->_init($type);
  push @{$self->get($type)}, @objects;
}

sub save {
  my ($self, @objects) = @_;
  my $added = 0;

 # if there are multiple objects to add and the array is empty -> do it quicker!
  if (@objects > 0) {
    my $type = ref($objects[0]);

    if ($self->empty($type)) {
      $self->_add(@objects);
      $added = scalar @objects;
      return $added;
    }
  }

  foreach my $obj (@objects) {
    if (!$self->exists($obj)) {
      ++$added;
      $self->_add($obj);
    }
    else {
      $self->update($obj);
    }
  }

  return $added;
}

sub count {
  my ($self, $type) = @_;
  die "all requires a type!" unless $type;
  return scalar $self->all($type);
}

sub empty {
  my ($self, $type) = @_;
  return $self->count($type) == 0;
}

## this is mega slow for relations!!!
sub exists {
  my ($self, $object) = @_;
  my $type = ref($object);
  $self->logger->error(
    "SmartArray->exists requires a type! Object: '$object', type: '$type'.")
    unless $type;
  my $found = first { $_->equals($object) } $self->all($type);
  return defined $found;
}

sub update {
  my ($self, @objects) = @_;

  # should happen automatically beacuse array keeps references to objects
}

sub delete {
  my ($self, @objects) = @_;
  my $type = ref($objects[0]);
  my $aref = $self->get($type);
  my @removed;
  foreach my $obj (@objects) {
    my $idx = first_index { $_ == $obj } @{$aref};
    push @removed, splice(@{$aref}, $idx, 1) if $idx > -1;
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
