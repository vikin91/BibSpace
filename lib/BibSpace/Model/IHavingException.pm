package IHavingException;

use namespace::autoclean;

use Moose::Role;

has 'exceptions' => (
  is      => 'rw',
  isa     => 'ArrayRef[Exception]',
  traits  => ['Array'],
  default => sub { [] },
  handles => {
    exceptions_all        => 'elements',
    exceptions_add        => 'push',
    exceptions_count      => 'count',
    exceptions_find       => 'first',
    exceptions_find_index => 'first_index',
    exceptions_filter     => 'grep',
    exceptions_delete     => 'delete',
    exceptions_clear      => 'clear',
  },
);

sub has_exception {
  my ($self, $exception) = @_;
  my $idx = $self->exceptions_find_index(sub { $_->equals($exception) });
  return $idx >= 0;
}

sub add_exception {
  my ($self, $exception) = @_;
  if (!$self->has_exception($exception)) {
    $self->exceptions_add($exception);
  }
}

sub remove_exception {
  my ($self, $exception) = @_;

  my $index = $self->exceptions_find_index(sub { $_->equals($exception) });
  return   if $index == -1;
  return 1 if $self->exceptions_delete($index);
  return;
}

sub get_exceptions {
  my $self = shift;
  return $self->exceptions_all;
}

1;
