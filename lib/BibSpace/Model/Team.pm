package Team;

use Try::Tiny;
use utf8;
use BibSpace::Model::Author;
use v5.16;
use List::MoreUtils qw(any uniq);
use Moose;
use MooseX::Storage;
with Storage;
use BibSpace::Model::IEntity;
use BibSpace::Model::IMembered;
use BibSpace::Model::IHavingException;
with 'IEntity', 'IMembered', 'IHavingException';
use BibSpace::Model::SerializableBase::TeamSerializableBase;
extends 'TeamSerializableBase';

sub equals {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
    unless ref($self) eq ref($obj);
  return $self->name eq $obj->name;
}

sub can_be_deleted {
  my $self = shift;

  return if scalar $self->get_authors > 0;
  return 1;
}

sub get_memberships {
  my $self = shift;
  return $self->repo->memberships_filter(sub { $_->team_id == $self->id });
}

sub get_authors {
  my $self       = shift;
  my @author_ids = map { $_->author_id } $self->get_memberships;
  return $self->repo->authors_filter(
    sub {
      my $a = $_;
      return grep { $_ eq $a->id } @author_ids;
    }
  );
}

sub get_members {
  return shift->get_authors;
}

sub get_membership_beginning {
  my $self   = shift;
  my $author = shift;

  die("Author is undefined") unless defined $author;

  return $author->joined_team($self);
}

sub get_membership_end {
  my $self   = shift;
  my $author = shift;

  die("Author is undefined") unless defined $author;

  return $author->left_team($self);
}

sub tags {
  my $self = shift;
  my $type = shift // 1;

  my @myTags;
  my @members = $self->get_authors;
  foreach my $author (@members) {
    push @myTags, $author->get_tags_of_type($type);
  }
  @myTags = uniq @myTags;

  return @myTags;
}

sub get_exceptions {
  my $self = shift;
  return $self->repo->exceptions_filter(sub { $_->team_id == $self->id });
}

sub get_entries {
  my $self = shift;

  my @myEntries = ();
  my @members   = $self->get_authors;
  foreach my $author (@members) {
    push @myEntries, $author->get_entries;
  }
  my @exception_entries = map { $_->entry } $self->get_exceptions;
  @myEntries = (@myEntries, @exception_entries);
  @myEntries = uniq @myEntries;

  return @myEntries;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
