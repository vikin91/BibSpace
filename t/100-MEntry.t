use Mojo::Base -strict;
use Test::More 0.96;
use Test::Mojo;
use Test::Exception;
use Data::Dumper;
use Array::Utils qw(:all);

# my $t_anyone    = Test::Mojo->new('BibSpace');
# my $t_logged_in = Test::Mojo->new('BibSpace');
# $t_logged_in->post_ok(
#     '/do_login' => { Accept => '*/*' },
#     form        => { user   => 'pub_admin', pass => 'asdf' }
# );
# my $self = $t_logged_in->app;

# my $dbh = $t_logged_in->app->db;


# use BibSpace::Functions::FPublications;
# use BibSpace::Controller::Core;


# $dbh->do('DELETE FROM Entry;');
# my $storage = StorageBase->get();
# $storage->entries_clear;

# ####################################################################
# subtest 'MEntry; basics 1, new, static_all, populate_from_bib, save' => sub {

#     # my $en = MEntry->new();
#     my @entries     = $storage->entries_all;
#     my $num_entries = scalar(@entries);
#     is( $num_entries, 0, "Got 0 entries" );

#     #### adding some fixtures. TODO: this needs to be done automatically at the beginning of the test suite
#     my $en3 = MEntry->new();
#     $en3->{bib} = '@mastersthesis{aaa1,
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {University of Bond},
#     title = {{Selected aspects of some methods}},
#     year = {1999},
#   }';
#     $en3->populate_from_bib($dbh);
#     $storage->entries_add($en3);
#     $en3->save($dbh);

#     my $en4 = MEntry->new();
#     $en4->{bib} = '@mastersthesis{aaa2,
#     address = {World},
#     author = {James Bond},
#     month = {March},
#     school = {University of Bond},
#     title = {{Selected aspects of some methods}},
#     year = {1999},
#   }';
#     $en4->populate_from_bib($dbh);
#     $storage->entries_add($en4);
#     $en4->save($dbh);

#     @entries     = $storage->entries_all;
#     ok( scalar(@entries) > 0, "Got more than 0 entries" );
# };
# ####################################################################
# subtest 'MEntry; ' => sub {

#     my @entries     = $storage->entries_all;
#     ok( scalar(@entries) > 0, "Got more than 0 entries" );

#     my $random_entry = $entries[ rand @entries ];

#     # is( MEntry->static_get( $dbh, $random_entry->{id} )->{id},
#     #     $random_entry->{id}, "static_get by id" );
#     # is( MEntry->static_get( $dbh, $random_entry->{id} )->{bib},
#     #     $random_entry->{bib}, "static_get by id" );

#     # is( MEntry->static_get_by_bibtex_key( $dbh, $random_entry->{bibtex_key} )->{bibtex_key},
#     #     $random_entry->{bibtex_key},
#     #     "static_get_by_bibtex_key by key"
#     # );
#     # is( MEntry->static_get_by_bibtex_key( $dbh, $random_entry->{bibtex_key} )->{id},
#     #     $random_entry->{id},
#     #     "static_get_by_bibtex_key by key"
#     # );

# };
# #### START fix months

# #### single entry

# ####################################################################
# subtest
#     'MEntry; basics 2, bibtex_has_field, get_bibtex_field_value, delete, update, insert'
#     => sub {

#     my $en2 = MEntry->new();
#     $en2->{bib} = '@mastersthesis{zzz' . random_string(64) . ',
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {University of Bond},
#     title = {{Selected aspects of some methods}},
#     year = {1999},
#   }';

#     is( $en2->bibtex_has_field('year'), 1, "MEntry has field year" );
#     isnt( $en2->bibtex_has_field('journal'),
#         1, "MEntry hasn't field journal" );

#     is( $en2->get_bibtex_field_value('year'),
#         1999, "MEntry year has value 1999" );
#     is( $en2->get_bibtex_field_value('year'),
#         '1999', "MEntry year has value 1999" );
#     isnt( $en2->get_bibtex_field_value('year'),
#         2000, "MEntry year hasn't value 2000" );
#     isnt( $en2->get_bibtex_field_value('year'),
#         '2000', "MEntry year hasn't value 2000" );

#     isnt( $en2->{month}, 8, "Month field empty" );

#     $en2->fix_month();

#     is( $en2->{month},      8, "Month field OK" );
#     is( $en2->{sort_month}, 8, "Sort month field OK" );

#     is( $en2->delete($dbh), '0E0',
#         "Deleting not-existing entry= cannot delete" );

#     is( $en2->update($dbh), '0E0', "updating not existing entry" );
#     ok( $en2->insert($dbh) > 1, "adding new entry" );
#     is( $en2->update($dbh), 1, "updating existing entry" );
#     is( $en2->delete($dbh), 1, "Deleting entry" );

#     };

# ####################################################################
# subtest 'MEntry; bibtex_has_field, fix_month' => sub {

#     my $en2 = MEntry->new();
#     $en2->{bib} = '@mastersthesis{zzz' . random_string(64) . ',
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {University of Bond},
#     title = {{Selected aspects of some methods}},
#     year = {1999},
#   }';

#     is( $en2->bibtex_has_field('month'), 1, "Month field exists" );
#     is( $en2->bibtex_has_field('dummy'), 0, "Month dummy does not exists" );

#     isnt( $en2->{month}, 8, "Month field empty" );

#     $en2->fix_month();

#     is( $en2->{month},      8, "Month field OK" );
#     is( $en2->{sort_month}, 8, "Sort month field OK" );

#     $en2->{bib} = '@misc{test, month = {January}}';
#     $en2->fix_month();
#     is( $en2->{month}, 1, "Month field OK" );
#     $en2->{bib} = '@misc{test, month = {February}}';
#     $en2->fix_month();
#     is( $en2->{month}, 2, "Month field OK" );
#     $en2->{bib} = '@misc{test, month = {March}}';
#     $en2->fix_month();
#     is( $en2->{month}, 3, "Month field OK" );
#     $en2->{bib} = '@misc{test, month = {April}}';
#     $en2->fix_month();
#     is( $en2->{month}, 4, "Month field OK" );

#     $en2->{bib} = '@misc{test, month = {May}}';
#     $en2->fix_month();
#     is( $en2->{month}, 5, "Month field OK" );

#     $en2->{bib} = '@misc{test, month = {June}}';
#     $en2->fix_month();
#     is( $en2->{month}, 6, "Month field OK" );

#     $en2->{bib} = '@misc{test, month = {July}}';
#     $en2->fix_month();
#     is( $en2->{month}, 7, "Month field OK" );

#     $en2->{bib} = '@misc{test, month = {August}}';
#     $en2->fix_month();
#     is( $en2->{month}, 8, "Month field OK" );

#     $en2->{bib} = '@misc{test, month = {September}}';
#     $en2->fix_month();
#     is( $en2->{month}, 9, "Month field OK" );

#     $en2->{bib} = '@misc{test, month = {October}}';
#     $en2->fix_month();
#     is( $en2->{month}, 10, "Month field OK" );

#     $en2->{bib} = '@misc{test, month = {November}}';
#     $en2->fix_month();
#     is( $en2->{month}, 11, "Month field OK" );

#     $en2->{bib} = '@misc{test, month = {December}}';
#     $en2->fix_month();
#     is( $en2->{month}, 12, "Month field OK" );
# };

# ####################################################################
# subtest 'MEntry; add_entry_tags manual' => sub {

#     $dbh->do('DELETE FROM Tag;');

#     # testing tags
#     my $en2 = MEntry->new();
#     $en2->{bib} = '@mastersthesis{zzz' . random_string(64) . ',
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {University of Bond},
#     title = {{Selected aspects of some methods}},
#     year = {1999},
#   }';
#     $en2->{bib} = '@misc{testA1, tags = {aa;bb}}';
#     $en2->populate_from_bib();
#     $en2->save($dbh);
#     is( $storage->add_entry_tags($en2), 2, "Adding 2 tags" );

#     $en2->{bib} = '@misc{testA2, tags = {}}';
#     $en2->populate_from_bib();
#     $en2->save($dbh);
#     is( $storage->add_entry_tags($en2), 0, "Adding 0 tags" );


#     $en2->{bib} = '@misc{testA3, tags = {aa;bb;cc}}';
#     $en2->populate_from_bib();
#     $en2->save($dbh);
#     is( $storage->add_entry_tags($en2), 1, "Adding 1 extra tag" );
# };

# ####################################################################
# subtest 'MEntry; add_entry_tags auto' => sub {

#     # test adding many tags
#     my $en2 = MEntry->new();
#     $en2->{bib} = '@mastersthesis{zzz' . random_string(64) . ',
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {University of Bond},
#     title = {{Selected aspects of some methods}},
#     year = {1999},
#   }';

# # map { int rand(100) } ( 1..30 ) -- array of length 30 filled with ints between 0 and 99
#     foreach my $num_tags ( map { int rand(100) } ( 1 .. 10 ) ) {
#         $dbh->do('DELETE FROM Tag;');

#         my $tstr = '@misc{test'.random_string(10).', tags = {';
#         $tstr .= join ';' => map random_string(25), 1 .. $num_tags;
#         $tstr .= '}}';
#         $en2->{bib} = $tstr;
#         $en2->populate_from_bib();
#         $en2->save($dbh);

#         is( $storage->add_entry_tags($en2), $num_tags, "Adding $num_tags tags" );
#     }
# };
# ####################################################################
# subtest 'MEntry; process_authors' => sub {

#     # test adding many authors
#     my $en2 = MEntry->new();
#     $en2->{bib} = '@mastersthesis{zzz' . random_string(64) . ',
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {University of Bond},
#     title = {{Selected aspects of some methods}},
#     year = {1999},
#   }';

#     foreach my $num_authors ( map { int rand(40) } ( 1 .. 10 ) ) {
#         $dbh->do('DELETE FROM Author;');
#         my $tstr = '@misc{test, author = {';
#         $tstr
#             .= join ' and ' =>
#             map( ( random_string(10) . " " . random_string(10) ),
#             1 .. $num_authors );
#         $tstr .= '}}';
#         $en2->{bib} = $tstr;
        
#         $en2->populate_from_bib();
#         $en2->save($dbh);

#         my $num_authors_created = $storage->add_entry_authors( $en2, 1 );
#         is( $num_authors_created, $num_authors, "Adding $num_authors authors" );
#     }
# };

# ####################################################################
# subtest 'MEntry; hide, unhide' => sub {
#     my $random1 = random_string(64);


#     my $en5 = MEntry->new();
#     $en5->{bib} = '@mastersthesis{zzz' . $random1 . ',
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {' . $random1 . '},
#     title = {{Selected aspects of some methods}},
#     year = {1999},
#   }';

#     is( $en5->get_bibtex_field_value('school'),
#         $random1, "MEntry school has value $random1 (random1)" );
#     $en5->populate_from_bib($dbh);
#     $storage->entries_add($en5);
#     $en5->save($dbh);
#     $en5->unhide();

#     print $en5->toString;

#     # $t_anyone = Test::Mojo->new('BibSpace');
#     $t_anyone->get_ok('/r/b')->status_isnt(404)->status_isnt(500)
#         ->content_like(qr/$random1/i);

#     $en5->hide();
#     $en5->save($dbh);
#     $t_anyone->get_ok('/r/b')->status_isnt(404)->status_isnt(500)
#         ->content_unlike(qr/$random1/i);

#     $en5->toggle_hide($dbh);    # unhiding
#     $t_anyone->get_ok('/r/b')->status_isnt(404)->status_isnt(500)
#         ->content_like(qr/$random1/i);

#     $en5->toggle_hide($dbh);    # hiding again
#     $t_anyone->get_ok('/r/b')->status_isnt(404)->status_isnt(500)
#         ->content_unlike(qr/$random1/i);
#     $en5->unhide($dbh);         # hiding again
# };
# ####################################################################
# subtest 'MEntry; is_paper, is_talk, make_paper, make_talk' => sub {

#     # get new random
#     my $random1 = random_string(32);
#     my $random2 = random_string(32);


    

#     my $en5 = MEntry->new();
#     $en5->{bib} = '@mastersthesis{zzz' . $random1 . ',
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {' . $random2 . '},
#     title = {{Selected aspects of some methods}},
#     year = {1999},
#   }';
#     is( $en5->get_bibtex_field_value('school'),
#         $random2, "MEntry school has value $random2 (random2)" );
#     $en5->populate_from_bib();
#     $storage->entries_add($en5);
#     $en5->save($dbh);

#     $en5->make_paper();
#     $en5->save($dbh);
#     is( $en5->is_paper(), 1 );
#     is( $en5->is_talk(),  0 );
#     $t_anyone->get_ok('/r/b?entry_type=talk')->status_isnt(404)
#         ->status_isnt(500)->content_unlike(qr/$random2/i);
#     $t_anyone->get_ok('/r/b?entry_type=paper')->status_isnt(404)
#         ->status_isnt(500)->content_like(qr/$random2/i);

#     $en5->make_talk();
#     $en5->save($dbh);
#     is( $en5->is_talk(),  1 );
#     is( $en5->is_paper(), 0 );

#     $t_anyone->get_ok('/r/b?entry_type=talk')->status_isnt(404)
#         ->status_isnt(500)->content_like(qr/$random2/i);
#     $t_anyone->get_ok('/r/b?entry_type=paper')->status_isnt(404)
#         ->status_isnt(500)->content_unlike(qr/$random2/i);
# };

# ####################################################################
# subtest 'MEntry; static_get_from_id_array' => sub {

#     my $e = MEntry->new(bib => 
#     '@misc{zzz' . random_string(12) . ',
#         author = {James Bond},
#         month = {August},
#         title = {{Selected aspects of some methods}},
#         year = {2019},
#     }' );
#     ok( $e->save($dbh) );
#     $e = MEntry->new(bib => 
#     '@misc{zzz' . random_string(12) . ',
#         author = {James Bond},
#         month = {August},
#         title = {{Selected aspects of some methods}},
#         year = {2000},
#     }' );
#     ok( $e->save($dbh) );

#     $e = MEntry->new(bib => 
#     '@misc{zzz' . random_string(12) . ',
#         author = {James Bond},
#         month = {August},
#         title = {{Selected aspects of some methods}},
#         year = {1990},
#     }' );
#     ok( $e->save($dbh) );

#     $e = MEntry->new(bib => 
#     '@misc{zzz' . random_string(12) . ',
#         author = {James Bond},
#         month = {August},
#         title = {{Selected aspects of some methods}},
#         year = {3000},
#     }' );
#     ok( $e->save($dbh) );

#     my @en6 = MEntry->static_get_from_id_array( $dbh, [], 1 );
#     is( scalar @en6, 0,
#         "MEntry->static_get_from_id_array: Empty input array returns 0?" );

#     # my @all_entries = $storage->entries_all;
#     # my $some_entry  = shift @all_entries;
#     # @en6 = MEntry->static_get_from_id_array( $dbh, [ $some_entry->{id} ], 1 );
#     # is( scalar @en6,
#     #     1,
#     #     "MEntry->static_get_from_id_array: input array with one object (entry id: "
#     #         . $some_entry->{id}
#     #         . ") returns 1?"
#     # );

#     # my @all_entry_ids = map { $_->{id} } $storage->entries_all;
#     # @en6 = MEntry->static_get_from_id_array( $dbh, \@all_entry_ids, 1 );
#     # is( scalar @en6,
#     #     scalar @all_entry_ids,
#     #     "MEntry->static_get_from_id_array: getting all ordered"
#     # );
#     # my $str1 = join(' ', map {$_->{id}} @en6 );
#     # my $str2 = join(' ', @all_entry_ids); 
#     # is( $str1,
#     #     $str2,
#     #     "static_get_from_id_array: is ordered ?"
#     # );
    
#     # @en6 = MEntry->static_get_from_id_array( $dbh, \@all_entry_ids, 0 );
#     # $str1 = join(' ', map {$_->{id}} @en6 );
#     # $str2 = join(' ', @all_entry_ids); 
#     # isnt( $str1,
#     #     $str2,
#     #     "static_get_from_id_array: is unordered ?"
#     # );
# };
# ####################################################################
# ###### testing filter function - this may be difficult
# subtest 'MEntry; static_get_filter' => sub {
#     ## todo: write more cases for static_get_filter

#     my $test_master_id   = undef;
#     my $test_year        = undef;
#     my $test_bibtex_type = undef;
#     my $test_entry_type  = undef;
#     my $test_tagid       = undef;
#     my $test_teamid      = undef;
#     my $test_visible     = undef;
#     my $test_permalink   = undef;
#     my $test_hidden      = undef;

#     my @en_objs          = MEntry->static_get_filter(
#         $dbh,              $test_master_id,  $test_year,
#         $test_bibtex_type, $test_entry_type, $test_tagid,
#         $test_teamid,      $test_visible,    $test_permalink,
#         $test_hidden
#     );



#     my @all_entries = MEntry->static_all($dbh);


#     is( scalar @all_entries,
#         scalar @en_objs,
#         "MEntry->static_get_filter: no filter returns all?"
#     );

# };

# ####################################################################
# subtest 'MEntry; has_tag_named, add_entry_tags' => sub {
#     my $random1 = random_string(16);
#     my $random2 = random_string(8);
#     my $random3 = random_string(8);
#     my $random4 = random_string(8);

#     my $en7 = MEntry->new();
#     $en7->{bib} = '@mastersthesis{zzz' . $random1 . ',
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {' . $random2 . '},
#     title = {{Selected aspects of some methods}},
#     tags = {' . $random3 . ',' . $random4 . '},
#     year = {1999},
#   }';
#     $en7->populate_from_bib($dbh);
#     $en7->save($dbh);
#     is( $en7->has_tag_named( $random3 ), 0, "Entry has no tag $random3 yet" );
#     is( $en7->has_tag_named( $random4 ), 0, "Entry has no tag $random4 yet" );
#     is( $storage->add_entry_tags($en7), 2, "Should add 2 tags" );
#     is( $en7->has_tag_named( $random3 ), 1, "Entry has no tag $random3 yet" );
#     is( $en7->has_tag_named( $random4 ), 1, "Entry has no tag $random4 yet" );
# };
# ####################################################################
# subtest
#     'MEntry; is_talk_in_tag, make_paper, make_talk'
#     => sub {
#     my $random1 = random_string(16);
#     my $random2 = random_string(8);
#     my $random3 = random_string(8);
#     my $random4 = random_string(8);

#     my $en7 = MEntry->new();
#     $en7->{bib} = '@mastersthesis{zzz' . $random1 . ',
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {' . $random2 . '},
#     title = {{Selected aspects of some methods}},
#     tags = {' . $random3 . ';' . $random4 . '; talk},
#     year = {1999},
#   }';
#     $en7->populate_from_bib($dbh);
#     $en7->save($dbh);
#     $en7->{entry_type} = 'talk';
#     is( $en7->is_talk_in_tag($dbh), 0 );
#     $en7->{entry_type} = 'paper';
#     $en7->make_talk();
#     $en7->save($dbh);
#     is( $en7->is_talk_in_tag($dbh), 0 );
#     $en7->make_paper();
#     $en7->save($dbh);
#     is( $en7->is_talk_in_tag($dbh), 0 );

#     # reset
#     $en7->populate_from_bib();
#     $en7->make_paper();
#     $en7->save($dbh);
#     is( $en7->is_talk_in_tag($dbh), 0 );

#     is( $storage->add_entry_tags($en7), 3, "Should add 3 tags" );
#     is( $en7->is_talk_in_tag($dbh), 1 );
#     $en7->make_paper($dbh);
#     };

# ####################################################################
# subtest 'MEntry; bibtex_has_field, remove_bibtex_fields' => sub {

#     my $en2 = MEntry->new();
#     $en2->{bib} = '@mastersthesis{ma_199A,
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {University of Bond},
#     title = {{Selected aspects of some methods}},
#     year = {1999},
#   }';

#     ok( $en2->bibtex_has_field('year'),     "MEntry has field year" );
#     ok( !$en2->bibtex_has_field('journal'), "MEntry hasn't field" );
#     ok( $en2->bibtex_has_field('school'),   "MEntry has field school" );

#     is( $en2->remove_bibtex_fields( ['school'] ),
#         1, "Remove field school" );
#     ok( !$en2->bibtex_has_field('school'), "MEntry hasn't field" );

#     is( $en2->remove_bibtex_fields( [ 'address', 'author' ] ),
#         2, "Remove 2 fields" );
#     ok( !$en2->bibtex_has_field('address'), "MEntry hasn't field" );
#     ok( !$en2->bibtex_has_field('author'),  "MEntry hasn't field" );

# };
# ####################################################################
# subtest 'MEntry; add_tags, tags, remove_tag_by_name, remove_tag_by_id ' =>
#     sub {
#     my $entry = MEntry->new();
#     $entry->{bib} = '@mastersthesis{ma_' . random_string(25) . ',
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {University of Bond},
#     title = {{Selected aspects of some methods}},
#     year = {1999},
#   }';
#     $entry->populate_from_bib($dbh);
#     $entry->make_paper($dbh);
#     $entry->save($dbh);

#     my @ints_arr = map { 5 + int rand(40) }
#         ( 1 .. 2 );    # 20 items from range: [5 - 40+5)

#     foreach my $num_tags (@ints_arr) {
#         $dbh->do('DELETE FROM Tag;');
#         $dbh->do(
#             'DELETE FROM Entry_to_Tag WHERE entry_id=' . $entry->{id} . ';' );
#         $entry->tags_clear;

#         my @tags_to_add_mix = map { random_string(25) } ( 1 .. $num_tags );
#         my @tags_to_add = unique( @tags_to_add_mix, @tags_to_add_mix );

#         my @tag_objs_to_add = map {MTag->new(name=>$_)} @tags_to_add;

#         is( $entry->assign_tag( @tag_objs_to_add ),
#             $num_tags, "Adding $num_tags tags" );

#         my @got_tags = $entry->tags;#($dbh);
#         my @got_tag_names = map { $_->{name} } @got_tags;
        
#         is( scalar @got_tag_names, $num_tags, "Added correctly default tag type" );

#         is( array_diff( @got_tag_names, @tags_to_add ),
#             0, "Arrays identical" );

#         ###### tags type 2
#         my @tags_to_add_mix2 = map { random_string(25) } ( 1 .. $num_tags );
#         my @tags_to_add2 = unique( @tags_to_add_mix2, @tags_to_add_mix2 );
#         my @tag_objs_to_add2 = map {MTag->new(name=>$_, type=>2)} @tags_to_add2;

#         is( $entry->assign_tag( @tag_objs_to_add2 ),
#             $num_tags, "Adding $num_tags tags of type 2" );

#         my @got_tag_names2 = map { $_->{name} } $entry->tags(2);#($dbh, 2);
#         is( scalar @got_tag_names2, $num_tags, "Added correctly type 2" );

#         is( array_diff( @got_tag_names2, @tags_to_add2 ),
#             0, "Arrays identical" );

#         ###### end tags type 2
#         my @entry_tags = $entry->tags;#($dbh);

#         ok(scalar @entry_tags > 0, "there are some tags");

#         my $some_tag = shift @entry_tags;
#         is( $entry->remove_tag_by_name( $some_tag->{name} ),
#             1, "MEntry remove Tag by name: $some_tag->{name} " );

#         @entry_tags = $entry->tags(1);
#         @got_tag_names = map { $_->{name} } @entry_tags;
#         is( array_diff( @got_tag_names, @tags_to_add ),
#             1, "Arrays identical but 1" );

#         # print "GTN: " .Dumper \@got_tag_names;
#         # print "TTA: " .Dumper \@tags_to_add;

#         my $some_tag2 = shift @entry_tags;
#         my $some_tag3 = shift @entry_tags;
#         my $some_tag4 = shift @entry_tags;
#         is( $entry->remove_tag_by_name( $some_tag2->{name} ),
#             1, "MEntry remove Tag by name2: $some_tag2->{name} " );
#         is( $entry->remove_tag_by_name( $some_tag3->{name} ),
#             1, "MEntry remove Tag by name3: $some_tag3->{name} " );
#         is( $entry->remove_tag_by_name( $some_tag4->{name} ),
#             1, "MEntry remove Tag by name4: $some_tag4->{name} " );

#         @entry_tags = $entry->tags(1);
#         @got_tag_names = map { $_->{name} } @entry_tags;

#         is( array_diff( @got_tag_names, @tags_to_add ),
#             4, "Arrays identical but 4" );
#     }

#     is( $entry->remove_tag_by_name( "zzz" ),
#         0, "MEntry remove Tag by name zzz" );

#     my @some_tag_objs = $entry->tags;#($dbh);
#     my $some_tag_obj  = shift @some_tag_objs;
#     is( $entry->remove_tag_by_id( $some_tag_obj->{id} ),
#         1, "MEntry remove Tag by id $some_tag_obj->{id}" );
# };

# ####################################################################
# subtest 'MEntry: generate with bst' => sub {

#     plan 'skip_all' => "Cannot find BST file"
#         unless -e $self->app->bst;

#     my $entry = MEntry->new();
#     $entry->{bib} = '@mastersthesis{ma_' . random_string(25) . ',
#     address = {World},
#     author = {James Bond},
#     month = {August},
#     school = {University of Bond},
#     title = {{Selected aspects of some methods}},
#     year = {1999},
#   }';
#     $entry->populate_from_bib($dbh);
#     $entry->make_paper($dbh);
#     $entry->save($dbh);

#     is( $entry->{need_html_regen}, 1, "need_html_regen 1" );
#     $entry->regenerate_html( 0, './lib/descartes2.bst' );
#     unlike( $entry->{html}, qr/ERROR: BST/ );
#     is( $entry->{need_html_regen}, 0, "need_html_regen 0" );

#     $entry->regenerate_html( 1, 'id-doesnt-exist.bst' );
#     is( $entry->{need_html_regen}, 0, "need_html_regen 0" );
#     like( $entry->{html}, qr/ERROR: BST/ );

#     $entry->{bst_file} = 'aaa';
#     $entry->regenerate_html( 1 );
#     like( $entry->{html}, qr/ERROR: BST/ );

#     $entry->{bst_file} = './lib/descartes2.bst';
#     $entry->regenerate_html( 1 );
#     unlike( $entry->{html}, qr/ERROR: BST/ );
# };

# ####################################################################
# subtest 'MEntry; exceptions, teams, authors2 ' => sub {

#     plan 'skip_all' => "There are no teams to test exceptions"
#         if scalar MTeam->static_all($dbh) == 0;

#     my $storage = StorageBase->get();

#     my $auth = random_string(8) . ' ' . random_string(8);
#     my $edit = random_string(8) . ' ' . random_string(8);

#     my $e = MEntry->new();
#     $e->{bib} = '@incollection{ma_' . random_string(12) . ',
#         author = {' . $auth . '},
#         editor = {' . $edit . '},
#         month = {August},
#         title = {{Selected aspects of some methods}},
#         year = {1999},
#     }';
#     $e->{bst_file} = './lib/descartes2.bst';
#     $e->populate_from_bib($dbh);
#     $e->make_paper($dbh);
#     ok( $e->save($dbh) );

#     ### editor should be ignored here!!
    

#     my @teams     = MTeam->static_all($dbh);
#     my $some_team = shift @teams;

#     is( scalar $e->teams($dbh), 0, "new paper has no teams" );
#     is( scalar $e->exceptions(), 0, "new paper has no exceptions" );

#     is( scalar $e->authors(), 0, "new paper has 0 authors: " . join(' ', map {$_->{master}} $e->authors($dbh)) );
#     is( scalar $e->get_authors_from_bibtex(), 1, "created 1 authors" );
    
#     $storage->add_entry_authors( $e, 1 );

#     is( scalar $e->authors(), 1, "new paper has 1 authors: " . join(' ', map {$_->{master}} $e->authors($dbh)) );
#     is( scalar $e->author_names_from_bibtex($dbh), 1, "new paper has 1 authors" );

#     {
#         my @curr_authors = $e->authors;
#         my $a1 = shift @curr_authors;
#         $e->assign_author($a1);
#         $e->assign_author($a1);
#         is( scalar $e->authors(), 1, "Paper should have 1 author and has: " . join(' ', map {$_->{master}} $e->authors()) );
#     }
#     $storage->add_entry_authors($e);
#     # is( $e->postprocess_updated($dbh), 1, "postproces_updated returns 1" ); # only call
#     is( scalar $e->authors() , 1, "new paper has 1 authors: " . join(' ', map {$_->{master}} $e->authors()) );

#     {
#         my @curr_authors = $e->authors;
#         my $a1 = shift @curr_authors;
        
#         is( scalar $e->authors(), 1, "Paper should have 1 author");
#         is( $e->remove_author($a1), 1, "removed author");
#         is( scalar $e->authors(), 0, "the paper has 0 authors: " . join(' ', map {$_->{master}} $e->authors()) );
#     }

#     # dies_ok { $e->teams() } 'expecting to die';

#     say "Exceptions: " . join(' ', map {$_->{name}} $e->exceptions());
#     is( $e->assign_exception($some_team), 1, "assign exception. Current exceptions: " . join(' ', map {$_->{name}} $e->exceptions($dbh)) );
#     is( $e->assign_exception(undef), 0, "assign bad exception. Current exceptions: " . join(' ', map {$_->{name}} $e->exceptions($dbh)) );
#     is( scalar $e->exceptions(), 1, "the paper has 1 exception. Current exceptions: " . join(' ', map {$_->{name}} $e->exceptions($dbh)) );
#     is( $e->remove_exception($some_team), 1, "remove exception. Current exceptions: " . join(' ', map {$_->{name}} $e->exceptions($dbh)) );
#     is( scalar $e->exceptions(), 0, "the paper has 0 exceptions: " . join(' ', map {$_->{name}} $e->exceptions()) );

# };


ok(1);
done_testing();
