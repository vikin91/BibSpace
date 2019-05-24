# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T17:02:11
package TypeMySQLDAO;

use namespace::autoclean;

use Moose;
use BibSpace::DAO::Interface::IDAO;
use BibSpace::Model::Type;
with 'IDAO';
use Try::Tiny;
use List::Util qw(first);
use List::MoreUtils qw(first_index);
use feature qw( say );

# for benchmarking
use Time::HiRes qw( gettimeofday tv_interval );

# Inherited fields from BibSpace::DAO::Interface::ITypeDAO Mixin:
# has 'logger' => ( is => 'ro', does => 'BibSpace::Util::ILogger', required => 1);
# has 'handle' => ( is => 'ro', required => 1);

=item all
    Method documentation placeholder.
=cut

sub all {
  my ($self) = @_;

  my $dbh = $self->handle;

  my $qry = "SELECT bibtex_type, our_type, landing, description
         FROM OurType_to_Type";

  my $sth = $dbh->prepare($qry);
  $sth->execute();

  # key = our_type
  # values = bibtex_types
  my %data_bibtex;
  my %data_desc;
  my %data_landing;

  while (my $row = $sth->fetchrow_hashref()) {
    my $our_type = $row->{our_type};
    if ($data_bibtex{"$our_type"}) {
      push @{$data_bibtex{"$our_type"}}, $row->{bibtex_type};
    }
    else {
      $data_bibtex{"$our_type"} = [$row->{bibtex_type}];
    }
    $data_desc{"$our_type"}    = $row->{description};
    $data_landing{"$our_type"} = $row->{landing};
  }

  my @mappings;
  foreach my $k (keys %data_bibtex) {
    my @bibtex_types = @{$data_bibtex{$k}};
    my $desc         = $data_desc{$k};
    my $landing      = $data_landing{$k};

    my $obj = $self->e_factory->new_Type(
      our_type    => $k,
      description => $desc,
      onLanding   => $landing
    );
    $obj->bibtexTypes_add(@bibtex_types);
    push @mappings, $obj;
  }
  return @mappings;
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
    "SELECT COUNT(DISTINCT our_type) as num FROM OurType_to_Type LIMIT 1");
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
  my $sth    = $dbh->prepare("SELECT 1 as num FROM OurType_to_Type LIMIT 1;");
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
    "SELECT EXISTS(SELECT 1 FROM OurType_to_Type WHERE our_type=? LIMIT 1) as num "
    );
  $sth->execute($object->our_type);
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num > 0;
}
before 'exists' => sub { shift->logger->entering(""); };
after 'exists'  => sub { shift->logger->exiting(""); };

=item _insert
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut

sub _insert {
  my ($self, @objects) = @_;
  my $dbh = $self->handle;
  my $qry = "
    INSERT INTO OurType_to_Type(bibtex_type, our_type, landing, description) VALUES (?,?,?,?);";
  my $sth = $dbh->prepare($qry);
  foreach my $obj (@objects) {
    foreach my $bibtex_type ($obj->bibtexTypes_all) {
      try {
        my $result
          = $sth->execute($bibtex_type, $obj->our_type, $obj->onLanding,
          $obj->description);
      }
      catch {
        $self->logger->error("Insert exception: $_");
      };
    }
  }

  # $dbh->commit();
}
before '_insert' => sub { shift->logger->entering(""); };
after '_insert'  => sub { shift->logger->exiting(""); };

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
    }
    else {
      $self->_insert($obj);
    }
  }
}
before 'save' => sub { shift->logger->entering(""); };
after 'save'  => sub { shift->logger->exiting(""); };

=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut

sub update {
  my ($self, @objects) = @_;

  # we have no autoincrement ID here, so we may delete all and reinsert
  $self->delete(@objects);
  $self->_insert(@objects);
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
  my $qry    = "
    DELETE FROM OurType_to_Type WHERE our_type=?;";
  my $sth = $dbh->prepare($qry);
  foreach my $obj (@objects) {
    try {
      $result = $sth->execute($obj->our_type);
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
