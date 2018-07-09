
package MembershipMySQLDAO;

use namespace::autoclean;

use Moose;
use DBI;

# use DBIx::Connector;
use BibSpace::DAO::Interface::IDAO;
use BibSpace::Model::Membership;
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
  my $qry    = "SELECT author_id, team_id, start, stop
          FROM Author_to_Team";

  my $sth = $dbh->prepare($qry);
  $sth->execute();

  my @memberships;
  while (my $row = $sth->fetchrow_hashref()) {
    my $mem = $self->e_factory->new_Membership(
      team_id   => $row->{team_id},
      author_id => $row->{author_id},
      start     => $row->{start},
      stop      => $row->{stop}
    );
    push @memberships, $mem;
  }
  return @memberships;

}
before 'all' => sub { shift->logger->entering(""); };
after 'all'  => sub { shift->logger->exiting(""); };

=item count
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut

sub count {
  my ($self) = @_;
  my $dbh = $self->handle;
  my $sth = $dbh->prepare("SELECT COUNT(*) as num FROM Author_to_Team LIMIT 1");
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
  my $dbh    = $self->handle;
  my $sth    = $dbh->prepare("SELECT 1 as num FROM Author_to_Team LIMIT 1");
  $sth->execute();
  my $row = $sth->fetchrow_hashref();
  return 1 if not defined $row;
  return;
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
    "SELECT EXISTS(SELECT 1 FROM Author_to_Team WHERE team_id=? AND author_id=? LIMIT 1) as num "
    );
  $sth->execute($object->team_id, $object->author_id);
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
  my $dbh = $self->handle;
  foreach my $obj (@objects) {
    if ($self->exists($obj)) {
      $self->update($obj);
      $self->logger->lowdebug(
        "Updated " . ref($obj) . " ID " . $obj->id . " in DB.");
    }
    else {
      $self->_insert($obj);
      $self->logger->lowdebug(
        "Inserted " . ref($obj) . " ID " . $obj->id . " into DB.");
    }
  }
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
    INSERT INTO Author_to_Team(author_id, team_id, start, stop) VALUES (?,?,?,?);";
  my $sth = $dbh->prepare($qry);
  foreach my $obj (@objects) {
    try {
      my $result = $sth->execute($obj->author_id, $obj->team_id, $obj->start,
        $obj->stop);
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
  my $dbh = $self->handle;

  foreach my $obj (@objects) {
    next if !defined $obj->id;

    # update field 'modified_time' only if needed
    my $qry = "UPDATE Author_to_Team SET
                      start=?,
                      stop=?
              WHERE author_id = ? AND team_id = ?";

    my $sth = $dbh->prepare($qry);
    try {
      my $result = $sth->execute($obj->start, $obj->stop, $obj->author_id,
        $obj->team_id);
    }
    catch {
      $self->logger->error("Update exception: $_");
    };
  }
}
before 'update' => sub { shift->logger->entering(""); };
after 'update'  => sub { shift->logger->exiting(""); };

=item delete
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut

sub delete {
  my ($self, @objects) = @_;
  my $dbh    = $self->handle;
  my $result = 0;
  foreach my $obj (@objects) {
    next if !defined $obj;
    my $qry = "DELETE FROM Author_to_Team WHERE author_id=? AND team_id=?;";
    my $sth = $dbh->prepare($qry);
    try {
      if (defined $obj->author and defined $obj->team) {
        $result = $sth->execute($obj->author->id, $obj->team->id);
      }
      else {
        $result = $sth->execute($obj->author_id, $obj->team_id);
      }
    }
    catch {
      $result = 0;
      $self->logger->error("Delete exception: $_");
    };
  }
  return 1 if $result > 0;
  return;
}
before 'delete' => sub { shift->logger->entering(""); };
after 'delete'  => sub { shift->logger->exiting(""); };

=item filter
    Method documentation placeholder.
=cut

sub filter {
  my ($self, $coderef) = @_;

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

  return if $self->empty();
  my $obj = first \&{$coderef}, $self->all();

  return $obj;

}
before 'find' => sub { shift->logger->entering(""); };
after 'find'  => sub { shift->logger->exiting(""); };
__PACKAGE__->meta->make_immutable;
no Moose;
1;
