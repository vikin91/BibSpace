# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T14:47:33
package MySQLDAOFactory;

use namespace::autoclean;
use feature qw(current_sub);
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

has 'handle' => ( is => 'ro', required => 1, traits => ['DoNotSerialize']);
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );
has 'e_factory' => ( is => 'ro', isa => 'EntityFactory', required => 1);

sub getMembershipDao {
  my $self       = shift;
  return MembershipMySQLDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getMembershipDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getMembershipDao" ); };
after 'getMembershipDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getMembershipDao" ); };

sub getTagDao {
  my $self       = shift;
  return TagMySQLDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getTagDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getTagDao" ); };
after 'getTagDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getTagDao" ); };

sub getAuthorshipDao {
  my $self       = shift;
  return AuthorshipMySQLDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getAuthorshipDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getAuthorshipDao" ); };
after 'getAuthorshipDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getAuthorshipDao" ); };

sub getEntryDao {
  my $self       = shift;
  return EntryMySQLDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getEntryDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getEntryDao" ); };
after 'getEntryDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getEntryDao" ); };

sub getTeamDao {
  my $self       = shift;
  return TeamMySQLDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getTeamDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getTeamDao" ); };
after 'getTeamDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getTeamDao" ); };

sub getExceptionDao {
  my $self       = shift;
  return ExceptionMySQLDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getExceptionDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getExceptionDao" ); };
after 'getExceptionDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getExceptionDao" ); };

sub getTagTypeDao {
  my $self       = shift;
  return TagTypeMySQLDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getTagTypeDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getTagTypeDao" ); };
after 'getTagTypeDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getTagTypeDao" ); };

sub getLabelingDao {
  my $self       = shift;
  return LabelingMySQLDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getLabelingDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getLabelingDao" ); };
after 'getLabelingDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getLabelingDao" ); };

sub getAuthorDao {
  my $self       = shift;
  return AuthorMySQLDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getAuthorDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getAuthorDao" ); };
after 'getAuthorDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getAuthorDao" ); };

sub getTypeDao {
  my $self       = shift;
  return TypeMySQLDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getTypeDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getTypeDao" ); };
after 'getTypeDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getTypeDao" ); };

sub getUserDao {
  my $self       = shift;
  return UserMySQLDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getUserDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getUserDao" ); };
after 'getUserDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getUserDao" ); };

__PACKAGE__->meta->make_immutable;
no Moose;
1;
