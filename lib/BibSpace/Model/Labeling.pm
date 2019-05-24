package Labeling;

use utf8;
use v5.16;
use BibSpace::Model::Entry;
use BibSpace::Model::Tag;
use BibSpace::Model::IRelation;
use Try::Tiny;
use Data::Dumper;
$Data::Dumper::Maxdepth = 2;

use Moose;
with 'IRelation';
use BibSpace::Model::SerializableBase::LabelingSerializableBase;
extends 'LabelingSerializableBase';

sub tag {
  my $self = shift;
  return if not $self->tag_id or $self->tag_id < 1;
  return $self->repo->tags_find(sub { $_->id == $self->tag_id });
}

sub entry {
  my $self = shift;
  return if not $self->entry_id or $self->entry_id < 1;
  return $self->repo->entries_find(sub { $_->id == $self->entry_id });
}

sub id {
  my $self = shift;
  return
      "("
    . ($self->entry_id || "undef") . "-"
    . ($self->tag_id   || "undef") . ")";
}

sub equals {
  my $self = shift;
  my $obj  = shift;
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
