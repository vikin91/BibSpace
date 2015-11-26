use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('AdminApi');
$t->get_ok('/')->status_is(200)->content_like(qr/Please login or register/i);
$t->ua->max_redirects(1);

my @pages = (
            '/read/authors-for-tag/31/1',
            '/read/tags-for-author/1',
            '/read/tags-for-team/1',
            '/log?num=100',
            '/cron',
            '/cron/day',
            '/cron/night',
            '/cron/week',
            '/cron/month',
            '/authors/reassign',
            '/authors/reassign_and_create',
            '/settings/fix_months',
            '/settings/fix_entry_types',
            '/settings/clean_all',
            '/settings/regenerate_all',
            '/settings/regenerate_all_force',
            '/types',
            '/types/add',
            '/types/manage/article',
            '/types/toggle/article',
            '/types/toggle/article',
            '/tagtypes',
            '/tagtypes/edit/1'
             );

for my $page (@pages){
    $t->get_ok($page)->status_isnt(404)->or(sub { diag "We have 404 for $page" });
    $t->get_ok($page)->status_isnt(500)->or(sub { diag "We have 500 for $page" });
}


my $aa = $t->post_ok('/tagtypes/add' => form => {new_name => 'test', new_comment => 'foobaz'});
$aa->status_isnt(404);
$aa->status_isnt(500);

$aa = $t->post_ok('/tags/add/1' => form => {new_tag => 'test'});
$aa->status_isnt(404);
$aa->status_isnt(500);



note '============ Hiding ============';
$t->get_ok('/publications/hide/1', 'Hiding entry');
$t->get_ok('/read/publications/meta')->content_unlike(qr/Paper with id 1:/i, 'Checking meta of entries after hiding');
$t->get_ok('/read/publications/meta/1')->content_like(qr/Cannot find entry id: 1/i, 'Checking meta of the hidden entry');

note '============ Unhiding ============';
$t->get_ok('/publications/unhide/1', 'Unhiding entry');
$t->get_ok('/read/publications/meta')->content_like(qr/Paper with id 1: <a href/i, 'Checking meta of entries after unhiding');
$t->get_ok('/read/publications/meta/1')->content_unlike(qr/Cannot find entry id: 1/i, 'Checking meta of the unhidden entry');

note '============ Hiding Bibtex============';
$t->get_ok('/publications/unhide/792');
$t->get_ok('/r/p/get/792')->content_like(qr/WaSpKo-SIMUTools-QPNParallelSimulation/i);
$t->get_ok('/landing-years/publications')->content_like(qr/WaSpKo-SIMUTools-QPNParallelSimulation/i);
$t->get_ok('/landing/publications')->content_like(qr/WaSpKo-SIMUTools-QPNParallelSimulation/i);
$t->get_ok('/r/b')->content_like(qr/WaSpKo-SIMUTools-QPNParallelSimulation/i);

$t->get_ok('/publications/hide/792');
$t->get_ok('/r/p/get/792')->content_unlike(qr/WaSpKo-SIMUTools-QPNParallelSimulation/i);
$t->get_ok('/landing-years/publications')->content_unlike(qr/WaSpKo-SIMUTools-QPNParallelSimulation/i);
$t->get_ok('/landing/publications')->content_unlike(qr/WaSpKo-SIMUTools-QPNParallelSimulation/i);
$t->get_ok('/r/b')->content_unlike(qr/WaSpKo-SIMUTools-QPNParallelSimulation/i);




done_testing();

