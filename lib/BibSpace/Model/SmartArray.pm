package SmartArray;

use 5.010;    #because of ~~ and say
use Try::Tiny;
use Data::Dumper;
use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;
use BibSpace::Model::IBibSpaceBackend;
with 'IBibSpaceBackend';
# use MooseX::Storage;
# with Storage( 'format' => 'JSON', 'io' => 'File' );

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
before 'all' => sub { shift->logger->entering("","".__PACKAGE__."->all"); };
after 'all'  => sub { shift->logger->exiting("","".__PACKAGE__."->all"); };

sub save {
    my ($self, @objects) = @_;
    my $type = ref($objects[0]);
    if(!$self->defined($type)){
        $self->set($type, []);
    }
    push @{$self->get($type)}, @objects;
}
before 'save' => sub { shift->logger->entering("","".__PACKAGE__."->save"); };
after 'save'  => sub { shift->logger->exiting("","".__PACKAGE__."->save"); };

sub count { 
    my ($self) = @_;
    die "Method unimplemented!";
}
before 'count' => sub { shift->logger->entering("","".__PACKAGE__."->count"); };
after 'count'  => sub { shift->logger->exiting("","".__PACKAGE__."->count"); };

sub empty { 
    my ($self) = @_;
    die "Method unimplemented!";
}
before 'empty' => sub { shift->logger->entering("","".__PACKAGE__."->empty"); };
after 'empty'  => sub { shift->logger->exiting("","".__PACKAGE__."->empty"); };

sub exists { 
    my ($self, $object) = @_;
    die "Method unimplemented!";
}
before 'exists' => sub { shift->logger->entering("","".__PACKAGE__."->exists"); };
after 'exists'  => sub { shift->logger->exiting("","".__PACKAGE__."->exists"); };

sub update { 
    my ($self, @objects) = @_;
    die "Method unimplemented!";
}
before 'update' => sub { shift->logger->entering("","".__PACKAGE__."->update"); };
after 'update'  => sub { shift->logger->exiting("","".__PACKAGE__."->update"); };

sub delete { 
    my ($self, @objects) = @_; 
    die "Method unimplemented!";
}
before 'delete' => sub { shift->logger->entering("","".__PACKAGE__."->delete"); };
after 'delete'  => sub { shift->logger->exiting("","".__PACKAGE__."->delete"); };

sub filter { 
    my ($self, $coderef) = @_;
    die "Method unimplemented!";
}
before 'filter' => sub { shift->logger->entering("","".__PACKAGE__."->filter"); };
after 'filter'  => sub { shift->logger->exiting("","".__PACKAGE__."->filter"); };

sub find { 
  my ($self, $coderef) = @_;
  die "Method unimplemented!";
}
before 'find' => sub { shift->logger->entering("","".__PACKAGE__."->find"); };
after 'find'  => sub { shift->logger->exiting("","".__PACKAGE__."->find"); };

# Moose::Meta::Attribute::Native::Trait::Array



__PACKAGE__->meta->make_immutable;
no Moose;
1;