package IBibSpaceBackend;
use v5.16;
use Try::Tiny;
use Data::Dumper;
use namespace::autoclean;

use Moose::Role;

requires 'all';
requires 'count';
requires 'empty';
requires 'exists';
requires 'save';
requires 'update';
requires 'delete';
requires 'filter';
requires 'find';

1;

