package SmartArray;

use 5.010;    #because of ~~ and say
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
    $self->logger->warn("Resetting SmartArray","".__PACKAGE__."->reset_data");
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
before '_init' => sub { shift->logger->entering("","".__PACKAGE__."->_init"); };
after '_init'  => sub { shift->logger->exiting("","".__PACKAGE__."->_init"); };

sub all {
    my $self = shift;
    my $type = shift;
    $self->logger->error("SmartArray->all requires a type! Type: $type.") unless $type;
    $self->_init($type);
    my $aref = $self->get($type);
    return @{ $aref };
}
before 'all' => sub { shift->logger->entering("","".__PACKAGE__."->all"); };
after 'all'  => sub { shift->logger->exiting("","".__PACKAGE__."->all"); };

sub _add {
    my ($self, @objects) = @_;
    my $type = ref($objects[0]);
    $self->_init($type);
    push @{$self->get($type)}, @objects;
}
before '_add' => sub { shift->logger->entering("","".__PACKAGE__."->_add"); };
after '_add'  => sub { shift->logger->exiting("","".__PACKAGE__."->_add"); };

sub save {
    my ($self, @objects) = @_;
    my $added = 0;
    
    # if there are multiple objetcs to add and the array is empty -> do it quicker!
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
before 'save' => sub { shift->logger->entering("","".__PACKAGE__."->save"); };
after 'save'  => sub { shift->logger->exiting("","".__PACKAGE__."->save"); };

sub count { 
    my ($self, $type) = @_;
    die "all requires a type!" unless $type;
    return scalar $self->all($type);
}
before 'count' => sub { shift->logger->entering("","".__PACKAGE__."->count"); };
after 'count'  => sub { shift->logger->exiting("","".__PACKAGE__."->count"); };

sub empty { 
    my ($self, $type) = @_;
    return $self->count($type) == 0;
}
before 'empty' => sub { shift->logger->entering("","".__PACKAGE__."->empty"); };
after 'empty'  => sub { shift->logger->exiting("","".__PACKAGE__."->empty"); };

sub exists { 
    my ($self, $object) = @_;
    my $type = ref($object);
    $self->logger->error("SmartArray->exists requires a type! Object: $object, type: $type.") unless $type;
    my $found = first {$_->equals($object)} $self->all($type);
    return defined $found;
}
before 'exists' => sub { shift->logger->entering("","".__PACKAGE__."->exists"); };
after 'exists'  => sub { shift->logger->exiting("","".__PACKAGE__."->exists"); };

sub update { 
    my ($self, @objects) = @_;
    # should happen automatically beacuser array keeps references to objects
}
before 'update' => sub { shift->logger->entering("","".__PACKAGE__."->update"); };
after 'update'  => sub { shift->logger->exiting("","".__PACKAGE__."->update"); };

sub delete { 
    my ($self, @objects) = @_; 
    my $type = ref($objects[0]);
    my $aref = $self->get($type);

    foreach my $obj (@objects){
        my $idx = first_index { $_ == $obj } @{$aref};
        splice( @{$aref}, $idx, 1) if $idx > -1;
    }
}
before 'delete' => sub { shift->logger->entering("","".__PACKAGE__."->delete"); };
after 'delete'  => sub { shift->logger->exiting("","".__PACKAGE__."->delete"); };

sub filter { 
    my ($self, $type, $coderef) = @_;
    # $self->logger->warn("Calling ".__PACKAGE__."->filter with param $type");
    return () if $self->empty($type);
    return grep &{$coderef}, $self->all($type); 
}
before 'filter' => sub { shift->logger->entering("","".__PACKAGE__."->filter"); };
after 'filter'  => sub { shift->logger->exiting("","".__PACKAGE__."->filter"); };

sub find { 
  my ($self, $type, $coderef) = @_;
  # $self->logger->warn("Calling ".__PACKAGE__."->find with param $type");
  return undef if $self->empty($type);
  return first \&{$coderef}, $self->all($type);
}
before 'find' => sub { shift->logger->entering("","".__PACKAGE__."->find"); };
after 'find'  => sub { shift->logger->exiting("","".__PACKAGE__."->find"); };

# Moose::Meta::Attribute::Native::Trait::Array



__PACKAGE__->meta->make_immutable;
no Moose;
1;