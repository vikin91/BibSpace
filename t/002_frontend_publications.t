use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Functions::Core;

my $t_anyone    = Test::Mojo->new('BibSpace');
my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);
my $self = $t_logged_in->app;

# this is crucial for the test to pass as there are redirects here!
$t_logged_in->ua->max_redirects(10);
$t_logged_in->ua->inactivity_timeout(3600);

my $page = '/';

$page = $self->url_for('fix_attachment_urls');
$t_logged_in->get_ok($page)->status_isnt( 404, "Checking: 404 $page" )
    ->status_isnt( 500, "Checking: 500 $page" )
    ->content_like(qr/The following urls are now fixed/i);

$page = $self->url_for('clean_ugly_bibtex');
$t_logged_in->get_ok($page)->status_isnt( 404, "Checking: 404 $page" )
    ->status_isnt( 500, "Checking: 500 $page" )
    ->content_like(qr/All entries have now their Bibtex cleaned/i);

$page = $self->url_for('add_publication');
$t_logged_in->get_ok($page)->status_isnt( 404, "Checking: 404 $page" )
    ->status_isnt( 500, "Checking: 500 $page" )
    ->content_like(
    qr/<strong>Adding mode<\/strong> You operate on an unsaved entry/i);

$page = $self->url_for('add_many_publications');
$t_logged_in->get_ok($page)->status_isnt( 404, "Checking: 404 $page" )
    ->status_isnt( 500, "Checking: 500 $page" )
    ->content_like(
    qr/Adding multiple publications at once is <strong>experimental!<\/strong>/i
    );

# this weak! fix it later
$page = $self->url_for( 'recently_changed', num => 10 );
$t_logged_in->get_ok($page)->status_isnt( 404, "Checking: 404 $page" )
    ->status_isnt( 500, "Checking: 500 $page" )
    ->content_like(qr/glyphicon-barcode/i);

# this weak! fix it later
$page = $self->url_for( 'recently_added', num => 10 );
$t_logged_in->get_ok($page)->status_isnt( 404, "Checking: 404 $page" )
    ->status_isnt( 500, "Checking: 500 $page" )
    ->content_like(qr/glyphicon-barcode/i);

done_testing();
