use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME            => 'BibSpace',
  VERSION_FROM    => 'lib/BibSpace/BibSpace.pm'
  PREREQ_PM => {'Mojolicious' => '7.20'},
  test      => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'}
);
