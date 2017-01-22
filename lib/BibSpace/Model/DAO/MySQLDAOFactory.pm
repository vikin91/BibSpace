# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T14:47:33
package MySQLDAOFactory;

use namespace::autoclean;
use Moose;
use BibSpace::Model::ILogger;
use BibSpace::Model::DAO::MySQL::MembershipMySQLDAO;
use BibSpace::Model::DAO::MySQL::TagMySQLDAO;
use BibSpace::Model::DAO::MySQL::AuthorshipMySQLDAO;
use BibSpace::Model::DAO::MySQL::EntryMySQLDAO;
use BibSpace::Model::DAO::MySQL::TeamMySQLDAO;
use BibSpace::Model::DAO::MySQL::ExceptionMySQLDAO;
use BibSpace::Model::DAO::MySQL::TagTypeMySQLDAO;
use BibSpace::Model::DAO::MySQL::LabelingMySQLDAO;
use BibSpace::Model::DAO::MySQL::AuthorMySQLDAO;
use BibSpace::Model::DAO::MySQL::TypeMySQLDAO;
use BibSpace::Model::DAO::DAOFactory;
extends 'DAOFactory';

has 'handle' => ( is => 'ro', required => 1 );
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );


sub getMembershipDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getMembershipDao MUST be called with valid idProvider!" if !defined $idProvider;
  return MembershipMySQLDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle );
}
before 'getMembershipDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getMembershipDao" ); };
after 'getMembershipDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getMembershipDao" ); };

sub getTagDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getTagDao MUST be called with valid idProvider!" if !defined $idProvider;
  return TagMySQLDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle );
}
before 'getTagDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getTagDao" ); };
after 'getTagDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getTagDao" ); };

sub getAuthorshipDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getAuthorshipDao MUST be called with valid idProvider!" if !defined $idProvider;
  return AuthorshipMySQLDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle );
}
before 'getAuthorshipDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getAuthorshipDao" ); };
after 'getAuthorshipDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getAuthorshipDao" ); };

sub getEntryDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getEntryDao MUST be called with valid idProvider!" if !defined $idProvider;
  return EntryMySQLDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle );
}
before 'getEntryDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getEntryDao" ); };
after 'getEntryDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getEntryDao" ); };

sub getTeamDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getTeamDao MUST be called with valid idProvider!" if !defined $idProvider;
  return TeamMySQLDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle );
}
before 'getTeamDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getTeamDao" ); };
after 'getTeamDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getTeamDao" ); };

sub getExceptionDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getExceptionDao MUST be called with valid idProvider!" if !defined $idProvider;
  return ExceptionMySQLDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle );
}
before 'getExceptionDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getExceptionDao" ); };
after 'getExceptionDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getExceptionDao" ); };

sub getTagTypeDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getTagTypeDao MUST be called with valid idProvider!" if !defined $idProvider;
  return TagTypeMySQLDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle );
}
before 'getTagTypeDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getTagTypeDao" ); };
after 'getTagTypeDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getTagTypeDao" ); };

sub getLabelingDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getLabelingDao MUST be called with valid idProvider!" if !defined $idProvider;
  return LabelingMySQLDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle );
}
before 'getLabelingDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getLabelingDao" ); };
after 'getLabelingDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getLabelingDao" ); };

sub getAuthorDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getAuthorDao MUST be called with valid idProvider!" if !defined $idProvider;
  return AuthorMySQLDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle );
}
before 'getAuthorDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getAuthorDao" ); };
after 'getAuthorDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getAuthorDao" ); };

sub getTypeDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getTypeDao MUST be called with valid idProvider!" if !defined $idProvider;
  return TypeMySQLDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle );
}
before 'getTypeDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getTypeDao" ); };
after 'getTypeDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getTypeDao" ); };

__PACKAGE__->meta->make_immutable;
no Moose;
1;
