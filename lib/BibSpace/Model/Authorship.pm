package Authorship;

use utf8;
use v5.16;
use BibSpace::Model::Author;
use BibSpace::Model::Entry;
use BibSpace::Model::IRelation;
use Try::Tiny;
use Data::Dumper;
$Data::Dumper::Maxdepth = 2;

use Moose;
with 'IRelation';
use BibSpace::Model::SerializableBase::AuthorshipSerializableBase;
extends 'AuthorshipSerializableBase';

# # the fileds below are used for linking process
# has 'entry_id'  => (is => 'ro', isa => 'Int');
# has 'author_id' => (is => 'ro', isa => 'Int');

sub author {
  my $self = shift;
  return $self->repo->authors_find(sub { $_->id == $self->author_id });
}

sub entry {
  my $self = shift;
  return $self->repo->entries_find(sub { $_->id == $self->entry_id });
}

sub id {
  my $self = shift;
  return
      "("
    . ($self->author_id || "undef") . "-"
    . ($self->entry_id  || "undef") . ")";
}

sub equals {
  my $self = shift;
  my $obj  = shift;
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

no Moose;
__PACKAGE__->meta->make_immutable;
1;
