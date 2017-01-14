# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T19:21:59
package IMembershipsRepository;
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
has 'backendsConfigHash' => ( is => 'ro', isa => 'HashRef[ArrayRef[HashRef]]', coerce => 0, traits => [ 'Hash' ], required => 1 );
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);

# this parameter is lazy, because the builder routine depends on logger. Logger will be set as first (is non-lazy).
has 'backendFactory'  => ( is => 'ro', isa => 'DAOFactory', lazy => 1, builder => '_buildDAOFactory' );


sub _buildDAOFactory{
    my $self = shift;
    return DAOFactory->new(logger => $self->logger);
}

sub getBackendsArray{
    my $self = shift;
    # this is sorted by 'prio' in the RepositoryFacotry
    return @{ $self->backendsConfigHash->{'backends'} };
}

1;
