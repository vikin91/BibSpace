package SmartUidProvider;

use 5.010;    #because of ~~ and say
use Try::Tiny;
use Data::Dumper;
use namespace::autoclean;

# use BibSpace::Model::IUidProvider;
# use BibSpace::Model::IntegerUidProvider;

use Moose;
use Moose::Util::TypeConstraints;
use List::Util qw(first);
use List::MoreUtils qw(first_index);
use MooseX::Storage;
with Storage( format => 'JSON', 'io' => 'File' );

=item
    This is a in-memory data structure (hash) to hold all objects of BibSpace.
    It is build like this:
    String "TypeName" => Array of Objects with type TypeName.
    It could be improved for performance like this:
    String "TypeName" => { Integer UID => Object with type TypeName}.
=cut

has 'logger' => (
    is       => 'ro',
    does     => 'ILogger',
    required => 1,
    traits   => ['DoNotSerialize']
);
has 'idProviderClassName' => ( is => 'ro', isa => 'Str', required => 1 );

has 'data' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[IUidProvider]',
    default => sub { {} },
    handles => {
        _set     => 'set',
        _get     => 'get',
        _has     => 'exists',
        _defined => 'defined',
        _keys    => 'keys',
        _values  => 'values',
        _num   => 'count',
        _pairs => 'kv',
    },
);

sub get_provider {
    my ( $self, $type ) = @_;
    $self->_init($type);
    $self->logger->debug("Returning idProvider for type '$type'.","".__PACKAGE__."->get_provider");
    return $self->_get($type);
}

sub _init {
    my ( $self, $type ) = @_;

    if(!$type){
        $self->logger->error("_init requires a type!","" . __PACKAGE__ . "->_init");
        die "_init requires a type!";
    }
    if ( !$self->_defined($type) ) {
        try {
            my $className = $self->idProviderClassName;
            Class::Load::load_class($className);
            my $providerInstance = $className->new();
            $self->_set( $type, $providerInstance );
        }
        catch {
            my $msg = "Requested unknown type of IUidProvider : '".$self->idProviderClassName."'. Error: $_";
            $self->logger->error($msg,"" . __PACKAGE__ . "->_init");
            die $msg;
        };
    }
}

sub reset {
    my $self = shift;
    $self->logger->warn("Resetting UID record!");
    foreach my $type ($self->_keys){
        $self->_get($type)->clear;    
    }
    
}

sub registerUID {
    my ( $self, $type, $uid ) = @_;

    if ( !$self->_get($type)->uid_defined($uid) ) {
        $self->_get($type)->uid_set( $uid => 1 );
    }
    else {
        my $msg
            = "Cannot registerUID. It exists already! Wanted to reg: $uid. Existing: "
            . join( ' ', sort $self->uid_keys );
        $self->logger->error($msg);
        die $msg;
    }
}

sub last_id {
    my ( $self, $type ) = @_;
    my $curr_max           = 1;                     # starting default id
    my $curr_max_candidate = max $self->_get($type)->uid_keys;
    if ( defined $curr_max_candidate and $curr_max_candidate > 0 ) {
        $curr_max = $curr_max_candidate;
    }
    return $curr_max;
}

sub generateUID {
    my ( $self, $type ) = @_;

    my $curr_max  = $self->last_id($type);
    my $new_uid = $curr_max + 1;
    $self->_get($type)->uid_set( $new_uid => 1 );
    $self->logger->debug("Generated uid '$new_uid' for object type '$type'.","".__PACKAGE__."->generateUID");
    return $new_uid;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;
