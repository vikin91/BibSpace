use Mojo::Base -strict;
use Test::More;
use Test::Mojo;



my $t_anyone = Test::Mojo->new('BibSpace');
my $self = $t_anyone->app;
my $dbh = $t_anyone->app->db;


use BibSpace::Model::MEntry;
use BibSpace::Model::MTeam;

use BibSpace::Controller::Set;
use BibSpace::Controller::Core;
use Set::Scalar;
use Data::Dumper;



my @all_entry_objects = MEntry->static_all($dbh);
my @all_entry_objects_ids_arr = map {$_->{id}} @all_entry_objects; # wow!
my $all_entry_objects_ids_arr_set = Set::Scalar->new(@all_entry_objects_ids_arr);

ok($all_entry_objects_ids_arr_set->is_equal(get_set_of_all_paper_ids($dbh)));


my @all_team_objects = MTeam->static_all($dbh);
my @all_teams = MTeam->static_all($dbh);
my @all_team_ids_arr = map {$_->{id}} @all_teams;
my $set_all_team_ids = Set::Scalar->new(@all_team_ids_arr);

ok($set_all_team_ids->is_equal(get_set_of_all_team_ids($dbh)));


done_testing();
