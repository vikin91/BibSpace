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
has 'repo' => (is => 'ro', isa => 'FlatRepositoryFacade', required => 1);
1;
