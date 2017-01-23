# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T13:56:17
package AuthorshipMySQLDAO;

use namespace::autoclean;
use Moose;
use BibSpace::Model::DAO::Interface::IDAO;
use BibSpace::Model::Authorship;
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
  my $dbh = $self->handle;
  my $qry = "SELECT author_id, entry_id
            FROM Entry_to_Author";

  my $sth = $dbh->prepare($qry);
  $sth->execute();

  my @objects;

  while ( my $row = $sth->fetchrow_hashref() ) {
      my $authorship = Authorship->new( author_id => $row->{author_id}, entry_id => $row->{entry_id} );
      push @objects, $authorship;
    }
  return @objects;
}
before 'all' => sub { shift->logger->entering("","".__PACKAGE__."->all"); };
after 'all'  => sub { shift->logger->exiting("","".__PACKAGE__."->all"); };
=item count
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub count {
  my ($self) = @_;

  die "".__PACKAGE__."->count not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before 'count' => sub { shift->logger->entering("","".__PACKAGE__."->count"); };
after 'count'  => sub { shift->logger->exiting("","".__PACKAGE__."->count"); };
=item empty
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub empty {
  my ($self) = @_;
  my $dbh = $self->handle;
  my $sth = $dbh->prepare("SELECT 1 as num FROM Entry_to_Author LIMIT 1");
  $sth->execute();
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num == 0;
}
before 'empty' => sub { shift->logger->entering("","".__PACKAGE__."->empty"); };
after 'empty'  => sub { shift->logger->exiting("","".__PACKAGE__."->empty"); };

=item exists
    Method documentation placeholder.
    This method takes single object as argument and returns a scalar.
=cut 
sub exists {
  my ($self, $object) = @_;
  my $dbh = $self->handle;
  my $sth = $dbh->prepare("SELECT EXISTS(SELECT 1 FROM Entry_to_Author WHERE author_id=? AND entry_id=? LIMIT 1) as num ");
  $sth->execute($object->author_id, $object->entry_id,);
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num > 0;
}
before 'exists' => sub { shift->logger->entering("","".__PACKAGE__."->exists"); };
after 'exists'  => sub { shift->logger->exiting("","".__PACKAGE__."->exists"); };

=item save
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub save {
  my ( $self, @objects ) = @_;
  my $dbh = $self->handle;
  foreach my $obj (@objects) {
    if ( $self->exists($obj) ) {
      $self->update($obj);
      $self->logger->info( "Updated object ID " . $obj->id . " in DB.", "" . __PACKAGE__ . "->save" );
    }
    else {
      $self->_insert($obj);
      $self->logger->info( "Inserted object ID " . $obj->id . " into DB.", "" . __PACKAGE__ . "->save" );
    }
  }
}
before 'save' => sub { shift->logger->entering("","".__PACKAGE__."->save"); };
after 'save'  => sub { shift->logger->exiting("","".__PACKAGE__."->save"); };

=item _insert
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub _insert {
  my ( $self, @objects ) = @_;
  my $dbh = $self->handle;
  my $qry = "
    INSERT INTO Entry_to_Author(author_id, entry_id) VALUES (?,?);";
  my $sth = $dbh->prepare($qry);
  foreach my $obj (@objects) {
    
    try {
      my $result = $sth->execute( $obj->author_id, $obj->entry_id );
      $sth->finish();
    }
    catch {
      $self->logger->error( "Insert exception: $_", "" . __PACKAGE__ . "->insert" );
    };
  }
}
before '_insert' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->_insert" ); };
after '_insert' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->_insert" ); };

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
  my ( $self, @objects ) = @_;
  my $dbh = $self->handle;
  foreach my $obj (@objects) {
    my $qry = "DELETE FROM Entry_to_Author WHERE entry_id=? AND author_id=?;";
    my $sth = $dbh->prepare($qry);
    try {
      my $result = $sth->execute( $obj->entry_id, $obj->author_id );
    }
    catch {
      $self->logger->error( "Delete exception: $_", "" . __PACKAGE__ . "->delete" );
    };
  }
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
