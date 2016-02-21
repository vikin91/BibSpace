use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use Hex64Publications;
use Hex64Publications::Controller::Core;
use Hex64Publications::Controller::Backup;
use Hex64Publications::Functions::BackupFunctions;
use Hex64Publications::Functions::EntryObj;

todo:{


my $t_anyone = Test::Mojo->new('Hex64Publications');
$t_anyone->get_ok('/')->status_is(200)->content_like(qr/Please login or register/i);

note "============ Testing bad password ============";
$t_anyone->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf1234' }
);

$t_anyone->get_ok('/')
    ->status_isnt(404)
    ->status_isnt(500)
    ->content_like(qr/Wrong username or password/i);



note "============ Loggin in ============";
my $t_logged_in = Test::Mojo->new('Hex64Publications');
$t_logged_in->ua->max_redirects(10);
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);

$t_logged_in->get_ok('/')
    ->status_is(200)
    ->content_like(qr/Nice to see you here <em>Admin<\/em>/i);


}

done_testing();

