use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

`rm test-backups/*sql`;
`rm backups/*dat`;
`rm backups/*sql`;



ok(1);
done_testing();


