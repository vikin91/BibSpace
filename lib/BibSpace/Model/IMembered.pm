package IMembered;

use namespace::autoclean;

use Moose::Role;

use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

has 'memberships' => (
  is      => 'rw',
  isa     => 'ArrayRef[Membership]',
  traits  => ['Array'],
  default => sub { [] },
  handles => {
    memberships_all        => 'elements',
    memberships_add        => 'push',
    memberships_count      => 'count',
    memberships_find       => 'first',
    memberships_find_index => 'first_index',
    memberships_filter     => 'grep',
    memberships_delete     => 'delete',
    memberships_clear      => 'clear',
  },
);

sub get_teams {
  my $self = shift;
  return map { $_->team } $self->memberships_all;
}

sub has_team {
  my $self = shift;
  my $team = shift;
  return defined $self->memberships_find(sub { $_->team->equals($team) });
}

sub has_membership {
  my ($self, $membership) = @_;
  my $idx = $self->memberships_find_index(sub { $_->equals($membership) });
  return $idx >= 0;
}

sub add_membership {
  my ($self, $membership) = @_;

  if (!$self->has_membership($membership)) {
    $self->memberships_add($membership);
  }
}

sub remove_membership {
  my ($self, $membership) = @_;

  # $membership->validate;

  my $index = $self->memberships_find_index(sub { $_->equals($membership) });
  return   if $index == -1;
  return 1 if $self->memberships_delete($index);
  return;
}

1;
