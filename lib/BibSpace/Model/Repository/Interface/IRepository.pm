# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package IRepository;
use namespace::autoclean;


use Moose::Role; # = this package (class) is an interface
# Perl interfaces (Roles) can contain attributes =)
# In fact, Perl roles are Mixins: https://en.wikipedia.org/wiki/Mixin
# classes that implement this interface must provide the following functions
use BibSpace::Model::DAO::DAOFactory;
use List::MoreUtils;

=item backendsConfigHash 
    The backendsConfigHash should look like:
    {
      backends => [
        { prio => 1, type => ‘Redis’, handle => $redisHandle },
        { prio => 2, type => ‘SQL’, handle => $dbh },
      ]
    }
=cut
has 'backendsConfigHash' => ( is => 'ro', isa => 'HashRef', coerce => 0, traits => [ 'Hash' ], required => 1 );
# this parameter is lazy, because the builder routine depends on logger. Logger will be set as first (is non-lazy).
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);
has '_idProvider' => ( is => 'ro', does => 'IUidProvider', required => 1, lazy => 0 );
has 'backendDaoFactory'  => ( is => 'ro', isa => 'DAOFactory', lazy => 1, builder => '_buildDAOFactory' );

requires 'all';
requires 'count';
requires 'save';
requires 'update';
requires 'delete';
requires 'exists';
requires 'filter';
requires 'find';

sub _buildDAOFactory{
    my $self = shift;
    return DAOFactory->new(logger => $self->logger);
}

sub getBackendsArray{
    my $self = shift;
    # this is sorted by 'prio' in the RepositoryFacotry
    return @{ $self->backendsConfigHash->{'backends'} };
}

sub getIdProvider{
    my $self = shift;
    return $self->{_idProvider};
}

1;