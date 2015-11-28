use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Hex64Publications;
use Hex64Publications::Core;
use EntryObj;
## :P

# my $author_id = 527;
# my $entry_id = 792;
# my $entry_bibtex_key = "WaSpKo-SIMUTools-QPNParallelSimulation";
# my $tag_id = 31;

my $t_anyone = Test::Mojo->new('Hex64Publications');
$t_anyone->get_ok('/')->status_is(200)->content_like(qr/Please login or register/i);

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


my $dbh = $t_logged_in->app->db;







note '============ Adding atuhor ============';
$t_logged_in->post_ok(
    '/authors/add' => { Accept => '*/*' },
    form        => { new_master   => 'ExampleJohn' }
);
### this should be author no. 1

note '============ Adding user ids to atuhor ============';
$t_logged_in->post_ok(
    '/authors/edit' => { Accept => '*/*' },
    form        => { master => 'ExampleJohn', id => 1,  new_user_id   => 'ExampleJoe' }
);

note '============ Adding publication 1 ============';
my $key1="key2015_0011";

$t_logged_in->post_ok(
    '/publications/add/store' => { Accept => '*/*' },
    form        => { save => 1, new_bib => '@article{'.$key1.',
    author = {John Example},
    title = {{Selected aspects of some methods}},
    year = {2015},
    month = {October},
    day = {1--31},
}'}
);

my $entry_id_1 = EntryObj->getByBibtexKey($dbh, $key1)->{id} || -1;
ok($entry_id_1 > 0, "Entry 1 added OK with id $entry_id_1");

note '============ Adding publication 2 ============';
my $key2="key2015_0022";

$t_logged_in->post_ok(
    '/publications/add/store' => { Accept => '*/*' },
    form        => { save => 1, new_bib => '@article{'.$key2.',
    author = {John Example},
    title = {{Selected aspects of some methods}},
    year = {2015},
    month = {October},
    day = {1--31},
}'}
);

my $entry_id_2 = EntryObj->getByBibtexKey($dbh, $key2)->{id} || -1;
ok($entry_id_2 > 0, "Entry 2 added OK with id $entry_id_2");


my $tag_type_id = TagTypeObj->getByName($dbh, 'test')->{id} || -1;
if($tag_type_id == -1){
    note "============ Adding tag type ============";
    $t_logged_in->post_ok('/tagtypes/add' => form => {new_name => 'test', new_comment => 'foobaz'});
    $tag_type_id = TagTypeObj->getByName($dbh, 'test')->{id} || -1;
}

note "============ Adding checking tag type ============";
$t_logged_in->get_ok("/tags/$tag_type_id")
    ->status_is(200)
    ->text_is( h2 => "Tags of type test (ID=$tag_type_id)" );


note "============ Adding tag ============";
$t_logged_in->post_ok("/tags/add/$tag_type_id" => form => {new_tag => 'test'});
my $tag_id = TagObj->getByName($dbh, 'test')->{id} || -1;

$t_logged_in->get_ok("/tags/$tag_type_id")
    ->status_is(200)
    ->text_is( h2 => "Tags of type test (ID=$tag_type_id)" )
    ->content_like(qr/bibtex\?tag=Test/i);

note "============ Adding second tag ============";
$t_logged_in->post_ok("/tags/add/$tag_type_id" => form => {new_tag => 'second_test'});
my $second_tag_id = TagObj->getByName($dbh, 'second_test')->{id} || -1;

$t_logged_in->get_ok("/tags/$tag_type_id")
    ->status_is(200)
    ->text_is( h2 => "Tags of type test (ID=$tag_type_id)" )
    ->content_like(qr/bibtex\?tag=Second_test/i);

note "============ Removing tag ============";
$t_logged_in->get_ok("/tags/delete/$second_tag_id")
    ->status_is(200)
    ->text_isnt( h2 => "Tags of type test (ID=$tag_type_id)" )
    ->content_unlike(qr/bibtex\?tag=Second_test"/i);






my $entry_id = $entry_id_1;
my $entry_bibtex_key = $key1;

note '============ Hiding ============';
$t_logged_in->get_ok("/publications/hide/$entry_id", "Hiding entry id $entry_id");
$t_anyone->get_ok("/read/publications/meta")->content_unlike(qr/Paper with id $entry_id:/i, "Entry id $entry_id visible on metalist?");
$t_anyone->get_ok("/read/publications/meta/$entry_id")->content_like(qr/Cannot find entry id: $entry_id/i, "Meta of Entry id $entry_id visible?");

note '============ Unhiding ============';
$t_logged_in->get_ok("/publications/unhide/$entry_id");
$t_anyone->get_ok("/read/publications/meta")->content_like(qr/Paper with id $entry_id: <a href/i);
$t_anyone->get_ok("/read/publications/meta/$entry_id")->content_unlike(qr/Cannot find entry id: $entry_id/i);

Skip : { # depends on successful installation of bibtex2html
    note '============ Hiding Bibtex ============';
    $t_logged_in->get_ok("/publications/unhide/$entry_id");
    

    if( $t_anyone->get_ok("/r/p/get/$entry_id")->content_like(qr/nohtml/i) == 0){
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
    }
}
# # todo: Opisy testow: ok($t->get_ok($_)->status_is(403) => "$_ no creds : 403") for @urls;



note '============ Basic Tests ============';
my $author_id = get_author_id_for_master($dbh, 'ExampleJohn');

my @pages = (
            "/read/authors-for-tag/$tag_id/$author_id",
            "/read/tags-for-author/$author_id",
            "/read/tags-for-team/$author_id",
            "/publications/untagged/$author_id/21",
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
            "/manage_users",
            "/profile/1", # assumin id 1 belongs always to admin and admin always exists
            "/types",
            "/types/add",
            "/types/manage/article",
            "/types/toggle/article",
            "/types/toggle/article",
            "/tagtypes",
             );

for my $page (@pages){
    note "============ Testing page $page ============";
    $t_logged_in->get_ok($page)->status_isnt(404)->status_isnt(500);
}



done_testing();

