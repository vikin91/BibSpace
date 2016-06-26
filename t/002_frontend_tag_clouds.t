use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Controller::Core;



my $t_anyone = Test::Mojo->new('BibSpace');
my $self = $t_anyone->app;
my $dbh      = $t_anyone->app->db;
$t_anyone->ua->inactivity_timeout(3600);



use BibSpace::Model::MTeam;


my @all_teams = MTeam->static_all($dbh);

####################################################################
subtest 'FRONTEND Tag Clouds TEAMS' => sub {
	
	plan 'skip_all' => "There are no teams"
        if scalar @all_teams == 0;


  foreach my $team (@all_teams){
  	my $page = $self->url_for('tags_for_team', tid=>$team->{id});	
  	$t_anyone->get_ok($page)->status_isnt(404, "Checking: 404 $page")->status_isnt(500, "Checking: 500 $page");
  }
  

	
};



my @all_author_ids = ();

####### this should be refacotred when MAuthor is ready!!!
my $qry = "SELECT master_id, id, master FROM Author WHERE id=master_id AND master IS NOT NULL;";
my $sth = $dbh->prepare_cached($qry);
$sth->execute();
while ( my $row = $sth->fetchrow_hashref() ) {
	my $master    = $row->{master};
    my $master_id = $row->{master_id};  ### this is what we look for. DB Table Author is badly designed :()
    my $id        = $row->{id};
    push @all_author_ids, $master_id;
}
#######

####################################################################
subtest 'FRONTEND Tag Clouds AUTHOR' => sub {
	
	plan 'skip_all' => "There are no authors"
        if scalar @all_author_ids == 0;

  foreach my $author_id (@all_author_ids){

  	my $page = $self->url_for('tags_for_author', aid=>$author_id);
  	$t_anyone->get_ok($page)->status_isnt(404, "Checking: 404 $page")->status_isnt(500, "Checking: 500 $page");
  }
};



done_testing();
