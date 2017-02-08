# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T13:56:17
package AuthorshipRedisDAO;

use namespace::autoclean;
use feature qw(current_sub);
use Moose;
use BibSpace::DAO::Interface::IDAO;
use BibSpace::Model::Authorship;
with 'IDAO';
use Try::Tiny;

# Inherited fields from BibSpace::DAO::Interface::IDAO Mixin:
# has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);
# has 'handle' => ( is => 'ro', required => 1);

=item all
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub all {
  my ($self) = @_;

  die "".(caller(0))[3]." not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before 'all' => sub { shift->logger->entering(""); };
after 'all'  => sub { shift->logger->exiting(""); };
=item count
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub count {
  my ($self) = @_;

  die "".(caller(0))[3]." not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before 'count' => sub { shift->logger->entering(""); };
after 'count'  => sub { shift->logger->exiting(""); };
=item empty
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub empty {
  my ($self) = @_;

  die "".(caller(0))[3]." not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before 'empty' => sub { shift->logger->entering(""); };
after 'empty'  => sub { shift->logger->exiting(""); };

=item exists
    Method documentation placeholder.
    This method takes single object as argument and returns a scalar.
=cut 
sub exists {
  my ($self, $object) = @_;
  
  die "".(caller(0))[3]." not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before 'exists' => sub { shift->logger->entering(""); };
after 'exists'  => sub { shift->logger->exiting(""); };

=item save
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub save {
  my ($self, @objects) = @_;

  die "".(caller(0))[3]." not implemented. Method was instructed to save ".scalar(@objects)." objects.";
  # TODO: auto-generated method stub. Implement me!

}
before 'save' => sub { shift->logger->entering(""); };
after 'save'  => sub { shift->logger->exiting(""); };
=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub update {
  my ($self, @objects) = @_;

  die "".(caller(0))[3]." not implemented. Method was instructed to update ".scalar(@objects)." objects.";
  # TODO: auto-generated method stub. Implement me!

}
before 'update' => sub { shift->logger->entering(""); };
after 'update'  => sub { shift->logger->exiting(""); };
=item delete
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub delete {
  my ($self, @objects) = @_;

  die "".(caller(0))[3]." not implemented. Method was instructed to delete ".scalar(@objects)." objects.";
  # TODO: auto-generated method stub. Implement me!

}
before 'delete' => sub { shift->logger->entering(""); };
after 'delete'  => sub { shift->logger->exiting(""); };

=item filter
    Method documentation placeholder.
=cut 
sub filter {
  my ($self, $coderef) = @_;
  die "".(caller(0))[3]." incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );

  die "".(caller(0))[3]." not implemented.";
  # TODO: auto-generated method stub. Implement me!
  
}
before 'filter' => sub { shift->logger->entering(""); };
after 'filter'  => sub { shift->logger->exiting(""); };
=item find
    Method documentation placeholder.
=cut 
sub find {
  my ($self, $coderef) = @_;
  die "".(caller(0))[3]." incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );

  die "".(caller(0))[3]." not implemented.";
  # TODO: auto-generated method stub. Implement me!
  
}
before 'find' => sub { shift->logger->entering(""); };
after 'find'  => sub { shift->logger->exiting(""); };
__PACKAGE__->meta->make_immutable;
no Moose;
1;
