# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T16:44:28
package AuthorSmartArrayDAO;

use namespace::autoclean;
use feature qw(current_sub);
use Moose;
use BibSpace::DAO::Interface::IDAO;
use BibSpace::Model::Author;
with 'IDAO';
use Try::Tiny;
use List::MoreUtils qw(any uniq);
use List::Util qw(first);

# Inherited fields from BibSpace::DAO::Interface::IDAO Mixin:
# has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);
# has 'handle' => ( is => 'ro', required => 1);

=item all
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub all {
  my ($self) = @_;
  return $self->handle->all("Author");
}
before 'all' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'all'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };
=item count
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub count {
  my ($self) = @_;
  return $self->handle->count("Author");
}
before 'count' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'count'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };
=item empty
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub empty {
  my ($self) = @_;

  die "".(caller(0))[3]." not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before 'empty' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'empty'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

=item exists
    Method documentation placeholder.
    This method takes single object as argument and returns a scalar.
=cut 
sub exists {
  my ($self, $object) = @_;
  
  die "".(caller(0))[3]." not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before 'exists' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'exists'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

=item save
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub save {
  my ($self, @objects) = @_;
  $self->handle->save(@objects);
}
before 'save' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'save'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };
=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub update {
  my ($self, @objects) = @_;
  # smart array does not require updating! Objects are direct references!
}
before 'update' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'update'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };
=item delete
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub delete {
  my ($self, @objects) = @_;
  my %toDelete = map {$_ => 1} @objects;
  my @diff = grep {not $toDelete{$_} } $self->all;
  $self->handle->data->{'Author'} = \@diff;
}
before 'delete' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'delete'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

=item filter
    Method documentation placeholder.
=cut 
sub filter {
  my ($self, $coderef) = @_;
  die "".(caller(0))[3]." incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  return $self->handle->filter("Author", $coderef);
}
before 'filter' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'filter'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };
=item find
    Method documentation placeholder.
=cut 
sub find {
  my ($self, $coderef) = @_;
  die "".(caller(0))[3]." incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  return $self->handle->find("Author", $coderef);
}
before 'find' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'find'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };
__PACKAGE__->meta->make_immutable;
no Moose;
1;
