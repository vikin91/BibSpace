package IRelation;
use namespace::autoclean;

use Moose::Role;

requires 'id';
requires 'equals';

# called after the default constructor
sub BUILD {
  my $self = shift;
  $self->id;    # trigger lazy execution of idProvider
}

1;
