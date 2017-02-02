use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Functions::Core;



my $t_anyone = Test::Mojo->new('BibSpace');
my $self = $t_anyone->app;
my $dbh      = $t_anyone->app->db;

$t_anyone->ua->inactivity_timeout(3600);
$t_anyone->ua->max_redirects(10);

## THIS SHOULD BE REPEATED FOR EACH TEST!
my $fixture_name = "bibspace_fixture.dat";
my $fixture_dir = "./fixture/";
use BibSpace::Model::Backup;
use BibSpace::Functions::BackupFunctions qw(restore_storable_backup);
my $fixture = Backup->new(dir => $fixture_dir, filename =>$fixture_name);
restore_storable_backup($fixture, $t_anyone->app);

my @all_teams = $self->app->repo->teams_all;

####################################################################
subtest 'FRONTEND Tag Clouds TEAMS' => sub {
	
	plan 'skip_all' => "There are no teams"
        if scalar @all_teams == 0;

  foreach my $team (@all_teams){
  	my $page = $self->url_for('tags_for_team', team_id=>$team->id);	
  	$t_anyone->get_ok($page)->status_isnt(404, "Checking: 404 $page")->status_isnt(500, "Checking: 500 $page");
  }

};



my @all_authors = $self->app->repo->authors_all;

####################################################################
subtest 'FRONTEND Tag Clouds AUTHOR' => sub {
  
  plan 'skip_all' => "There are no authors"
        if scalar @all_authors == 0;

  foreach my $author (@all_authors){
    my $page = $self->url_for( 'tags_for_author', author_id=>$author->id );
    $t_anyone->get_ok($page)->status_isnt(404, "Checking: 404 $page")->status_isnt(500, "Checking: 500 $page");
  }

};


done_testing();
