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

sub team {
  my $self = shift;
  return if not $self->team_id or $self->team_id < 1;
  return $self->repo->teams_find(sub { $_->id == $self->team_id });
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
    . ($self->team_id  || "undef") . ")";
}

=item equals
    In case of any strange problems: this must return 1 or 0!
=cut

sub equals {
  my $self = shift;
  my $obj  = shift;
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
