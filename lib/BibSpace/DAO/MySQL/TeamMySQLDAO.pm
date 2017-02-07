# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T13:56:17
package TeamMySQLDAO;

use namespace::autoclean;
use feature qw(current_sub);
use Moose;
use BibSpace::DAO::Interface::IDAO;
use BibSpace::Model::Team;
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
  my $dbh    = $self->handle;
  my $qry    = "SELECT id,
          name,
          parent
      FROM Team";
  my @objs;
  my $sth = $dbh->prepare($qry);
  $sth->execute();

  while ( my $row = $sth->fetchrow_hashref() ) {
    my $obj = $self->e_factory->new_Team(
      old_mysql_id => $row->{id},
      id           => $row->{id},
      name         => $row->{name},
      parent       => $row->{parent}
    );
    push @objs, $obj;
  }
  return @objs;
}
before 'all' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->all" ); };
after 'all' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->all" ); };

=item count
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 

sub count {
  my ($self) = @_;
  my $dbh    = $self->handle;
  my $num = 0;
  try {
    my $sth    = $dbh->prepare("SELECT COUNT(*) as num FROM Team LIMIT 1");
    $sth->execute();
    my $row = $sth->fetchrow_hashref();
    $num = $row->{num};
  }
  catch {
    $self->logger->error( "Count exception: $_", "" . __PACKAGE__ . "->count" );
  };
  return $num;
}
before 'count' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->count" ); };
after 'count' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->count" ); };

=item empty
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 

sub empty {
  my ($self) = @_;
  my $dbh    = $self->handle;
  my $num = 0;
  try {
    my $sth    = $dbh->prepare("SELECT 1 as num FROM Team LIMIT 1");
    $sth->execute();
    my $row = $sth->fetchrow_hashref();
    $num = $row->{num};
  }
  catch {
    $self->logger->error( "Count exception: $_", "" . __PACKAGE__ . "->count" );
  };
  return $num == 0;
}
before 'empty' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->empty" ); };
after 'empty' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->empty" ); };

=item exists
    Method documentation placeholder.
    This method takes single object as argument and returns a scalar.
=cut 

sub exists {
  my ( $self, $object ) = @_;
  my $dbh = $self->handle;
  my $sth = $dbh->prepare("SELECT EXISTS(SELECT 1 FROM Team WHERE id=? LIMIT 1) as num ");
  $sth->execute( $object->id );
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num > 0;

}
before 'exists' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->exists" ); };
after 'exists' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->exists" ); };

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
      $self->logger->lowdebug( "Updated ".ref($obj)." ID " . $obj->id . " in DB.", "" . __PACKAGE__ . "->save" );
    }
    else {
      $self->_insert($obj);
      $self->logger->lowdebug( "Inserted ".ref($obj)." ID " . $obj->id . " into DB.", "" . __PACKAGE__ . "->save" );
    }
  }
}
before 'save' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->save" ); };
after 'save' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->save" ); };


=item _insert
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub _insert {
  my ( $self, @objects ) = @_;
  my $dbh = $self->handle;
  my $qry = "
    INSERT INTO Team (id, name, parent) VALUES (?,?,?);";
  my $sth = $dbh->prepare($qry);
  foreach my $obj (@objects) {
    try {
      my $result = $sth->execute( $obj->id, $obj->name, $obj->parent );
    }
    catch {
      $self->logger->error( "Insert exception: $_", "" . __PACKAGE__ . "->insert" );
    };
  }
  # $dbh->commit();
}
before '_insert' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->_insert" ); };
after '_insert' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->_insert" ); };


=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub update {
  my ( $self, @objects ) = @_;
  my $dbh = $self->handle;

  my $qry = "UPDATE Team SET
                      name=?,
                      parent=?";
    $qry .= " WHERE id = ?";
  my $sth = $dbh->prepare($qry);
  foreach my $obj (@objects) {
    next if !defined $obj->id;
    try {
      my $result = $sth->execute( $obj->name, $obj->parent, $obj->id );
    }
    catch {
      $self->logger->error( "Update exception: $_", "" . __PACKAGE__ . "->update" );
    };
  }
  # $dbh->commit();
}
before 'update' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->update" ); };
after 'update' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->update" ); };

=item delete
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub delete {
  my ( $self, @objects ) = @_;
  my $dbh = $self->handle;
  foreach my $obj (@objects) {
    my $qry = "DELETE FROM Team WHERE id=?;";
    my $sth = $dbh->prepare($qry);
    try {
      my $result = $sth->execute( $obj->id );
    }
    catch {
      $self->logger->error( "Delete exception: $_", "" . __PACKAGE__ . "->delete" );
    };
  }

}
before 'delete' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->delete" ); };
after 'delete' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->delete" ); };

=item filter
    Method documentation placeholder.
=cut 

sub filter {
  my ( $self, $coderef ) = @_;
  die ""
    . __PACKAGE__
    . "->filter incorrect type of argument. Got: '"
    . ref($coderef)
    . "', expected: "
    . ( ref sub { } ) . "."
    unless ( ref $coderef eq ref sub { } );

  die "" . __PACKAGE__ . "->filter not implemented.";

  # TODO: auto-generated method stub. Implement me!

}
before 'filter' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->filter" ); };
after 'filter' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->filter" ); };

=item find
    Method documentation placeholder.
=cut 

sub find {
  my ( $self, $coderef ) = @_;
  die ""
    . __PACKAGE__
    . "->find incorrect type of argument. Got: '"
    . ref($coderef)
    . "', expected: "
    . ( ref sub { } ) . "."
    unless ( ref $coderef eq ref sub { } );

  die "" . __PACKAGE__ . "->find not implemented.";

  # TODO: auto-generated method stub. Implement me!

}
before 'find' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->find" ); };
after 'find' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->find" ); };
__PACKAGE__->meta->make_immutable;
no Moose;
1;
