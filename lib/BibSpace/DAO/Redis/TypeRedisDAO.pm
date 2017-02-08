# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T17:02:11
package BibSpace::DAO::Redis::TypeRedisDAO;

use namespace::autoclean;

use Moose;
use BibSpace::DAO::Interface::ITypeDAO;
use BibSpace::Model::Type;
with 'BibSpace::DAO::Interface::ITypeDAO';

# Inherited fields from BibSpace::DAO::Interface::ITypeDAO Mixin:
# has 'logger' => ( is => 'ro', does => 'BibSpace::Util::ILogger', required => 1);
# has 'handle' => ( is => 'ro', required => 1);

=item all
    Method documentation placeholder.
=cut 
sub all {
  my ($self) = @_;
  $self->logger->entering("");
  die "".(caller(0))[3]." not implemented.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("");
}

=item save
    Method documentation placeholder.
=cut 
sub save {
  my ($self, @objects) = @_;
  $self->logger->entering("");
  die "".(caller(0))[3]." not implemented. Method was instructed to save ".scalar(@objects)." objects.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("");
}

=item update
    Method documentation placeholder.
=cut 
sub update {
  my ($self, @objects) = @_;
  $self->logger->entering("");
  die "".(caller(0))[3]." not implemented. Method was instructed to save ".scalar(@objects)." objects.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("");
}

=item delete
    Method documentation placeholder.
=cut 
sub delete {
  my ($self, @objects) = @_;
  $self->logger->entering("");
  die "".(caller(0))[3]." not implemented. Method was instructed to save ".scalar(@objects)." objects.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("");
}

=item exists
    Method documentation placeholder.
=cut 
sub exists {
  my ($self, @objects) = @_;
  $self->logger->entering("");
  die "".(caller(0))[3]." not implemented. Method was instructed to save ".scalar(@objects)." objects.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("");
}

=item filter
    Method documentation placeholder.
=cut 
sub filter {
  my ($self, $coderef) = @_;
  $self->logger->entering("");
  die "".(caller(0))[3]." incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  die "".(caller(0))[3]." not implemented.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("");
}

=item find
    Method documentation placeholder.
=cut 
sub find {
  my ($self, $coderef) = @_;
  $self->logger->entering("");
  die "".(caller(0))[3]." incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  die "".(caller(0))[3]." not implemented.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("");
}

=item count
    Method documentation placeholder.
=cut 
sub count {
  my ($self, $coderef) = @_;
  $self->logger->entering("");
  die "".(caller(0))[3]." incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  die "".(caller(0))[3]." not implemented.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("");
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
