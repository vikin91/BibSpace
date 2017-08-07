# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T16:44:28
package MembershipSmartArrayDAO;

use namespace::autoclean;

use Moose;
use BibSpace::DAO::Interface::IDAO;
use BibSpace::Model::Membership;
with 'IDAO';
use Try::Tiny;
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
  return $self->handle->all("Membership");
}
before 'all' => sub { shift->logger->entering(""); };
after 'all'  => sub { shift->logger->exiting(""); };

=item count
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 

sub count {
  my ($self) = @_;
  return $self->handle->count("Membership");
}
before 'count' => sub { shift->logger->entering(""); };
after 'count'  => sub { shift->logger->exiting(""); };

=item empty
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 

sub empty {
  my ($self) = @_;
  return $self->handle->empty("Membership");
}
before 'empty' => sub { shift->logger->entering(""); };
after 'empty'  => sub { shift->logger->exiting(""); };

=item exists
    Method documentation placeholder.
    This method takes single object as argument and returns a scalar.
=cut 

sub exists {
  my ($self, $object) = @_;
  $self->handle->exists($object);
}
before 'exists' => sub { shift->logger->entering(""); };
after 'exists'  => sub { shift->logger->exiting(""); };

=item save
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub save {
  my ($self, @objects) = @_;
  $self->handle->save(@objects);
}
before 'save' => sub { shift->logger->entering(""); };
after 'save'  => sub { shift->logger->exiting(""); };

=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub update {
  my ($self, @objects) = @_;

  # smart array does not require updating! Objects are direct references!
}
before 'update' => sub { shift->logger->entering(""); };
after 'update'  => sub { shift->logger->exiting(""); };

=item delete
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub delete {
  my ($self, @objects) = @_;
  $self->handle->delete(@objects);
}
before 'delete' => sub { shift->logger->entering(""); };
after 'delete'  => sub { shift->logger->exiting(""); };

=item filter
    Method documentation placeholder.
=cut 

sub filter {
  my ($self, $coderef) = @_;
  die ""
    . (caller(0))[3]
    . " incorrect type of argument. Got: '"
    . ref($coderef)
    . "', expected: "
    . (ref sub { }) . "."
    unless (ref $coderef eq ref sub { });
  return $self->handle->filter("Membership", $coderef);
}
before 'filter' => sub { shift->logger->entering(""); };
after 'filter'  => sub { shift->logger->exiting(""); };

=item find
    Method documentation placeholder.
=cut 

sub find {
  my ($self, $coderef) = @_;
  die ""
    . (caller(0))[3]
    . " incorrect type of argument. Got: '"
    . ref($coderef)
    . "', expected: "
    . (ref sub { }) . "."
    unless (ref $coderef eq ref sub { });
  return $self->handle->find("Membership", $coderef);
}
before 'find' => sub { shift->logger->entering(""); };
after 'find'  => sub { shift->logger->exiting(""); };
__PACKAGE__->meta->make_immutable;
no Moose;
1;
