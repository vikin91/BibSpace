use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Data::Dumper;
use Array::Utils qw(:all);


my $t_anyone = Test::Mojo->new('BibSpace');
my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);
my $self = $t_logged_in->app;

my $dbh = $t_logged_in->app->db;


use BibSpace::Model::MEntry;
use BibSpace::Functions::FPublications;
use BibSpace::Controller::Core;

$dbh->do('DELETE FROM Entry;');


####################################################################
subtest 'MEntry; basics 1, new, static_all, populate_from_bib, save' => sub {

  # my $en = MEntry->new();
  my @entries = MEntry->static_all($dbh);
  my $num_entries = scalar(@entries);
  is($num_entries, 0, "Got 0 entries");

  #### adding some fixtures. TODO: this needs to be done automatically at the beginning of the test suite
  my $en3 = MEntry->new();
  $en3->{bib} = '@mastersthesis{aaa1,
    address = {World},
    author = {James Bond},
    month = {August},
    school = {University of Bond},
    title = {{Selected aspects of some methods}},
    year = {1999},
  }';
  $en3->populate_from_bib($dbh);
  $en3->save($dbh);

  my $en4 = MEntry->new();
  $en4->{bib} = '@mastersthesis{aaa2,
    address = {World},
    author = {James Bond},
    month = {March},
    school = {University of Bond},
    title = {{Selected aspects of some methods}},
    year = {1999},
  }';
  $en4->populate_from_bib($dbh);
  $en4->save($dbh);

  @entries = MEntry->static_all($dbh);
  $num_entries = scalar(@entries);
  ok($num_entries > 0, "Got more than 0 entries");
};

#### START fix months


#### single entry

####################################################################
subtest 'MEntry; basics 2, bibtex_has_field, get_bibtex_field_value, delete, update, insert' => sub {


  my $en2 = MEntry->new();
  $en2->{bib} = '@mastersthesis{zzz'.random_string(64).',
    address = {World},
    author = {James Bond},
    month = {August},
    school = {University of Bond},
    title = {{Selected aspects of some methods}},
    year = {1999},
  }';

  is($en2->bibtex_has_field('year'), 1, "MEntry has field year");
  isnt($en2->bibtex_has_field('journal'), 1, "MEntry hasn't field journal");

  is($en2->get_bibtex_field_value('year'), 1999, "MEntry year has value 1999");
  is($en2->get_bibtex_field_value('year'), '1999', "MEntry year has value 1999");
  isnt($en2->get_bibtex_field_value('year'), 2000, "MEntry year hasn't value 2000");
  isnt($en2->get_bibtex_field_value('year'), '2000', "MEntry year hasn't value 2000");


  isnt($en2->{month}, 8 , "Month field empty");

  $en2->fix_month();

  is($en2->{month}, 8, "Month field OK");
  is($en2->{sort_month}, 8, "Sort month field OK");

  is($en2->delete($dbh), '0E0', "Deleting not-existing entry= cannot delete");

  is($en2->update($dbh), -1, "updating not existing entry");
  ok($en2->insert($dbh) > 1, "adding new entry");
  is($en2->update($dbh), 1, "updating existing entry");
  is($en2->delete($dbh), 1, "Deleting entry");

};

####################################################################
subtest 'MEntry; bibtex_has_field, fix_month' => sub {

  my $en2 = MEntry->new();
  $en2->{bib} = '@mastersthesis{zzz'.random_string(64).',
    address = {World},
    author = {James Bond},
    month = {August},
    school = {University of Bond},
    title = {{Selected aspects of some methods}},
    year = {1999},
  }';

  is($en2->bibtex_has_field('month'), 1 , "Month field exists");
  is($en2->bibtex_has_field('dummy'), 0 , "Month dummy does not exists");

  isnt($en2->{month}, 8 , "Month field empty");

  $en2->fix_month();

  is($en2->{month}, 8, "Month field OK");
  is($en2->{sort_month}, 8, "Sort month field OK");

  $en2->{bib} = '@misc{test, month = {January}}';
  $en2->fix_month();
  is($en2->{month}, 1, "Month field OK");
  $en2->{bib} = '@misc{test, month = {February}}';
  $en2->fix_month();
  is($en2->{month}, 2, "Month field OK");
  $en2->{bib} = '@misc{test, month = {March}}';
  $en2->fix_month();
  is($en2->{month}, 3, "Month field OK");
  $en2->{bib} = '@misc{test, month = {April}}';
  $en2->fix_month();
  is($en2->{month}, 4, "Month field OK");

  $en2->{bib} = '@misc{test, month = {May}}';
  $en2->fix_month();
  is($en2->{month}, 5, "Month field OK");

  $en2->{bib} = '@misc{test, month = {June}}';
  $en2->fix_month();
  is($en2->{month}, 6, "Month field OK");

  $en2->{bib} = '@misc{test, month = {July}}';
  $en2->fix_month();
  is($en2->{month}, 7, "Month field OK");

  $en2->{bib} = '@misc{test, month = {August}}';
  $en2->fix_month();
  is($en2->{month}, 8, "Month field OK");

  $en2->{bib} = '@misc{test, month = {September}}';
  $en2->fix_month();
  is($en2->{month}, 9, "Month field OK");

  $en2->{bib} = '@misc{test, month = {October}}';
  $en2->fix_month();
  is($en2->{month}, 10, "Month field OK");

  $en2->{bib} = '@misc{test, month = {November}}';
  $en2->fix_month();
  is($en2->{month}, 11, "Month field OK");

  $en2->{bib} = '@misc{test, month = {December}}';
  $en2->fix_month();
  is($en2->{month}, 12, "Month field OK");
};

####################################################################
subtest 'MEntry; process_tags manual' => sub {

  $dbh->do('DELETE FROM Tag;');
  # testing tags
  my $en2 = MEntry->new();
  $en2->{bib} = '@mastersthesis{zzz'.random_string(64).',
    address = {World},
    author = {James Bond},
    month = {August},
    school = {University of Bond},
    title = {{Selected aspects of some methods}},
    year = {1999},
  }';
  $en2->{bib} = '@misc{test, tags = {aa;bb}}';
  is($en2->process_tags($dbh), 2, "Adding 2 tags");
  $en2->{bib} = '@misc{test, tags = {}}';
  is($en2->process_tags($dbh), 0, "Adding 0 tags");
  $en2->{bib} = '@misc{test, tags = {aa;bb;cc}}';
  is($en2->process_tags($dbh), 1, "Adding 1 extra tag");
};


####################################################################
subtest 'MEntry; process_tags auto' => sub {
  # test adding many tags
  my $en2 = MEntry->new();
  $en2->{bib} = '@mastersthesis{zzz'.random_string(64).',
    address = {World},
    author = {James Bond},
    month = {August},
    school = {University of Bond},
    title = {{Selected aspects of some methods}},
    year = {1999},
  }';
  # map { int rand(100) } ( 1..30 ) -- array of length 30 filled with ints between 0 and 99
  foreach my $num_tags (map { int rand(100) } ( 1..30 )){
    $dbh->do('DELETE FROM Tag;');
    my $tstr = '@misc{test, tags = {';
    $tstr .= join ';' => map random_string(25), 1 .. $num_tags;
    $tstr .= '}}';  
    $en2->{bib} = $tstr;

    is($en2->process_tags($dbh), $num_tags, "Adding $num_tags tags"); # we assume, that some may repeat
  }
};
####################################################################
subtest 'MEntry; process_authors' => sub {
# test adding many authors
  my $en2 = MEntry->new();
  $en2->{bib} = '@mastersthesis{zzz'.random_string(64).',
    address = {World},
    author = {James Bond},
    month = {August},
    school = {University of Bond},
    title = {{Selected aspects of some methods}},
    year = {1999},
  }';

  foreach my $num_authors (map { int rand(100) } ( 1..30 )){
    $dbh->do('DELETE FROM Author;');
    my $tstr = '@misc{test, author = {';
    $tstr .= join ' and ' => map( (random_string(10)." ".random_string(10)), 1 .. $num_authors);
    $tstr .= '}}';  
    $en2->{bib} = $tstr;

    is($en2->process_authors($dbh), $num_authors , "Adding $num_authors authors");
  }
};



####################################################################
subtest 'MEntry; hide, unhide' => sub {
  my $random1 = random_string(64);

  my $en5 = MEntry->new();
  $en5->{bib} = '@mastersthesis{zzz'.$random1.',
    address = {World},
    author = {James Bond},
    month = {August},
    school = {'.$random1.'},
    title = {{Selected aspects of some methods}},
    year = {1999},
  }';

  is($en5->get_bibtex_field_value('school'), $random1, "MEntry school has value $random1 (random1)");
  $en5->populate_from_bib($dbh);
  $en5->save($dbh);
  $en5->unhide($dbh);

  $t_anyone = Test::Mojo->new('BibSpace');
  $t_anyone->get_ok('/r/b')
      ->status_isnt(404)
      ->status_isnt(500)
      ->content_like(qr/$random1/i);

  $en5->hide($dbh);
  $t_anyone->get_ok('/r/b')
      ->status_isnt(404)
      ->status_isnt(500)
      ->content_unlike(qr/$random1/i);

  $en5->toggle_hide($dbh);  # unhiding
  $t_anyone->get_ok('/r/b')
      ->status_isnt(404)
      ->status_isnt(500)
      ->content_like(qr/$random1/i);

  $en5->toggle_hide($dbh);  # hiding again
  $t_anyone->get_ok('/r/b')
      ->status_isnt(404)
      ->status_isnt(500)
      ->content_unlike(qr/$random1/i);
  $en5->unhide($dbh);  # hiding again
};
####################################################################
subtest 'MEntry; is_paper, is_talk, make_paper, make_talk' => sub {
  # get new random
  my $random1 = random_string(32);
  my $random2 = random_string(32);

  my $en5 = MEntry->new();
  $en5->{bib} = '@mastersthesis{zzz'.$random1.',
    address = {World},
    author = {James Bond},
    month = {August},
    school = {'.$random2.'},
    title = {{Selected aspects of some methods}},
    year = {1999},
  }';
  is($en5->get_bibtex_field_value('school'), $random2, "MEntry school has value $random2 (random2)");
  $en5->populate_from_bib($dbh);
  $en5->save($dbh);

  $en5->make_paper($dbh);
  is($en5->is_paper(), 1);
  is($en5->is_talk(), 0);
  $t_anyone->get_ok('/r/b?entry_type=talk')
      ->status_isnt(404)
      ->status_isnt(500)
      ->content_unlike(qr/$random2/i);
  $t_anyone->get_ok('/r/b?entry_type=paper')
      ->status_isnt(404)
      ->status_isnt(500)
      ->content_like(qr/$random2/i);

  $en5->make_talk($dbh);
  is($en5->is_talk(), 1);
  is($en5->is_paper(), 0);

  $t_anyone->get_ok('/r/b?entry_type=talk')
      ->status_isnt(404)
      ->status_isnt(500)
      ->content_like(qr/$random2/i);
  $t_anyone->get_ok('/r/b?entry_type=paper')
      ->status_isnt(404)
      ->status_isnt(500)
      ->content_unlike(qr/$random2/i);
};


####################################################################
subtest 'MEntry; static_get_from_id_array' => sub {

  my @en6 = MEntry->static_get_from_id_array($dbh, [], 1);
  is(scalar @en6, 0, "MEntry->static_get_from_id_array: Empty input array returns 0?");

  my @all_entries = MEntry->static_all($dbh);
  my $some_entry = shift @all_entries;
  @en6 = MEntry->static_get_from_id_array($dbh, [$some_entry->{id}], 1);
  is(scalar @en6, 1, "MEntry->static_get_from_id_array: input array with one object (entry id: ".$some_entry->{id}.") returns 1?");
};
####################################################################
###### testing filter function - this may be difficult
subtest 'MEntry; static_get_filter' => sub {
  ## todo: write more cases for static_get_filter

  my @all_entries = MEntry->static_all($dbh);

  my $test_master_id = undef;
  my $test_year = undef;
  my $test_bibtex_type = undef;
  my $test_entry_type = undef;
  my $test_tagid = undef;
  my $test_teamid = undef;
  my $test_visible = undef;
  my $test_permalink = undef;
  my $test_hidden = undef;
  my @en_objs = MEntry->static_get_filter($dbh, 
                                           $test_master_id, 
                                           $test_year, 
                                           $test_bibtex_type, 
                                           $test_entry_type, 
                                           $test_tagid, 
                                           $test_teamid, 
                                           $test_visible, 
                                           $test_permalink, 
                                           $test_hidden);
  @all_entries = MEntry->static_all($dbh);
  is(scalar @all_entries, scalar @en_objs, "MEntry->static_get_filter: no filter returns all?");
};


####################################################################
subtest 'MEntry; hasTag, process_tags' => sub {
  my $random1 = random_string(16);
  my $random2 = random_string(8);
  my $random3 = random_string(8);
  my $random4 = random_string(8);

  my $en7 = MEntry->new();
  $en7->{bib} = '@mastersthesis{zzz'.$random1.',
    address = {World},
    author = {James Bond},
    month = {August},
    school = {'.$random2.'},
    title = {{Selected aspects of some methods}},
    tags = {'.$random3.','.$random4.'},
    year = {1999},
  }';
  $en7->populate_from_bib($dbh);
  $en7->save($dbh);
  is($en7->hasTag($dbh, $random3), 0, "Entry has no tag $random3 yet");
  is($en7->hasTag($dbh, $random4), 0, "Entry has no tag $random4 yet");
  is($en7->process_tags($dbh), 2, "Should add 2 tags");
  is($en7->hasTag($dbh, $random3), 1, "Entry has no tag $random3 yet");
  is($en7->hasTag($dbh, $random4), 1, "Entry has no tag $random4 yet");
};
####################################################################
subtest 'MEntry; is_talk_in_DB, is_talk_in_tag, fix_entry_type_based_on_tag, make_paper, make_talk' => sub {
  my $random1 = random_string(16);
  my $random2 = random_string(8);
  my $random3 = random_string(8);
  my $random4 = random_string(8);

  my $en7 = MEntry->new();
  $en7->{bib} = '@mastersthesis{zzz'.$random1.',
    address = {World},
    author = {James Bond},
    month = {August},
    school = {'.$random2.'},
    title = {{Selected aspects of some methods}},
    tags = {'.$random3.';'.$random4.'; talk},
    year = {1999},
  }';
  $en7->populate_from_bib($dbh);
  $en7->save($dbh);
  is($en7->is_talk_in_DB($dbh), 0);
  $en7->{entry_type} = 'talk';
  is($en7->is_talk_in_DB($dbh), 0);
  is($en7->is_talk_in_tag($dbh), 0);
  $en7->{entry_type} = 'paper';
  $en7->make_talk($dbh);
  is($en7->is_talk_in_DB($dbh), 1);
  is($en7->is_talk_in_tag($dbh), 0);
  $en7->make_paper($dbh);
  is($en7->is_talk_in_DB($dbh), 0);
  is($en7->is_talk_in_tag($dbh), 0);
  is($en7->fix_entry_type_based_on_tag($dbh), 0, "Entry fix_entry_type_based_on_tag");
  is($en7->is_talk_in_DB($dbh), 0);
  is($en7->is_talk_in_tag($dbh), 0);

  # reset
  $en7->populate_from_bib($dbh);
  $en7->make_paper($dbh);
  $en7->save($dbh);
  is($en7->is_talk_in_DB($dbh), 0);
  is($en7->is_talk_in_tag($dbh), 0);

  is($en7->process_tags($dbh), 3, "Should add 3 tags");
  is($en7->is_talk_in_DB($dbh), 0);
  is($en7->is_talk_in_tag($dbh), 1);

  is($en7->fix_entry_type_based_on_tag($dbh), 1, "Entry fix_entry_type_based_on_tag");
  $en7->save($dbh);
  is($en7->is_talk_in_DB($dbh), 1);
  is($en7->is_talk_in_tag($dbh), 1);
  $en7->make_paper($dbh);
  is($en7->is_talk_in_DB($dbh), 0);
  is($en7->is_talk_in_tag($dbh), 1); # tag remains!
  is($en7->is_talk($dbh), 0); # tag remains, but this has no meaning
  $en7->make_talk($dbh);
  is($en7->is_talk_in_DB($dbh), 1);
  is($en7->is_talk_in_tag($dbh), 1);
  $en7->make_paper($dbh);
};

####################################################################
subtest 'MEntry; bibtex_has_field, remove_bibtex_fields' => sub {

  my $en2 = MEntry->new();
  $en2->{bib} = '@mastersthesis{ma_199A,
    address = {World},
    author = {James Bond},
    month = {August},
    school = {University of Bond},
    title = {{Selected aspects of some methods}},
    year = {1999},
  }';


  ok($en2->bibtex_has_field('year'), "MEntry has field year");
  ok(!$en2->bibtex_has_field('journal'), "MEntry hasn't field");
  ok($en2->bibtex_has_field('school'), "MEntry has field school");

  is($en2->remove_bibtex_fields($dbh, ['school']), 1, "Remove field school");
  ok(!$en2->bibtex_has_field('school'), "MEntry hasn't field");

  is($en2->remove_bibtex_fields($dbh, ['address', 'author']), 2, "Remove 2 fields");
  ok(!$en2->bibtex_has_field('address'), "MEntry hasn't field");
  ok(!$en2->bibtex_has_field('author'), "MEntry hasn't field");

};
####################################################################
subtest 'MEntry; add_tags, tags, remove_tag_by_name, remove_tag_by_id ' => sub {
  my $entry = MEntry->new();
  $entry->{bib} = '@mastersthesis{ma_'.random_string(25).',
    address = {World},
    author = {James Bond},
    month = {August},
    school = {University of Bond},
    title = {{Selected aspects of some methods}},
    year = {1999},
  }';
  $entry->populate_from_bib($dbh);
  $entry->make_paper($dbh);
  $entry->save($dbh);
  
  
  my @ints_arr = map { 5+int rand(40) } ( 1..20 ); # 20 items from range: [5 - 40+5)
  

  foreach my $num_tags (@ints_arr){
    $dbh->do('DELETE FROM Tag;');
    $dbh->do('DELETE FROM Entry_to_Tag WHERE entry_id='.$entry->{id}.';');
    
    my @tags_to_add_mix = map { random_string(25) } (1 .. $num_tags);
    my @tags_to_add = unique(@tags_to_add_mix, @tags_to_add_mix);

    is($entry->add_tags($dbh, \@tags_to_add), $num_tags, "Adding $num_tags tags");

    my @got_tags = $entry->tags($dbh);
    my @got_tag_names = map {$_->{name}} @got_tags;
    is(scalar @got_tag_names, $num_tags, "Added correctly");

    is(array_diff(@got_tag_names, @tags_to_add), 0, "Arrays identical");

    # my $random_index = int rand($num_tags - 1);
    my $some_tag_name = shift @got_tag_names; #$got_tag_names[$random_index];
    is($entry->remove_tag_by_name($dbh, $some_tag_name), 1, "MEntry remove Tag by name: $some_tag_name ");

    @got_tags = $entry->tags($dbh);
    @got_tag_names = map {$_->{name}} @got_tags;
    is(array_diff(@got_tag_names, @tags_to_add), 1, "Arrays identical but 1");

    my $some_tag_name2 = shift @got_tag_names;
    my $some_tag_name3 = shift @got_tag_names;
    my $some_tag_name4 = shift @got_tag_names;
    is($entry->remove_tag_by_name($dbh, $some_tag_name2), 1, "MEntry remove Tag by name: $some_tag_name2 ");
    is($entry->remove_tag_by_name($dbh, $some_tag_name3), 1, "MEntry remove Tag by name: $some_tag_name3 ");
    is($entry->remove_tag_by_name($dbh, $some_tag_name4), 1, "MEntry remove Tag by name: $some_tag_name4 ");

    @got_tags = $entry->tags($dbh);
    @got_tag_names = map {$_->{name}} @got_tags;
    
    is(array_diff(@got_tag_names, @tags_to_add), 4, "Arrays identical but 4");
  }

  is($entry->remove_tag_by_name($dbh, "zzz"), 0, "MEntry remove Tag by name zzz");

  is($entry->remove_tag_by_id($dbh, -1), 0, "MEntry remove Tag by id -1");
  my @some_tag_objs = $entry->tags($dbh);
  my $some_tag_obj = shift @some_tag_objs;
  is($entry->remove_tag_by_id($dbh, $some_tag_obj->{id}), 1, "MEntry remove Tag by id $some_tag_obj->{id}");
};



####################################################################
subtest 'MEntry: regenerate' => sub {
  
  my $entry = MEntry->new();
  $entry->{bib} = '@mastersthesis{ma_'.random_string(25).',
    address = {World},
    author = {James Bond},
    month = {August},
    school = {University of Bond},
    title = {{Selected aspects of some methods}},
    year = {1999},
  }';
  $entry->populate_from_bib($dbh);
  $entry->make_paper($dbh);
  $entry->save($dbh);

  is($entry->{need_html_regen}, 1, "need_html_regen 1");
  $entry->regenerate_html($dbh);
  is($entry->{need_html_regen}, 0, "need_html_regen 0");
};



### to test:
# sort_by_year_month_modified_time



done_testing();
