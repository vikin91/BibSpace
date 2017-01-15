# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T22:33:39
package LabellingsLayeredRepository;
use namespace::autoclean;
use Moose;
require BibSpace::Model::Repository::Interface::ILabellingsRepository;
with 'ILabellingsRepository';
use BibSpace::Model::Labeling;
use Try::Tiny; # for try/catch
use List::Util qw(first);
use List::MoreUtils;


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

=item copy 
    Copies all entries from backend with prio $fromLayer to backend with prio $toLayer
=cut
sub copy{
    my ($self, $fromLayer, $toLayer) = @_;
    $self->logger->entering("","".__PACKAGE__."->copy");
    $self->logger->debug("Copying all data from layer $fromLayer to layer $toLayer.","".__PACKAGE__."->copy");

    my @resultRead = $self->backendFactory->getInstance( 
        $self->_getBackendWithPrio($fromLayer)->{'type'},
        $self->_getBackendWithPrio($fromLayer)->{'handle'} 
    )->getEntryDao()->all();

    $self->logger->debug(scalar(@resultRead)." entries read from layer $fromLayer.","".__PACKAGE__."->copy");
    
    my $resultSave = $self->backendFactory->getInstance( 
        $self->_getBackendWithPrio($toLayer)->{'type'},
        $self->_getBackendWithPrio($toLayer)->{'handle'}
    )->getEntryDao()->save( @resultRead );

    $self->logger->debug(" $resultSave entries saved to layer $toLayer.","".__PACKAGE__."->copy");

    $self->logger->exiting("","".__PACKAGE__."->copy");
}


### READ METHODS

=item all
    Method documentation placeholder.
=cut 
sub all {
    my ($self) = @_;
    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    my $daoFactoryType = $self->_getReadBackend()->{'type'};
    my $daoBackendHandle = $self->_getReadBackend()->{'handle'};
    my $result;
    try{
        return $self->backendFactory
            ->getInstance( $daoFactoryType, $daoBackendHandle )
            ->getLabelingDao()
            ->all();
    }
    catch{
        print;
    };
}
before 'all' => sub { shift->logger->entering("","".__PACKAGE__."->all"); };
after 'all'  => sub { shift->logger->exiting("","".__PACKAGE__."->all"); };
=item count
    Method documentation placeholder.
=cut 
sub count {
    my ($self) = @_;
    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    my $daoFactoryType = $self->_getReadBackend()->{'type'};
    my $daoBackendHandle = $self->_getReadBackend()->{'handle'};
    my $result;
    try{
        return $self->backendFactory
            ->getInstance( $daoFactoryType, $daoBackendHandle )
            ->getLabelingDao()
            ->count();
    }
    catch{
        print;
    };
}
before 'count' => sub { shift->logger->entering("","".__PACKAGE__."->count"); };
after 'count'  => sub { shift->logger->exiting("","".__PACKAGE__."->count"); };
=item empty
    Method documentation placeholder.
=cut 
sub empty {
    my ($self) = @_;
    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    my $daoFactoryType = $self->_getReadBackend()->{'type'};
    my $daoBackendHandle = $self->_getReadBackend()->{'handle'};
    my $result;
    try{
        return $self->backendFactory
            ->getInstance( $daoFactoryType, $daoBackendHandle )
            ->getLabelingDao()
            ->empty();
    }
    catch{
        print;
    };
}
before 'empty' => sub { shift->logger->entering("","".__PACKAGE__."->empty"); };
after 'empty'  => sub { shift->logger->exiting("","".__PACKAGE__."->empty"); };

### CKECK METHODS

=item exists
    Method documentation placeholder.
=cut 
sub exists {
    my ($self, $obj) = @_;
    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    my $daoFactoryType = $self->_getReadBackend()->{'type'};
    my $daoBackendHandle = $self->_getReadBackend()->{'handle'};
    my $result;
    try{
        return $self->backendFactory
            ->getInstance( $daoFactoryType, $daoBackendHandle )
            ->getLabelingDao()
            ->exists($obj);
    }
    catch{
        print;
    };
}
before 'exists' => sub { shift->logger->entering("","".__PACKAGE__."->exists"); };
after 'exists'  => sub { shift->logger->exiting("","".__PACKAGE__."->exists"); };

### WRITE METHODS

=item save
    Method documentation placeholder.
=cut 
sub save {
    my ($self, @objects) = @_;
    die "".__PACKAGE__."->save argument 'objects' is undefined." unless @objects;

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    foreach my $backendDAO ( $self->getBackendsArray() ){
        my $daoFactoryType = $backendDAO->{'type'};
        my $daoBackendHandle = $backendDAO->{'handle'};
        try{
            return $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getLabelingDao()->save( @objects );
        }
        catch{
            print;
        };
    }
}
before 'save' => sub { shift->logger->entering("","".__PACKAGE__."->save"); };
after 'save'  => sub { shift->logger->exiting("","".__PACKAGE__."->save"); };
=item update
    Method documentation placeholder.
=cut 
sub update {
    my ($self, @objects) = @_;
    die "".__PACKAGE__."->update argument 'objects' is undefined." unless @objects;

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    foreach my $backendDAO ( $self->getBackendsArray() ){
        my $daoFactoryType = $backendDAO->{'type'};
        my $daoBackendHandle = $backendDAO->{'handle'};
        try{
            return $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getLabelingDao()->update( @objects );
        }
        catch{
            print;
        };
    }
}
before 'update' => sub { shift->logger->entering("","".__PACKAGE__."->update"); };
after 'update'  => sub { shift->logger->exiting("","".__PACKAGE__."->update"); };
=item delete
    Method documentation placeholder.
=cut 
sub delete {
    my ($self, @objects) = @_;
    die "".__PACKAGE__."->delete argument 'objects' is undefined." unless @objects;

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    foreach my $backendDAO ( $self->getBackendsArray() ){
        my $daoFactoryType = $backendDAO->{'type'};
        my $daoBackendHandle = $backendDAO->{'handle'};
        try{
            return $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getLabelingDao()->delete( @objects );
        }
        catch{
            print;
        };
    }
}
before 'delete' => sub { shift->logger->entering("","".__PACKAGE__."->delete"); };
after 'delete'  => sub { shift->logger->exiting("","".__PACKAGE__."->delete"); };

### SEARCH METHODS

=item filter
    Method documentation placeholder.
=cut 
sub filter {
    my ($self, $coderef) = @_;
    die "".__PACKAGE__."->filter 'coderef' is undefined." unless defined $coderef;
    if( ref $coderef ne ref sub{} ){
        die "".__PACKAGE__."->filter incorrect type of argument. Got: ".ref($coderef).", expected: ".(ref sub{}).".";
    }

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value
    my @result;
    my $daoFactoryType = $self->_getReadBackend()->{'type'};
    my $daoBackendHandle = $self->_getReadBackend()->{'handle'};
    try{
        return $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getLabelingDao()->filter( $coderef );
    }
    catch{
        print;
    };
}
before 'filter' => sub { shift->logger->entering("","".__PACKAGE__."->filter"); };
after 'filter'  => sub { shift->logger->exiting("","".__PACKAGE__."->filter"); };
=item find
    Method documentation placeholder.
=cut 
sub find {
    my ($self, $coderef) = @_;
    die "".__PACKAGE__."->find 'coderef' is undefined." unless defined $coderef;
    if( ref $coderef ne ref sub{} ){
        die "".__PACKAGE__."->find incorrect type of argument. Got: ".ref($coderef).", expected: ".(ref sub{}).".";
    }

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value
    my @result;
    my $daoFactoryType = $self->_getReadBackend()->{'type'};
    my $daoBackendHandle = $self->_getReadBackend()->{'handle'};
    try{
        return $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getLabelingDao()->find( $coderef );
    }
    catch{
        print;
    };
}
before 'find' => sub { shift->logger->entering("","".__PACKAGE__."->find"); };
after 'find'  => sub { shift->logger->exiting("","".__PACKAGE__."->find"); };
__PACKAGE__->meta->make_immutable;
no Moose;
1;
