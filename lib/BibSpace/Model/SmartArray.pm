package SmartArray;

use 5.010;    #because of ~~ and say
use Try::Tiny;
use Data::Dumper;

use Moose;
use Moose::Util::TypeConstraints;
use BibSpace::Model::IBibSpaceBackend;
with 'IBibSpaceBackend';
# use MooseX::Storage;
# with Storage( 'format' => 'JSON', 'io' => 'File' );


has 'data' => (
    traits    => ['Hash'],
    is        => 'ro',
    isa       => 'HashRef[ArrayRef[Object]]',
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

sub all {
    my $self = shift;
    my $type = shift;
    die "all requires a type!" unless $type;
    my $aref = $self->get($type);
    return @{ $aref };
}

sub save {
    my ($self, @objects) = @_;
    my $type = ref($objects[0]);
    if(!$self->defined($type)){
        $self->set($type, []);
    }
    push $self->get($type), @objects;
}

sub count { 
    my ($self) = @_;
    die "Method unimplemented!";
}
sub empty { 
    my ($self) = @_;
    die "Method unimplemented!";
}
sub exists { 
    my ($self, $object) = @_;
    die "Method unimplemented!";
}
sub update { 
    my ($self, @objects) = @_;
    die "Method unimplemented!";
}
sub delete { 
    my ($self, @objects) = @_; 
    die "Method unimplemented!";
}
sub filter { 
    my ($self, $coderef) = @_;
    die "Method unimplemented!";
}
sub find { 
  my ($self, $coderef) = @_;
  die "Method unimplemented!";
}

# Moose::Meta::Attribute::Native::Trait::Array



__PACKAGE__->meta->make_immutable;
no Moose;
1;