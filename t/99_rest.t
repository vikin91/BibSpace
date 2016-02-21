use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Hex64Publications;
use Hex64Publications::Controller::Core;
use Hex64Publications::Controller::Backup;
use Hex64Publications::Functions::BackupFunctions;
use Hex64Publications::Functions::EntryObj;

ok(1);

# skip: {

# # ############################ PREPARATION
# my $t_anyone = Test::Mojo->new('Hex64Publications');
# my $t_logged_in = Test::Mojo->new('Hex64Publications');
# $t_logged_in->post_ok(
#     '/do_login' => { Accept => '*/*' },
#     form        => { user   => 'pub_admin', pass => 'asdf' }
# );

# my $dbh = $t_logged_in->app->db;

# # ############################ READY FOR TESTING

# # # GET ROUTES
# #   +/settings/regenerate_all                  GET   settingsregenerate_all

# # #   +/settings/regenerate_all                  GET   settingsregenerate_all
# # #   +/backup                                   GET   backup
# # #   +/backup/download/:file                    GET   backupdownloadfile
# # #   +/types                                    GET   types
# # #   +/types/add                                GET   typesadd
# # #   +/types/manage/:type                       GET   typesmanagetype
# # #   +/types/delete/:type_to_delete             GET   typesdeletetype_to_delete
# # #   +/types/toggle/:type                       GET   typestoggletype
# # #   +/types/:our_type/map/:bibtex_type         GET   typesour_typemapbibtex_type
# # #   +/types/:our_type/unmap/:bibtex_type       GET   typesour_typeunmapbibtex_type
# # #   +/authors                                  GET   authors
# # #   +/authors/add                              GET   authorsadd
# # #   +/authors/edit/:id                         GET   authorseditid
# # #   +/authors/delete/:id                       GET   authorsdeleteid
# # #   +/authors/delete/:id/force                 GET   authorsdeleteidforce
# # #   +/authors/:id/add_to_team/:tid             GET   authorsidadd_to_teamtid
# # #   +/authors/:id/remove_from_team/:tid        GET   authorsidremove_from_teamtid
# # #   +/authors/:id/remove_uid/:uid              GET   authorsidremove_uiduid
# # #   +/authors/reassign                         GET   authorsreassign
# # #   +/authors/reassign_and_create              GET   authorsreassign_and_create
# # #   +/authors/visible                          GET   authorsvisible
# # #   +/authors/toggle_visibility/:id            GET   authorstoggle_visibilityid
# # #   +/tagtypes                                 GET   tagtypes
# # #   +/tagtypes/add                             GET   tagtypesadd
# # #   +/tagtypes/delete/:id                      GET   tagtypesdeleteid
# # #   +/tags/:type                               GET   tagstype
# # #   +/tags/add/:type                           GET   tagsaddtype
# # #   +/tags/authors/:tid/:type                  GET   tagsauthorstidtype
# # #   +/tags/delete/:id_to_delete                GET   tagsdeleteid_to_delete
# # #   +/tags/edit/:id                            GET   tagseditid
# # #   +/teams                                    GET   teams
# # #   +/teams/members/:teamid                    GET   teamsmembersteamid
# # #   +/teams/edit/:teamid                       GET   teamseditteamid
# # #   +/teams/delete/:id_to_delete               GET   teamsdeleteid_to_delete
# # #   +/teams/delete/:id_to_delete/force         GET   teamsdeleteid_to_deleteforce
# # #   +/teams/unrealted_papers/:teamid           GET   teamsunrealted_papersteamid
# # #   +/teams/add                                GET   teamsadd
# # #   +/publications-set                         GET   publicationsset
# # #   +/publications                             GET   publications
# # #   +/publications/recently_added/:num         GET   publicationsrecently_addednum
# # #   +/publications/recently_modified/:num      GET   publicationsrecently_modifiednum
# # #   +/publications/orphaned                    GET   publicationsorphaned
# # #   +/publications/untagged/:tagtype           GET   publicationsuntaggedtagtype
# # #   +/publications/untagged/:author/:tagtype   GET   publicationsuntaggedauthortagtype
# # #   +/publications/candidates_to_delete        GET   publicationscandidates_to_delete
# # #   +/publications/missing_month               GET   publicationsmissing_month
# # #   +/publications/sdqpdf                      GET   publicationssdqpdf
# # #   +/publications/get/:id                     GET   publicationsgetid
# # #   +/publications/hide/:id                    GET   publicationshideid
# # #   +/publications/unhide/:id                  GET   publicationsunhideid
# # #   +/publications/toggle_hide/:id             GET   publicationstoggle_hideid
# # #   +/publications/add                         GET   publicationsadd
# # #   +/publications/make_paper/:id              GET   publicationsmake_paperid
# # #   +/publications/make_talk/:id               GET   publicationsmake_talkid
# # #   +/publications/edit/:id                    GET   publicationseditid
# # #   +/publications/edit/store/:id              GET   publicationseditstoreid
# # #   +/publications/regenerate/:id              GET   publicationsregenerateid
# # #   +/publications/delete/:id                  GET   publicationsdeleteid
# # #   +/publications/delete_sure/:id             GET   publicationsdelete_sureid
# # #   +/publications/add_pdf/:id                 GET   publicationsadd_pdfid
# # #   +/publications/manage_tags/:id             GET   publicationsmanage_tagsid
# # #   +/publications/:eid/remove_tag/:tid        GET   publicationseidremove_tagtid
# # #   +/publications/:eid/add_tag/:tid           GET   publicationseidadd_tagtid
# # #   +/publications/manage_exceptions/:id       GET   publicationsmanage_exceptionsid
# # #   +/publications/:eid/remove_exception/:tid  GET   publicationseidremove_exceptiontid
# # #   +/publications/:eid/add_exception/:tid     GET   publicationseidadd_exceptiontid
# # #   +/publications/show_authors/:id            GET   publicationsshow_authorsid
# # # /publications/download/:filetype/:id
# # # /backup/do                                   GET   backupdo
# # # /search/:type/:q                             GET   searchtypeq
# # # /read/publications/meta                      GET   readpublicationsmeta
# # # /read/publications/meta/:id                  GET   readpublicationsmetaid
# # # /read/publications                           GET   readpublications
# # # /r/publications                              GET   rpublications
# # # /r/p                                         GET   rp
# # # /read/bibtex                                 GET   readbibtex
# # # /r/bibtex                                    GET   rbibtex
# # # /r/b                                         GET   rb
# # # /read/publications/get/:id                   GET   readpublicationsgetid
# # # /r/p/get/:id                                 GET   rpgetid
# # # /landing/publications                        GET   landingpublications
# # # /l/p                                         GET   lp
# # # /landing-years/publications                  GET   landingyearspublications
# # # /ly/p                                        GET   lyp
# # # /read/authors-for-tag/:tid/:team             GET   readauthorsfortagtidteam
# # # /r/a4t/:tid/:team                            GET   ra4ttidteam
# # # /read/tags-for-author/:aid                   GET   readtagsforauthoraid
# # # /r/t4a/:aid                                  GET   rt4aaid
# # # /read/tags-for-team/:tid                     GET   readtagsforteamtid
# # # /r/t4a/:tid                                  GET   rt4atid
# # # /cron                                        GET   cron
# # # /cron/day                                    GET   cronday
# # # /cron/night                                  GET   cronnight
# # # /cron/week                                   GET   cronweek
# # # /cron/month                                  GET   cronmonth


# # # NON-GET ROUTES
# # # /forgot/gen                                  POST  forgotgen
# # # /forgot/store                                POST  forgotstore
# # # /login_form                                  *     "login_form"
# # # /do_login                                    POST  "do_login"
# # # /test/500                                    *     test500
# # # /test/404                                    *     test404
# # # /register                                    POST  register
# # # /noregister                                  *     noregister
# # # /                                            *     
# # #   +/                                         *     
# # #   +/                                         *     
# # #   +/types/add                                POST  typesadd
# # #   +/types/store_description                  POST  typesstore_description
# # #   +/authors/add                              POST  authorsadd
# # #   +/authors/edit                             POST  authorsedit
# # #   +/authors/edit_membership_dates            POST  authorsedit_membership_dates
# # #   +/tagtypes/add                             POST  tagtypesadd
# # #   +/tagtypes/edit/:id                        *     tagtypeseditid
# # #   +/tags/add/:type                           POST  tagsaddtype
# # #   +/tags/add_and_assign/:eid                 *     tagsadd_and_assigneid
# # #   +/teams/add                                POST  teamsadd
# # #   +/publications/add/store                   POST  publicationsaddstore
# # #   +/publications/edit/store/:id              POST  publicationseditstoreid
# # #   +/publications/add_pdf/do/:id              POST  publicationsadd_pdfdoid


  
# note '============ Adding author ============';
# $t_logged_in->post_ok(
#     '/authors/add' => { Accept => '*/*' },
#     form        => { new_master   => 'ExampleJohn' }
# );
# ### this should be author no. 1

# note '============ Adding user ids to author ============';
# $t_logged_in->post_ok(
#     '/authors/edit' => { Accept => '*/*' },
#     form        => { master => 'ExampleJohn', id => 1,  new_user_id   => 'ExampleJoe' }
# );

$t_logged_in->post_ok(
    '/publications/add/store' => { Accept => '*/*' },
    form        => { save => 1, new_bib => '@article{'.$key1.',
    author = {John Example},
    title = {{Selected aspects of some methods}},
    year = {2015},
# note '============ Adding publication 1 ============';
# my $key1="key2015_0011";

# $t_logged_in->post_ok(
#     '/publications/add/store' => { Accept => '*/*' },
#     form        => { save => 1, new_bib => '@article{'.$key1.',
#     author = {John Example},
#     title = {{Selected aspects of some methods}},
#     year = {2015},
#     month = {October},
#     day = {1--31},
# }'}
# );

# my $entry_id_1 = EntryObj->getByBibtexKey($dbh, $key1)->{id} || -1;
# ok($entry_id_1 > 0, "Entry 1 added OK with id $entry_id_1");

# note '============ Adding publication 2 ============';
# my $key2="key2015_0022";

# $t_logged_in->post_ok(
#     '/publications/add/store' => { Accept => '*/*' },
#     form        => { save => 1, new_bib => '@article{'.$key2.',
#     author = {John Example},
#     title = {{Selected aspects of some methods}},
#     year = {2015},
#     month = {October},
#     day = {1--31},
# }'}
# );

# my $entry_id_2 = EntryObj->getByBibtexKey($dbh, $key2)->{id} || -1;
# ok($entry_id_2 > 0, "Entry 2 added OK with id $entry_id_2");


# my $tag_type_id = TagTypeObj->getByName($dbh, 'test')->{id} || -1;
# if($tag_type_id == -1){
#     note "============ Adding tag type ============";
#     $t_logged_in->post_ok('/tagtypes/add' => form => {new_name => 'test', new_comment => 'foobaz'});
#     $tag_type_id = TagTypeObj->getByName($dbh, 'test')->{id} || -1;
# }

# note "============ Adding checking tag type ============";
# $t_logged_in->get_ok("/tags/$tag_type_id")
#     ->status_is(200)
#     ->text_is( h2 => "Tags of type test (ID=$tag_type_id)" );

note "============ Adding tag ============";
$t_logged_in->post_ok("/tags/add/$tag_type_id" => form => {new_tag => 'test'});
my $tag_id = TagObj->getByName($dbh, 'test')->{id} || -1;

# note "============ Adding tag ============";
# $t_logged_in->post_ok("/tags/add/$tag_type_id" => form => {new_tag => 'test'});
# my $tag_id = TagObj->getByName($dbh, 'test')->{id} || -1;

# $t_logged_in->get_ok("/tags/$tag_type_id")
#     ->status_is(200)
#     ->text_is( h2 => "Tags of type test (ID=$tag_type_id)" )
#     ->content_like(qr/bibtex\?tag=Test/i);

# note "============ Adding second tag ============";
# $t_logged_in->post_ok("/tags/add/$tag_type_id" => form => {new_tag => 'second_test'});
# my $second_tag_id = TagObj->getByName($dbh, 'second_test')->{id} || -1;

# $t_logged_in->get_ok("/tags/$tag_type_id")
#     ->status_is(200)
#     ->text_is( h2 => "Tags of type test (ID=$tag_type_id)" )
#     ->content_like(qr/bibtex\?tag=Second_test/i);

# note "============ Removing tag ============";
# $t_logged_in->get_ok("/tags/delete/$second_tag_id")
#     ->status_isnt(404)->status_isnt(500)
#     ->text_isnt( h2 => "Tags of type test (ID=$tag_type_id)" )
#     ->content_unlike(qr/bibtex\?tag=Second_test"/i);






# my $entry_id = $entry_id_1;
# my $entry_bibtex_key = $key1;

# note '============ Hiding ============';
# $t_logged_in->get_ok("/publications/hide/$entry_id", "Hiding entry id $entry_id");
# $t_anyone->get_ok("/read/publications/meta")->content_unlike(qr/Paper with id $entry_id:/i, "Entry id $entry_id visible on metalist?");
# $t_anyone->get_ok("/read/publications/meta/$entry_id")->content_like(qr/Cannot find entry id: $entry_id/i, "Meta of Entry id $entry_id visible?");

# note '============ Unhiding ============';
# $t_logged_in->get_ok("/publications/unhide/$entry_id");
# $t_anyone->get_ok("/read/publications/meta")->content_like(qr/Paper with id $entry_id: <a href/i);
# $t_anyone->get_ok("/read/publications/meta/$entry_id")->content_unlike(qr/Cannot find entry id: $entry_id/i);

# Skip : { # depends on successful installation of bibtex2html
#     note '============ Hiding Bibtex ============';
#     $t_logged_in->get_ok("/publications/unhide/$entry_id");
    

#     if( $t_anyone->get_ok("/r/p/get/$entry_id")->content_like(qr/nohtml/i) == 0){
#         $t_anyone->get_ok("/r/p/get/$entry_id")->content_like(qr/$entry_bibtex_key/i);
#         $t_anyone->get_ok("/landing-years/publications")->content_like(qr/$entry_bibtex_key/i);
#         $t_anyone->get_ok("/landing/publications")->content_like(qr/$entry_bibtex_key/i);
#         $t_anyone->get_ok("/r/b")->content_like(qr/$entry_bibtex_key/i);    

#         $t_logged_in->get_ok("/publications/hide/$entry_id");
#         $t_anyone->get_ok("/r/p/get/$entry_id")->content_unlike(qr/$entry_bibtex_key/i);
#         $t_anyone->get_ok("/landing-years/publications")->content_unlike(qr/$entry_bibtex_key/i);
#         $t_anyone->get_ok("/landing/publications")->content_unlike(qr/$entry_bibtex_key/i);
#         $t_anyone->get_ok("/r/b")->content_unlike(qr/$entry_bibtex_key/i);
#         $t_logged_in->get_ok("/publications/unhide/$entry_id");
#     }
# }
# # # todo: Opisy testow: ok($t->get_ok($_)->status_is(403) => "$_ no creds : 403") for @urls;



# note '============ Basic Tests ============';
# my $author_id = get_author_id_for_master($dbh, 'ExampleJohn');

# my @pages = (
#             "/read/authors-for-tag/$tag_id/$author_id",
#             "/read/tags-for-author/$author_id",
#             "/read/tags-for-team/$author_id",
#             "/publications/untagged/$author_id/21",
#             "/log?num=100",
#             "/cron",
#             "/cron/day",
#             "/cron/night",
#             "/cron/week",
#             "/cron/month",
#             "/authors/reassign",
#             "/authors/reassign_and_create",
#             "/settings/fix_months",
#             "/settings/fix_entry_types",
#             "/settings/clean_all",
#             "/settings/regenerate_all",
#             "/settings/regenerate_all_force",
#             "/manage_users",
#             "/profile/1", # assumin id 1 belongs always to admin and admin always exists
#             "/types",
#             "/types/add",
#             "/types/manage/article",
#             "/types/toggle/article",
#             "/types/toggle/article",
#             "/tagtypes",
#              );

# for my $page (@pages){
#     note "============ Testing page $page ============";
#     $t_logged_in->get_ok($page)->status_isnt(404)->status_isnt(500);
# }

# }

done_testing();

