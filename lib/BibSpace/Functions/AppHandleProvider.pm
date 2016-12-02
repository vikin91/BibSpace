package AppHandleProvider;

use Data::Dumper;
use 5.010;           #because of ~~ and say
use Try::Tiny;
use Redis;
use MooseX::Singleton;


has app => (
    is      => 'ro',
);

has dbh => (
    is      => 'ro',
);

has bst => (
    is      => 'ro',
);

no Moose;
__PACKAGE__->meta->make_immutable();
1;
