# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T22:33:39
package SmartArrayDAOFactory;

use namespace::autoclean;
use Moose;
use BibSpace::Model::ILogger;
use BibSpace::Model::DAO::SmartArray::MembershipSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::TagTypeSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::TagSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::AuthorSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::EntrySmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::AuthorshipSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::TeamSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::LabelingSmartArrayDAO;
use BibSpace::Model::DAO::SmartArray::ExceptionSmartArrayDAO;
use BibSpace::Model::DAO::DAOFactory;
extends 'DAOFactory';

has 'handle' => ( is => 'ro', required => 1 );
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);


sub getMembershipDao {
    my $self = shift;
    return MembershipSmartArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTagTypeDao {
    my $self = shift;
    return TagTypeSmartArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTagDao {
    my $self = shift;
    return TagSmartArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getAuthorDao {
    my $self = shift;
    return AuthorSmartArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getEntryDao {
    my $self = shift;
    return EntrySmartArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getAuthorshipDao {
    my $self = shift;
    return AuthorshipSmartArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTeamDao {
    my $self = shift;
    return TeamSmartArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getLabelingDao {
    my $self = shift;
    return LabelingSmartArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getExceptionDao {
    my $self = shift;
    return ExceptionSmartArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
