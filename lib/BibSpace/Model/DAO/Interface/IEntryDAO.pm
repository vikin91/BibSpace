# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T22:33:39
package IEntryDAO;

use namespace::autoclean;
use Moose::Role; # = this package (class) is an interface
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

has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);
# e.g. database connection handle
has 'handle' => ( is => 'ro', required => 1);
1;
