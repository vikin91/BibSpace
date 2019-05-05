use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

`rm -f test-backups/*sql`;

my $anyone = Test::Mojo->new('BibSpace');
if ($anyone->app->mode ne 'production') {
  `rm -f backups/*dat`;
  `rm -f backups/*sql`;
  `rm -f test-backups/*dat`;
  `rm -f test-backups/*sql`;
}

ok(1);
done_testing();

