package IMembered;

use namespace::autoclean;
use Moose::Role;

sub has_membership {
  my ($self, $membership) = @_;
  return defined $self->repo->memberships_find(sub { $_->equals($membership) });
}

sub add_membership {
  my ($self, $membership) = @_;
  $self->repo->memberships_save($membership);
}

sub remove_membership {
  my ($self, $membership) = @_;
  return $self->repo->memberships_delete($membership);
}

1;
