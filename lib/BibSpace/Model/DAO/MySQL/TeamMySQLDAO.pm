# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T17:18:02
package BibSpace::Model::DAO::MySQL::TeamMySQLDAO;

use namespace::autoclean;
use Moose;
use BibSpace::Model::DAO::Interface::ITeamDAO;
use BibSpace::Model::Team;
with 'BibSpace::Model::DAO::Interface::ITeamDAO';

# Inherited fields from BibSpace::Model::DAO::Interface::ITeamDAO Mixin:
# has 'logger' => ( is => 'ro', does => 'BibSpace::Model::ILogger', required => 1);
# has 'handle' => ( is => 'ro', required => 1);

=item all
    Method documentation placeholder.
=cut 
sub all {
  my ($self) = @_;
  $self->logger->entering("","".__PACKAGE__."->all");
  die "".__PACKAGE__."->all not implemented.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->all");
}

=item save
    Method documentation placeholder.
=cut 
sub save {
  my ($self, @objects) = @_;
  $self->logger->entering("","".__PACKAGE__."->save");
  die "".__PACKAGE__."->save not implemented. Method was instructed to save ".scalar(@objects)." objects.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->save");
}

=item update
    Method documentation placeholder.
=cut 
sub update {
  my ($self, @objects) = @_;
  $self->logger->entering("","".__PACKAGE__."->update");
  die "".__PACKAGE__."->update not implemented. Method was instructed to save ".scalar(@objects)." objects.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->update");
}

=item delete
    Method documentation placeholder.
=cut 
sub delete {
  my ($self, @objects) = @_;
  $self->logger->entering("","".__PACKAGE__."->delete");
  die "".__PACKAGE__."->delete not implemented. Method was instructed to save ".scalar(@objects)." objects.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->delete");
}

=item exists
    Method documentation placeholder.
=cut 
sub exists {
  my ($self, @objects) = @_;
  $self->logger->entering("","".__PACKAGE__."->exists");
  die "".__PACKAGE__."->exists not implemented. Method was instructed to save ".scalar(@objects)." objects.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->exists");
}

=item filter
    Method documentation placeholder.
=cut 
sub filter {
  my ($self, $coderef) = @_;
  $self->logger->entering("","".__PACKAGE__."->filter");
  die "".__PACKAGE__."->filter incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  die "".__PACKAGE__."->filter not implemented.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->filter");
}

=item find
    Method documentation placeholder.
=cut 
sub find {
  my ($self, $coderef) = @_;
  $self->logger->entering("","".__PACKAGE__."->find");
  die "".__PACKAGE__."->find incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  die "".__PACKAGE__."->find not implemented.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->find");
}

=item count
    Method documentation placeholder.
=cut 
sub count {
  my ($self, $coderef) = @_;
  $self->logger->entering("","".__PACKAGE__."->count");
  die "".__PACKAGE__."->count incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  die "".__PACKAGE__."->count not implemented.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->count");
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
