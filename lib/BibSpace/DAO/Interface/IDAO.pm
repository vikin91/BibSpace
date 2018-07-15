package IDAO;

use namespace::autoclean;

use Try::Tiny;
use List::Util qw(first);
use List::MoreUtils qw(first_index);
use feature qw( say );

# for benchmarking
use Time::HiRes qw( gettimeofday tv_interval );

use Moose::Role;    # = this package (class) is an interface

# Perl interfaces (Roles) can contain attributes =)
# In Java this interface would differ from other DAO::ENTITY interfaces.
# classes that implement this interface must provide the following functions

requires 'all';
requires 'count';
requires 'save';
requires 'update';
requires 'delete';
requires 'exists';
requires 'filter';
requires 'find';

has 'logger' => (is => 'ro', does => 'ILogger', required => 1);

# e.g. database connection handle
has 'handle' => (is => 'ro', required => 1, traits => ['DoNotSerialize']);
has 'e_factory' => (is => 'ro', isa => 'EntityFactory', required => 1);

1;
