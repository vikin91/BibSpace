package Team;

use Try::Tiny;
use Devel::StackTrace;
use Data::Dumper;
use utf8;
use BibSpace::Model::Author;
use 5.010;    #because of ~~ and say
use List::MoreUtils qw(any uniq);
use Moose;
use BibSpace::Model::IEntity;
use BibSpace::Model::IMembered;
use BibSpace::Model::IHavingException;
with 'IEntity', 'IMembered', 'IHavingException';
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );


has 'name' => ( is => 'rw', isa => 'Str' );
has 'parent' => ( is => 'rw' );




####################################################################################
sub toString {
  my $self = shift;
  $self->freeze;
}
####################################################################################
sub equals {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj) unless ref($self) eq ref($obj);
  return $self->name eq $obj->name;
}
####################################################################################
sub can_be_deleted {
  my $self = shift;

  return if $self->memberships_count > 0;
  return 1;
}
####################################################################################
sub has_author {
  my $self   = shift;
  my $author = shift;

  my $found = $self->authors_find( sub { $_->equals($author) } );
  return 1 if $found;
  return 0;
}
####################################################################################
sub add_author {
  my $self   = shift;
  my $author = shift;

  return 0 if !defined $author and $author->{id} <= 0;


  if ( !$self->has_author($author) ) {

    $self->authors_add($author);
    $self->teamMemberships_add(
      MTeamMembership->new(
        author_id => $author->id,
        team_id   => $self->id,
        author    => $author,
        team      => $self,
        start     => 0,
        stop      => 0
      )
    );
    return 1;
  }
  return 0;


}
####################################################################################
sub remove_all_authors {
  my $self = shift;

  $self->teamMemberships_clear;
  $self->authors_clear;
}
####################################################################################
sub remove_author {
  my $self   = shift;
  my $author = shift;

  return 0 if !defined $author and $author->{id} <= 0;

  my $mem_index = $self->teamMemberships_find_index(
    sub {
      $_->{author_id} == $author->id and $_->{team_id} == $self->id;
    }
  );
  return 0 if $mem_index == -1;
  $self->teamMemberships_delete($mem_index);

  my $index = $self->authors_find_index( sub { $_->equals($author) } );
  return 0 if $index == -1;
  return 1 if $self->authors_delete($index);
  return 0;

}
####################################################################################
sub get_members {
  my $self = shift;
  return map { $_->author } $self->memberships_all;
}
####################################################################################
sub members {
  my $self = shift;
  return $self->get_members; 
}
####################################################################################
sub get_membership_beginning {
  my $self   = shift;
  my $author = shift;

  die("Author is undefined") unless defined $author;

  return $author->joined_team($self);
}
####################################################################################
sub get_membership_end {
  my $self   = shift;
  my $author = shift;

  die("Author is undefined") unless defined $author;

  return $author->left_team($self);
}
####################################################################################
sub get_authors {
  my $self = shift;
  return map { $_->author } $self->memberships_all;
}
####################################################################################
sub tags {
  my $self = shift;
  my $type = shift // 1;

  my @myTags;
  my @members = $self->get_authors;
  foreach my $author (@members) {
    push @myTags, $author->get_tags($type);
  }
  @myTags = uniq @myTags;

  return @myTags;
}
####################################################################################
sub entries {
  my $self = shift;

  my @myEntries;
  my @members = $self->get_authors;
  foreach my $author (@members) {
    push @myEntries, $author->get_entries;
  }
  @myEntries = uniq @myEntries;

  return @myEntries;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
