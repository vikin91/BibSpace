use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

## :P

my $author_id = 527;
my $entry_id = 792;
my $entry_bibtex_key = "WaSpKo-SIMUTools-QPNParallelSimulation";
my $tag_id = 31;

my $t_anyone = Test::Mojo->new('AdminApi');
$t_anyone->get_ok('/')->status_is(200)->content_like(qr/Please login or register/i);




my $t_logged_in = Test::Mojo->new('AdminApi');
$t_logged_in->ua->max_redirects(10);
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'aaaa' }
);
$t_logged_in->get_ok('/')->status_is(200)->content_like(qr/Nice to see you here <em>Admin<\/em>/i);



my @pages = (
            "/read/authors-for-tag/$tag_id/$author_id",
            "/read/tags-for-author/$author_id",
            "/read/tags-for-team/$author_id",
            "/log?num=100",
            "/cron",
            "/cron/day",
            "/cron/night",
            "/cron/week",
            "/cron/month",
            "/authors/reassign",
            "/authors/reassign_and_create",
            "/settings/fix_months",
            "/settings/fix_entry_types",
            "/settings/clean_all",
            "/settings/regenerate_all",
            "/settings/regenerate_all_force",
            "/types",
            "/types/add",
            "/types/manage/article",
            "/types/toggle/article",
            "/types/toggle/article",
            "/tagtypes",
            "/tagtypes/edit/1",
             );

for my $page (@pages){
    $t_logged_in->get_ok($page)->status_isnt(404)->or(sub { diag "We have 404 for $page" });
    $t_logged_in->get_ok($page)->status_isnt(500)->or(sub { diag "We have 500 for $page" });
}


my $aa = $t_logged_in->post_ok('/tagtypes/add' => form => {new_name => 'test', new_comment => 'foobaz'});
$aa->status_isnt(404);
$aa->status_isnt(500);

$aa = $t_logged_in->post_ok('/tags/add/1' => form => {new_tag => 'test'});
$aa->status_isnt(404);
$aa->status_isnt(500);



note '============ Hiding ============';
$t_logged_in->get_ok("/publications/hide/$entry_id");
$t_anyone->get_ok("/read/publications/meta")->content_unlike(qr/Paper with id $entry_id:/i);
$t_anyone->get_ok("/read/publications/meta/$entry_id")->content_like(qr/Cannot find entry id: $entry_id/i);

note '============ Unhiding ============';
$t_logged_in->get_ok("/publications/unhide/$entry_id");
$t_anyone->get_ok("/read/publications/meta")->content_like(qr/Paper with id $entry_id: <a href/i);
$t_anyone->get_ok("/read/publications/meta/$entry_id")->content_unlike(qr/Cannot find entry id: $entry_id/i);


# shall I refresh it to avoid timeouts by testing??
$t_logged_in = Test::Mojo->new('AdminApi');
$t_logged_in->ua->max_redirects(10);
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'aaaa' }
);
$t_logged_in->get_ok('/')->status_is(200)->content_like(qr/Nice to see you here <em>Admin<\/em>/i);


note '============ Hiding Bibtex============';
$t_logged_in->get_ok("/publications/unhide/$entry_id");
$t_anyone->get_ok("/r/p/get/$entry_id")->content_like(qr/$entry_bibtex_key/i);
$t_anyone->get_ok("/landing-years/publications")->content_like(qr/$entry_bibtex_key/i);
$t_anyone->get_ok("/landing/publications")->content_like(qr/$entry_bibtex_key/i);
$t_anyone->get_ok("/r/b")->content_like(qr/$entry_bibtex_key/i);

$t_logged_in->get_ok("/publications/hide/$entry_id");
$t_anyone->get_ok("/r/p/get/$entry_id")->content_unlike(qr/$entry_bibtex_key/i);
$t_anyone->get_ok("/landing-years/publications")->content_unlike(qr/$entry_bibtex_key/i);
$t_anyone->get_ok("/landing/publications")->content_unlike(qr/$entry_bibtex_key/i);
$t_anyone->get_ok("/r/b")->content_unlike(qr/$entry_bibtex_key/i);
$t_logged_in->get_ok("/publications/unhide/$entry_id");


# todo: Opisy testow: ok($t->get_ok($_)->status_is(403) => "$_ no creds : 403") for @urls;

done_testing();

