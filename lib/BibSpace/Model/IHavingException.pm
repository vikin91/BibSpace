package IHavingException;

use namespace::autoclean;
use Moose::Role;

sub add_exception {
  my ($self, $exception) = @_;
  $self->repo->exceptions_save($exception);
}

sub remove_exception {
  my ($self, $exception) = @_;
  return $self->repo->exceptions_delete($exception);
}

1;
