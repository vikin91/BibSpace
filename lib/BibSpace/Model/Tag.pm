package Tag;

use utf8;
use Text::BibTeX;
use v5.16;
use List::MoreUtils qw(any uniq first_index);
use Moose;
use MooseX::Storage;    # required for traits => DoNotSerialize
with Storage;
require BibSpace::Model::IEntity;
require BibSpace::Model::ILabeled;
with 'IEntity', 'ILabeled';

use BibSpace::Model::SerializableBase::TagSerializableBase;
extends 'TagSerializableBase';

has 'tagtype' =>
  (is => 'rw', isa => 'Maybe[TagType]', traits => ['DoNotSerialize'],);

sub equals {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
    unless ref($self) eq ref($obj);
  return $self->name eq $obj->name;
}

sub get_authors {
  my $self = shift;

  my @entries = $self->get_entries;
  my @authors = map { $_->get_authors } @entries;
  return uniq @authors;
}

sub get_labelings {
  my $self = shift;
  return $self->repo->labelings_filter(sub { $_->tag_id == $self->id });
}

sub get_entries {
  my $self      = shift;
  my @entry_ids = map { $_->entry_id } $self->get_labelings;

  return $self->repo->entries_filter(
    sub {
      my $e = $_;
      return grep { $_ eq $e->id } @entry_ids;
    }
  );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
