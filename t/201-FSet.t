use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;
my $dbh      = $t_anyone->app->db;

use BibSpace::Model::MTeam;

use BibSpace::Controller::Set;    # this code will be
use BibSpace::Functions::FSet;    # ported to here and refactored

use BibSpace::Controller::Core;

use Set::Scalar;
use Data::Dumper;

use BibSpace::Controller::BackupFunctions qw(do_restore_backup_from_file);

my $app_config = $t_anyone->app->config;
my $fixture_dir = "./fixture/";
SKIP: {
    note "============ APPLY DATABASE FIXTURE ============";
    skip "Directory $fixture_dir does not exist", 1 if !-e $fixture_dir."db.sql";

    my $status = 0;
    $status = do_restore_backup_from_file($dbh, "./fixture/db.sql", $app_config);
    is($status, 1, "preparing DB for test");
}





my @teams      = MTeam->static_all($dbh);
my @tags       = MTag->static_all($dbh);
my @entries    = MEntry->static_all($dbh);
my @author_ids = ();




####################################################################
subtest 'Controller Set basics - getters' => sub {

    ok( Fget_set_of_all_team_ids($dbh) );
    ok( Fget_set_of_papers_with_exceptions($dbh) );
    ok( Fget_set_of_tagged_papers($dbh) );

};

####################################################################
subtest 'Controller Set basics - getters for team' => sub {

    my $rteam = $teams[ rand @teams ];

    plan 'skip_all' =>
        "Cannot test. There is no team and one is needed for testing"
        if scalar @teams == 0;

    ok( Fget_set_of_authors_for_team( $dbh, $rteam->{id} ) );
    ok( Fget_set_of_papers_for_all_authors_of_team_id( $dbh, $rteam->{id} ) );
    ok( Fget_set_of_authors_for_team( $dbh, $rteam->{id} ) );
    ok( Fget_set_of_papers_for_team( $dbh, $rteam->{id} ) );
};
####################################################################
subtest 'Controller Set basics - getters for authors' => sub {

    my $rteam = $teams[ rand @teams ];

    @author_ids = Fget_set_of_authors_for_team( $dbh, $rteam->{id} )
        ->elements;    # this is also function under test, so watch out!

    plan 'skip_all' =>
        "Cannot test. There is no author and one is needed for testing"
        if scalar @author_ids == 0;

    ok( scalar @author_ids > 0, "there are some authors" );

    my $author_id = $author_ids[ rand @author_ids ];

    is( scalar Fget_set_of_papers_for_author_id( $dbh, -1 )->elements,
        0, "Fget_set_of_papers_for_author_id -1" );

};
####################################################################
TODO: {
    local $TODO = "Fixture is not prepared for this test";

    my $author_id = $author_ids[ rand @author_ids ];

    ok( Fget_set_of_papers_for_author_id( $dbh, $author_id )->elements,
        "Fget_set_of_papers_for_author_id" );
};

####################################################################
subtest 'Controller Set basics - getters for tags' => sub {

    my $rteam     = $teams[ rand @teams ];
    my $rtag      = $tags[ rand @tags ];
    my $author_id = $author_ids[ rand @author_ids ];

    ok( defined Fget_set_of_papers_for_team_and_tag(
            $dbh, $rteam->{id}, $rtag->{id}
        )
    );

    ok( Fget_set_of_teams_for_author_id( $dbh, $author_id ) );
};
####################################################################
TODO: {
    local $TODO = "Fixture is not prepared for this test";

    my $author_id = $author_ids[ rand @author_ids ];
    my $rentry = $entries[ rand @entries ];

    # ok( Fget_set_of_authors_for_entry_id( $dbh, $rentry->{id} )->elements );
    # ok( Fget_set_of_teams_for_entry_id( $dbh, $rentry->{id} )->elements );

    my $year = 2011;    # FIXME!
    ok( Fget_set_of_teams_for_author_id_w_year( $dbh, $author_id, $year ) );
};
####################################################################

done_testing();

