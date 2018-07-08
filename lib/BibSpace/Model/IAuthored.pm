package IAuthored;

use namespace::autoclean;
use BibSpace::Functions::Core qw( sort_publications );
use Moose::Role;

sub has_authorship {
  my ($self, $authorship) = @_;
  my $au = $self->repo->authorships_find(sub { $_->equals($authorship) });
  return defined $au;
}

sub add_authorship {
  my ($self, $authorship) = @_;
  $self->repo->authorships_save($authorship);
}

sub remove_authorship {
  my ($self, $authorship) = @_;
  return $self->repo->authorships_delete($authorship);
}

1;
