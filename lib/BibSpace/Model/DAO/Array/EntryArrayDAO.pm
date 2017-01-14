# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T18:29:16
package EntryArrayDAO;

use namespace::autoclean;
use Moose;
use BibSpace::Model::DAO::Interface::IEntryDAO;
use BibSpace::Model::Entry;
with 'IEntryDAO';

# Inherited fields from BibSpace::Model::DAO::Interface::IEntryDAO Mixin:
# has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);
# has 'handle' => ( is => 'ro', required => 1);


sub BUILD {
      my $self = shift;
      # called after the default constructor
      # $self->logger->error("CONSTRUCTOR","".__PACKAGE__."->BUILD");
  }

=item all
    Method documentation placeholder.
=cut 
sub all {
  my ($self) = @_;
  $self->logger->entering("","".__PACKAGE__."->all");
  
  my @result = @{ $self->handle };

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->all");

  return @result;
}

=item save
    Method documentation placeholder.
=cut 
sub save {
  my ($self, @objects) = @_;
  $self->logger->entering("","".__PACKAGE__."->save");
  
  my $result = push $self->handle, @objects;

  $self->logger->info("Saved $result objects.","".__PACKAGE__."->save");
  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->save");
  return $result;
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
    It should be used like this:
    @allEntries = $erepo->filter( sub{$_->id > 600} );
=cut 
sub filter {
  my ($self, $coderef) = @_;
  $self->logger->entering("","".__PACKAGE__."->filter");
  die "".__PACKAGE__."->filter incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  
  my @result = grep(&{ $coderef }, @{ $self->handle });

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->filter");
  return @result;
}

=item find
    Method documentation placeholder.
=cut 
sub find {
  my ($self, $coderef) = @_;
  $self->logger->entering("","".__PACKAGE__."->find");
  die "".__PACKAGE__."->find incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  
  my @result = first {$coderef} @{ $self->handle };

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->find");
  return @result;
}

=item count
    Method documentation placeholder.
=cut 
sub count {
  my ($self, $coderef) = @_;
  $self->logger->entering("","".__PACKAGE__."->count");
  die "".__PACKAGE__."->count incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  
  my @result = $self->filter($coderef);

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->count");
  return scalar @result;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
