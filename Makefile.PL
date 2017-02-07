use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION   => '0.05',
  PREREQ_PM => {'Mojolicious' => '7.20'},
  test      => {TESTS => 't/*.t'}
);
