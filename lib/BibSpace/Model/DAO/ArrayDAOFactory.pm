# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T17:18:02
package BibSpace::Model::DAO::ArrayDAOFactory;

use namespace::autoclean;
use Moose;
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
extends 'BibSpace::Model::DAO::DAOFactory';

has 'handle' => ( is => 'ro', required => 1 );
has 'logger' => ( is => 'ro', does => 'BibSpace::Model::ILogger', required => 1);


sub getEntryDao {
    my $self = shift;
    return BibSpace::Model::DAO::Array::EntryArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getAuthorDao {
    my $self = shift;
    return BibSpace::Model::DAO::Array::AuthorArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTeamDao {
    my $self = shift;
    return BibSpace::Model::DAO::Array::TeamArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTagDao {
    my $self = shift;
    return BibSpace::Model::DAO::Array::TagArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getTagTypeDao {
    my $self = shift;
    return BibSpace::Model::DAO::Array::TagTypeArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getAuthorshipDao {
    my $self = shift;
    return BibSpace::Model::DAO::Array::AuthorshipArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getMembershipDao {
    my $self = shift;
    return BibSpace::Model::DAO::Array::MembershipArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getLabelingDao {
    my $self = shift;
    return BibSpace::Model::DAO::Array::LabelingArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
sub getExceptionDao {
    my $self = shift;
    return BibSpace::Model::DAO::Array::ExceptionArrayDAO->new( logger=>$self->logger, handle => $self->handle );
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
