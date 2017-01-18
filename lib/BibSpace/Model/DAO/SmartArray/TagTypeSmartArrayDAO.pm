# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T16:44:28
package TagTypeSmartArrayDAO;

use namespace::autoclean;
use Moose;
use BibSpace::Model::DAO::Interface::IDAO;
use BibSpace::Model::TagType;
with 'IDAO';
use Try::Tiny;

# Inherited fields from BibSpace::Model::DAO::Interface::IDAO Mixin:
# has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);
# has 'handle' => ( is => 'ro', required => 1);

=item all
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub all {
  my ($self) = @_;

  return $self->handle->all("TagType");

}
before 'all' => sub { shift->logger->entering("","".__PACKAGE__."->all"); };
after 'all'  => sub { shift->logger->exiting("","".__PACKAGE__."->all"); };
=item count
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub count {
  my ($self) = @_;
  return scalar $self->handle->all("TagType");
}
before 'count' => sub { shift->logger->entering("","".__PACKAGE__."->count"); };
after 'count'  => sub { shift->logger->exiting("","".__PACKAGE__."->count"); };
=item empty
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub empty {
  my ($self) = @_;

  die "".__PACKAGE__."->empty not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before 'empty' => sub { shift->logger->entering("","".__PACKAGE__."->empty"); };
after 'empty'  => sub { shift->logger->exiting("","".__PACKAGE__."->empty"); };

=item exists
    Method documentation placeholder.
    This method takes single object as argument and returns a scalar.
=cut 
sub exists {
  my ($self, $object) = @_;
  
  die "".__PACKAGE__."->exists not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before 'exists' => sub { shift->logger->entering("","".__PACKAGE__."->exists"); };
after 'exists'  => sub { shift->logger->exiting("","".__PACKAGE__."->exists"); };

=item save
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub save {
  my ($self, @objects) = @_;
  $self->handle->save(@objects);
}
before 'save' => sub { shift->logger->entering("","".__PACKAGE__."->save"); };
after 'save'  => sub { shift->logger->exiting("","".__PACKAGE__."->save"); };
=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub update {
  my ($self, @objects) = @_;

  die "".__PACKAGE__."->update not implemented. Method was instructed to update ".scalar(@objects)." objects.";
  # TODO: auto-generated method stub. Implement me!

}
before 'update' => sub { shift->logger->entering("","".__PACKAGE__."->update"); };
after 'update'  => sub { shift->logger->exiting("","".__PACKAGE__."->update"); };
=item delete
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub delete {
  my ($self, @objects) = @_;

  die "".__PACKAGE__."->delete not implemented. Method was instructed to delete ".scalar(@objects)." objects.";
  # TODO: auto-generated method stub. Implement me!

}
before 'delete' => sub { shift->logger->entering("","".__PACKAGE__."->delete"); };
after 'delete'  => sub { shift->logger->exiting("","".__PACKAGE__."->delete"); };

=item filter
    Method documentation placeholder.
=cut 
sub filter {
  my ($self, $coderef) = @_;
  die "".__PACKAGE__."->filter incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );

  die "".__PACKAGE__."->filter not implemented.";
  # TODO: auto-generated method stub. Implement me!
  
}
before 'filter' => sub { shift->logger->entering("","".__PACKAGE__."->filter"); };
after 'filter'  => sub { shift->logger->exiting("","".__PACKAGE__."->filter"); };
=item find
    Method documentation placeholder.
=cut 
sub find {
  my ($self, $coderef) = @_;
  die "".__PACKAGE__."->find incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );

  die "".__PACKAGE__."->find not implemented.";
  # TODO: auto-generated method stub. Implement me!
  
}
before 'find' => sub { shift->logger->entering("","".__PACKAGE__."->find"); };
after 'find'  => sub { shift->logger->exiting("","".__PACKAGE__."->find"); };
__PACKAGE__->meta->make_immutable;
no Moose;
1;
