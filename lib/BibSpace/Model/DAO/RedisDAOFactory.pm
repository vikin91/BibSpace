# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T18:29:16
package RedisDAOFactory;

use namespace::autoclean;
use Moose;
use BibSpace::Model::ILogger;
use BibSpace::Model::DAO::Redis::EntryRedisDAO;
use BibSpace::Model::DAO::Redis::AuthorRedisDAO;
use BibSpace::Model::DAO::Redis::TeamRedisDAO;
use BibSpace::Model::DAO::Redis::TagRedisDAO;
use BibSpace::Model::DAO::Redis::TagTypeRedisDAO;
use BibSpace::Model::DAO::Redis::AuthorshipRedisDAO;
use BibSpace::Model::DAO::Redis::MembershipRedisDAO;
use BibSpace::Model::DAO::Redis::LabelingRedisDAO;
use BibSpace::Model::DAO::Redis::ExceptionRedisDAO;
use BibSpace::Model::DAO::DAOFactory;
extends 'DAOFactory';

has 'handle' => ( is => 'ro', required => 1 );
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);


sub getEntryDao {
    my $self = shift;
    return EntryRedisDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getAuthorDao {
    my $self = shift;
    return AuthorRedisDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTeamDao {
    my $self = shift;
    return TeamRedisDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTagDao {
    my $self = shift;
    return TagRedisDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTagTypeDao {
    my $self = shift;
    return TagTypeRedisDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getAuthorshipDao {
    my $self = shift;
    return AuthorshipRedisDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getMembershipDao {
    my $self = shift;
    return MembershipRedisDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getLabelingDao {
    my $self = shift;
    return LabelingRedisDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getExceptionDao {
    my $self = shift;
    return ExceptionRedisDAO->new( logger=>$self->logger, handle => $self->handle );
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
