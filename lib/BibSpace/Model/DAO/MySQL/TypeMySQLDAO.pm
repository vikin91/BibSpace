# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T17:02:11
package TypeMySQLDAO;

use namespace::autoclean;
use Moose;
use BibSpace::Model::DAO::Interface::IDAO;
use BibSpace::Model::Type;
with 'IDAO';
use Try::Tiny;

# Inherited fields from BibSpace::Model::DAO::Interface::ITypeDAO Mixin:
# has 'logger' => ( is => 'ro', does => 'BibSpace::Model::ILogger', required => 1);
# has 'handle' => ( is => 'ro', required => 1);

=item all
    Method documentation placeholder.
=cut 

sub all {
  my ($self) = @_;

   my $dbh    = $self->handle;

  my $qry = "SELECT bibtex_type, our_type, landing, description
         FROM OurType_to_Type";

  my $sth = $dbh->prepare($qry);
  $sth->execute();

  # key = our_type
  # values = bibtex_types
  my %data_bibtex;
  my %data_desc;
  my %data_landing;

  while ( my $row = $sth->fetchrow_hashref() ) {
    my $our_type = $row->{our_type};
    if ( $data_bibtex{ "$our_type" } ) {
      push @{ $data_bibtex{ "$our_type" } }, $row->{bibtex_type};
    }
    else {
      $data_bibtex{ "$our_type" } = [ $row->{bibtex_type} ];
    }
    $data_desc{ "$our_type" }    = $row->{description};
    $data_landing{ "$our_type" } = $row->{landing};
  }

  my @mappings;
  foreach my $k ( keys %data_bibtex ) {
    my @bibtex_types = @{ $data_bibtex{$k} };
    my $desc         = $data_desc{$k};
    my $landing      = $data_landing{$k};

    my $obj = Type->new( idProvider => $self->idProvider, our_type => $k, description => $desc, onLanding => $landing );
    $obj->bibtexTypes_add(@bibtex_types);
    push @mappings, $obj;
  }
  return @mappings;
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
  my $sth    = $dbh->prepare("SELECT COUNT(our_type) as num FROM OurType_to_Type LIMIT 1");
  $sth->execute();
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
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
  return $self->count == 0;
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
  my $sth = $dbh->prepare("SELECT EXISTS(SELECT 1 FROM OurType_to_Type WHERE our_type=? LIMIT 1) as num ");
  $sth->execute( $object->our_type );
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num > 0;
}
before 'exists' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->exists" ); };
after 'exists' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->exists" ); };

=item _insert
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub _insert {
  my ( $self, @objects ) = @_;
  my $dbh = $self->handle;
  my $qry = "
    INSERT INTO OurType_to_Type(bibtex_type, our_type, landing, description) VALUES (?,?,?,?);";
  my $sth = $dbh->prepare($qry);
  foreach my $obj (@objects) {
    foreach my $bibtex_type ($obj->bibtexTypes_all) {
      try {
        my $result = $sth->execute( $bibtex_type, $obj->our_type, $obj->onLanding, $obj->description);
        $sth->finish();
      }
      catch {
        $self->logger->error( "Insert exception: $_", "" . __PACKAGE__ . "->insert" );
      };
    }
  }
  # $dbh->commit();
}
before '_insert' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->_insert" ); };
after '_insert' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->_insert" ); };


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
      $self->logger->info( "Updated ".ref($obj)." ID " . $obj->id . " in DB.", "" . __PACKAGE__ . "->save" );
    }
    else {
      $self->_insert($obj);
      $self->logger->info( "Inserted ".ref($obj)." ID " . $obj->id . " into DB.", "" . __PACKAGE__ . "->save" );
    }
  }
}
before 'save' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->save" ); };
after 'save' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->save" ); };

=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub update {
  my ( $self, @objects ) = @_;
  # we have no autoincrement ID here, so we may delete all and reinsert
  $self->delete(@objects);
  $self->_insert(@objects);
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
  my $qry = "
    DELETE FROM OurType_to_Type WHERE our_type=?;";
  my $sth = $dbh->prepare($qry);
  foreach my $obj (@objects) {
    try {
      my $result = $sth->execute( $obj->our_type );
      $sth->finish();
    }
    catch {
      $self->logger->error( "Delete exception: $_", "" . __PACKAGE__ . "->delete" );
    };
  }
  # $dbh->commit();
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
