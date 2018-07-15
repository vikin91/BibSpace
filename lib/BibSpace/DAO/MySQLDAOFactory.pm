# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T14:47:33
package MySQLDAOFactory;

use namespace::autoclean;

use Moose;
use BibSpace::Util::ILogger;
use BibSpace::DAO::MySQL::MembershipMySQLDAO;
use BibSpace::DAO::MySQL::TagMySQLDAO;
use BibSpace::DAO::MySQL::AuthorshipMySQLDAO;
use BibSpace::DAO::MySQL::EntryMySQLDAO;
use BibSpace::DAO::MySQL::TeamMySQLDAO;
use BibSpace::DAO::MySQL::ExceptionMySQLDAO;
use BibSpace::DAO::MySQL::TagTypeMySQLDAO;
use BibSpace::DAO::MySQL::LabelingMySQLDAO;
use BibSpace::DAO::MySQL::AuthorMySQLDAO;
use BibSpace::DAO::MySQL::TypeMySQLDAO;
use BibSpace::DAO::MySQL::UserMySQLDAO;
use BibSpace::DAO::DAOFactory;
extends 'DAOFactory';

has 'handle' => (is => 'ro', required => 1, traits => ['DoNotSerialize']);
has 'logger'    => (is => 'ro', does => 'ILogger',       required => 1);
has 'e_factory' => (is => 'ro', isa  => 'EntityFactory', required => 1);

sub getMembershipDao {
  my $self = shift;
  return MembershipMySQLDAO->new(
    logger    => $self->logger,
    handle    => $self->handle,
    e_factory => $self->e_factory
  );
}

sub getTagDao {
  my $self = shift;
  return TagMySQLDAO->new(
    logger    => $self->logger,
    handle    => $self->handle,
    e_factory => $self->e_factory
  );
}

sub getAuthorshipDao {
  my $self = shift;
  return AuthorshipMySQLDAO->new(
    logger    => $self->logger,
    handle    => $self->handle,
    e_factory => $self->e_factory
  );
}

sub getEntryDao {
  my $self = shift;
  return EntryMySQLDAO->new(
    logger    => $self->logger,
    handle    => $self->handle,
    e_factory => $self->e_factory
  );
}

sub getTeamDao {
  my $self = shift;
  return TeamMySQLDAO->new(
    logger    => $self->logger,
    handle    => $self->handle,
    e_factory => $self->e_factory
  );
}

sub getExceptionDao {
  my $self = shift;
  return ExceptionMySQLDAO->new(
    logger    => $self->logger,
    handle    => $self->handle,
    e_factory => $self->e_factory
  );
}

sub getTagTypeDao {
  my $self = shift;
  return TagTypeMySQLDAO->new(
    logger    => $self->logger,
    handle    => $self->handle,
    e_factory => $self->e_factory
  );
}

sub getLabelingDao {
  my $self = shift;
  return LabelingMySQLDAO->new(
    logger    => $self->logger,
    handle    => $self->handle,
    e_factory => $self->e_factory
  );
}

sub getAuthorDao {
  my $self = shift;
  return AuthorMySQLDAO->new(
    logger    => $self->logger,
    handle    => $self->handle,
    e_factory => $self->e_factory
  );
}

sub getTypeDao {
  my $self = shift;
  return TypeMySQLDAO->new(
    logger    => $self->logger,
    handle    => $self->handle,
    e_factory => $self->e_factory
  );
}

sub getUserDao {
  my $self = shift;
  return UserMySQLDAO->new(
    logger    => $self->logger,
    handle    => $self->handle,
    e_factory => $self->e_factory
  );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
