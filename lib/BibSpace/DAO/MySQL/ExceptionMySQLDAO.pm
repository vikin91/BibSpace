
package ExceptionMySQLDAO;

use namespace::autoclean;

use Moose;
use BibSpace::DAO::Interface::IDAO;
use BibSpace::Model::Exception;
with 'IDAO';
use Try::Tiny;
use List::Util qw(first);
use List::MoreUtils qw(first_index);
use feature qw( say );

# for benchmarking
use Time::HiRes qw( gettimeofday tv_interval );

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
  my $qry    = "SELECT team_id, entry_id FROM Exceptions_Entry_to_Team";

  my @objs;
  my $sth = $dbh->prepare($qry);
  $sth->execute();

  while (my $row = $sth->fetchrow_hashref()) {
    push @objs,
      Exception->new(entry_id => $row->{entry_id}, team_id => $row->{team_id});
  }
  return @objs;
}
before 'all' => sub { shift->logger->entering(""); };
after 'all'  => sub { shift->logger->exiting(""); };

=item count
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 

sub count {
  my ($self) = @_;
  my $dbh    = $self->handle;
  my $sth    = $dbh->prepare(
    "SELECT COUNT(*) as num FROM Exceptions_Entry_to_Team LIMIT 1");
  $sth->execute();
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num;
}
before 'count' => sub { shift->logger->entering(""); };
after 'count'  => sub { shift->logger->exiting(""); };

=item empty
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 

sub empty {
  my ($self) = @_;
  my $dbh = $self->handle;
  my $sth
    = $dbh->prepare("SELECT 1 as num FROM Exceptions_Entry_to_Team LIMIT 1");
  $sth->execute();
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num == 0;
}
before 'empty' => sub { shift->logger->entering(""); };
after 'empty'  => sub { shift->logger->exiting(""); };

=item exists
    Method documentation placeholder.
    This method takes single object as argument and returns a scalar.
=cut 

sub exists {
  my ($self, $object) = @_;
  my $dbh = $self->handle;
  my $sth
    = $dbh->prepare(
    "SELECT EXISTS(SELECT 1 FROM Exceptions_Entry_to_Team WHERE team_id=? AND entry_id=? LIMIT 1) as num "
    );
  $sth->execute($object->team_id, $object->entry_id,);
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num > 0;
}
before 'exists' => sub { shift->logger->entering(""); };
after 'exists'  => sub { shift->logger->exiting(""); };

=item save
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub save {
  my ($self, @objects) = @_;
  $self->_insert(@objects);

}
before 'save' => sub { shift->logger->entering(""); };
after 'save'  => sub { shift->logger->exiting(""); };

=item _insert
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub _insert {
  my ($self, @objects) = @_;
  my $dbh = $self->handle;
  my $qry = "
    INSERT IGNORE INTO Exceptions_Entry_to_Team(team_id, entry_id) VALUES (?,?);";
  my $sth = $dbh->prepare($qry);
  foreach my $obj (@objects) {
    try {
      my $result = $sth->execute($obj->team_id, $obj->entry_id);
      $self->logger->lowdebug(
        "Inserted " . ref($obj) . " ID " . $obj->id . " into DB.");
    }
    catch {
      $self->logger->error("Insert exception: $_");
    };
  }

  # $dbh->commit();
}
before '_insert' => sub { shift->logger->entering(""); };
after '_insert'  => sub { shift->logger->exiting(""); };

=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub update {
  my ($self, @objects) = @_;

  warn ""
    . (caller(0))[3]
    . " it makes no sense to update Exception! Method was instructed to update "
    . scalar(@objects)
    . " objects.";

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
  my $dbh = $self->handle;
  foreach my $obj (@objects) {
    my $qry
      = "DELETE FROM Exceptions_Entry_to_Team WHERE entry_id=? AND team_id=?;";
    my $sth = $dbh->prepare($qry);
    try {
      my $result = $sth->execute($obj->entry_id, $obj->team_id);
    }
    catch {
      $self->logger->error("Delete exception: $_");
    };
  }
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

  return () if $self->empty();
  my @arr = grep &{$coderef}, $self->all();

  return @arr;
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

  return if $self->empty();
  my $obj = first \&{$coderef}, $self->all();

  return $obj;

}
before 'find' => sub { shift->logger->entering(""); };
after 'find'  => sub { shift->logger->exiting(""); };
__PACKAGE__->meta->make_immutable;
no Moose;
1;
