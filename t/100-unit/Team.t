use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $t_anyone    = Test::Mojo->new('BibSpace');
my $self = $t_anyone->app;

## THIS SHOULD BE REPEATED FOR EACH TEST!
my $fixture_name = "bibspace_fixture.dat";
my $fixture_dir = "./fixture/";
use BibSpace::Model::Backup;
use BibSpace::Functions::BackupFunctions qw(restore_storable_backup);
my $fixture = Backup->new(dir => $fixture_dir, filename =>$fixture_name);
restore_storable_backup($fixture, $self->app);

# ####################################################################
# subtest 'MTeam basics' => sub {

#     $dbh->do('DELETE FROM Team;');

#     # my $en = MTeam->new();
#     my @teams     = MTeam->static_all($dbh);
#     my $num_teams = scalar(@teams);
#     is( $num_teams, 0, "Got 0 teams" );

#     my $t1 = MTeam->new();
#     $t1->{name}   = 'Shy_writers';
#     $t1->{parent} = undef;
#     $t1->save($dbh);

#     @teams     = MTeam->static_all($dbh);
#     $num_teams = scalar(@teams);
#     is( $num_teams, 1, "Got 1 teams" );

#     my $some_team = shift @teams;
#     is( $some_team->delete($dbh), 1 );

#     @teams     = MTeam->static_all($dbh);
#     $num_teams = scalar(@teams);
#     is( $num_teams, 0, "Got 0 teams" );
#     is( $some_team->{id}, undef );

#     foreach ( 1 .. 10 ) {
#         my $t2 = MTeam->new();
#         $t2->{name}   = random_string(8);
#         $t2->{parent} = undef;
#         $t2->save($dbh);
#     }

#     @teams     = MTeam->static_all($dbh);
#     $num_teams = scalar(@teams);
#     is( $num_teams, 10, "Got 10 teams" );
# };

# ####################################################################
# subtest 'MTeam basics 2' => sub {

#     # test updating
#     my @teams = MTeam->static_all($dbh);
#     my $rteam = $teams[ rand @teams ];
#     $rteam->{name} .= "super";
#     is( $rteam->save($dbh), 1, "updated 1 team" );

#     #test getting defined team by id
#     my $the_same = MTeam->static_get( $dbh, $rteam->{id} );
#     is( $the_same->{id}, $rteam->{id}, "getter team for id" );

#     # test getter by name
#     $rteam = $teams[rand @teams];
#     $the_same = MTeam->static_get_by_name( $dbh, $rteam->{name} );
#     is( $the_same->{id}, $rteam->{id}, "getter team for name" );
    
#     # test getter by name - name does not exist
#     is(MTeam->static_get_by_name( $dbh, "doesnotexitsforsure" ), undef, "getter by name not exsiting team");
    
#     #test saving bad team
#     my $bad_team = MTeam->new();
#     $bad_team->{id} = undef;
#     is( $bad_team->save($dbh), -1, "saving bad team" );

#     $rteam = $teams[rand @teams];
#     $rteam->{id} = undef;
#     is( $rteam->update($dbh), -1, "updating with undef id" );

# };
ok(1);
done_testing();
