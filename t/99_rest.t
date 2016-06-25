use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Controller::Core;


ok(1);
done_testing();
# DO NOT RUN THE CODE BELOW - it is not ready

# # ############################ PREPARATION
# my $t_anyone = Test::Mojo->new('BibSpace');
# my $t_logged_in = Test::Mojo->new('BibSpace');
# $t_logged_in->post_ok(
#     '/do_login' => { Accept => '*/*' },
#     form        => { user   => 'pub_admin', pass => 'asdf' }
# );

# my $dbh = $t_logged_in->app->db;

# # ############################ READY FOR TESTING


  
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






# done_testing();

