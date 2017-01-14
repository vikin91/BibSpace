# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T17:18:02
package BibSpace::Model::DAO::MySQLDAOFactory;

use namespace::autoclean;
use Moose;
use BibSpace::Model::DAO::MySQL::EntryMySQLDAO;
use BibSpace::Model::DAO::MySQL::AuthorMySQLDAO;
use BibSpace::Model::DAO::MySQL::TeamMySQLDAO;
use BibSpace::Model::DAO::MySQL::TagMySQLDAO;
use BibSpace::Model::DAO::MySQL::TagTypeMySQLDAO;
use BibSpace::Model::DAO::MySQL::AuthorshipMySQLDAO;
use BibSpace::Model::DAO::MySQL::MembershipMySQLDAO;
use BibSpace::Model::DAO::MySQL::LabelingMySQLDAO;
use BibSpace::Model::DAO::MySQL::ExceptionMySQLDAO;
use BibSpace::Model::DAO::DAOFactory;
extends 'BibSpace::Model::DAO::DAOFactory';

has 'handle' => ( is => 'ro', required => 1 );
has 'logger' => ( is => 'ro', does => 'BibSpace::Model::ILogger', required => 1);


sub getEntryDao {
    my $self = shift;
    return BibSpace::Model::DAO::MySQL::EntryMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getAuthorDao {
    my $self = shift;
    return BibSpace::Model::DAO::MySQL::AuthorMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTeamDao {
    my $self = shift;
    return BibSpace::Model::DAO::MySQL::TeamMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTagDao {
    my $self = shift;
    return BibSpace::Model::DAO::MySQL::TagMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTagTypeDao {
    my $self = shift;
    return BibSpace::Model::DAO::MySQL::TagTypeMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getAuthorshipDao {
    my $self = shift;
    return BibSpace::Model::DAO::MySQL::AuthorshipMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getMembershipDao {
    my $self = shift;
    return BibSpace::Model::DAO::MySQL::MembershipMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getLabelingDao {
    my $self = shift;
    return BibSpace::Model::DAO::MySQL::LabelingMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getExceptionDao {
    my $self = shift;
    return BibSpace::Model::DAO::MySQL::ExceptionMySQLDAO->new( logger=>$self->logger, handle => $self->handle );
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
