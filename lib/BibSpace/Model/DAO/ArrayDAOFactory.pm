# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T18:29:16
package ArrayDAOFactory;

use namespace::autoclean;
use Moose;
use BibSpace::Model::ILogger;
use BibSpace::Model::DAO::Array::EntryArrayDAO;
use BibSpace::Model::DAO::Array::AuthorArrayDAO;
use BibSpace::Model::DAO::Array::TeamArrayDAO;
use BibSpace::Model::DAO::Array::TagArrayDAO;
use BibSpace::Model::DAO::Array::TagTypeArrayDAO;
use BibSpace::Model::DAO::Array::AuthorshipArrayDAO;
use BibSpace::Model::DAO::Array::MembershipArrayDAO;
use BibSpace::Model::DAO::Array::LabelingArrayDAO;
use BibSpace::Model::DAO::Array::ExceptionArrayDAO;
use BibSpace::Model::DAO::DAOFactory;
extends 'DAOFactory';

has 'handle' => ( is => 'ro', required => 1 );
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);


sub getEntryDao {
    my $self = shift;
    return EntryArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getAuthorDao {
    my $self = shift;
    return AuthorArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTeamDao {
    my $self = shift;
    return TeamArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTagDao {
    my $self = shift;
    return TagArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTagTypeDao {
    my $self = shift;
    return TagTypeArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getAuthorshipDao {
    my $self = shift;
    return AuthorshipArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getMembershipDao {
    my $self = shift;
    return MembershipArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getLabelingDao {
    my $self = shift;
    return LabelingArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getExceptionDao {
    my $self = shift;
    return ExceptionArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
