package BibSpace::Controller::Authors;


use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use Try::Tiny;
use File::Slurp;
use Time::Piece;
use 5.010;           #because of ~~
use strict;
use warnings;
use DBI;

use List::MoreUtils qw(any uniq);

use BibSpace::Controller::Core;
use BibSpace::Controller::Publications;

use BibSpace::Functions::FPublications;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';


##############################################################################################################
sub all_authors {    # refactored
  my $self    = shift;
  my $dbh     = $self->app->db;
  my $visible = $self->param('visible');
  my $search  = $self->param('search') || '%';
  my $letter  = $self->param('letter') || '%';

  my $letter_pattern = $letter;
  if ( $letter ne '%' ) {
    $letter_pattern .= '%';
  }

  my @authors = $self->app->repo->getAuthorsRepository->all;
  if ( defined $visible ) {
    @authors = grep { $_->display == $visible } @authors;
  }
  @authors = grep { $_->is_master } @authors;

  if ( $letter ne '%' ) {
    @authors = grep { ( substr( $_->master, 0, 1 ) cmp $letter ) == 0 } @authors;
  }
  my @letters = map { substr( $_->master, 0, 1 ) } @authors;
  @letters = uniq @letters;
  @letters = sort @letters;

  $self->stash( authors => \@authors, letters => \@letters, letter => $letter, visible => $visible );

  $self->render( template => 'authors/authors' );
}
##############################################################################################################
sub add_author {
  my $self = shift;

  $self->stash( master => '', id => '' );
  $self->render( template => 'authors/add_author' );
}

##############################################################################################################
sub add_post {
  my $self       = shift;
  my $dbh        = $self->app->db;
  my $new_master = $self->param('new_master');

  if ( defined $new_master and length($new_master) > 0 ) {

    my $author = $self->app->repo->getAuthorsRepository->find( sub { $_->master eq $new_master } );

    if ( !defined $author ) {    # no such user exists yet

      $author = Author->new( uid => $new_master, idProvider => $self->app->repo->getAuthorsRepository->getIdProvider );
      $self->app->repo->getAuthorsRepository->save($author);

      if ( !defined $author->id ) {
        $self->flash(
          msg_type => 'danger',
          msg      => "Error saving author. Saving to the database returned no insert row id."
        );
        $self->redirect_to( $self->url_for('add_author') );
        return;
      }
      $self->write_log( "Added new author with master: $new_master. Author id is " . $author->{id} );
      $self->flash( msg_type => 'success', msg => "Author added successfully!" );
      $self->redirect_to( $self->url_for( 'edit_author', id => $author->{id} ) );
      return;
    }
    else {    # such user already exists!
      $self->write_log("Author with master: $new_master already exists!");
      $self->flash(
        msg_type => 'warning',
        msg      => "Author with proposed master: $new_master already exists! Pick a different one."
      );
      $self->redirect_to( $self->url_for('add_author') );
      return;
    }
  }

  $self->flash( msg_type => 'warning', msg => "Bad input." );
  $self->redirect_to( $self->url_for('add_author') );
}
##############################################################################################################
sub edit_author {
  my $self = shift;
  my $id   = $self->param('id');

  my $dbh = $self->app->db;
  my $author = $self->app->repo->getAuthorsRepository->find( sub { $_->id == $id } );

# redirect to master if master is defined for this author
# if( defined $author and $author->{id} != $author->{master_id} ){
#     $self->redirect_to( $self->url_for('edit_author', id=>$author->{master_id}) );
#     return;
# }


  if ( !defined $author ) {
    $self->flash( msg => "Author with id $id does not exist!", msg_type => "danger" );
    $self->redirect_to( $self->url_for('all_authors') );
  }
  else {

    my @all_teams    = $self->app->repo->getTeamsRepository->all;
    my @author_teams = $author->get_teams;
    my @author_tags  = $author->get_tags;

    # cannot use objects as keys due to hash stringification!
    my %author_teams_hash = map { $_->id => 1 } @author_teams;
    my @unassigned_teams = grep { not $author_teams_hash{ $_->id } } @all_teams;


    my @minor_authors = $self->app->repo->getAuthorsRepository->filter( sub { $_->is_minion_of($author) } );

    # $author->all_author_user_ids($dbh);

    $self->stash(
      author           => $author,
      minor_authors    => \@minor_authors,
      teams            => \@author_teams,
      exit_code        => '',
      tags             => \@author_tags,
      all_teams        => \@all_teams,
      unassigned_teams => \@unassigned_teams
    );
    $self->render( template => 'authors/edit_author' );
  }
}
##############################################################################################################
sub add_to_team {
  my $self      = shift;
  my $dbh       = $self->app->db;
  my $master_id = $self->param('id');
  my $team_id   = $self->param('tid');

  my $author = $self->app->repo->getAuthorsRepository->find( sub { $_->id == $master_id } );
  my $team   = $self->app->repo->getTeamsRepository->find( sub   { $_->id == $team_id } );

  if ( defined $author and defined $team ) {
    my $membership = Membership->new(
      author    => $author->get_master,
      team      => $team,
      author_id => $author->get_master->id,
      team_id   => $team->id
    );
    $self->app->repo->getMembershipsRepository->save($membership);
    $team->add_membership($membership);
    $author->add_membership($membership);

    $self->flash(
      msg      => "Author <b>" . $author->uid . "</b> has just joined team <b>" . $team->name . "</b>",
      msg_type => "success"
    );
  }
  else {
    $self->flash( msg => "Author or team does does not exist!", msg_type => "danger" );
  }
  $self->redirect_to( $self->get_referrer );
}
##############################################################################################################
sub remove_from_team {
  my $self      = shift;
  my $dbh       = $self->app->db;
  my $master_id = $self->param('id');
  my $team_id   = $self->param('tid');

  my $author = $self->app->repo->getAuthorsRepository->find( sub { $_->id == $master_id } );
  my $team   = $self->app->repo->getTeamsRepository->find( sub   { $_->id == $team_id } );

  if ( defined $author and defined $team ) {
    my $membership = $author->memberships_find(sub { $_->team->equals($team) });
    $author->remove_membership($membership);
    $team->remove_membership($membership);
    $self->app->repo->getMembershipsRepository->delete($membership);

    $self->flash(
      msg      => "Author <b>" . $author->uid . "</b> has just left team <b>" . $team->name . "</b>",
      msg_type => "success"
    );
  }
  else {
    $self->flash( msg => "Author or team does does not exist!", msg_type => "danger" );
  }
  $self->redirect_to( $self->get_referrer );
}
##############################################################################################################
sub remove_uid {
  my $self      = shift;
  my $dbh       = $self->app->db;
  my $master_id = $self->param('masterid');
  my $minor_id  = $self->param('uid');
 

  my $author_master = $self->app->repo->getAuthorsRepository->find( sub { $_->id == $master_id } );
  my $author_minor  = $self->app->repo->getAuthorsRepository->find( sub { $_->id == $minor_id } );

  if ( !defined $author_minor ) {
    $self->flash( msg => "Cannot remove user_id $minor_id. Reason: such author deos not exist.", msg_type => "danger" );
  }
  elsif ( $author_minor->is_master ) {
    $self->flash( msg => "Cannot remove user_id $minor_id. Reason: it is a master_id.", msg_type => "danger" );
  }
  else {

    my @all_entries = $author_master->entries();
    $author_minor->remove_master();
    $self->app->repo->getAuthorsRepository->save($author_minor);

# authors are uncnnected now
# ON UPDATE CASCADE has removed all entreis from $author_master and assigned them to $author_minor
# All entries of the $author_master from before seperation needs be updated
# The $author_minor comes back to the list of all authors and it keeps its entries.

    my $storage = StorageBase->get();
    foreach my $e (@all_entries) {

      # 0 = no creation of new authors
      $storage->add_entry_authors( $e, 0 );
    }
  }
  $self->redirect_to( $self->get_referrer );
}
##############################################################################################################
sub merge_authors {
  my $self           = shift;
  my $dbh            = $self->app->db;
  my $destination_id = $self->param('author_to');
  my $source_id      = $self->param('author_from');

  my $storage            = StorageBase->get();
  my $author_destination = $storage->find_author_by_id_or_name($destination_id);
  my $author_source      = $storage->find_author_by_id_or_name($source_id);

  my $copy_name = $author_source->{uid};

  my $success = 0;

  if ( defined $author_source and defined $author_destination ) {
    if ( $author_destination->can_merge_authors($author_source) ) {

      $author_destination->merge_authors($author_source);
      $author_destination->save($dbh);
      $author_source->save($dbh);

      $self->flash(
        msg =>
          "Authors merged. <strong>$copy_name</strong> was merged into <strong>$author_destination->{master}</strong>.",
        msg_type => "success"
      );
    }
    else {
      $self->flash( msg => "Author cannot be merged with its self. ", msg_type => "danger" );
    }

  }
  else {
    $self->flash( msg => "Authors cannot be merged. Some of authors does not exist.", msg_type => "danger" );
  }

  $self->redirect_to( $self->get_referrer );
}


##############################################################################################################
sub edit_post {
  my $self        = shift;
  my $dbh         = $self->app->db;
  my $id          = $self->param('id');
  my $new_master  = $self->param('new_master');
  my $new_user_id = $self->param('new_user_id');
  my $visibility  = $self->param('visibility');

  my $author = $self->app->repo->getAuthorsRepository->find( sub { $_->id == $id } );

  if ( defined $author ) {
    if ( defined $new_master ) {

      my $existing = $self->app->repo->getAuthorsRepository->find( sub { ( $_->master cmp $new_master ) == 0 } );

      if ( !defined $existing ) {
        $author->update_master_name($new_master);
        $self->app->repo->getAuthorsRepository->save($author);
        $self->flash( msg => "Master name has been updated sucesfully.", msg_type => "success" );
        $self->redirect_to( $self->url_for( 'edit_author', id => $author->id ) );
      }
      else {

        $self->flash(
          msg => "This master name is already taken by <a href=\""
            . $self->url_for( 'edit_author', id => $existing->id ) . "\">"
            . $existing->master . "</a>.",
          msg_type => "danger"
        );
        $self->redirect_to( $self->url_for( 'edit_author', id => $id ) );
      }


    }
    elsif ( defined $visibility ) {
      $author->toggle_visibility;
      $self->app->repo->getAuthorsRepository->save($author);
    }
    elsif ( defined $new_user_id ) {

      my $existing_author = $self->app->repo->getAuthorsRepository->find( sub { $_->uid eq $new_user_id } );

      if ( defined $existing_author ) {
        $self->flash(
          msg      => "Cannot add user ID $new_user_id. Such ID already exist. Maybe you wan to merge authors?",
          msg_type => "warning"
        );
      }
      else {
        my $minion
          = Author->new( uid => $new_user_id, idProvider => $self->app->repo->getAuthorsRepository->getIdProvider );
        $minion->id;
        $author->add_minion($minion);
        $self->app->repo->getAuthorsRepository->save($author);
        $self->app->repo->getAuthorsRepository->save($minion);
      }
    }
  }
  $self->redirect_to( $self->url_for( 'edit_author', id => $id ) );
}
##############################################################################################################
sub post_edit_membership_dates {
  my $self      = shift;
  my $dbh       = $self->app->db;
  my $master_id = $self->param('aid');
  my $team_id   = $self->param('tid');
  my $new_start = $self->param('new_start');
  my $new_stop  = $self->param('new_stop');

  my $author = $self->app->repo->getAuthorsRepository->find( sub { $_->id == $master_id } );
  my $team   = $self->app->repo->getTeamsRepository->find( sub   { $_->id == $team_id } );

  if ( $author and $team ) {
    my $membership = $self->app->repo->getMembershipsRepository->find(
      sub {
        $_->author->equals($author) and $_->team->equals($team);
      }
    );
    $membership->start($new_start);
    $membership->stop($new_stop);
    $self->app->repo->getMembershipsRepository->update($membership);

    # $author->remove_membership($membership);
    # $team->remove_membership($membership);

    $self->flash( msg => "Membership updated successfully.", msg_type => "success" );
    $self->redirect_to( $self->url_for( 'edit_author', id => $author->id ) );
    return;
  }
  
  $self->flash( msg => "Cannot update membership: author or team not found.", msg_type => "danger" );
  $self->redirect_to( $self->get_referrer );

}
##############################################################################################################
sub delete_author {
  my $self = shift;
  my $dbh  = $self->app->db;
  my $id   = $self->param('id');

  my $author = $self->app->repo->getAuthorsRepository->find( sub { $_->{id} == $id } );

  if ( $author and $author->can_be_deleted() ) {
    $self->delete_author_force();
  }
  else {
    $self->flash( msg => "Cannot delete author ID $id.", msg_type => "danger" );
  }

  $self->redirect_to( $self->url_for('all_authors') );

}
##############################################################################################################
sub delete_author_force {
  my $self = shift;
  my $dbh  = $self->app->db;
  my $id   = $self->param('id');

  my $author = $self->app->repo->getAuthorsRepository->find( sub { $_->{id} == $id } );

  if ($author) {

    ## TODO: refactor these blocks nicely!

    ## Deleting memberships
    my @memberships = $author->memberships_all;
    # for each team, remove membership in this team
    foreach my $membership ( @memberships ){
        $membership->team->remove_membership($membership);
    }
    $self->app->repo->getMembershipsRepository->delete(@memberships);
    # remove all memberships for this team
    $author->memberships_clear;

    ## Deleting authorships
    my @authorships = $author->authorships_all;
    # for each team, remove authorship in this team
    foreach my $authorship ( @authorships ){
        $authorship->entry->remove_authorship($authorship);
    }
    $self->app->repo->getAuthorshipsRepository->delete(@authorships);
    # remove all authorships for this team
    $author->authorships_clear;

    # finally delete author
    $self->app->repo->getAuthorsRepository->delete($author);

    $self->write_log( "Author " . $author->uid . " ID $id has been deleted." );
    $self->flash( msg => "Author " . $author->uid . " ID $id removed successfully.", msg_type => "success" );
  }
  else {
    $self->flash( msg => "Cannot delete author ID $id.", msg_type => "danger" );
  }


  $self->redirect_to( $self->url_for('all_authors') );

}
##############################################################################################################
sub reassign_authors_to_entries {
  my $self = shift;
  my $create_new = shift // 0;

  my @all_entries         = $self->app->repo->getEntriesRepository->all;
  my $num_authors_created = 0;
  foreach my $entry (@all_entries) {
    next unless defined $entry;
    $self->app->logger->debug( "Reassignning authors for entry " . $entry->id );

    my @bibtex_author_name = $entry->author_names_from_bibtex();

    for my $author_name (@bibtex_author_name) {

      my $author = $self->app->repo->getAuthorsRepository->find( sub { $_->uid eq $author_name } );
      $self->app->logger->debug( "\t found " . $author->uid ) if defined $author;
      $self->app->logger->debug( "\t NOT found " . $author_name ) unless defined $author;

      if ( $create_new == 1 and !defined $author ) {
        $author
          = Author->new( idProvider => $self->app->repo->getAuthorsRepository->getIdProvider, uid => $author_name );
        $self->app->repo->getAuthorsRepository->save($author);
        $self->app->logger->debug( "\t CREATED " . $author->uid );
        ++$num_authors_created;
      }
      if ( defined $author ) {
        my $authorship = Authorship->new(
          author    => $author->get_master,
          entry     => $entry,
          author_id => $author->get_master->id,
          entry_id  => $entry->id
        );
        $self->app->repo->getAuthorshipsRepository->save($authorship);
        $entry->add_authorship($authorship);
        $author->add_authorship($authorship);
      }
    }
  }
  $self->flash( msg =>
      "Reassignment with author creation has finished. $num_authors_created authors have been created or assigned." );
  $self->redirect_to( $self->get_referrer );
}
##############################################################################################################
sub reassign_authors_to_entries_and_create_authors {
  my $self = shift;
  $self->reassign_authors_to_entries(1);
}

##############################################################################################################

sub toggle_visibility {
  my $self = shift;
  my $id   = $self->param('id');

  my $author = $self->app->repo->getAuthorsRepository->find( sub { $_->id == $id } );
  $author->toggle_visibility();
  $self->app->repo->getAuthorsRepository->update($author);
  $self->redirect_to( $self->get_referrer );
}

##############################################################################################################

1;
