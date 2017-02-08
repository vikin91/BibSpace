# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T14:47:33
package RedisDAOFactory;

use namespace::autoclean;

use Moose;
use BibSpace::Util::ILogger;
use BibSpace::DAO::Redis::MembershipRedisDAO;
use BibSpace::DAO::Redis::TagRedisDAO;
use BibSpace::DAO::Redis::AuthorshipRedisDAO;
use BibSpace::DAO::Redis::EntryRedisDAO;
use BibSpace::DAO::Redis::TeamRedisDAO;
use BibSpace::DAO::Redis::ExceptionRedisDAO;
use BibSpace::DAO::Redis::TagTypeRedisDAO;
use BibSpace::DAO::Redis::LabelingRedisDAO;
use BibSpace::DAO::Redis::AuthorRedisDAO;
use BibSpace::DAO::Redis::UserRedisDAO;
use BibSpace::DAO::DAOFactory;
extends 'DAOFactory';

has 'handle' => ( is => 'ro', required => 1 );
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1 );
has 'e_factory' => ( is => 'ro', isa => 'EntityFactory', required => 1);

sub getMembershipDao {
  my $self       = shift;
  return MembershipRedisDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getMembershipDao' => sub { shift->logger->entering(""); };
after 'getMembershipDao' => sub { shift->logger->exiting(""); };

sub getTagDao {
  my $self       = shift;
  return TagRedisDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getTagDao' => sub { shift->logger->entering(""); };
after 'getTagDao' => sub { shift->logger->exiting(""); };

sub getAuthorshipDao {
  my $self       = shift;
  return AuthorshipRedisDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getAuthorshipDao' => sub { shift->logger->entering(""); };
after 'getAuthorshipDao' => sub { shift->logger->exiting(""); };

sub getEntryDao {
  my $self       = shift;
  return EntryRedisDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getEntryDao' => sub { shift->logger->entering(""); };
after 'getEntryDao' => sub { shift->logger->exiting(""); };

sub getTeamDao {
  my $self       = shift;
  return TeamRedisDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getTeamDao' => sub { shift->logger->entering(""); };
after 'getTeamDao' => sub { shift->logger->exiting(""); };

sub getExceptionDao {
  my $self       = shift;
  return ExceptionRedisDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getExceptionDao' => sub { shift->logger->entering(""); };
after 'getExceptionDao' => sub { shift->logger->exiting(""); };

sub getTagTypeDao {
  my $self       = shift;
  return TagTypeRedisDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getTagTypeDao' => sub { shift->logger->entering(""); };
after 'getTagTypeDao' => sub { shift->logger->exiting(""); };

sub getLabelingDao {
  my $self       = shift;
  return LabelingRedisDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getLabelingDao' => sub { shift->logger->entering(""); };
after 'getLabelingDao' => sub { shift->logger->exiting(""); };

sub getAuthorDao {
  my $self       = shift;
  return AuthorRedisDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getAuthorDao' => sub { shift->logger->entering(""); };
after 'getAuthorDao' => sub { shift->logger->exiting(""); };

sub getTypeDao {
  my $self       = shift;
  return TypeRedisDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getTypeDao' => sub { shift->logger->entering(""); };
after 'getTypeDao' => sub { shift->logger->exiting(""); };

sub getUserDao {
  my $self       = shift;
  return UserRedisDAO->new( logger => $self->logger, handle => $self->handle, e_factory => $self->e_factory );
}
before 'getUserDao' => sub { shift->logger->entering(""); };
after 'getUserDao' => sub { shift->logger->exiting(""); };

__PACKAGE__->meta->make_immutable;
no Moose;
1;
