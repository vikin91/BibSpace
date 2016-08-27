use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;
my $dbh      = $t_anyone->app->db;

use BibSpace::Model::MAuthor;

use BibSpace::Controller::Set;
use BibSpace::Controller::Core;
use Set::Scalar;
use Data::Dumper;

####################################################################
subtest 'MAuthor basics' => sub {

    $dbh->do('DELETE FROM Author;');

    # my $en = MAuthor->new();
    my @authors     = MAuthor->static_all($dbh);
    my $num_teams = scalar(@authors);
    is( $num_teams, 0, "Got 0 authors" );

    my $t1 = MAuthor->new(uid => 'AnAuthor');
    $t1->save($dbh);
    is( $t1->{master}, $t1->{uid}, "master equals uid" );
    is( $t1->{master_id}, $t1->{id}, "master_id equals id" );

    @authors     = MAuthor->static_all($dbh);
    $num_teams = scalar(@authors);
    is( $num_teams, 1, "Got 1 authors" );

    my $some_author = shift @authors;
    is( $some_author->delete($dbh), 1 );

    @authors     = MAuthor->static_all($dbh);
    $num_teams = scalar(@authors);
    is( $num_teams, 0, "Got 0 authors" );
    is( $some_author->{id}, undef );

    foreach ( 1 .. 10 ) {
        my $t2 = MAuthor->new(uid => random_string(8));
        $t2->save($dbh);
    }

    @authors     = MAuthor->static_all($dbh);
    $num_teams = scalar(@authors);
    is( $num_teams, 10, "Got 10 authors" );
};

####################################################################
subtest 'MAuthor basics 2' => sub {

    # test updating
    my @authors = MAuthor->static_all($dbh);
    my $random_author = $authors[ rand @authors ];
    $random_author->{uid} .= "super";
    is( $random_author->save($dbh), 1, "updated 1 author" );

    #test getting defined team by id
    my $the_same = MAuthor->static_get( $dbh, $random_author->{id} );
    is( $the_same->{id}, $random_author->{id}, "getter author for id" );

    # test getter by name
    $random_author = $authors[rand @authors];
    $the_same = MAuthor->static_get_by_name( $dbh, $random_author->{uid} );
    is( $the_same->{id}, $random_author->{id}, "getter author for name" );

    $the_same = MAuthor->static_get_by_master( $dbh, $random_author->{master} );
    is( $the_same->{id}, $random_author->{id}, "getter author for master" );
    
    # test getter by name - name does not exist
    is(MAuthor->static_get_by_name( $dbh, "doesnotexitsforsure" ), undef, "getter by name not existing author");
    is(MAuthor->static_get_by_master( $dbh, "doesnotexitsforsure" ), undef, "getter by master not existing author");
    
    #test saving bad team
    my $bad_authoe = MAuthor->new();
    $bad_authoe->{id} = undef;
    is( $bad_authoe->save($dbh), -1, "saving bad author" );

    $random_author = $authors[rand @authors];
    $random_author->{id} = undef;
    is( $random_author->update($dbh), -1, "updating with undef id" );

};

####################################################################
subtest 'MAuthor basics 3' => sub {

    $dbh->do('DELETE FROM Author;');

    # my $en = MAuthor->new();
    my @authors     = MAuthor->static_all($dbh);
    is( scalar @authors, 0, "Got 0 authors" );

    my $t1 = MAuthor->new(uid => 'AnAuthor');
    $t1->save($dbh);

    @authors     = MAuthor->static_get_filter($dbh, undef, 'A');
    is( scalar @authors, 1, "Got 1 authors" );
    @authors     = MAuthor->static_get_filter($dbh, 1, 'A');
    is( scalar @authors, 0, "Got 0 authors" );
    @authors     = MAuthor->static_get_filter($dbh, 0, 'A');
    is( scalar @authors, 1, "Got 1 authors" );

    @authors     = MAuthor->static_get_filter($dbh, undef, 'A');

    my $random_author = $authors[ rand @authors ];
    # default is invisible
    is( $random_author->{display}, 0, "author invisible" );
    $random_author->toggle_visibility($dbh);
    is( $random_author->{display}, 1, "author visible" );

    is( $random_author->delete($dbh), 1, "author deleted" );
    @authors     = MAuthor->static_all($dbh);
    is( scalar @authors, 0, "Got 0 authors" );
};

# OK static_all
# OK static_get
# OK static_get_filter
# OK update
# OK insert
# OK save
# OK toggle_visibility 
# !! can_be_deleted 
# OK delete
# OK static_get_by_name
# OK static_get_by_master

####################################################################
subtest 'MAuthor assign master 1' => sub {

    $dbh->do('DELETE FROM Author;');


    my $t1 = MAuthor->new(uid => 'AnAuthor');
    $t1->save($dbh);

    my $t2 = MAuthor->new(uid => 'MasterAuthor');
    $t2->save($dbh);

    my @master_authors     = MAuthor->static_all_masters($dbh);
    is( scalar @master_authors, 2, "Got 2 master_authors" );

    my @authors     = MAuthor->static_all($dbh);
    is( scalar @authors, 2, "Got 2 authors" );

    $t1->assign_master($dbh, $t2);

    is( $t1->{master_id}, $t2->{id}, "Master assigned" );
    is( $t1->{master}, $t2->{uid}, "Master assigned" );

    @authors     = MAuthor->static_all($dbh);
    is( scalar @authors, 2, "Got 2 authors" );

    @master_authors     = MAuthor->static_all_masters($dbh);
    is( scalar @master_authors, 1, "Got 1 master_author" );
    

};

# assign_master

# teams 
# joined_team 
# left_team 


done_testing();
