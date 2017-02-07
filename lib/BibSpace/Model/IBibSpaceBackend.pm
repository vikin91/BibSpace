package IBibSpaceBackend;
use v5.16;    #because of ~~ and say
use Try::Tiny;
use Data::Dumper;
use namespace::autoclean;
use feature qw(current_sub);
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

