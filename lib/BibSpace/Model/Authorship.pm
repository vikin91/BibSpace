package Authorship;

use Data::Dumper;
use utf8;
use v5.16;
use BibSpace::Model::Author;
use BibSpace::Model::Entry;
use BibSpace::Model::IRelation;
use Try::Tiny;

use Moose;
with 'IRelation';

use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

# the fileds below are used for linking process
has 'entry_id'  => (is => 'ro', isa => 'Int');
has 'author_id' => (is => 'ro', isa => 'Int');
has 'entry'     => (
  is     => 'rw',
  isa    => 'Maybe[Entry]',
  traits => ['DoNotSerialize']    # due to cycyles
);
has 'author' => (
  is     => 'rw',
  isa    => 'Maybe[Author]',
  traits => ['DoNotSerialize']    # due to cycyles
);

sub id {
  my $self = shift;
  return "(" . $self->entry_id . "-" . $self->author->id . ")"
    if defined $self->author;
  return "(" . $self->entry_id . "-" . $self->author_id . ")";
}

sub validate {
  my $self = shift;
  if (defined $self->author and defined $self->entry) {
    if ($self->author->id != $self->author_id) {
      die "Label has been built wrongly author->id and author_id differs.\n"
        . "label->author->id: "
        . $self->author->id
        . ", label->author_id: "
        . $self->author_id;
    }
    if ($self->entry->id != $self->entry_id) {
      die "Label has been built wrongly entry->id and entry_id differs.\n"
        . "label->entry->id: "
        . $self->entry->id
        . ", label->entry_id: "
        . $self->entry_id;
    }
  }
  return 1;
}

sub toString {
  my $self = shift;
  my $str  = $self->freeze;
  $str .= "\n";
  $str .= "\n\t (ENTRY): " . $self->entry->id if defined $self->entry;
  $str .= "\n\t (AUTHOR): " . $self->author->id if defined $self->author;
  $str;
}

sub equals {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
    unless ref($self) eq ref($obj);
  if ($self->entry and $self->author and $obj->entry and $obj->author) {
    return $self->equals_obj($obj);
  }
  return $self->equals_id($obj);
}

sub equals_id {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches!!" unless ref($self) eq ref($obj);
  return if $self->entry_id != $obj->entry_id;
  return if $self->author_id != $obj->author_id;
  return 1;
}

sub equals_obj {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches!!" unless ref($self) eq ref($obj);
  return if !$self->entry->equals($obj->entry);
  return if !$self->author->equals($obj->author);
  return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
