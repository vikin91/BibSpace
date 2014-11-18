package BibSpace::Controller::Tagtypes;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;

# use File::Slurp;

use v5.16;           #because of ~~
use strict;
use warnings;

use BibSpace::Functions::Core;
use BibSpace::Model::TagType;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;

sub index {
  my $self      = shift;
  my @tag_types = $self->app->repo->tagTypes_all;
  $self->render(template => 'tagtypes/tagtypes', tagtypes => \@tag_types);
}

sub add {
  my $self = shift;
  $self->render(template => 'tagtypes/add');
}

sub add_post {
  my $self    = shift;
  my $dbh     = $self->app->db;
  my $name    = $self->param('new_name');
  my $comment = $self->param('new_comment');

  my $tt = $self->app->repo->tagTypes_find(sub { $_->name eq $name });

  if (defined $tt) {
    $self->flash(
      msg_type => 'error',
      msg      => 'Tag type with such name already exists.'
    );
  }
  else {
    $tt = $self->app->entityFactory->new_TagType(
      name    => $name,
      comment => $comment
    );
    $self->app->repo->tagTypes_save($tt);
    $self->flash(msg_type => 'success', msg => 'Tag type added.');
  }

  $self->redirect_to($self->url_for('all_tag_types'));
}

sub delete {
  my $self = shift;
  my $id   = $self->param('id');

  # we do not allow to delete the two first tag types!
  if ($id == 1 or $id == 2) {
    $self->flash(
      msg_type => 'error',
      msg      => 'Tag Types 1 or 2 are essential and cannot be deleted.'
    );
    $self->redirect_to($self->url_for('all_tag_types'));
    return;
  }

  my $tt = $self->app->repo->tagTypes_find(sub { $_->id == $id });

  my @tags_of_tag_type = $self->app->repo->tags_filter(sub { $_->type == $id });
  $self->app->repo->tags_delete(@tags_of_tag_type);
  $self->app->repo->tagTypes_delete($tt);

  $self->flash(msg_type => 'success', msg => 'Tag type deleted.');

  $self->redirect_to($self->get_referrer);
}

sub edit {
  my $self = shift;
  my $id   = $self->param('id');

  my $name    = $self->param('new_name');
  my $comment = $self->param('new_comment');
  my $saved   = 0;

  my $tt = $self->app->repo->tagTypes_find(sub { $_->id == $id });

  if (!defined $tt) {
    $self->flash(msg_type => 'error', msg => 'Tag Type does not exist.');
    $self->redirect_to($self->url_for('all_tag_types'));
    return;
  }

  if (defined $name or defined $comment) {
    $tt->name($name)       if defined $name;
    $tt->comment($comment) if defined $comment;
    $self->app->repo->tagTypes_update($tt);

    $self->flash(msg_type => 'success', msg => 'Update successful.');
    $self->redirect_to($self->url_for('all_tag_types'));
    return;
  }
  else {
    $self->flash(
      msg_type => 'warning',
      msg      => 'No change made or empty input.'
    );
  }

  $self->stash(obj => $tt);
  $self->render(template => 'tagtypes/edit');

}

1;
