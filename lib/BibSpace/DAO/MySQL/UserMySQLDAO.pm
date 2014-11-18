
package UserMySQLDAO;

use namespace::autoclean;

use Moose;
use BibSpace::DAO::Interface::IDAO;
use BibSpace::Model::User;
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
    $self->logger->error("SELECT exception: $_");
  };

  # this pattern was used in mysql internally
  my $mysqlPattern
    = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d %H:%M:%S');

  my @objs;
  while (my $row = $sth->fetchrow_hashref()) {

    # set formatter to parse date/time in the requested format
    my $regTime   = $mysqlPattern->parse_datetime($row->{registration_time});
    my $lastLogin = $mysqlPattern->parse_datetime($row->{last_login});

    # set defaults if there is no data in mysql
    $regTime   ||= DateTime->now();
    $lastLogin ||= DateTime->now();

    my $obj = $self->e_factory->new_User(
      old_mysql_id      => $row->{id},
      id                => $row->{id},
      login             => $row->{login},
      registration_time => $regTime,
      last_login        => $lastLogin,
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
  return 1 if not defined $row;
  return;
}

=item exists
    Method documentation placeholder.
    This method takes single object as argument and returns a scalar.
=cut

sub exists {
  my ($self, $object) = @_;
  my $dbh = $self->handle;
  my $sth = $dbh->prepare(
    "SELECT EXISTS(SELECT 1 FROM Login WHERE id=? LIMIT 1) as num ");
  $sth->execute($object->id);
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num > 0;
}

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

=item _insert
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut

sub _insert {
  my ($self, @objects) = @_;
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
    my $id = undef;
    $id = $obj->id if defined $obj->id and $obj->id > 0;
    try {
      my $result = $sth->execute(
        $id,              $obj->login,     $obj->registration_time,
        $obj->last_login, $obj->real_name, $obj->email,
        $obj->pass,       $obj->pass2,     $obj->pass3,
        $obj->rank,       $obj->master_id, $obj->tennant_id
      );
      $obj->id($sth->{mysql_insertid});
    }
    catch {
      $self->logger->error("Insert exception: $_");
    };
  }

  # $dbh->commit();
}

=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut

sub update {
  my ($self, @objects) = @_;
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
        $obj->login,     $obj->registration_time, $obj->last_login,
        $obj->real_name, $obj->email,             $obj->pass,
        $obj->pass2,     $obj->pass3,             $obj->rank,
        $obj->master_id, $obj->tennant_id,        $obj->id
      );
    }
    catch {
      $self->logger->error("Update exception: $_");
    };
  }

}

=item delete
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut

sub delete {
  my ($self, @objects) = @_;
  my $dbh    = $self->handle;
  my $result = 0;
  foreach my $obj (@objects) {
    my $qry = "DELETE FROM Login WHERE id=?;";
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

=item filter
    Method documentation placeholder.
=cut

sub filter {
  my ($self, $coderef) = @_;

  return () if $self->empty();
  my @arr = grep &{$coderef}, $self->all();

  return @arr;

}

=item find
    Method documentation placeholder.
=cut

sub find {
  my ($self, $coderef) = @_;

  return if $self->empty();
  my $obj = first \&{$coderef}, $self->all();

  return $obj;

}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
