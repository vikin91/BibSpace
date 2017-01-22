package BibSpace::Controller::Teams;

use utf8;
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010;    #because of ~~
use strict;
use warnings;
use DBI;
use Data::Dumper;

use BibSpace::Controller::Core;
use BibSpace::Model::Team;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';

################################################################################################################

sub show {
  my $self  = shift;
  my @teams = $self->app->repo->getTeamsRepository->all;
  $self->stash( teams => \@teams );
  $self->render( template => 'teams/teams', layout => 'admin' );
}
################################################################################################################
sub edit {
  my $self = shift;
  my $id   = $self->param('teamid');

  my $team = $self->app->repo->getTeamsRepository->find( sub { $_->id == $id } );

  if ( !defined $team ) {
    $self->flash( msg => "There is no team with id $id", msg_type => 'danger' );
    $self->redirect_to( $self->get_referrer );
    return;
  }

  my @team_members = $team->members;


  $self->stash( members => \@team_members, team => $team );
  $self->render( template => 'teams/members' );
}
################################################################################################################
sub add_team {
  my $self = shift;
  $self->render( template => 'teams/add_team' );
}
##############################################################################################################
sub add_team_post {
  my $self          = shift;
  my $new_team_name = $self->param('new_team');


  my $existing_mteam = $self->app->repo->getTeamsRepository->find( sub { $_->name eq $new_team_name } );

  if ( defined $existing_mteam ) {
    $self->write_log( "add new team: team with proposed name ($new_team_name) exists!!" );
    $self->flash( msg => "Team with such name exists already! Pick a different one." );
    $self->redirect_to( $self->url_for('add_team_get') );
    return;
  }
  my $new_mteam = Team->new( name => $new_team_name, idProvider => $self->app->repo->getTeamsRepository->getIdProvider );
  $self->app->repo->getTeamsRepository->save($new_mteam);
  my $new_team_id = $new_mteam->id;
  if ( !defined $new_team_id or $new_team_id <= 0 ) {
    $self->flash( msg => "Something went wrong. The Team $new_team_name has not been added." );
    $self->redirect_to( $self->url_for('add_team_get') );
    return;
  }
  $self->write_log( "Add new team: Added new team with proposed name ($new_team_name). Team id is $new_team_id." );
  $self->redirect_to( 'edit_team', teamid => $new_team_id );
}

##############################################################################################################
sub delete_team {
  my $self = shift;
  my $id   = $self->param('id');

  my $team = $self->app->repo->getTeamsRepository->find( sub { $_->id == $id } );

  if ( $team and $team->can_be_deleted ) {
    my $msg = "Team " . $team->name . " ID " . $team->id . " has been deleted";
    $self->write_log( $msg );
    $self->flash( msg => $msg, msg_type => 'success' );
    $self->do_delete_team($team);
  }
  else {
    $self->flash( msg_type => 'warning', msg => "Unable to delete team id $id." );
  }

  $self->redirect_to( $self->url_for('all_teams') );
}

##############################################################################################################
sub delete_team_force {
  my $self = shift;
  my $dbh  = $self->app->db;
  my $id   = $self->param('id');

  my $team = $self->app->repo->getTeamsRepository->find( sub { $_->id == $id } );
  if ($team) {
    my $msg = "Team " . $team->name . " ID " . $team->id . " has been deleted";
    $self->write_log( $msg );
    $self->flash( msg => $msg, msg_type => 'success' );
    $self->do_delete_team($team);
  }
  else{
    $self->flash( msg_type => 'warning', msg => "Unable to delete team id $id." );
  }

  $self->redirect_to( $self->url_for('all_teams') );

}
##############################################################################################################
sub do_delete_team {
  my $self = shift;
  my $team = shift;

  ## Deleting memberships
  my @memberships = $team->memberships_all;
  # for each team, remove membership in this team
  foreach my $membership ( @memberships ){
      $membership->author->remove_membership($membership);
  }
  $self->app->repo->getMembershipsRepository->delete(@memberships);
  # remove all memberships for this team
  $team->memberships_clear;
  $self->app->repo->getTeamsRepository->delete($team);
}
##############################################################################################################


1;
