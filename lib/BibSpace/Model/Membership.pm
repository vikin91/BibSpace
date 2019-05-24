package Membership;

use utf8;
use v5.16;
use BibSpace::Model::Author;
use BibSpace::Model::Team;
use BibSpace::Model::IRelation;
use Try::Tiny;
use Moose;
with 'IRelation';
use BibSpace::Model::SerializableBase::MembershipSerializableBase;
extends 'MembershipSerializableBase';

sub author {
  my $self = shift;
  return if not $self->author_id or $self->author_id < 1;
  return $self->repo->authors_find(sub { $_->id == $self->author_id });
}

sub team {
  my $self = shift;
  return if not $self->team_id or $self->team_id < 1;
  return $self->repo->teams_find(sub { $_->id == $self->team_id });
}

sub id {
  my $self = shift;
  return
      "("
    . ($self->author_id || "undef") . "-"
    . ($self->team_id   || "undef") . ")";
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
  return if not $self->team_id;
  return if not $self->author_id;
  return if $self->team_id != $obj->team_id;
  return if $self->author_id != $obj->author_id;
  return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
