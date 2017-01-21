# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T17:02:08
package BibSpace::Model::Repository::Layered::TypesLayeredRepository;
use namespace::autoclean;
use Moose;
require BibSpace::Model::Repository::Interface::ITypesRepository;
with 'BibSpace::Model::Repository::Interface::ITypesRepository';
use BibSpace::Model::Type;
use Try::Tiny; # for try/catch


=item _getReadBackend 
    Returns backend with lowest 'prio' value from $backendsConfigHash
=cut
sub _getReadBackend {
  my $self = shift;
  # here or before, the number of elements in $self->backendsConfigHash gets decreased

  if( !defined $self->backendsConfigHash ){
    die "".__PACKAGE__."->_getReadBackendType: backendsConfigHash is not defined";
  }
  my @backendsArray = $self->getBackendsArray;
  my $prioHash = shift @backendsArray;
  if( !$prioHash ){
    die "".__PACKAGE__."->_getReadBackendType: backend confg hash for lowest prio (read) backend is not defined";
  }
  return $prioHash;
}


### READ METHODS

=item all
    Method documentation placeholder.
=cut 
sub all {
    my ($self) = @_;
    $self->logger->entering("","".__PACKAGE__."->all");
    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    my $daoFactoryType = $self->_getReadBackend()->{'type'};
    my $daoBackendHandle = $self->_getReadBackend()->{'handle'};
    try{
        $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getTypeDao()->all();
    }
    catch{
        print;
    };
    $self->logger->exiting("","".__PACKAGE__."->all");
}


### WRITE METHODS

=item save
    Method documentation placeholder.
=cut 
sub save {
    my ($self, @objects) = @_;
    $self->logger->entering("","".__PACKAGE__."->save");
    die "".__PACKAGE__."->save argument 'objects' is undefined." unless @objects;

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    foreach my $backendDAO ( $self->getBackendsArray() ){
        my $daoFactoryType = $backendDAO->{'type'};
        my $daoBackendHandle = $backendDAO->{'handle'};
        try{
            $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getTypeDao()->save( @objects );
        }
        catch{
            print;
        };
    }
    $self->logger->exiting("","".__PACKAGE__."->save");
}

=item update
    Method documentation placeholder.
=cut 
sub update {
    my ($self, @objects) = @_;
    $self->logger->entering("","".__PACKAGE__."->update");
    die "".__PACKAGE__."->update argument 'objects' is undefined." unless @objects;

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    foreach my $backendDAO ( $self->getBackendsArray() ){
        my $daoFactoryType = $backendDAO->{'type'};
        my $daoBackendHandle = $backendDAO->{'handle'};
        try{
            $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getTypeDao()->update( @objects );
        }
        catch{
            print;
        };
    }
    $self->logger->exiting("","".__PACKAGE__."->update");
}

=item delete
    Method documentation placeholder.
=cut 
sub delete {
    my ($self, @objects) = @_;
    $self->logger->entering("","".__PACKAGE__."->delete");
    die "".__PACKAGE__."->delete argument 'objects' is undefined." unless @objects;

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    foreach my $backendDAO ( $self->getBackendsArray() ){
        my $daoFactoryType = $backendDAO->{'type'};
        my $daoBackendHandle = $backendDAO->{'handle'};
        try{
            $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getTypeDao()->delete( @objects );
        }
        catch{
            print;
        };
    }
    $self->logger->exiting("","".__PACKAGE__."->delete");
}

=item exists
    Method documentation placeholder.
=cut 
sub exists {
    my ($self, @objects) = @_;
    $self->logger->entering("","".__PACKAGE__."->exists");
    die "".__PACKAGE__."->exists argument 'objects' is undefined." unless @objects;

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    foreach my $backendDAO ( $self->getBackendsArray() ){
        my $daoFactoryType = $backendDAO->{'type'};
        my $daoBackendHandle = $backendDAO->{'handle'};
        try{
            $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getTypeDao()->exists( @objects );
        }
        catch{
            print;
        };
    }
    $self->logger->exiting("","".__PACKAGE__."->exists");
}


### SEARCH METHODS

=item filter
    Method documentation placeholder.
=cut 
sub filter {
    my ($self, $coderef) = @_;
    $self->logger->entering("","".__PACKAGE__."->filter");
    die "".__PACKAGE__."->filter 'coderef' is undefined." unless defined $coderef;
    if( ref $coderef ne ref sub{} ){
        die "".__PACKAGE__."->filter incorrect type of argument. Got: ".ref($coderef).", expected: ".(ref sub{}).".";
    }

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    my $daoFactoryType = $self->_getReadBackend()->{'type'};
    my $daoBackendHandle = $self->_getReadBackend()->{'handle'};
    try{
        $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getTypeDao()->filter( $coderef );
    }
    catch{
        print;
    };
    $self->logger->exiting("","".__PACKAGE__."->filter");
}

=item find
    Method documentation placeholder.
=cut 
sub find {
    my ($self, $coderef) = @_;
    $self->logger->entering("","".__PACKAGE__."->find");
    die "".__PACKAGE__."->find 'coderef' is undefined." unless defined $coderef;
    if( ref $coderef ne ref sub{} ){
        die "".__PACKAGE__."->find incorrect type of argument. Got: ".ref($coderef).", expected: ".(ref sub{}).".";
    }

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    my $daoFactoryType = $self->_getReadBackend()->{'type'};
    my $daoBackendHandle = $self->_getReadBackend()->{'handle'};
    try{
        $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getTypeDao()->find( $coderef );
    }
    catch{
        print;
    };
    $self->logger->exiting("","".__PACKAGE__."->find");
}

=item count
    Method documentation placeholder.
=cut 
sub count {
    my ($self, $coderef) = @_;
    $self->logger->entering("","".__PACKAGE__."->count");
    die "".__PACKAGE__."->count 'coderef' is undefined." unless defined $coderef;
    if( ref $coderef ne ref sub{} ){
        die "".__PACKAGE__."->count incorrect type of argument. Got: ".ref($coderef).", expected: ".(ref sub{}).".";
    }

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    my $daoFactoryType = $self->_getReadBackend()->{'type'};
    my $daoBackendHandle = $self->_getReadBackend()->{'handle'};
    try{
        $self->backendFactory->getInstance( $daoFactoryType, $daoBackendHandle )->getTypeDao()->count( $coderef );
    }
    catch{
        print;
    };
    $self->logger->exiting("","".__PACKAGE__."->count");
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;