package BibSpace::Controller::Teams;

use utf8;
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; #because of ~~
use strict;
use warnings;
use DBI;

use BibSpace::Controller::Core;
use BibSpace::Model::MTeam;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';

################################################################################################################

sub show {
   my $self = shift;
   my $dbh = $self->app->db;
   
   my $sth = $dbh->prepare( "SELECT id, name, parent FROM Team
         ORDER BY name ASC" );  
   $sth->execute(); 

   my @teams;
   my @ids
   my $i = 1;
   while(my $row = $sth->fetchrow_hashref()) {
      my $team = $row->{name} || "noname-team";
      my $id = $row->{id};

      push @teams, $team;
      push @ids, $id;
      $i++;
   }
   
   
   $self->stash(teams_arr  => \@teams, ids_arr  => \@ids);
   $self->render(template => 'teams/teams', layout => 'admin');
 };

################################################################################################################

################################################################################################################
sub add_team {
   my $self = shift;
   my $dbh = $self->app->db;
   $self->render(template => 'teams/add_team');
};

##############################################################################################################
### POST like for HTML forms, not a blog post
sub add_team_post {
  my $self = shift;
  my $dbh = $self->app->db;
  my $new_team_name = $self->param('new_team');

  my $existing_mteam = MTeam->static_get_by_name($dbh, $new_team_name);
  if(defined $existing_mteam){
    $self->write_log("add new team: team with proposed name ($new_team_name) exists!!");
    $self->flash(msg => "Team with such name exists already! Pick a different one.");
    $self->redirect_to($self->url_for('add_team_get'));
    return;
  }

  my $new_mteam = MTeam->new();
  $new_mteam->{name} = $new_team_name;
  $new_mteam->{parent} = undef;
  my $new_team_id = $new_mteam->save($dbh);

  if(!defined $new_team_id or $new_team_id <= 0){
      $self->flash(msg => "Something went wrong. The Team $new_team_name has not been added.");
      $self->redirect_to($self->url_for('add_team_get'));
      return;
  }
  
  $self->write_log("Add new team: Added new team with proposed name ($new_team_name). Team id is $new_team_id.");
  $self->redirect_to('edit_team', teamid=>$new_team_id); 
}

##############################################################################################################
sub delete_team {
    my $self = shift;
    my $dbh = $self->app->db;
    my $id_to_delete = $self->param('id_to_delete');

    if(defined $id_to_delete and $id_to_delete != -1 and  $self->team_can_be_deleted($id_to_delete)){
        do_delete_team_force($self, $id_to_delete);
    }
    $self->flash(msg => "Team id $id_to_delete has been deleted.");
    $self->redirect_to($self->get_referrer);
};

##############################################################################################################
sub delete_team_force {
    my $self = shift;
    my $dbh = $self->app->db;
    my $id_to_delete = $self->param('id_to_delete');


    if(defined $id_to_delete and $id_to_delete != -1){

        $self->write_log("Trying to delete team with force");
        my $urank = $self->get_rank_of_current_user($self->session('user'));
        if( $urank < 3){
            $self->write_log("Rank too low. User: ".$self->session('user').", Rank: $urank");
            $self->flash(msg => "You are not super admin. You have not enough mana to delete this team with force.");
            $self->redirect_to("teams");        
        }
        else{
            $self->write_log("Deleting. User: ".$self->session('user').", Rank: $urank");
            $self->flash(msg => "Team deleted");
            do_delete_team_force($self, $id_to_delete);
        }
    }

    $self->redirect_to("teams");
     
};

##############################################################################################################
sub do_delete_team_force {
  my $self = shift;
  my $id = shift;

  my $dbh = $self->app->db;

  my $mteam = MTeam->static_get($dbh, $id);
  if(!defined $mteam){
    $self->flash(msg => "There is no team with id $id");
    $self->redirect_to($self->get_referrer);  
    return;
  }
  $mteam->delete($dbh);    
};
################################################################################################################

sub edit {
  my $self = shift;
  my $id = $self->param('teamid');
  my $dbh = $self->app->db;

  my $mteam = MTeam->static_get($dbh, $id);
  if(!defined $mteam){
    $self->flash(msg => "There is no team with id $id");
    $self->redirect_to($self->get_referrer);  
    return;
  }

  my ($author_ids_ref, $start_arr_ref, $stop_arr_ref) = get_team_members($self, $id);
  my @members = @$author_ids_ref;
  my $team_name = $mteam->{name};


  $self->stash(members  => \@members, start_arr => $start_arr_ref, stop_arr => $stop_arr_ref, team => $id, teamname => $team_name);
  $self->render(template => 'teams/members');
}
################################################################################################################

1;