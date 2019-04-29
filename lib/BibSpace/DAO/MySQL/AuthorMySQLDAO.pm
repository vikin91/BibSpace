
package AuthorMySQLDAO;

use namespace::autoclean;

use Moose;
use BibSpace::DAO::Interface::IDAO;
use BibSpace::Model::Author;
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
  my $qry    = "SELECT
          id,
          uid,
          display,
          master_id
      FROM Author";
  my @objs;
  my $sth = $dbh->prepare($qry);
  $sth->execute();

  while (my $row = $sth->fetchrow_hashref()) {
    my $obj = $self->e_factory->new_Author(
      old_mysql_id => $row->{id},
      id           => $row->{id},
      uid          => $row->{uid},
      display      => $row->{display},
      master_id    => $row->{master_id}
    );

    $obj->{masterObj} = undef;
    $obj->id;    # due to lazy filling of this field

    push @objs, $obj;
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
  my $sth    = $dbh->prepare("SELECT COUNT(*) as num FROM Author LIMIT 1");
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
  my $sth    = $dbh->prepare("SELECT 1 as num FROM Author LIMIT 1");
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
  my $sth = $dbh->prepare(
    "SELECT EXISTS(SELECT 1 FROM Author WHERE id=? LIMIT 1) as num ");
  my $result = $sth->execute($object->id);
  my $row    = $sth->fetchrow_hashref();
  my $num    = $row->{num} // 0;
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

  my $added = 0;
  foreach my $obj (@objects) {
    if ($self->exists($obj)) {
      $self->update($obj);
      $self->logger->lowdebug(
        "Updated " . ref($obj) . " ID " . $obj->id . " in DB.");
    }
    else {
      $added = $added + $self->_insert($obj);
      $self->logger->lowdebug(
        "Inserted " . ref($obj) . " ID " . $obj->id . " into DB.");
    }
  }
  return $added;
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
    INSERT INTO Author(
    id,
    uid,
    display,
    master_id
    )
    VALUES (?,?,?,?);";
  my $sth   = $dbh->prepare($qry);
  my $added = 0;
  foreach my $obj (@objects) {
    my $id        = undef;
    my $master_id = undef;
    $id        = $obj->id if defined $obj->id and $obj->id > 0;
    $master_id = $obj->get_master_id
      if defined $obj->get_master_id and $obj->get_master_id > 0;
    try {
      $added += $sth->execute($id, $obj->uid, $obj->display, $master_id);
      my $inserted_id = $sth->{mysql_insertid};
      $obj->id($inserted_id);
      if (not $master_id) {

        # sets master_id if unset
        $obj->get_master_id;

        # This updates master_id to point to i
        $obj->repo->authors_update($obj);
      }
    }
    catch {
      $self->logger->error("Author insert exception: $_");
    };
  }
  return $added;
}

=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut

sub update {
  my ($self, @objects) = @_;
  my $dbh     = $self->handle;
  my $success = 0;

  foreach my $obj (@objects) {
    next if !defined $obj->id;

    my $qry = "UPDATE Author SET
                      uid=?,
                      master_id=?,
                      display=?";
    $qry .= " WHERE id = ?";

    my $sth = $dbh->prepare($qry);
    my $result;
    try {
      $sth->execute($obj->uid, $obj->get_master_id, $obj->display, $obj->id);
      $success = 1;
    }
    catch {
      $success = 0;
      $self->logger->error("Update exception: $_");
    };
  }

  # Return for tests to signal that nothing has been thrown
  return $success;
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
    my $qry = "DELETE FROM Author WHERE id=?;";
    my $sth = $dbh->prepare($qry);
    try {
      $result = $sth->execute($obj->id);
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
