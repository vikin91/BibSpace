# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package LabelingsLayeredRepository;
use namespace::autoclean;
use Moose;
require BibSpace::Model::Repository::Interface::IRepository;
with 'IRepository';
use BibSpace::Model::Labeling;
use Try::Tiny; # for try/catch
use List::Util qw(first);
use List::MoreUtils;



=item copy 
    Copies all entries from backend with prio $fromLayer to backend with prio $toLayer
=cut
sub copy{
    my ($self, $fromLayer, $toLayer) = @_;
    $self->logger->debug("Copying all Labeling from layer $fromLayer to layer $toLayer.","".__PACKAGE__."->copy");

    my @resultRead = $self->backendDaoFactory->getInstance( 
        $self->_getBackendWithPrio($fromLayer)->{'type'},
        $self->_getBackendWithPrio($fromLayer)->{'handle'} 
    )->getLabelingDao($self->getIdProvider)->all();

    $self->logger->debug(scalar(@resultRead)." Labeling read from layer $fromLayer.","".__PACKAGE__."->copy");
    
    my $resultSave = $self->backendDaoFactory->getInstance( 
        $self->_getBackendWithPrio($toLayer)->{'type'},
        $self->_getBackendWithPrio($toLayer)->{'handle'}
    )->getLabelingDao($self->getIdProvider)->save( @resultRead );

    $self->logger->debug(" $resultSave Labeling saved to layer $toLayer.","".__PACKAGE__."->copy");
}
before 'copy' => sub { shift->logger->entering("","".__PACKAGE__."->copy"); };
after 'copy'  => sub { shift->logger->exiting("","".__PACKAGE__."->copy"); };

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
        return $self->backendDaoFactory
            ->getInstance( $daoFactoryType, $daoBackendHandle )
            ->getLabelingDao($self->getIdProvider)
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
        return $self->backendDaoFactory
            ->getInstance( $daoFactoryType, $daoBackendHandle )
            ->getLabelingDao($self->getIdProvider)
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
        return $self->backendDaoFactory
            ->getInstance( $daoFactoryType, $daoBackendHandle )
            ->getLabelingDao($self->getIdProvider)
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
        return $self->backendDaoFactory
            ->getInstance( $daoFactoryType, $daoBackendHandle )
            ->getLabelingDao($self->getIdProvider)
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
            $self->backendDaoFactory->getInstance( $daoFactoryType, $daoBackendHandle )
              ->getLabelingDao($self->getIdProvider)
              ->save( @objects );
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
            $self->backendDaoFactory->getInstance( $daoFactoryType, $daoBackendHandle )
              ->getLabelingDao($self->getIdProvider)
              ->update( @objects );
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
    $self->logger->info("Nothing to delete","".__PACKAGE__."->delete") unless @objects;
return unless @objects;

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    foreach my $backendDAO ( $self->getBackendsArray() ){
        my $daoFactoryType = $backendDAO->{'type'};
        my $daoBackendHandle = $backendDAO->{'handle'};
        try{
            $self->backendDaoFactory->getInstance( $daoFactoryType, $daoBackendHandle )
              ->getLabelingDao($self->getIdProvider)
              ->delete( @objects );
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
        return $self->backendDaoFactory->getInstance( $daoFactoryType, $daoBackendHandle )
            ->getLabelingDao($self->getIdProvider)
            ->filter( $coderef );
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
        return $self->backendDaoFactory->getInstance( $daoFactoryType, $daoBackendHandle )
            ->getLabelingDao($self->getIdProvider)
            ->find( $coderef );
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
