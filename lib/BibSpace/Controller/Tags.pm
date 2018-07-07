package BibSpace::Controller::Tags;

use strict;
use warnings;
use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;

# use File::Slurp;

use v5.16;           #because of ~~

use Scalar::Util qw(looks_like_number);
use List::MoreUtils qw(any uniq);

use BibSpace::Functions::Core;
use BibSpace::Functions::FPublications;
use BibSpace::Model::TagCloud;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;

sub index {
  my $self   = shift;
  my $dbh    = $self->app->db;
  my $letter = $self->param('letter');
  my $type   = $self->param('type') // 1;

  my @all_tags = $self->app->repo->tags_filter(sub { $_->type == $type });
  my @tags = @all_tags;
  if (defined $letter) {
    @tags = grep { (substr($_->name, 0, 1) cmp $letter) == 0 } @all_tags;
  }
  my @letters_arr = map { substr($_->name, 0, 1) } @all_tags;
  @letters_arr = uniq @letters_arr;
  @letters_arr = sort @letters_arr;
  @tags        = sort { $a->name cmp $b->name } @tags;

  $self->stash(otags => \@tags, type => $type, letters_arr => \@letters_arr);
  $self->render(template => 'tags/tags');
}

sub add {
  my $self = shift;
  my $dbh  = $self->app->db;
  my $type = $self->param('type') // 1;

  $self->render(template => 'tags/add', type => $type);
}

sub add_post {
  my $self        = shift;
  my $tag_type    = $self->param('type') // 1;
  my $tags_to_add = $self->param('new_tag');

  my @tags;
  my @tag_names;
  if (defined $tags_to_add) {
    my @pre_tag_names = split(';', $tags_to_add);
    foreach my $tag (@pre_tag_names) {
      $tag = clean_tag_name($tag);

      if (defined $tag and $tag ne '' and length($tag) > 0) {
        push @tag_names, $tag if defined $tag;
      }
    }
    foreach my $tag_name (@tag_names) {
      my $new_tag = $self->app->entityFactory->new_Tag(
        name => $tag_name,
        type => $tag_type
      );

      $self->app->repo->tags_save($new_tag);
      $self->app->logger->info("Added new tag '$tag_name' type '$tag_type'.");
      push @tags, $new_tag;

    }
  }

  $self->flash(
    msg => "The following tags (of type $tag_type) were added successfully: "
      . " <i>"
      . join(", ", map { $_->name } @tags)
      . "</i> ,"
      . " ids: <i>"
      . join(", ", map { $_->id } @tags) . "</i>")
    if scalar @tags > 0;

  $self->redirect_to($self->url_for('all_tags', type => $tag_type));

  # $self->render(template => 'tags/add');
}

sub edit {
  my $self = shift;
  my $id   = $self->param('id');

  my $new_name      = $self->param('new_tag')       || undef;
  my $new_permalink = $self->param('new_permalink') || undef;
  my $new_type      = $self->param('new_type')      || undef;
  my $saved         = 0;

  my $tag = $self->app->repo->tags_find(sub { $_->id == $id });

  $tag->name($new_name)           if defined $new_name;
  $tag->permalink($new_permalink) if defined $new_permalink;
  $tag->type($new_type)           if defined $new_type;

  $self->app->repo->tags_update($tag);

  $self->flash(msg_type => 'success', msg => 'Changes saved.');

  $self->stash(tagobj => $tag);
  $self->render(template => 'tags/edit');

}

sub get_authors_for_tag_and_team {
  my $self    = shift;
  my $dbh     = $self->app->db;
  my $tag_id  = $self->param('tag_id');
  my $team_id = $self->param('team_id');

  my $tag = $self->app->repo->tags_find(sub { $_->id == $tag_id });
  if (!$tag) {
    $tag = $self->app->repo->tags_find(sub { $_->name eq $tag_id });
  }
  my $team = $self->app->repo->teams_find(sub { $_->id == $team_id });
  if (!$team) {
    $team = $self->app->repo->teams_find(sub { $_->name eq $team_id });
  }

  if (!defined $tag) {
    $self->render(text => "Tag $tag_id does not exist", status => 404);
    return;
  }
  if ((defined $team_id) and (!defined $team)) {
    $self->render(text => "Team $team_id does not exist", status => 404);
    return;
  }

  my @authors = $tag->get_authors($dbh);
  @authors = grep { $_->has_team($team) } @authors;

  $self->stash(tag => $tag, authors => \@authors);
  $self->render(template => 'tags/authors_having_tag_read');
}

sub get_tags_for_author_read {
  my $self      = shift;
  my $author_id = $self->param('author_id');

  my $author = $self->app->repo->authors_find(sub { $_->id == $author_id });
  if (!$author) {
    $author
      = $self->app->repo->authors_find(sub { $_->get_master->uid eq $author_id }
      );
  }
  if (!$author) {
    $author = $self->app->repo->authors_find(sub { $_->uid eq $author_id });
  }

  if (!$author) {
    $self->render(text => "Cannot find author $author_id.", status => 404);
    return;
  }

  my @author_tags = $author->get_tags;

  if (!@author_tags) {
    $self->render(
      text   => "Author $author_id has no tagged papers.",
      status => 200
    );
    return;
  }

  ### here list of objects should be created

  my @tagc_cloud_arr;
  my @sorted_tagc_cloud_arr;

  foreach my $tag (@author_tags) {

    my $tag_name = $tag->{name};
    $tag_name =~ s/_/\ /g;
    my @objs = Fget_publications_main_hashed_args($self,
      {hidden => 0, author => $author->{id}, tag => $tag->{id}});
    my $count = scalar @objs;

    my $url = $self->url_for('lyp')->query(
      author => $author->{master},
      tag    => $tag_name,
      title  => '1',
      navbar => '1'
    );

    my $tag_cloud_obj = TagCloud->new();
    $tag_cloud_obj->{url}   = $url;
    $tag_cloud_obj->{count} = $count;
    $tag_cloud_obj->{name}  = $tag_name;

    push @tagc_cloud_arr, $tag_cloud_obj;
  }

  @sorted_tagc_cloud_arr
    = reverse sort { $a->{count} <=> $b->{count} } @tagc_cloud_arr;

  ### old code

  $self->stash(
    tags   => \@author_tags,
    author => $author,
    tcarr  => \@sorted_tagc_cloud_arr
  );
  $self->render(template => 'tags/author_tags_read');

}

# we mean here tags of type 1
sub get_tags_for_team_read {
  my $self     = shift;
  my $team_id  = $self->param('team_id');
  my $tag_type = 1;

  my $team = $self->app->repo->teams_find(sub { $_->id == $team_id });
  $team ||= $self->app->repo->teams_find(sub { $_->name eq $team_id });

  if (!$team) {
    $self->render(
      text   => "404. Team '$team_id' does not exist.",
      status => 404
    );
    return;
  }

  my @team_entries = grep { $_->has_team($team) } $self->app->repo->entries_all;
  my %team_tags_hash;
  foreach my $paper (@team_entries) {

    # merge two hashes
    %team_tags_hash = (%team_tags_hash,
      map { "" . $_->name => $_ } $paper->get_tags($tag_type));
  }
  my @team_tags = values %team_tags_hash;

  if (!@team_tags) {
    $self->render(
      text   => "Team '$team_id' has no tagged papers.",
      status => 200
    );
    return;
  }

  my @tagc_cloud_arr;
  my @sorted_tagc_cloud_arr;

  foreach my $tag (@team_tags) {
    my $tag_name = $tag->name;
    $tag_name =~ s/_/\ /g;

    # FIXME: not all papers belong to team
    # FIXME: take exceptions into account
    my @papers = grep { $_->has_team($team) } $tag->get_entries;

    my $url = ""
      . $self->url_for('lyp')->query(
      team   => $team->name,
      tag    => $tag->name,
      title  => '1',
      navbar => '1'
      );

    my $tag_cloud_obj = TagCloud->new(
      url   => $url,
      count => "" . scalar(@papers),
      name  => $tag_name,
    );
    push @tagc_cloud_arr, $tag_cloud_obj;
  }

  @sorted_tagc_cloud_arr
    = reverse sort { $a->count <=> $b->count or $b->name cmp $a->name }
    @tagc_cloud_arr;

  $self->stash(tcarr => \@sorted_tagc_cloud_arr);
  $self->render(template => 'tags/author_tags_read');

}

sub get_authors_for_tag {
  my $self   = shift;
  my $tag_id = $self->param('id');

  my $tag = $self->app->repo->tags_find(sub { $_->id == $tag_id });
  if (!defined $tag) {
    $self->render(text => "404. Tag '$tag_id' does not exist.", status => 404);
    return;
  }

  my @papers = map { $_->entry } $tag->labelings_all;
  my @authors;
  foreach my $paper (@papers) {
    my @subset_authors = map { $_->author } $paper->authorships_all;
    push @subset_authors, @authors;
  }
  if (!@authors) {
    $self->render(
      text   => "There are no authors having papers with tag $tag_id.",
      status => 200
    );
    return;
  }

  $self->stash(tag => $tag, authors => \@authors);
  $self->render(template => 'tags/authors_having_tag');
}

sub delete {
  my $self = shift;
  my $id   = $self->param('id');

  my $tag = $self->app->repo->tags_find(sub { $_->id == $id });
  if ($tag) {
    my $name = $tag->name;

    ## TODO: refactor these blocks nicely!
    ## Deleting labelings
    my @labelings = $tag->labelings_all;

    # for each entry, remove labeling in this team
    foreach my $labeling (@labelings) {
      $labeling->entry->remove_labeling($labeling);
    }
    $self->app->repo->labelings_delete(@labelings);

    # remove all labelings for this team
    $tag->labelings_clear;

    # finally delete tag
    $self->app->repo->tags_delete($tag);

    $self->flash(msg_type => 'success', msg => "Tag $name has been deleted.");
    $self->app->logger->info("Tag $name has been deleted.");
  }
  else {
    $self->flash(msg_type => 'danger', msg => "Tag $id can not be deleted.");
  }

  $self->redirect_to($self->get_referrer);
}

1;
