package BibSpace::Controller::Authors;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use Try::Tiny;

# use File::Slurp;

use v5.16;           #because of ~~
use strict;
use warnings;

use List::MoreUtils qw(any uniq);

use BibSpace::Functions::Core;
use BibSpace::Controller::Publications;

use BibSpace::Functions::FPublications;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';

sub all_authors {    # refactored
  my $self    = shift;
  my $visible = $self->param('visible');
  my $search  = $self->param('search');
  my $letter  = $self->param('letter');

  my @authors = $self->app->repo->authors_all;
  if (defined $visible) {
    @authors = grep { $_->display == $visible } @authors;
  }

  @authors = grep { $_->is_master } @authors;

  if ($letter) {
    @authors = grep { (substr($_->master, 0, 1) cmp $letter) == 0 } @authors;
  }
  my @letters;
  if (defined $visible) {
    @letters = map { substr($_->master, 0, 1) }
      $self->app->repo->authors_filter(sub { $_->display == $visible });
  }
  else {
    @letters = map { substr($_->master, 0, 1) } $self->app->repo->authors_all;
  }
  @letters = uniq @letters;
  @letters = sort @letters;

  @authors = sort { $a->uid cmp $b->uid } @authors;

  $self->stash(
    authors         => \@authors,
    letters         => \@letters,
    selected_letter => $letter,
    visible         => $visible
  );

  $self->render(template => 'authors/authors');
}

sub add_author {
  my $self = shift;

  $self->stash(master => '', id => '');
  $self->render(template => 'authors/add_author');
}

sub add_post {
  my $self       = shift;
  my $new_master = $self->param('new_master');

  if (defined $new_master and length($new_master) > 0) {

    my $author
      = $self->app->repo->authors_find(sub { $_->master eq $new_master });

    if (!defined $author) {    # no such user exists yet

      $author = $self->app->entityFactory->new_Author(uid => $new_master);
      $self->app->repo->authors_save($author);

      if (!defined $author->id) {
        $self->flash(
          msg_type => 'danger',
          msg =>
            "Error saving author. Saving to the database returned no insert row id."
        );
        $self->redirect_to($self->url_for('add_author'));
        return;
      }
      $self->app->logger->info(
        "Added new author with master: $new_master. Author id is "
          . $author->{id});
      $self->flash(msg_type => 'success', msg => "Author added successfully!");
      $self->redirect_to($self->url_for('edit_author', id => $author->{id}));
      return;
    }
    else {    # such user already exists!
      $self->app->logger->info(
        "Author with master: $new_master already exists!");
      $self->flash(
        msg_type => 'warning',
        msg =>
          "Author with proposed master: $new_master already exists! Pick a different one."
      );
      $self->redirect_to($self->url_for('add_author'));
      return;
    }
  }

  $self->flash(msg_type => 'warning', msg => "Bad input.");
  $self->redirect_to($self->url_for('add_author'));
}

sub edit_author {
  my $self = shift;
  my $id   = $self->param('id');

  my $author = $self->app->repo->authors_find(sub { $_->id == $id });

  if (!defined $author) {
    $self->flash(
      msg      => "Author with id $id does not exist!",
      msg_type => "danger"
    );
    $self->redirect_to($self->url_for('all_authors'));
  }
  else {

    my @all_teams    = $self->app->repo->teams_all;
    my @author_teams = $author->get_teams;
    my @author_tags  = $author->get_tags;

    # cannot use objects as keys due to hash stringification!
    my %author_teams_hash = map { $_->id => 1 } @author_teams;
    my @unassigned_teams = grep { not $author_teams_hash{$_->id} } @all_teams;

    my @minor_authors
      = $self->app->repo->authors_filter(sub { $_->is_minion_of($author) });

    # $author->all_author_user_ids($dbh);

    $self->stash(
      author           => $author,
      minor_authors    => \@minor_authors,
      teams            => \@author_teams,
      tags             => \@author_tags,
      all_teams        => \@all_teams,
      unassigned_teams => \@unassigned_teams
    );
    $self->render(template => 'authors/edit_author');
  }
}

sub add_to_team {
  my $self      = shift;
  my $master_id = $self->param('id');
  my $team_id   = $self->param('tid');

  my $author = $self->app->repo->authors_find(sub { $_->id == $master_id });
  my $team   = $self->app->repo->teams_find(sub   { $_->id == $team_id });

  if (defined $author and defined $team) {
    my $membership = Membership->new(
      author    => $author->get_master,
      team      => $team,
      author_id => $author->get_master->id,
      team_id   => $team->id
    );
    $self->app->repo->memberships_save($membership);
    $team->add_membership($membership);
    $author->add_membership($membership);

    $self->flash(
      msg => "Author <b>"
        . $author->uid
        . "</b> has just joined team <b>"
        . $team->name . "</b>",
      msg_type => "success"
    );
  }
  else {
    $self->flash(
      msg      => "Author or team does does not exist!",
      msg_type => "danger"
    );
  }
  $self->redirect_to($self->get_referrer);
}

sub remove_from_team {
  my $self      = shift;
  my $master_id = $self->param('id');
  my $team_id   = $self->param('tid');

  my $author = $self->app->repo->authors_find(sub { $_->id == $master_id });
  my $team   = $self->app->repo->teams_find(sub   { $_->id == $team_id });

  if (defined $author and defined $team) {
    my $membership = $author->memberships_find(sub { $_->team->equals($team) });
    $author->remove_membership($membership);
    $team->remove_membership($membership);
    $self->app->repo->memberships_delete($membership);

    $self->flash(
      msg => "Author <b>"
        . $author->uid
        . "</b> has just left team <b>"
        . $team->name . "</b>",
      msg_type => "success"
    );
  }
  else {
    $self->flash(
      msg      => "Author or team does does not exist!",
      msg_type => "danger"
    );
  }
  $self->redirect_to($self->get_referrer);
}

sub remove_uid {
  my $self      = shift;
  my $master_id = $self->param('masterid');
  my $minor_id  = $self->param('uid');

  my $author_master
    = $self->app->repo->authors_find(sub { $_->id == $master_id });
  my $author_minor
    = $self->app->repo->authors_find(sub { $_->id == $minor_id });

  if (!defined $author_minor) {
    $self->flash(
      msg =>
        "Cannot remove user_id $minor_id. Reason: such author deos not exist.",
      msg_type => "danger"
    );
  }
  elsif ($author_minor->is_master) {
    $self->flash(
      msg      => "Cannot remove user_id $minor_id. Reason: it is a master_id.",
      msg_type => "warning"
    );
  }
  else {

    my @master_entries = $author_master->get_entries;

    # remove master authorships from both authors
    foreach my $master_authorship ($author_master->authorships_all) {
      $author_master->remove_authorship($master_authorship);
      $author_minor->remove_authorship($master_authorship);

      $master_authorship->entry->remove_authorship($master_authorship);
      $self->app->repo->authorships_delete($master_authorship);
    }

    # remove minion authorships from both authors
    foreach my $minion_authorship ($author_minor->authorships_all) {
      $author_minor->remove_authorship($minion_authorship);
      $author_master->remove_authorship($minion_authorship);

      $minion_authorship->entry->remove_authorship($minion_authorship);
      $self->app->repo->authorships_delete($minion_authorship);
    }

    # unlink authors
    $author_minor->remove_master;

    # save changes (minor should be enough)
    $self->app->repo->authors_update($author_master);
    $self->app->repo->authors_update($author_minor);

    # calculate proper authorships automatically
    Freassign_authors_to_entries_given_by_array($self->app, 0,
      \@master_entries);

  }

  $self->redirect_to($self->get_referrer);
}

sub merge_authors {
  my $self           = shift;
  my $destination_id = $self->param('author_to');
  my $source_id      = $self->param('author_from');

  my $author_destination
    = $self->app->repo->authors_find(sub { $_->id == $destination_id });
  $author_destination
    ||= $self->app->repo->authors_find(sub { $_->uid eq $destination_id });

  my $author_source
    = $self->app->repo->authors_find(sub { $_->id == $source_id });
  $author_source
    ||= $self->app->repo->authors_find(sub { $_->uid eq $source_id });

  my $copy_name = $author_source->uid;

  my $success = 0;

  if (defined $author_source and defined $author_destination) {
    if ($author_destination->can_merge_authors($author_source)) {

      my @src_authorships = $author_source->authorships_all;
      foreach my $src_authorship (@src_authorships) {

        # Removing the authorship from the source author
        $src_authorship->author->remove_authorship($src_authorship);

        # authorships cannot be updated, so we need to delete and add later
        $self->app->repo->authorships_delete($src_authorship);

        # Changing the authorship to point to a new author
        $src_authorship->author($author_destination);

        # store changes the authorship in the repo
        $self->app->repo->authorships_save($src_authorship);

        # Adding the authorship to the new author
        $author_destination->add_authorship($src_authorship);
      }
      $author_source->memberships_clear;
      $author_source->set_master($author_destination);

      $self->app->repo->authors_save($author_destination);
      $self->app->repo->authors_save($author_source);

      my @entries = $author_destination->get_entries;
      Freassign_authors_to_entries_given_by_array($self->app, 0, \@entries);

      $self->flash(
        msg =>
          "Author <strong>$copy_name</strong> was merged into <strong>$author_destination->{master}</strong>.",
        msg_type => "success"
      );
    }
    else {
      $self->flash(
        msg      => "An author cannot be merged with its self. ",
        msg_type => "danger"
      );
    }

  }
  else {
    $self->flash(
      msg      => "Authors cannot be merged. One or both authors do not exist.",
      msg_type => "danger"
    );
  }

  $self->redirect_to($self->get_referrer);
}

sub edit_post {
  my $self        = shift;
  my $id          = $self->param('id');
  my $new_master  = $self->param('new_master');
  my $new_user_id = $self->param('new_user_id');
  my $visibility  = $self->param('visibility');

  my $author = $self->app->repo->authors_find(sub { $_->id == $id });

  if (defined $author) {
    if (defined $new_master) {

      my $existing = $self->app->repo->authors_find(
        sub { ($_->master cmp $new_master) == 0 });

      if (!defined $existing) {
        $author->update_master_name($new_master);
        $self->app->repo->authors_save($author);
        $self->flash(
          msg      => "Master name has been updated successfully.",
          msg_type => "success"
        );
        $self->redirect_to($self->url_for('edit_author', id => $author->id));
      }
      else {

        $self->flash(
          msg => "This master name is already taken by <a href=\""
            . $self->url_for('edit_author', id => $existing->id) . "\">"
            . $existing->master . "</a>.",
          msg_type => "danger"
        );
        $self->redirect_to($self->url_for('edit_author', id => $id));
      }

    }
    elsif (defined $visibility) {
      $author->toggle_visibility;
      $self->app->repo->authors_save($author);
    }
    elsif (defined $new_user_id) {

      my $existing_author
        = $self->app->repo->authors_find(sub { $_->uid eq $new_user_id });

      if (defined $existing_author) {
        $self->flash(
          msg =>
            "Cannot add user ID $new_user_id. Such ID already exist. Maybe you wan to merge authors?",
          msg_type => "warning"
        );
      }
      else {
        my $minion = $self->app->entityFactory->new_Author(uid => $new_user_id);
        $author->add_minion($minion);
        $self->app->repo->authors_save($author);
        $self->app->repo->authors_save($minion);
      }
    }
  }
  $self->redirect_to($self->url_for('edit_author', id => $id));
}

sub post_edit_membership_dates {
  my $self      = shift;
  my $master_id = $self->param('aid');
  my $team_id   = $self->param('tid');
  my $new_start = $self->param('new_start');
  my $new_stop  = $self->param('new_stop');

  my $author = $self->app->repo->authors_find(sub { $_->id == $master_id });
  my $team   = $self->app->repo->teams_find(sub   { $_->id == $team_id });

  if ($author and $team) {
    my $search_mem = Membership->new(
      author    => $author->get_master,
      team      => $team,
      author_id => $author->get_master->id,
      team_id   => $team->id
    );
    my $membership
      = $self->app->repo->memberships_find(sub { $_->equals($search_mem) });

    if ($membership) {

      $membership->start($new_start);
      $membership->stop($new_stop);
      $self->app->repo->memberships_update($membership);
      $self->flash(
        msg      => "Membership updated successfully.",
        msg_type => "success"
      );
    }
    else {
      $self->flash(msg => "Cannot find membership.", msg_type => "danger");
    }
    $self->redirect_to($self->url_for('edit_author', id => $author->id));
    return;
  }

  $self->flash(
    msg      => "Cannot update membership: author or team not found.",
    msg_type => "danger"
  );
  $self->redirect_to($self->get_referrer);

}

sub delete_author {
  my $self = shift;
  my $id   = $self->param('id');

  my $author = $self->app->repo->authors_find(sub { $_->{id} == $id });

  if ($author and $author->can_be_deleted()) {
    $self->delete_author_force();
  }
  else {
    $self->flash(msg => "Cannot delete author ID $id.", msg_type => "danger");
  }

  $self->redirect_to($self->url_for('all_authors'));

}

sub delete_author_force {
  my $self = shift;
  my $id   = $self->param('id');

  my $author = $self->app->repo->authors_find(sub { $_->{id} == $id });

  if ($author) {

    ## TODO: refactor these blocks nicely!

    ## Deleting memberships
    my @memberships = $author->memberships_all;

    # for each team, remove membership in this team
    foreach my $membership (@memberships) {
      $membership->team->remove_membership($membership);
    }
    $self->app->repo->memberships_delete(@memberships);

    # remove all memberships for this team
    $author->memberships_clear;

    ## Deleting authorships
    my @authorships = $author->authorships_all;

    # for each team, remove authorship in this team
    foreach my $authorship (@authorships) {
      $authorship->entry->remove_authorship($authorship);
    }
    $self->app->repo->authorships_delete(@authorships);

    # remove all authorships for this team
    $author->authorships_clear;

    # finally delete author
    $self->app->repo->authors_delete($author);

    $self->app->logger->info(
      "Author " . $author->uid . " ID $id has been deleted.");
    $self->flash(
      msg      => "Author " . $author->uid . " ID $id removed successfully.",
      msg_type => "success"
    );
  }
  else {
    $self->flash(msg => "Cannot delete author ID $id.", msg_type => "danger");
  }

  $self->redirect_to($self->url_for('all_authors'));
}

## do not use this on production! this is for making the tests faster!!
sub delete_invisible_authors {
  my $self = shift;

  my @authors = $self->app->repo->authors_filter(sub { !$_->is_visible });

  foreach my $author (@authors) {

    ## TODO: refactor these blocks nicely!

    ## Deleting memberships
    my @memberships = $author->memberships_all;

    # for each team, remove membership in this team
    foreach my $membership (@memberships) {
      $membership->team->remove_membership($membership);
    }
    $self->app->repo->memberships_delete(@memberships);

    # remove all memberships for this team
    $author->memberships_clear;

    ## Deleting authorships
    my @authorships = $author->authorships_all;

    # for each team, remove authorship in this team
    foreach my $authorship (@authorships) {

      # my $entry = $authorship->entry;
      $authorship->entry->remove_authorship($authorship);

      # $self->app->repo->entries_delete($entry);
    }
    $self->app->repo->authorships_delete(@authorships);

    # remove all authorships for this team
    $author->authorships_clear;

    # finally delete author
    $self->app->repo->authors_delete($author);

    $self->flash(msg => "Authors decimated! ", msg_type => "success");
  }

  $self->redirect_to($self->url_for('all_authors'));

}

sub reassign_authors_to_entries {
  my $self = shift;
  my $create_new = shift // 0;

  my @all_entries = $self->app->repo->entries_all;
  my $num_authors_created
    = Freassign_authors_to_entries_given_by_array($self->app, $create_new,
    \@all_entries);

  $self->flash(msg =>
      "Reassignment with author creation has finished. $num_authors_created authors have been created or assigned."
  );
  $self->redirect_to($self->get_referrer);
}

sub reassign_authors_to_entries_and_create_authors {
  my $self = shift;
  $self->reassign_authors_to_entries(1);
}

sub fix_masters {
  my $self = shift;

  my @all_authors = $self->app->repo->authors_all;

  my @broken_authors_0
    = grep { ($_->is_minion) and (!defined $_->masterObj) } @all_authors;

  # masterObj not set although it should be
  my @broken_authors_1
    = grep { (!defined $_->masterObj) and ($_->master_id != $_->id) }
    @all_authors;

  # masterObj set incorrectly
  my @broken_authors_2
    = grep { $_->masterObj and $_->master_id != $_->masterObj->id }
    @all_authors;

  my $num_fixes_0 = @broken_authors_0;
  my $num_fixes_1 = @broken_authors_1;
  my $num_fixes_2 = @broken_authors_2;

  my $msg_type
    = ($num_fixes_0 + $num_fixes_1 + $num_fixes_2) == 0 ? 'success' : 'danger';
  my $msg = "Analysis is finished. Authors broken: 
  <ul>
    <li>"
    . scalar(@broken_authors_0)
    . " of type 0 (is minion but master undefined)</li>
    <li>"
    . scalar(@broken_authors_1)
    . " of type 1 (masterObj not set although it should)</li>
    <li>"
    . scalar(@broken_authors_2) . " of type 2 (masterObj set incorrectly)</li>
  </ul>";

  # we cure all problems with the same medicine...
  foreach my $author ((@broken_authors_0, @broken_authors_1, @broken_authors_2))
  {
    my $master
      = $self->app->repo->authors_find(sub { $_->id == $author->master_id });
    if (defined $master) {
      $author->masterObj($master);
      ++$num_fixes_0;
      ++$num_fixes_1;
      ++$num_fixes_2;
    }
  }
  $msg
    .= "</br>Fixing is finished. Masters were re-added to the authors. Fixed: 
  <ul>
    <li>$num_fixes_0 of type 0 (is minion but master undefined)</li>
    <li>$num_fixes_1 of type 1 (masterObj not set although it should)</li>
    <li>$num_fixes_2 of type 2 (masterObj set incorrectly)</li>
  </ul>";

  $self->flash(msg => $msg, msg_type => $msg_type);
  $self->redirect_to($self->get_referrer);
}

sub toggle_visibility {
  my $self = shift;
  my $id   = $self->param('id');

  my $author = $self->app->repo->authors_find(sub { $_->id == $id });
  $author->toggle_visibility();
  $self->app->repo->authors_update($author);
  $self->redirect_to($self->get_referrer);
}

1;
