package Author;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use v5.16;           # because of ~~ and say
use List::MoreUtils qw(any uniq);
use BibSpace::Model::Membership;
use Moose;
use MooseX::Storage;
use MooseX::Privacy;
with Storage;
require BibSpace::Model::IEntity;
require BibSpace::Model::IAuthored;
require BibSpace::Model::IMembered;
with 'IEntity', 'IAuthored', 'IMembered';
use BibSpace::Model::SerializableBase::AuthorSerializableBase;
extends 'AuthorSerializableBase';

# A placeholder for master object. This will be lazily populated on first read
has 'masterObj' => (
  is            => 'rw',
  isa           => 'Maybe[Author]',
  default       => sub {undef},
  traits        => [qw/DoNotSerialize/, qw/Private/],
  documentation => q{Author's master author object.}
);

# called after the default constructor
sub BUILD {
  my $self = shift;
  $self->name($self->uid);
}

# Entitiy receives ID first on save to DB
# This can be fixed with generating UUID on object creation and referencing master using uuid as FK
sub post_insert_hook {
  my $self = shift;
  if (defined $self->id and $self->id > 0) {
    $self->get_master_id;    # sets master_id if unset
    $self->repo->authors_update($self);
  }
}

sub equals {
  my $self = shift;
  my $obj  = shift;

  return if !defined $obj;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
    unless ref($self) eq ref($obj);

  my $result = $self->uid eq $obj->uid;
  return $result;
}

sub master_name {
  my $self = shift;
  return $self->get_master->uid;
}

sub master {
  my $self = shift;
  return $self if not $self->master_id;
  return $self if not $self->masterObj;
  return $self->masterObj;
}

sub set_master {
  my $self   = shift;
  my $master = shift;
  if (not $master->id) {
    warn "Cannot set_master if master has no ID";
    return;
  }
  $self->masterObj($master);
  $self->master_id($master->id);
}

sub get_master {
  shift->master;
}

sub is_master {
  my $self = shift;
  return 1 if ($self->id == $self->master_id);
  return;
}

sub is_minion {
  my $self = shift;
  return not $self->is_master;
}

sub is_minion_of {
  my $self   = shift;
  my $master = shift;
  return 1 if $self->master_id == $master->id;
  return;
}

sub update_name {
  my $self       = shift;
  my $new_master = shift;

  $self->uid($new_master);
  $self->name($new_master);
  return 1;
}

sub remove_master {
  my $self = shift;
  $self->set_master($self);
}

sub add_minion {
  my $self   = shift;
  my $minion = shift;

  return if !defined $minion;
  $minion->set_master($self);
  return 1;
}

sub can_merge_authors {
  my $self          = shift;
  my $source_author = shift;

  if (  (defined $source_author)
    and (defined $source_author->id)
    and (defined $self->id)
    and ($source_author->id != $self->id)
    and (!$self->equals($source_author)))
  {
    return 1;
  }
  return;
}

sub toggle_visibility {
  my $self = shift;

  if ($self->display == 0) {
    $self->display(1);
  }
  else {
    $self->display(0);
  }
}

sub is_visible {
  my $self = shift;

  return $self->display == 1;
}

sub can_be_deleted {
  my $self = shift;

  return if $self->display == 1;

  my @teams = $self->get_teams;

  return 1 if scalar @teams == 0 and $self->display == 0;
  return;
}

sub has_team {
  my $self = shift;
  my $team = shift;
  return grep { $_->id eq $team->id } $self->get_teams;
}

sub get_teams {
  my $self = shift;
  my @team_ids
    = map { $_->team_id }
    $self->repo->memberships_filter(
    sub { $_->author_id == $self->id or $_->author_id == $self->get_master_id }
    );
  return $self->repo->teams_filter(
    sub {
      my $t = $_;
      return grep { $_ eq $t->id } @team_ids;
    }
  );
}

sub get_entries {
  my $self      = shift;
  my @entry_ids = map { $_->entry_id }
    $self->repo->authorships_filter(sub { $_->author_id == $self->id });
  return $self->repo->entries_filter(
    sub {
      my $e = $_;
      return grep { $_ eq $e->id } @entry_ids;
    }
  );
}

sub has_entry {
  my $self  = shift;
  my $entry = shift;

  my $authorship_to_find = $self->repo->entityFactory->new_Authorship(
    author_id => $self->id,
    entry_id  => $entry->id
  );
  my $authorship
    = $self->repo->authorships_find(sub { $_->equals_id($authorship_to_find) });
  return defined $authorship;
}

################################################################################ TEAMS

sub joined_team {
  my $self = shift;
  my $team = shift;

  return -1 if !defined $team;

  my $query_mem = $self->repo->entityFactory->new_Membership(
    team_id   => $team->id,
    author_id => $self->get_master->id,
  );
  my $mem = $self->repo->memberships_find(sub { $_->equals($query_mem) });

  return -1 if !defined $mem;
  return $mem->start;
}

sub left_team {
  my $self = shift;
  my $team = shift;

  return -1 if !defined $team;

  my $query_mem = $self->repo->entityFactory->new_Membership(
    author_id => $self->get_master->id,
    team_id   => $team->id
  );
  my $mem = $self->repo->memberships_find(sub { $_->equals($query_mem) });

  return -1 if !defined $mem;
  return $mem->stop;
}

sub update_membership {
  my $self  = shift;
  my $team  = shift;
  my $start = shift;
  my $stop  = shift;

  return if !$team;

  my $query_mem_master = $self->repo->entityFactory->new_Membership(
    author_id => $self->get_master->id,
    team_id   => $team->id
  );
  my $query_mem_minor = $self->repo->entityFactory->new_Membership(
    author_id => $self->id,
    team_id   => $team->id
  );
  my $mem_master
    = $self->repo->memberships_find(sub { $_->equals($query_mem_master) });
  my $mem_minor
    = $self->repo->memberships_find(sub { $_->equals($query_mem_minor) });

  if (  defined $mem_minor
    and defined $mem_master
    and not $mem_minor->equals($mem_master))
  {
    warn "MEMBERSHIP for master differs to membership of minor! master has "
      . $mem_master->id
      . ", minor has "
      . $mem_minor->id;
  }
  my $mem = $mem_master // $mem_minor;

  if ($start < 0) {
    die "Invalid start $start: start must be 0 or greater";
  }
  if ($stop < 0) {
    die "Invalid stop $stop: stop must be 0 or greater";
  }
  if ($stop > 0 and $start > 0 and $stop < $start) {
    die "Invalid range: stop must me non-smaller than start";
  }
  if (!$mem) {
    die "Invalid team. Cannot find author membership in that team.";
  }

  $mem->start($start) if defined $start;
  $mem->stop($stop)   if defined $stop;
  $self->repo->memberships_update($mem);
  return 1;
}

#################################################################################### TAGS

sub get_tags_of_type {
  my $self     = shift;
  my $tag_type = shift // 1;
  return grep { $_->type == $tag_type } $self->get_tags;
}

sub get_tags {
  my $self          = shift;
  my $potentialType = shift;
  die "use entry->get_tags_of_type instead" if defined $potentialType;

  my @myTags;
  map { push @myTags, $_->get_tags } $self->get_entries;
  @myTags = uniq @myTags;

  return @myTags;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
