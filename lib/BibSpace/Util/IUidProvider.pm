package IUidProvider;

use Moose::Role;

requires 'registerUID';
requires 'generateUID';
requires 'reset';


has 'for_type' => ( is => 'ro', isa => 'Str', required => 1);

has 'logger' => (
    is       => 'ro',
    does     => 'ILogger',
    required => 1,
);


no Moose;
1;