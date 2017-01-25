use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;


# use BibSpace::Controller::Core;
# use BibSpace::Controller::BackupFunctions;
# use BibSpace::Functions::FDB;

# use Data::Dumper;

# my $t_logged_in = Test::Mojo->new('BibSpace');
# $t_logged_in->post_ok(
#     '/do_login' => { Accept => '*/*' },
#     form        => { user   => 'pub_admin', pass => 'asdf' }
# );
# my $self       = $t_logged_in->app;
# my $dbh        = $t_logged_in->app->db;
# my $app_config = $t_logged_in->app->config;





# my $status = 0;
# $status
#     = do_restore_backup_from_file( $dbh, "./fixture/db.sql", $app_config );
# is( $status, 1, "preparing DB for test" );

# my $storage = StorageBase::get();

# ####################################################################
# subtest 'MAuthor teams experiments' => sub {
#     plan 'skip_all' => "Test contains hardocded data (fixture-specific). Skipping for safety!";

#     ok( $storage->authors_count > 0 , "There are some authors");
#     my $testAuthor = $storage->authors_find( sub { ($_->{uid} cmp 'KounevSamuel') == 0} );
#     ok( $testAuthor , "Found Samuel");
#     is( $testAuthor->teams_count, 2, "Samuel has 2 teams"); # = DESCARTES, SE_WUERZBURG

#     my $testTeam = $storage->teams_find( sub { ($_->{name} cmp 'PiotrPL') == 0} );
#     ok( $testTeam );
#     $testAuthor->add_to_team($testTeam);

#     is( scalar($testAuthor->teams), 3, "Samuel has 3 teams"); # = DESCARTES, SE_WUERZBURG

#     # hardocded!!!
#     my $samuelsEntry = $storage->entries_find( sub { $_->{id} == 1083} );
#     ok( $samuelsEntry , "Found Samuels Entry");

#     my $testAuthor2 = $samuelsEntry->authors_find( sub { ($_->{uid} cmp 'KounevSamuel') == 0} );
#     ok( $testAuthor2 , "Found Samuel2");
#     $testAuthor2->add_to_team($testTeam);
#     is( scalar($testAuthor2->teams), 3, "Samuel2 has 3 teams"); # = DESCARTES, SE_WUERZBURG
    
#     # ok( $testAuthor == $testAuthor2, "Objects are identical!");

# };

# ####################################################################
# subtest 'MAuthor basics' => sub {

#     $dbh->do('DELETE FROM Author;');
#     $storage->authors_clear;

#     # my $en = MAuthor->new();
#     my @authors   = $storage->authors_all;
#     my $num_teams = scalar(@authors);
#     is( $num_teams, 0, "Got 0 authors" );

#     my $t1 = MAuthor->new( uid => 'AnAuthor' );
#     ok( $storage->add($t1) );

#     $t1->save($dbh);
#     is( $t1->{master}, $t1->{uid}, "master equals uid" );
#     ok( $t1->{master_id} == $t1->{id}
#             or !defined $t1->{master_id},
#         "master_id equals id" );

#     @authors   = $storage->authors_all;
#     $num_teams = scalar(@authors);
#     is( $num_teams, 1, "Got 1 authors" );

#     my $some_author = shift @authors;
#     is( $some_author->delete($dbh),        1 );
#     is( $storage->deleteObj($some_author), 1 );

#     @authors = $storage->authors_all;
#     is( scalar(@authors), 0,
#         "Should get 0 authors, got: "
#             . join( ', ', map { $_->{uid} } @authors ) );
#     is( $some_author->{id}, undef );

#     foreach ( 1 .. 10 ) {
#         my $t2 = MAuthor->new( uid => random_string(8) );
#         $storage->add($t2);
#         $t2->save($dbh);
#     }

#     @authors   = $storage->authors_all;
#     $num_teams = scalar(@authors);
#     is( $num_teams, 10, "Got 10 authors" );
# };

# ####################################################################
# subtest 'MAuthor basics 2' => sub {

#     # test updating
#     my @authors       = $storage->authors_all;
#     my $random_author = $authors[ rand @authors ];
#     $random_author->{uid} .= "super";
#     is( $random_author->save($dbh), 1, "updated 1 author" );
#     $storage->add($random_author);

#     #test getting defined team by id
#     # my $the_same = MAuthor->static_get( $dbh, $random_author->{id} );
#     my $the_same
#         = $storage->authors_find( sub { $_->{id} == $random_author->{id} } );
#     is( $the_same->{id}, $random_author->{id}, "getter author for id" );

#     # test getter by name
#     $random_author = $authors[ rand @authors ];
#     $the_same      = $storage->authors_find(
#         sub { ( $_->{uid} cmp $random_author->{uid} ) == 0 } );

#     # $the_same = MAuthor->static_get_by_name( $dbh, $random_author->{uid} );
#     is( $the_same->{id}, $random_author->{id}, "getter author for name" );

#     $the_same = $storage->authors_find(
#         sub { ( $_->{master} cmp $random_author->{master} ) == 0 } );

# # $the_same = MAuthor->static_get_by_master( $dbh, $random_author->{master} );
#     is( $the_same->{id}, $random_author->{id}, "getter author for master" );

#     # test getter by name - name does not exist
#     is( MAuthor->static_get_by_name( $dbh, "doesnotexitsforsure" ),
#         undef, "getter by name not existing author" );
#     is( MAuthor->static_get_by_master( $dbh, "doesnotexitsforsure" ),
#         undef, "getter by master not existing author" );

#     #test saving bad team
#     my $bad_authoe = MAuthor->new();
#     $bad_authoe->{id} = undef;
#     is( $bad_authoe->save($dbh), -1, "saving bad author" );

#     $random_author = $authors[ rand @authors ];
#     $random_author->{id} = undef;
#     is( $random_author->update($dbh), -1, "updating with undef id" );

# };

# ####################################################################
# subtest 'MAuthor basics 3' => sub {

#     $dbh->do('DELETE FROM Author;');
#     $storage = StorageBase::load($dbh);
#     $storage->authors_clear;

#     # my $en = MAuthor->new();
#     my @authors = $storage->authors_all;
#     is( scalar @authors, 0, "Got 0 authors" );

#     my $t1 = MAuthor->new( uid => 'AnAuthor' );
#     $t1->save($dbh);

#     @authors = MAuthor->static_get_filter( $dbh, undef, 'A' );
#     is( scalar @authors, 1, "Got 1 authors" );
#     @authors = MAuthor->static_get_filter( $dbh, 1, 'A' );
#     is( scalar @authors, 0, "Got 0 authors" );
#     @authors = MAuthor->static_get_filter( $dbh, 0, 'A' );
#     is( scalar @authors, 1, "Got 1 authors" );

#     @authors = MAuthor->static_get_filter( $dbh, undef, 'A' );

#     my $random_author = $authors[ rand @authors ];

#     # default is invisible
#     is( $random_author->{display}, 0, "author invisible" );
#     $random_author->toggle_visibility($dbh);
#     is( $random_author->{display}, 1, "author visible" );
#     $random_author->toggle_visibility($dbh);
#     is( $random_author->{display}, 0, "author invisible" );

#     is( $random_author->delete($dbh), 1, "author deleted" );
#     @authors = $storage->authors_all;
#     is( scalar @authors, 0, "Got 0 authors" );
# };

# # OK static_all
# # OK static_get
# # OK static_get_filter
# # OK update
# # OK insert
# # OK save
# # OK toggle_visibility
# # !! can_be_deleted
# # OK delete
# # OK static_get_by_name
# # OK static_get_by_master

# ####################################################################
# subtest 'MAuthor assign master 1' => sub {

#     $dbh->do('DELETE FROM Author;');
#     $storage->authors_clear;

#     my $t1 = MAuthor->new( uid => 'AnAuthor' );
#     ok( $storage->add($t1) > 0, "added to storage" );
#     $t1->save($dbh);

#     my $t2 = MAuthor->new( uid => 'MasterAuthor' );
#     ok( $storage->add($t2) > 0, "added to storage" );
#     $t2->save($dbh);

#     my @authors = $storage->authors_all;

#     # say "ALL AUTHORS \n" . Dumper $storage->authors_all;


#     my @master_authors = $storage->authors_filter( sub { $_->is_master } );

#     # my @master_authors = MAuthor->static_all_masters($dbh);
#     is( scalar @master_authors, 2, "Got 2 master_authors" );

#     @authors = $storage->authors_all;
#     is( scalar @authors, 2, "Got 2 authors" );


#     $t1->set_master($t2);

#     is( $t1->{master_id}, $t2->{id},  "Master assigned" );
#     is( $t1->{master},    $t2->{uid}, "Master assigned" );

#     @authors = $storage->authors_all;
#     is( scalar @authors, 2, "Got 2 authors" );

# # say "ALL AUTHORS \n" . Dumper $storage->authors_all;
# # say "ALL MASTERS \n" . Dumper $storage->authors_filter( sub{ $_->is_master } );

#     @master_authors = $storage->authors_filter( sub { $_->is_master } );
#     is( scalar @master_authors, 1, "Got 1 master_author" );
# };

# ####################################################################
# subtest 'MAuthor all_author_user_ids add_user_id merge_authors' => sub {

#     $dbh->do('DELETE FROM Author;');
#     $storage->authors_clear;

#     my $t2 = MAuthor->new( uid => 'MasterAuthor' );
#     $t2->save($dbh);
#     ok( $storage->add($t2) > 0, "added to storage" );

#     my @minions = $storage->authors_filter( sub { $_->is_minion_of($t2) } );

#     is( scalar @minions, 1, "Got 1 uids" );
#     is( ( shift @minions )->{uid}, 'MasterAuthor', "uid ok" );

#     my $m1 = MAuthor->new( uid => 'SuperMan' );
#     ok( $storage->add($m1) > 0, "added to storage" );

#     is( $t2->add_minion($m1), 1, "add user id" );

#     @minions = $storage->authors_filter( sub { $_->is_minion_of($t2) } );

#     is( scalar @minions,    2,              "Got 2 uids" );
#     is( $minions[0]->{uid}, 'MasterAuthor', "uid 1 ok" );
#     is( $minions[1]->{uid}, 'SuperMan',     "uid 2 ok" );

#     my $t1 = MAuthor->new( uid => 'BigAuthor' );
#     ok( $storage->add($t1) > 0, "added to storage" );
#     $t1->save($dbh);

#     # say "ALL AUTHORS \n" . Dumper $storage->authors_all;

#     is( $t2->can_merge_authors(undef), 0, "can merge authors" );
#     is( $t2->can_merge_authors($t1), 1, "can merge authors" );
#     $t2->merge_authors($t1);
#     $t2->save($dbh);
#     $t1->save($dbh);

#     # say "ALL AUTHORS \n" . Dumper $storage->authors_all;

#     @minions = $storage->authors_filter( sub { $_->is_minion_of($t2) } );

#     is( scalar @minions, 3, "Got 3 uids" );
#     is( (@minions)[0]->{uid}, 'MasterAuthor', "uid 1 ok" );
#     is( (@minions)[1]->{uid}, 'SuperMan',     "uid 2 ok" );
#     is( (@minions)[2]->{uid}, 'BigAuthor',    "uid 3 ok" );
# };

# ####################################################################
# subtest 'MAuthor abandon entries update_master_name' => sub {

#     $dbh->do('DELETE FROM Author;');
#     $storage->authors_clear;

#     my $e = MEntry->new(
#         bib => '@mastersthesis{zz' . random_string(12) . ',
#         address = {World},
#         author = {James Bond},
#         month = {March},
#         school = {University of Bond},
#         title = {{Selected aspects of some methods}},
#         year = {1999},
#       }'
#     );
#     $e->populate_from_bib($dbh);
#     ok( $storage->add($e) );
#     $e->save($dbh);
#     $storage->add_entry_authors($e);
#     $storage->add_entry_tags($e);

#     my @authors = $e->authors();
#     is( scalar @authors, 1, "Got 1 author" );
#     my $a = shift @authors;

#     is( scalar $a->entries(), 1, "The author has 1 entry" );

#     $a->{display} = 1;
#     $a->save($dbh);

#     is( $a->can_be_deleted($dbh), 0, 'author can_be_deleted' );

#     $a->abandon_all_entries($dbh);
#     is( $a->can_be_deleted($dbh), 0, 'author can_be_deleted' );
#     is( scalar $a->entries($dbh), 0, "Got 0 entries" );

#     $a->{display} = 0;
#     $a->save($dbh);
#     is( $a->can_be_deleted($dbh), 1, 'author can_be_deleted' );

#     lives_ok { $a->update_master_name('HeMan') } 'update_master_name';
#     is( $a->{master}, 'HeMan', 'new master ok' );

#     my $t2 = MAuthor->new( uid => 'MasterAuthor' );
#     ok( $storage->add($t2) > 0, "added to storage" );
#     $t2->save($dbh);

#     lives_ok { $a->update_master_name('MasterAuthor') } 'update_master_name';
#     is( $a->{master}, 'MasterAuthor', 'new master ok' );

# };

# ####################################################################
# subtest 'MAuthor teams' => sub {

#     $dbh->do('DELETE FROM Author;');
#     $dbh->do('DELETE FROM Team;');
#     $storage->authors_clear;
#     $storage->teams_clear;

#     my $a = MAuthor->new( uid => 'MasterAuthor' );
#     $storage->add($a);
#     $a->save($dbh);

#     my $t = MTeam->new( name => 'Masters' );
#     $storage->add($t);
#     $t->save($dbh);

#     is( scalar $a->teams(),     0, 'teams' );
#     is( $a->add_to_team(undef), 0, 'add to team' );
#     isnt( $a->add_to_team($t), 0, 'add to team' );
#     is( scalar $a->teams(), 1, 'teams' );

#     is( $a->joined_team(undef), -1, 'joined_team' );
#     is( $a->joined_team($t),    0,  'joined_team' );
#     is( $a->left_team(undef),   -1, 'left_team' );
#     is( $a->left_team($t),      0,  'left_team' );

#     is( $a->remove_from_team(undef), 0, 'add to team' );
#     isnt( $a->remove_from_team($t), 0, 'add to team' );
#     is( scalar $a->teams(), 0, 'teams' );

# };

ok(1);
done_testing();
