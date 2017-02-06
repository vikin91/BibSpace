# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T16:44:28
package SmartArrayDAOFactory;

use namespace::autoclean;
use Moose;
use BibSpace::Model::ILogger;
use BibSpace::Model::DAO::SmartArray::TagTypeSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::TeamSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::AuthorSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::AuthorshipSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::MembershipSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::EntrySmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::LabelingSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::TagSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::ExceptionSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::TypeSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::UserSmartArrayDAO;
use BibSpace::Model::DAO::DAOFactory;
extends 'DAOFactory';

has 'handle' => ( is => 'ro', required => 1 );
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );
has 'e_factory' => ( is => 'ro', isa => 'EntityFactory', required => 1);

sub getTagTypeDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getTagTypeDao MUST be called with valid idProvider!" if !defined $idProvider;
  return TagTypeSmartArrayDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getTagTypeDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getTagTypeDao" ); };
after 'getTagTypeDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getTagTypeDao" ); };

sub getTeamDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getTeamDao MUST be called with valid idProvider!" if !defined $idProvider;
  return TeamSmartArrayDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getTeamDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getTeamDao" ); };
after 'getTeamDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getTeamDao" ); };

sub getAuthorDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getAuthorDao MUST be called with valid idProvider!" if !defined $idProvider;
  return AuthorSmartArrayDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getAuthorDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getAuthorDao" ); };
after 'getAuthorDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getAuthorDao" ); };

sub getAuthorshipDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getAuthorshipDao MUST be called with valid idProvider!" if !defined $idProvider;
  return AuthorshipSmartArrayDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getAuthorshipDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getAuthorshipDao" ); };
after 'getAuthorshipDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getAuthorshipDao" ); };

sub getMembershipDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getMembershipDao MUST be called with valid idProvider!" if !defined $idProvider;
  return MembershipSmartArrayDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getMembershipDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getMembershipDao" ); };
after 'getMembershipDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getMembershipDao" ); };

sub getEntryDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getEntryDao MUST be called with valid idProvider!" if !defined $idProvider;
  return EntrySmartArrayDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getEntryDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getEntryDao" ); };
after 'getEntryDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getEntryDao" ); };

sub getLabelingDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getLabelingDao MUST be called with valid idProvider!" if !defined $idProvider;
  return LabelingSmartArrayDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getLabelingDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getLabelingDao" ); };
after 'getLabelingDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getLabelingDao" ); };

sub getTagDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getTagDao MUST be called with valid idProvider!" if !defined $idProvider;
  return TagSmartArrayDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getTagDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getTagDao" ); };
after 'getTagDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getTagDao" ); };

sub getExceptionDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getExceptionDao MUST be called with valid idProvider!" if !defined $idProvider;
  return ExceptionSmartArrayDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getExceptionDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getExceptionDao" ); };
after 'getExceptionDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getExceptionDao" ); };

sub getTypeDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getTypeDao MUST be called with valid idProvider!" if !defined $idProvider;
  return TypeSmartArrayDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getTypeDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getTypeDao" ); };
after 'getTypeDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getTypeDao" ); };

sub getUserDao {
  my $self       = shift;
  my $idProvider = shift;
  die "" . __PACKAGE__ . "->getUserDao MUST be called with valid idProvider!" if !defined $idProvider;
  return UserSmartArrayDAO->new( idProvider => $idProvider, logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getUserDao' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->getUserDao" ); };
after 'getUserDao' => sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->getUserDao" ); };

__PACKAGE__->meta->make_immutable;
no Moose;
1;
