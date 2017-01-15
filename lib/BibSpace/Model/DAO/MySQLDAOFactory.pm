# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T22:33:39
package MySQLDAOFactory;

use namespace::autoclean;
use Moose;
use BibSpace::Model::ILogger;
use BibSpace::Model::DAO::MySQL::MembershipMySQLDAO;
use BibSpace::Model::DAO::MySQL::TagTypeMySQLDAO;
use BibSpace::Model::DAO::MySQL::TagMySQLDAO;
use BibSpace::Model::DAO::MySQL::AuthorMySQLDAO;
use BibSpace::Model::DAO::MySQL::EntryMySQLDAO;
use BibSpace::Model::DAO::MySQL::AuthorshipMySQLDAO;
use BibSpace::Model::DAO::MySQL::TeamMySQLDAO;
use BibSpace::Model::DAO::MySQL::LabelingMySQLDAO;
use BibSpace::Model::DAO::MySQL::ExceptionMySQLDAO;
use BibSpace::Model::DAO::DAOFactory;
extends 'DAOFactory';

has 'handle' => ( is => 'ro', required => 1 );
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);


sub getMembershipDao {
    my $self = shift;
    return MembershipMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTagTypeDao {
    my $self = shift;
    return TagTypeMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTagDao {
    my $self = shift;
    return TagMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getAuthorDao {
    my $self = shift;
    return AuthorMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getEntryDao {
    my $self = shift;
    return EntryMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getAuthorshipDao {
    my $self = shift;
    return AuthorshipMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTeamDao {
    my $self = shift;
    return TeamMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getLabelingDao {
    my $self = shift;
    return LabelingMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getExceptionDao {
    my $self = shift;
    return ExceptionMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
