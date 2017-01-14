# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T17:18:02
package BibSpace::Model::DAO::Interface::IAuthorshipDAO;

use namespace::autoclean;
use Moose::Role; # = this package (class) is an interface
# Perl interfaces (Roles) can contain attributes =)
# In Java this interface would differ from other DAO::ENTITY interfaces.
# classes that implement this interface must provide the following functions
requires 'all';
requires 'save';
requires 'update';
requires 'delete';
requires 'exists';
requires 'filter';
requires 'find';
requires 'count';

has 'logger' => ( is => 'ro', does => 'BibSpace::Model::ILogger', required => 1);
# e.g. database connection handle
has 'handle' => ( is => 'ro', required => 1);
1;
