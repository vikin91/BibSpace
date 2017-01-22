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
with 'IEntity';
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );


has 'name' => ( is => 'rw', isa => 'Str' );
has 'parent' => ( is => 'rw' );

has 'exceptions' => (
  is      => 'rw',
  isa     => 'ArrayRef[Exception]',
  traits  => ['Array'],
  default => sub { [] },
  handles => {
    exceptions_all    => 'elements',
    exceptions_add    => 'push',
    exceptions_count  => 'count',
    exceptions_find   => 'first',
    exceptions_filter => 'grep',
  },
);

has 'memberships' => (
  is      => 'rw',
  isa     => 'ArrayRef[Membership]',
  traits  => ['Array'],
  default => sub { [] },
  handles => {
    memberships_all    => 'elements',
    memberships_add    => 'push',
    memberships_count  => 'count',
    memberships_find   => 'first',
    memberships_filter => 'grep',
  },
);

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
################################################################################
sub has_author {
  my $self   = shift;
  my $author = shift;

  my $found = $self->authors_find( sub { $_->equals($author) } );
  return 1 if $found;
  return 0;
}
################################################################################
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
################################################################################
sub remove_all_authors {
  my $self = shift;

  $self->teamMemberships_clear;
  $self->authors_clear;
}
################################################################################
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
################################################################################
sub members {
  my $self = shift;
  return map { $_->author } $self->memberships_all;
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
sub tags {
  my $self = shift;
  my $type = shift // 1;

  my @myTags;
  my @members = $self->authors_all;
  foreach my $author (@members) {
    push @myTags, $author->tags($type);
  }
  @myTags = uniq @myTags;

  return @myTags;
}
####################################################################################
sub entries {
  my $self = shift;

  my @myEntries;
  my @members = $self->authors_all;
  foreach my $author (@members) {
    push @myEntries, $author->entries;
  }
  @myEntries = uniq @myEntries;

  return @myEntries;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
