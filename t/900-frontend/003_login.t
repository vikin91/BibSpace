use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Functions::Core;



my $t_anyone = Test::Mojo->new('BibSpace');

## THIS SHOULD BE REPEATED FOR EACH TEST!
my $fixture_name = "bibspace_fixture.dat";
my $fixture_dir = "./fixture/";
use BibSpace::Model::Backup;
use BibSpace::Functions::BackupFunctions qw(restore_storable_backup);
my $fixture = Backup->new(dir => $fixture_dir, filename =>$fixture_name);
restore_storable_backup($fixture, $t_anyone->app);

####################################################################
subtest 'login: start page asking to login' => sub {
	$t_anyone->get_ok('/')->status_is(200);
	$t_anyone->get_ok('/logout')->status_isnt(404)->status_isnt(500);
	$t_anyone->get_ok('/')->status_is(200)->content_like(qr/Please login or register/i);
};


####################################################################
subtest 'login: pub_admin bad password' => sub {

	$t_anyone->post_ok(
	    '/do_login' => { Accept => '*/*' },
	    form        => { user   => 'pub_admin', pass => 'something_really_wrong' }
	);

	$t_anyone->get_ok('/')
	    ->status_isnt(404)
	    ->status_isnt(500)
	    ->content_like(qr/Wrong user\s*name or password/i);  # accepts username and user name
};



####################################################################
subtest 'login: pub_admin login' => sub {

	$t_anyone->ua->max_redirects(10);
	$t_anyone->post_ok(
	    '/do_login' => { Accept => '*/*' },
	    form        => { user   => 'pub_admin', pass => 'asdf' }
	);

	$t_anyone->get_ok('/')
	    ->status_isnt(404)->status_isnt(500)
	    ->content_like(qr/Nice to see you here/i);
};




done_testing();

