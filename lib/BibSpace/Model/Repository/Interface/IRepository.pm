# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package IRepository;
use namespace::autoclean;


use Moose::Role; # = this package (class) is an interface
# Perl interfaces (Roles) can contain attributes =)
# In fact, Perl roles are Mixins: https://en.wikipedia.org/wiki/Mixin
# classes that implement this interface must provide the following functions
use BibSpace::Model::DAO::DAOFactory;
use List::MoreUtils;
use List::Util qw(first);
=item backendsConfigHash 
    The backendsConfigHash should look like:
    {
      backends => [
        { prio => 1, type => ‘Redis’, handle => $redisHandle },
        { prio => 2, type => ‘SQL’, handle => $dbh },
      ]
    }
=cut
has 'backendsConfigHash' => ( is => 'rw', isa => 'Maybe[HashRef]', coerce => 0, traits => [ 'DoNotSerialize'], required => 1 );
# this parameter is lazy, because the builder routine depends on logger. Logger will be set as first (is non-lazy).
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);
has '_idProvider' => ( is => 'ro', does => 'IUidProvider', required => 1 );
has 'backendDaoFactory'  => ( is => 'ro', isa => 'DAOFactory', lazy => 1, builder => '_buildDAOFactory' );

requires 'all';
requires 'count';
requires 'save';
requires 'update';
requires 'delete';
requires 'exists';
requires 'filter';
requires 'find';

sub removeBackendHandles{
  my $self = shift;
  $self->backendsConfigHash(undef);
}

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

=item _getReadBackend 
    Returns backend with lowest 'prio' value from $backendsConfigHash
=cut
sub _getReadBackend {
  my $self = shift;

  if( !defined $self->backendsConfigHash ){
    die "".__PACKAGE__."->_getReadBackendType: backendsConfigHash is not defined";
  }
  my @backendsArray = $self->getBackendsArray;
  my $prioHash = shift @backendsArray;
  if( !$prioHash ){
    die "".__PACKAGE__."->_getReadBackendType: backend config hash for lowest prio (read) backend is not defined";
  }
  return $prioHash;
}

=item _getBackendWithPrio 
    Returns backend with given 'prio' value from $backendsConfigHash
=cut
sub _getBackendWithPrio {
  my $self = shift;
  my $prio = shift;

  if( !defined $self->backendsConfigHash ){
    die "".__PACKAGE__."->_getReadBackendType: backendsConfigHash is not defined";
  }
  my @backendsArray = $self->getBackendsArray;
  my $prioHash = first {$_->{'prio'} == $prio} @backendsArray;
  if( !$prioHash ){
    die "".__PACKAGE__."->_getReadBackendType: backend config hash for prio '$prio' is not defined";
  }
  return $prioHash;
}

1;
