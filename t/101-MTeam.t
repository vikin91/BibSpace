use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self = $t_anyone->app;
my $dbh = $t_anyone->app->db;


use BibSpace::Model::MTeam;

use BibSpace::Controller::Set;
use BibSpace::Controller::Core;
use Set::Scalar;
use Data::Dumper;



$dbh->do('DELETE FROM Team;');

# my $en = MTeam->new();
my @teams = MTeam->static_all($dbh);
my $num_teams = scalar(@teams);
is($num_teams, 0, "Got 0 teams");


my $t1 = MTeam->new();
$t1->{name} = 'Shy_writers';
$t1->{parent} = undef;
$t1->save($dbh);

@teams = MTeam->static_all($dbh);
$num_teams = scalar(@teams);
is($num_teams, 1, "Got 1 teams");

my $some_team = shift( \@teams );
is($some_team->delete($dbh), 1);
@teams = MTeam->static_all($dbh);
$num_teams = scalar(@teams);
is($num_teams, 0, "Got 0 teams");
is($some_team->{id}, undef);


done_testing();
