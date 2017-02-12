use Mojo::Base -strict;
use Test::More;
use Test::Mojo;


package DummyLogger;
use namespace::autoclean;

use Moose;
use BibSpace::Util::ILogger;
with 'ILogger';

package main;
use DummyLogger;

my $log = DummyLogger->new;
ok($log->debug("message"));
ok($log->entering("message"));
ok($log->exiting("message"));
ok($log->info("message"));
ok($log->warn("message"));
ok($log->error("message"));


ok(1);
done_testing();
