# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T14:22:05
package RedisDAOFactory;

use namespace::autoclean;
use Moose;
use BibSpace::Model::ILogger;
use BibSpace::Model::DAO::Redis::LabelingRedisDAO;
use BibSpace::Model::DAO::Redis::ExceptionRedisDAO;
use BibSpace::Model::DAO::Redis::EntryRedisDAO;
use BibSpace::Model::DAO::Redis::AuthorshipRedisDAO;
use BibSpace::Model::DAO::Redis::MembershipRedisDAO;
use BibSpace::Model::DAO::Redis::TeamRedisDAO;
use BibSpace::Model::DAO::Redis::AuthorRedisDAO;
use BibSpace::Model::DAO::Redis::TagTypeRedisDAO;
use BibSpace::Model::DAO::Redis::TagRedisDAO;
use BibSpace::Model::DAO::DAOFactory;
extends 'DAOFactory';

has 'handle' => ( is => 'ro', required => 1 );
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);


sub getLabelingDao {
    my $self = shift;
    my $idProvider = shift;
    die "".__PACKAGE__."->getLabelingDao MUST be called with valid idProvider!" if !defined $idProvider;
    return LabelingRedisDAO->new( idProvider=> $idProvider, logger=>$self->logger, handle => $self->handle );
}
sub getExceptionDao {
    my $self = shift;
    my $idProvider = shift;
    die "".__PACKAGE__."->getExceptionDao MUST be called with valid idProvider!" if !defined $idProvider;
    return ExceptionRedisDAO->new( idProvider=> $idProvider, logger=>$self->logger, handle => $self->handle );
}
sub getEntryDao {
    my $self = shift;
    my $idProvider = shift;
    die "".__PACKAGE__."->getEntryDao MUST be called with valid idProvider!" if !defined $idProvider;
    return EntryRedisDAO->new( idProvider=> $idProvider, logger=>$self->logger, handle => $self->handle );
}
sub getAuthorshipDao {
    my $self = shift;
    my $idProvider = shift;
    die "".__PACKAGE__."->getAuthorshipDao MUST be called with valid idProvider!" if !defined $idProvider;
    return AuthorshipRedisDAO->new( idProvider=> $idProvider, logger=>$self->logger, handle => $self->handle );
}
sub getMembershipDao {
    my $self = shift;
    my $idProvider = shift;
    die "".__PACKAGE__."->getMembershipDao MUST be called with valid idProvider!" if !defined $idProvider;
    return MembershipRedisDAO->new( idProvider=> $idProvider, logger=>$self->logger, handle => $self->handle );
}
sub getTeamDao {
    my $self = shift;
    my $idProvider = shift;
    die "".__PACKAGE__."->getTeamDao MUST be called with valid idProvider!" if !defined $idProvider;
    return TeamRedisDAO->new( idProvider=> $idProvider, logger=>$self->logger, handle => $self->handle );
}
sub getAuthorDao {
    my $self = shift;
    my $idProvider = shift;
    die "".__PACKAGE__."->getAuthorDao MUST be called with valid idProvider!" if !defined $idProvider;
    return AuthorRedisDAO->new( idProvider=> $idProvider, logger=>$self->logger, handle => $self->handle );
}
sub getTagTypeDao {
    my $self = shift;
    my $idProvider = shift;
    die "".__PACKAGE__."->getTagTypeDao MUST be called with valid idProvider!" if !defined $idProvider;
    return TagTypeRedisDAO->new( idProvider=> $idProvider, logger=>$self->logger, handle => $self->handle );
}
sub getTagDao {
    my $self = shift;
    my $idProvider = shift;
    die "".__PACKAGE__."->getTagDao MUST be called with valid idProvider!" if !defined $idProvider;
    return TagRedisDAO->new( idProvider=> $idProvider, logger=>$self->logger, handle => $self->handle );
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
