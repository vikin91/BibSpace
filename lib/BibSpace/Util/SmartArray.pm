package SmartArray;

use v5.16;    #because of ~~ and say
use Try::Tiny;
use Data::Dumper;
use namespace::autoclean;

use Moose;

use Moose::Util::TypeConstraints;
use BibSpace::Model::IBibSpaceBackend;
require BibSpace::Model::IEntity;
with 'IBibSpaceBackend';
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

has 'logger' => ( is => 'ro', does => 'ILogger', required => 1, traits  => ['DoNotSerialize']);

has 'data' => (
    traits    => ['Hash'],
    is        => 'ro',
    isa       => 'HashRef[ArrayRef[BibSpace::Model::IEntity]]',
    default   => sub { {} },
    handles   => {
        set     => 'set',
        get     => 'get',
        has     => 'exists',
        defined => 'defined',
        keys    => 'keys',
        # values  => 'values',
        num     => 'count',
        pairs   => 'kv',
        _clear   => 'clear',
    },
);

sub reset_data {
    my $self = shift;
    $self->logger->warn("Resetting SmartArray");
    $self->_clear;
}

sub dump {
    my $self = shift;
    $self->logger->debug("SmartArray keys: ".join(', ', $self->keys));
}

sub _init {
    my $self = shift;
    my $type = shift;
    die "_init requires a type!" unless $type;
    if(!$self->defined($type)){
        $self->set($type, []);
    }
}
before '_init' => sub { shift->logger->entering(""); };
after '_init'  => sub { shift->logger->exiting(""); };

sub all {
    my $self = shift;
    my $type = shift;
    $self->logger->error("SmartArray->all requires a type! Type: $type.") unless $type;
    $self->_init($type);
    my $aref = $self->get($type);
    return @{ $aref };
}
before 'all' => sub { shift->logger->entering(""); };
after 'all'  => sub { shift->logger->exiting(""); };

sub _add {
    my ($self, @objects) = @_;
    my $type = ref($objects[0]);
    $self->_init($type);
    push @{$self->get($type)}, @objects;
}
before '_add' => sub { shift->logger->entering(""); };
after '_add'  => sub { shift->logger->exiting(""); };

sub save {
    my ($self, @objects) = @_;
    my $added = 0;
    
    # if there are multiple objects to add and the array is empty -> do it quicker!
    if( @objects > 0 ){
        my $type = ref($objects[0]);

        if( $self->empty($type) ){
            $self->_add(@objects);
            $added = scalar @objects;
            return $added;
        }
    }
    

    foreach my $obj(@objects){
        if( !$self->exists($obj)){
            ++$added;
            $self->_add($obj);
        }
        else{
            $self->update($obj);
        }
    }
    
    return $added;
}
before 'save' => sub { shift->logger->entering(""); };
after 'save'  => sub { shift->logger->exiting(""); };

sub count { 
    my ($self, $type) = @_;
    die "all requires a type!" unless $type;
    return scalar $self->all($type);
}
before 'count' => sub { shift->logger->entering(""); };
after 'count'  => sub { shift->logger->exiting(""); };

sub empty { 
    my ($self, $type) = @_;
    return $self->count($type) == 0;
}
before 'empty' => sub { shift->logger->entering(""); };
after 'empty'  => sub { shift->logger->exiting(""); };

## this is mega slow for relations!!!
sub exists { 
    my ($self, $object) = @_;
    my $type = ref($object);
    $self->logger->error("SmartArray->exists requires a type! Object: $object, type: $type.") unless $type;
    my $found = first {$_->equals($object)} $self->all($type);
    return defined $found;
}
before 'exists' => sub { shift->logger->entering(""); };
after 'exists'  => sub { shift->logger->exiting(""); };

sub update { 
    my ($self, @objects) = @_;
    # should happen automatically beacuse array keeps references to objects
}
before 'update' => sub { shift->logger->entering(""); };
after 'update'  => sub { shift->logger->exiting(""); };

sub delete { 
    my ($self, @objects) = @_; 
    my $type = ref($objects[0]);
    my $aref = $self->get($type);

    foreach my $obj (@objects){
        my $idx = first_index { $_ == $obj } @{$aref};
        splice( @{$aref}, $idx, 1) if $idx > -1;
    }
}
before 'delete' => sub { shift->logger->entering(""); };
after 'delete'  => sub { shift->logger->exiting(""); };

sub filter { 
    my ($self, $type, $coderef) = @_;
    # $self->logger->warn("Calling ".(caller(0))[3]." with param $type");
    return () if $self->empty($type);
    return grep &{$coderef}, $self->all($type); 
}
before 'filter' => sub { shift->logger->entering(""); };
after 'filter'  => sub { shift->logger->exiting(""); };

sub find { 
  my ($self, $type, $coderef) = @_;
  # $self->logger->warn("Calling ".(caller(0))[3]." with param $type");
  return undef if $self->empty($type);
  return first \&{$coderef}, $self->all($type);
}
before 'find' => sub { shift->logger->entering(""); };
after 'find'  => sub { shift->logger->exiting(""); };

# Moose::Meta::Attribute::Native::Trait::Array



__PACKAGE__->meta->make_immutable;
no Moose;
1;