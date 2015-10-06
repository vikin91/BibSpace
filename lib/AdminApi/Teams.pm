package AdminApi::Teams;

use utf8;
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; #because of ~~
use strict;
use warnings;
use DBI;

use AdminApi::Core;

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
   my @ids;

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
   my $back_url = $self->param('back_url') || "/teams";

   my $dbh = $self->app->db;


   $self->stash(back_url => $back_url);
   $self->render(template => 'teams/add_team');
};

##############################################################################################################
### POST like for HTML forms, not a blog post
sub add_team_post {
    my $self = shift;
    my $dbh = $self->app->db;
    my $new_team = $self->param('new_team');

    if(defined $new_team){
        my $existing_team = get_team_id($dbh, $new_team);
        if($existing_team == -1){
            
            my $sth = $dbh->prepare('INSERT INTO Team(name) VALUES(?)');
            $sth->execute($new_team);    

            my $teamid = $dbh->last_insert_id(undef, undef, 'Team', 'id');

            if(!defined $teamid){
                $self->flash(msg => "Something went wrong. The Team $new_team has not beed added");
                $self->redirect_to('/teams/add');
                return;
            }
            
            $self->write_log("add new team: Added new team with proposed name ($new_team). Team id is $teamid.");

            $self->redirect_to('/teams/edit/'.$teamid); 
            return;
            
        }
        else{
            $self->write_log("add new team: team with proposed name ($new_team) exists!!");
            $self->flash(msg => "Team with such name exists already! Pick a different one.");
            $self->redirect_to('/teams/add');
            return;
        }
    } 
     $self->redirect_to('/teams');
}

##############################################################################################################
sub delete_team {
    my $self = shift;
    my $dbh = $self->app->db;
    my $id_to_delete = $self->param('id_to_delete');

    if(defined $id_to_delete and $id_to_delete != -1 and  $self->team_can_be_deleted($id_to_delete)){
        do_delete_team_force($self, $id_to_delete);
    }

    my $back_url = $self->param('back_url') || "/teams";
    $self->redirect_to($back_url);
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
            $self->redirect_to("/teams");        
        }
        else{
            $self->write_log("Deleting. User: ".$self->session('user').", Rank: $urank");
            $self->flash(msg => "Team deleted");
            do_delete_team_force($self, $id_to_delete);
        }
    }

    my $back_url = $self->param('back_url') || "/teams";
    $self->redirect_to("/teams");
     
};

##############################################################################################################
sub do_delete_team_force {
    my $self = shift;
    my $dbh = $self->app->db;
    my $id_to_delete = shift;


    if(defined $id_to_delete and $id_to_delete != -1){
        $dbh->begin_work; #transaction

        my $sth = $dbh->prepare('DELETE FROM Author_to_Team WHERE team_id=?');
        $sth->execute($id_to_delete);

        my $sth2 = $dbh->prepare('DELETE FROM Team WHERE id=?');
        $sth2->execute($id_to_delete);  

        $dbh->commit; #end transaction
    }
    
};
################################################################################################################

sub edit {
    my $self = shift;
    my $teamid = $self->param('teamid');
    my $back_url = $self->param('back_url') || "/teams";
    my $dbh = $self->app->db;

    # TODO: Implement me!!

    return team_members($self);

    $self->redirect_to('/teams');
}
################################################################################################################

 sub team_members {
   my $self = shift;

   my $teamid = $self->param('teamid');
   my $back_url = $self->param('back_url') || "/teams";

   my $dbh = $self->app->db;


   my ($author_ids_ref, $start_arr_ref, $stop_arr_ref) = get_team_members($self, $teamid);
   my @members = @$author_ids_ref;
   my $team_name = get_team_for_id($dbh, $teamid);

   
   $self->stash(back_url => $back_url, members  => \@members, start_arr => $start_arr_ref, stop_arr => $stop_arr_ref, team => $teamid, teamname => $team_name);
   $self->render(template => 'teams/members');
 }

################################################################################################################

1;