package SmartArray;

use 5.010;    #because of ~~ and say
use Try::Tiny;
use Data::Dumper;

use Moose;

# use MooseX::Storage;
# with Storage( 'format' => 'JSON', 'io' => 'File' );

# Moose::Meta::Attribute::Native::Trait::Array

has 'container' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        all        => 'elements',
        add        => 'push',
        map        => 'map',
        filter     => 'grep',
        find       => 'first',
        find_index => 'first_index',
        delete     => 'delete',
        clear      => 'clear',
        find       => 'first',
        get        => 'get',
        join       => 'join',
        count      => 'count',
        has        => 'count',
        has_no     => 'is_empty',
        sorted     => 'sort',
    },
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;