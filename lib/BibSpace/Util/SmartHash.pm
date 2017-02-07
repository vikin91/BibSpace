package SmartHash;

use v5.16;    #because of ~~ and say
use Try::Tiny;
use Data::Dumper;
use namespace::autoclean;
use feature qw(current_sub);
use Moose;
use feature qw(current_sub);
use Moose::Util::TypeConstraints;
use BibSpace::Model::IBibSpaceBackend;
require BibSpace::Model::IEntity;
with 'IBibSpaceBackend';
use List::Util qw(first);
use List::MoreUtils qw(any uniq first_index);

=item
    This is a in-memory data structure (hash) to hold all objects of BibSpace.
    It is build like this:
    String "TypeName" => Array of Objects with type TypeName.
    It could be improved for performance like this:
    String "TypeName" => { Integer UID => Object with type TypeName}.
=cut

has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);

has 'data' => (
    traits    => ['Hash'],
    is        => 'ro',
    isa       => 'HashRef[HashRef[BibSpace::Model::IEntity]]',
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
    },
);


sub dump {
    my $self = shift;
    $self->logger->debug("SmartArray keys: ".join(', ', $self->keys));
}

sub _init {
    my $self = shift;
    my $type = shift;
    die "_init requires a type!" unless $type;
    if(!$self->defined($type)){
        $self->set($type, {});
    }
}
before '_init' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after '_init'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

sub all {
    my $self = shift;
    my $type = shift;
    die "all requires a type!" unless $type;
    $self->_init($type);
    my $href = $self->get($type);
    return () if !%{ $href };
    return values %{ $href };
}
before 'all' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'all'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

sub _add {
    my ($self, @objects) = @_;
    my $type = ref($objects[0]);
    $self->_init($type);
    my $href = $self->get($type);
    
    foreach my $obj (@objects){
        $href->{$obj->id} = $obj;
    }
}
before '_add' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after '_add'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

sub save {
    my ($self, @objects) = @_;
    my $added = 0;
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
before 'save' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'save'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

sub count { 
    my ($self, $type) = @_;
    die "all requires a type!" unless $type;
    $self->_init($type);
    my $href = $self->get($type);
    return 0 if !$href->{$type};
    return scalar keys %{ $href->{$type} };
}
before 'count' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'count'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

sub empty { 
    my ($self, $type) = @_;
    return $self->count($type) == 0;
}
before 'empty' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'empty'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

sub exists { 
    my ($self, $object) = @_;
    my $type = ref($object);
    my $href = $self->get($type);
    return exists $href->{$object->id};
}
before 'exists' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'exists'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

sub update { 
    my ($self, @objects) = @_;
    return $self->_add(@objects);
}
before 'update' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'update'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

sub delete { 
    my ($self, @objects) = @_; 
    my $type = ref($objects[0]);
    my $href = $self->get($type);

    foreach my $obj (@objects){
        delete $href->{$obj->id};
    }
}
before 'delete' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'delete'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

sub filter { 
    my ($self, $type, $coderef) = @_;
    # $self->logger->warn("Calling ".(caller(0))[3]." with param $type");
    return () if $self->empty($type);
    return grep \&{$coderef}, $self->all($type); 
}
before 'filter' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'filter'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

sub find { 
  my ($self, $type, $coderef) = @_;
  # $self->logger->warn("Calling ".(caller(0))[3]." with param $type");
  return undef if $self->empty($type);
  return first \&{$coderef}, $self->all($type);
}
before 'find' => sub { shift->logger->entering("","".(caller(0))[3].""); };
after 'find'  => sub { shift->logger->exiting("","".(caller(0))[3].""); };

# Moose::Meta::Attribute::Native::Trait::Array



__PACKAGE__->meta->make_immutable;
no Moose;
1;