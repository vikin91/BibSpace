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
use BibSpace::Model::M::MTeam;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';

################################################################################################################

sub show {
    my $self = shift;
    my $dbh  = $self->app->db;

    my $storage = StorageBase->get();
    my @teams   = $storage->teams_all;


    $self->stash( teams => \@teams );
    $self->render( template => 'teams/teams', layout => 'admin' );
}
################################################################################################################
sub edit {
    my $self = shift;
    my $id   = $self->param('teamid');
    my $dbh  = $self->app->db;

    my $storage = StorageBase->get();
    my $team = $storage->teams_find( sub { $_->id == $id } );

    if ( !defined $team ) {
        $self->flash(
            msg      => "There is no team with id $id",
            msg_type => 'danger'
        );
        $self->redirect_to( $self->get_referrer );
        return;
    }

    my @team_members = $team->members;


    $self->stash( members => \@team_members, team => $team );
    $self->render( template => 'teams/members' );
}
################################################################################################################

################################################################################################################
sub add_team {
    my $self = shift;
    my $dbh  = $self->app->db;
    $self->render( template => 'teams/add_team' );
}

##############################################################################################################
### POST like for HTML forms, not a blog post
sub add_team_post {
    my $self          = shift;
    my $dbh           = $self->app->db;
    my $new_team_name = $self->param('new_team');

    my $storage = StorageBase->get();


    my $existing_mteam
        = $storage->teams_find( sub { ( $_->name cmp $new_team_name ) == 0 }
        );

    if ( defined $existing_mteam ) {
        $self->write_log(
            "add new team: team with proposed name ($new_team_name) exists!!"
        );
        $self->flash( msg =>
                "Team with such name exists already! Pick a different one." );
        $self->redirect_to( $self->url_for('add_team_get') );
        return;
    }

    my $new_mteam = MTeam->new( name => $new_team_name, parent => undef );
    $storage->add($new_mteam);

    my $new_team_id = $new_mteam->save($dbh);

    if ( !defined $new_team_id or $new_team_id <= 0 ) {
        $self->flash( msg =>
                "Something went wrong. The Team $new_team_name has not been added."
        );
        $self->redirect_to( $self->url_for('add_team_get') );
        return;
    }

    $self->write_log(
        "Add new team: Added new team with proposed name ($new_team_name). Team id is $new_team_id."
    );
    $self->redirect_to( 'edit_team', teamid => $new_team_id );
}

##############################################################################################################
sub delete_team {
    my $self = shift;
    my $dbh  = $self->app->db;
    my $id   = $self->param('id');

    my $storage = StorageBase->get();
    my $team = $storage->teams_find( sub { $_->id == $id } );

    if ( defined $team and $team->can_be_deleted() ) {

        $self->write_log( "Team " . $team->name . " has been deleted" );

        $team->remove_all_authors;
        $storage->delete($team);

        $self->flash(
            msg_type => 'success',
            msg      => "Team id $id has been deleted."
        );
    }
    else {
        $self->flash(
            msg_type => 'warning',
            msg      => "Unable to delete team id $id."
        );
    }

    $self->redirect_to( $self->url_for('all_teams') );
}

##############################################################################################################
sub delete_team_force {
    my $self = shift;
    my $dbh  = $self->app->db;
    my $id   = $self->param('id');

    my $storage = StorageBase->get();
    my $team = $storage->teams_find( sub { $_->id == $id } );


    if ($team) {

        $self->write_log( "Team " . $team->name . " has been deleted" );

        $self->flash( msg => "Team has deleted", msg_type => 'success' );

        $storage->delete($team);
    }

    $self->redirect_to( $self->url_for('all_teams') );

}
################################################################################################################


1;
