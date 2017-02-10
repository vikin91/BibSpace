
package UserMySQLDAO;

use namespace::autoclean;

use Moose;
use BibSpace::DAO::Interface::IDAO;
use BibSpace::Model::User;
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
  my $qry = "SELECT 
              id, 
              login, 
              registration_time, 
              last_login, 
              real_name, 
              email, 
              pass, 
              pass2, 
              pass3, 
              rank, 
              master_id, 
              tennant_id
            FROM Login
            ORDER BY login ASC";

  my $sth;
  try {
    $sth = $dbh->prepare($qry);
    $sth->execute();
  }
  catch {
    $self->logger->error( "SELECT exception: $_");
  };


  # this pattern was used in mysql internally
  my $mysqlPattern
      = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S' );

  my @objs;
  while ( my $row = $sth->fetchrow_hashref() ) {
    # set formatter to parse date/time in the requested format
    my $rt = $mysqlPattern->parse_datetime( $row->{registration_time} );
    my $ll = $mysqlPattern->parse_datetime( $row->{last_login} );
    # set defaults if there is no data in mysql 
    $rt ||= DateTime->now();# formatter => $mysqlPattern);  # do not store pattern! - it is incompat. with Storable
    $ll ||= DateTime->now();# formatter => $mysqlPattern);  # do not store pattern! - it is incompat. with Storable

    my $obj = $self->e_factory->new_User(
      old_mysql_id      => $row->{id},
      id                => $row->{id},
      login             => $row->{login},
      registration_time => $rt,
      last_login        => $ll,
      real_name         => $row->{real_name},
      email             => $row->{email},
      pass              => $row->{pass},
      pass2             => $row->{pass2},
      pass3             => $row->{pass3},
      rank              => $row->{rank},
      master_id         => $row->{master_id},
      tennant_id        => $row->{tennant_id},
    );
    push @objs, $obj;
  }
  return @objs;
}
before 'all' => sub { shift->logger->entering( "" ); };
after 'all' => sub { shift->logger->exiting( "" ); };

=item count
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 

sub count {
  my ($self) = @_;
  my $dbh    = $self->handle;
  my $sth    = $dbh->prepare("SELECT COUNT(*) as num FROM Login LIMIT 1");
  $sth->execute();
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num;
}
before 'count' => sub { shift->logger->entering( "" ); };
after 'count' => sub { shift->logger->exiting( "" ); };

=item empty
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 

sub empty {
  my ($self) = @_;
  my $dbh    = $self->handle;
  my $sth    = $dbh->prepare("SELECT 1 as num FROM Login LIMIT 1");
  $sth->execute();
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num == 0;
}
before 'empty' => sub { shift->logger->entering( "" ); };
after 'empty' => sub { shift->logger->exiting( "" ); };

=item exists
    Method documentation placeholder.
    This method takes single object as argument and returns a scalar.
=cut 

sub exists {
  my ( $self, $object ) = @_;
  my $dbh = $self->handle;
  my $sth = $dbh->prepare("SELECT EXISTS(SELECT 1 FROM Login WHERE id=? LIMIT 1) as num ");
  $sth->execute( $object->id );
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num > 0;
}
before 'exists' => sub { shift->logger->entering( "" ); };
after 'exists' => sub { shift->logger->exiting( "" ); };

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
      $self->logger->lowdebug( "Updated ".ref($obj)." ID " . $obj->id . " in DB." );
    }
    else {
      $self->_insert($obj);
      $self->logger->lowdebug( "Inserted ".ref($obj)." ID " . $obj->id . " into DB." );
    }
  }
}
before 'save' => sub { shift->logger->entering( "" ); };
after 'save' => sub { shift->logger->exiting( "" ); };

=item _insert
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub _insert {
  my ( $self, @objects ) = @_;
  my $dbh = $self->handle;
  my $qry = "
    INSERT INTO Login(
      id, 
      login, 
      registration_time, 
      last_login, 
      real_name, 
      email, 
      pass, 
      pass2, 
      pass3, 
      rank, 
      master_id, 
      tennant_id
    ) 
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?);";
  my $sth = $dbh->prepare($qry);
  foreach my $obj (@objects) {
    
    try {
      my $result = $sth->execute(
        $obj->id,
        $obj->login,
        $obj->registration_time,
        $obj->last_login,
        $obj->real_name,
        $obj->email,
        $obj->pass,
        $obj->pass2,
        $obj->pass3,
        $obj->rank,
        $obj->master_id,
        $obj->tennant_id
      );
    }
    catch {
      $self->logger->error( "Insert exception: $_");
    };
  }
  # $dbh->commit();
}
before '_insert' => sub { shift->logger->entering(""); };
after '_insert' => sub { shift->logger->exiting(""); };

=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub update {
  my ( $self, @objects ) = @_;
  my $dbh = $self->handle;

  foreach my $obj (@objects) {
    next if !defined $obj->login;

    # update field 'modified_time' only if needed
    my $qry = "UPDATE Login SET 
            login=?,
            registration_time=?, 
            last_login=?, 
            real_name=?, 
            email=?, 
            pass=?, 
            pass2=?, 
            pass3=?, 
            rank=?, 
            master_id=?, 
            tennant_id=?
          WHERE id = ?";

    my $sth = $dbh->prepare($qry);
    try {
      my $result = $sth->execute(
        $obj->login,
        $obj->registration_time,
        $obj->last_login,
        $obj->real_name,
        $obj->email,
        $obj->pass,
        $obj->pass2,
        $obj->pass3,
        $obj->rank,
        $obj->master_id,
        $obj->tennant_id,
        $obj->id
      );
    }
    catch {
      $self->logger->error( "Update exception: $_");
    };
  }

}
before 'update' => sub { shift->logger->entering( ""); };
after 'update' => sub { shift->logger->exiting( ""); };

=item delete
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub delete {
  my ( $self, @objects ) = @_;
  my $dbh = $self->handle;
  foreach my $obj (@objects) {
    my $qry = "DELETE FROM Login WHERE id=?;";
    my $sth = $dbh->prepare($qry);
    try {
      my $result = $sth->execute( $obj->id );
    }
    catch {
      $self->logger->error( "Delete exception: $_" );
    };
  }

}
before 'delete' => sub { shift->logger->entering( "" ); };
after 'delete' => sub { shift->logger->exiting( "" ); };

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
before 'filter' => sub { shift->logger->entering( "" ); };
after 'filter' => sub { shift->logger->exiting( "" ); };

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
before 'find' => sub { shift->logger->entering( "" ); };
after 'find' => sub { shift->logger->exiting( "" ); };
__PACKAGE__->meta->make_immutable;
no Moose;
1;
