package Exception;

use Data::Dumper;
use utf8;
use v5.16;
use BibSpace::Model::Team;
use BibSpace::Model::Entry;
use BibSpace::Model::IRelation;
use Try::Tiny;
use Moose;
with 'IRelation';
use BibSpace::Model::SerializableBase::ExceptionSerializableBase;
extends 'ExceptionSerializableBase';

# Cast self to SerializableBase and serialize
sub TO_JSON {
  my $self = shift;
  my $copy = $self->meta->clone_object($self);
  return ExceptionSerializableBase->meta->rebless_instance_back($copy)->TO_JSON;
}

has 'entry' => (
  is     => 'rw',
  isa    => 'Maybe[Entry]',
  traits => ['DoNotSerialize']    # due to cycyles
);
has 'team' => (
  is     => 'rw',
  isa    => 'Maybe[Team]',
  traits => ['DoNotSerialize']    # due to cycyles
);

sub id {
  my $self = shift;
  return "(" . $self->entry_id . "-" . $self->team->name . ")"
    if defined $self->team;
  return "(" . $self->entry_id . "-" . $self->team_id . ")";
}

=item equals
    In case of any strange problems: this must return 1 or 0!
=cut

sub equals {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
    unless ref($self) eq ref($obj);
  if ($self->entry and $self->team and $obj->entry and $obj->team) {
    return $self->equals_obj($obj);
  }
  return $self->equals_id($obj);
}

sub equals_id {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
    unless ref($self) eq ref($obj);
  return if $self->entry_id != $obj->entry_id;
  return if $self->team_id != $obj->team_id;
  return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
