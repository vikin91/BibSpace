package ILabeled;

use namespace::autoclean;
use Moose::Role;

sub has_labeling {
  my ($self, $labeling) = @_;
  return $self->repo->labelings_find(sub { $_->equals($labeling) });
}

sub add_labeling {
  my ($self, $labeling) = @_;
  $self->repo->labelings_save($labeling);
}

sub remove_labeling {
  my ($self, $labeling) = @_;
  return $self->repo->labelings_delete($labeling);
}

1;
