# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T22:33:39
package UniversalSmartArrayDAO;

use namespace::autoclean;
use Moose;
use BibSpace::Model::DAO::Interface::IDAO;
with 'IDAO';
use Try::Tiny;

# Inherited fields from BibSpace::Model::DAO::Interface::IAuthorshipDAO Mixin:
# has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);
# has 'handle' => ( is => 'ro', required => 1);

=item all
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 

sub all {
    my ($self) = @_;
    return $self->handle->all;
}
before 'all' =>
    sub { shift->logger->entering( "", "" . __PACKAGE__ . "->all" ); };
after 'all' =>
    sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->all" ); };

=item count
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 

sub count {
    my ($self) = @_;
    return $self->handle->count;
}
before 'count' =>
    sub { shift->logger->entering( "", "" . __PACKAGE__ . "->count" ); };
after 'count' =>
    sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->count" ); };

=item empty
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 

sub empty {
    my ($self) = @_;
    return $self->handle->count == 0;

}
before 'empty' =>
    sub { shift->logger->entering( "", "" . __PACKAGE__ . "->empty" ); };
after 'empty' =>
    sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->empty" ); };

=item exists
    Method documentation placeholder.
    This method takes single object as argument and returns a scalar.
=cut 

sub exists {
    my ( $self, $object ) = @_;
    return defined $self->find( sub { $_->equals($object) } );
}
before 'exists' =>
    sub { shift->logger->entering( "", "" . __PACKAGE__ . "->exists" ); };
after 'exists' =>
    sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->exists" ); };

=item save
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub save {
    my ( $self, @objects ) = @_;

    my $result = $self->handle->add(@objects);
    $self->logger->info( "Saved. Container has now $result objects.",
        "" . __PACKAGE__ . "->save" );
    return $result;

}
before 'save' =>
    sub { shift->logger->entering( "", "" . __PACKAGE__ . "->save" ); };
after 'save' =>
    sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->save" ); };

    
=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
    for this container update is not necessary. 
    The operations are conducted on object references, so everything is updated automatically
=cut 

sub update {
    my ( $self, @objects ) = @_;

    # $self->delete(@objects);
    # $self->add(@objects);
}
before 'update' =>
    sub { shift->logger->entering( "", "" . __PACKAGE__ . "->update" ); };
after 'update' =>
    sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->update" ); };

=item delete
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 

sub delete {
    my ( $self, @objects ) = @_;

    foreach my $obj (@objects) {
        my $index = $self->handle->find_index( sub { $_->equals($obj) } );
        $self->handle->delete($index);
    }

}
before 'delete' =>
    sub { shift->logger->entering( "", "" . __PACKAGE__ . "->delete" ); };
after 'delete' =>
    sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->delete" ); };

=item filter
    Method documentation placeholder.
=cut 

sub filter {
    my ( $self, $coderef ) = @_;
    die ""
        . __PACKAGE__
        . "->filter incorrect type of argument. Got: '"
        . ref($coderef)
        . "', expected: "
        . ( ref sub { } ) . "."
        unless ( ref $coderef eq ref sub { } );

    die ""
        . __PACKAGE__
        . "->filter incorrect type of argument. Got: '"
        . ref($coderef)
        . "', expected: "
        . ( ref sub { } ) . "."
        unless ( ref $coderef eq ref sub { } );

    # my @result = grep(&{ $coderef }, @{ $self->handle });
    # my @result = $self->handle->filter( &{$coderef} );
    return $self->handle->filter($coderef);
}
before 'filter' =>
    sub { shift->logger->entering( "", "" . __PACKAGE__ . "->filter" ); };
after 'filter' =>
    sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->filter" ); };

=item find
    Method documentation placeholder.
=cut 

sub find {
    my ( $self, $coderef ) = @_;
    die ""
        . __PACKAGE__
        . "->find incorrect type of argument. Got: '"
        . ref($coderef)
        . "', expected: "
        . ( ref sub { } ) . "."
        unless ( ref $coderef eq ref sub { } );
    return $self->handle->find($coderef);

}
before 'find' =>
    sub { shift->logger->entering( "", "" . __PACKAGE__ . "->find" ); };
after 'find' =>
    sub { shift->logger->exiting( "", "" . __PACKAGE__ . "->find" ); };
__PACKAGE__->meta->make_immutable;
no Moose;
1;
