package Membership;

use Data::Dumper;
use utf8;
use v5.16;
use BibSpace::Model::Author;
use BibSpace::Model::Team;
use BibSpace::Model::IRelation;
use Try::Tiny;

use Moose;
with 'IRelation';
use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

# the fileds below are used for linking process
has 'team_id'   => (is => 'ro', isa => 'Int');
has 'author_id' => (is => 'ro', isa => 'Int');
has 'team'      => (
  is     => 'rw',
  isa    => 'Maybe[Team]',
  traits => ['DoNotSerialize']    # due to cycyles
);
has 'author' => (
  is     => 'rw',
  isa    => 'Maybe[Author]',
  traits => ['DoNotSerialize']    # due to cycyles
);
has 'start' => (is => 'rw', isa => 'Int', default => 0);
has 'stop'  => (is => 'rw', isa => 'Int', default => 0);

sub id {
  my $self = shift;
  return "(" . $self->team->name . "-" . $self->author->uid . ")"
    if defined $self->author and defined $self->team;
  return "(" . $self->team_id . "-" . $self->author_id . ")";
}

sub validate {
  my $self = shift;
  if (defined $self->author and defined $self->team) {
    if ($self->author->id != $self->author_id) {
      die "Label has been built wrongly author->id and author_id differs.\n"
        . "label->author->id: "
        . $self->author->id
        . ", label->author_id: "
        . $self->author_id;
    }
    if ($self->team->id != $self->team_id) {
      die "Label has been built wrongly team->id and team_id differs.\n"
        . "label->team->id: "
        . $self->team->id
        . ", label->team_id: "
        . $self->team_id;
    }
  }
  return 1;
}

sub toString {
  my $self = shift;
  my $str  = $self->freeze;
  $str .= "\n\t (TEAM): " . $self->team->id     if defined $self->team;
  $str .= "\n\t (AUTHOR): " . $self->author->id if defined $self->author;
  $str;
}

sub equals {
  my $self = shift;
  my $obj  = shift;
  return if !defined $obj;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
    unless ref($self) eq ref($obj);
  if ($self->team and $self->author and $obj->team and $obj->author) {
    return $self->equals_obj($obj);
  }
  return $self->equals_id($obj);
}

sub equals_id {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches!!" unless ref($self) eq ref($obj);
  return if $self->team_id != $obj->team_id;
  return if $self->author_id != $obj->author_id;
  return 1;
}

sub equals_obj {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches!!" unless ref($self) eq ref($obj);
  return if !$self->team->equals($obj->team);
  return if !$self->author->equals($obj->author);
  return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
