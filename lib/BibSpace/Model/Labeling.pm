package Labeling;

use utf8;
use v5.16;
use BibSpace::Model::Entry;
use BibSpace::Model::Tag;
use BibSpace::Model::IRelation;
use Try::Tiny;

use Moose;
with 'IRelation';
use BibSpace::Model::SerializableBase::LabelingSerializableBase;
extends 'LabelingSerializableBase';

# Cast self to SerializableBase and serialize
sub TO_JSON {
  my $self = shift;
  my $copy = $self->meta->clone_object($self);
  return LabelingSerializableBase->meta->rebless_instance_back($copy)->TO_JSON;
}

has 'entry' => (
  is     => 'rw',
  isa    => 'Maybe[Entry]',
  traits => ['DoNotSerialize']    # due to cycyles
);
has 'tag' => (
  is     => 'rw',
  isa    => 'Maybe[Tag]',
  traits => ['DoNotSerialize']    # due to cycyles
);

sub id {
  my $self = shift;
  return "(" . $self->entry_id . "-" . $self->tag->name . ")"
    if defined $self->tag;
  return "(" . $self->entry_id . "-" . $self->tag_id . ")";
}

sub validate {
  my $self = shift;
  if (defined $self->entry and defined $self->tag) {
    if ($self->entry->id != $self->entry_id) {
      die "Label has been built wrongly entry->id and entry_id differs.\n"
        . "label->entry->id: "
        . $self->entry->id
        . ", label->entry_id: "
        . $self->entry_id;
    }
    if ($self->tag->id != $self->tag_id) {
      die "Label has been built wrongly tag->id and tag_id differs.\n"
        . "label->tag->id: "
        . $self->tag->id
        . ", label->tag_id: "
        . $self->tag_id;
    }
  }
  return 1;
}

sub equals {
  my $self = shift;
  my $obj  = shift;

  die "Comparing apples to peaches! "
    . ref($self)
    . " against "
    . ref($obj) . "."
    unless ref($self) eq ref($obj);

  if ($self->entry and $self->tag and $obj->entry and $obj->tag) {
    return $self->equals_obj($obj);
  }
  return $self->equals_id($obj);
}

sub equals_id {
  my $self = shift;
  my $obj  = shift;
  return if $self->entry_id != $obj->entry_id;
  return if $self->tag_id != $obj->tag_id;
  return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
