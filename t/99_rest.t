use Mojo::Base -strict;
use Test::More;
use Test::Mojo;



my $anyone = Test::Mojo->new('BibSpace');
if($anyone->app->mode ne 'production'){	
	`rm backups/*dat`;
	`rm backups/*sql`;
	`rm test-backups/*dat`;
	`rm test-backups/*sql`;
}

ok(1);
done_testing();


