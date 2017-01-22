package BibSpace::Controller::Tags;

use strict;
use warnings;
use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010;           #because of ~~
use DBI;
use Scalar::Util qw(looks_like_number);
use List::MoreUtils qw(any uniq);

use BibSpace::Controller::Core;
use BibSpace::Functions::FPublications;
use BibSpace::Model::M::MTagCloud;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;

####################################################################################

sub index {
  my $self   = shift;
  my $dbh    = $self->app->db;
  my $letter = $self->param('letter');
  my $type   = $self->param('type') // 1;

  my @all_tags = $self->app->repo->getTagsRepository->filter( sub { $_->type == $type } );
  my @tags = @all_tags;
  if ( defined $letter ) {
    @tags = grep { ( substr( $_->name, 0, 1 ) cmp $letter ) == 0 } @all_tags;
  }
  my @letters_arr = map { substr( $_->name, 0, 1 ) } @all_tags;
  @letters_arr = uniq @letters_arr;
  @letters_arr = sort @letters_arr;
  @tags        = sort { $a->name cmp $b->name } @tags;

  $self->stash( otags => \@tags, type => $type, letters_arr => \@letters_arr );
  $self->render( template => 'tags/tags' );
}

####################################################################################
sub add {
  my $self = shift;
  my $dbh  = $self->app->db;
  my $type = $self->param('type') // 1;

  $self->render( template => 'tags/add', type => $type );
}

####################################################################################
sub add_post {
  my $self        = shift;
  my $type        = $self->param('type') // 1;
  my $tags_to_add = $self->param('new_tag');


  my @tags;
  my @tag_names;
  if ( defined $tags_to_add ) {
    my @pre_tag_names = split( ';', $tags_to_add );
    foreach my $tag (@pre_tag_names) {
      $tag = clean_tag_name($tag);

      if ( defined $tag and $tag ne '' and length($tag) > 0 ) {
        push @tag_names, $tag if defined $tag;
      }
    }
    foreach my $tag_name (@tag_names) {
      my $new_tag = Tag->new( idProvider => $self->app->repo->getTagsRepository->getIdProvider, name => $tag_name,
        type => $type );
      $self->app->repo->getTagsRepository->save($new_tag);
      $self->app->logger->info("Added new tag $tag_name.");
      push @tags, $new_tag;

    }
  }


  $self->flash( msg => "The following tags (of type $type) were added successfully: " . " <i>"
      . join( ", ", map { $_->name } @tags )
      . "</i> ,"
      . " ids: <i>"
      . join( ", ", map { $_->id } @tags )
      . "</i>" )
    if scalar @tags > 0;

  $self->redirect_to( $self->url_for( 'all_tags', type => $type ) );

  # $self->render(template => 'tags/add');
}

####################################################################################

sub edit {
  my $self = shift;
  my $id   = $self->param('id');

  my $new_name      = $self->param('new_tag')       || undef;
  my $new_permalink = $self->param('new_permalink') || undef;
  my $new_type      = $self->param('new_type')      || undef;
  my $saved         = 0;

  my $tag = $self->app->repo->getTagsRepository->find( sub { $_->id == $id } );

  $tag->name($new_name)           if defined $new_name;
  $tag->permalink($new_permalink) if defined $new_permalink;
  $tag->type($new_type)           if defined $new_type;

  $self->app->repo->getTagsRepository->update($tag);

  $self->flash( msg_type => 'success', msg => 'Changes saved.' );

  $self->stash( tagobj => $tag );
  $self->render( template => 'tags/edit' );

}

####################################################################################
sub get_authors_for_tag_read {
  my $self    = shift;
  my $dbh     = $self->app->db;
  my $tag_id  = $self->param('tid');
  my $team_id = $self->param('team');

  my $tag = $self->app->repo->getTagsRepository->find( sub { $_->id == $tag_id } );
  if( !$tag ){
    $tag  = $self->app->repo->getTagsRepository->find( sub { $_->name eq $tag_id } );
  }
  my $team = $self->app->repo->getTeamsRepository->find( sub { $_->id == $team_id } );
  if( !$team ){
    $team = $self->app->repo->getTeamsRepository->find( sub { $_->name eq $team_id } );
  }

  if ( !defined $tag ) {
    $self->render( text => "Tag $tag_id does not exist", status => 404 );
    return;
  }
  if ( defined $team_id and !defined $team ) {
    $self->render( text => "Team $team_id does not exist", status => 404 );
    return;
  }

  my @authors = $tag->get_authors($dbh);
  @authors = grep {$_->has_team($team)} @authors;

  $self->stash( tag => $tag, authors => \@authors );
  $self->render( template => 'tags/authors_having_tag_read' );
}
####################################################################################
sub get_tags_for_author_read {
  my $self      = shift;
  my $author_id = $self->param('author_id');

  my $author = $self->app->repo->getAuthorsRepository->find( sub { $_->id == $author_id } );
  if( !$author ){
    $author  = $self->app->repo->getAuthorsRepository->find( sub { $_->get_master->uid eq $author_id } );
  }
  if( !$author ){
    $author  = $self->app->repo->getAuthorsRepository->find( sub { $_->uid eq $author_id } );
  }

  my @author_tags = $author->tags;


  ### here list of objects should be created

  my @tagc_cloud_arr;
  my @sorted_tagc_cloud_arr;

  foreach my $tag (@author_tags) {


    my $tag_name = $tag->{name};
    $tag_name =~ s/_/\ /g;
    my @objs = Fget_publications_main_hashed_args( $self, { hidden => 0, author => $author->{id}, tag => $tag->{id} } );
    my $count = scalar @objs;

    my $url
      = $self->url_for('lyp')->query( author => $author->{master}, tag => $tag_name, title => '1', navbar => '1' );

    my $tag_cloud_obj = MTagCloud->new();
    $tag_cloud_obj->{tag}   = $tag->{name};
    $tag_cloud_obj->{url}   = $url;
    $tag_cloud_obj->{count} = $count;
    $tag_cloud_obj->{name}  = $tag_name;

    push @tagc_cloud_arr, $tag_cloud_obj;
  }

  @sorted_tagc_cloud_arr = reverse sort { $a->{count} <=> $b->{count} } @tagc_cloud_arr;

  ### old code

  $self->stash( tags => \@author_tags, author => $author, tcarr => \@sorted_tagc_cloud_arr );
  $self->render( template => 'tags/author_tags_read' );

}
####################################################################################
sub get_tags_for_team_read {
  my $self    = shift;
  my $team_id = $self->param('tid');

  my $team = $self->app->repo->getTeamsRepository->filter( sub { $_->id == $team_id } );
  if ( !defined $team ) {
    $team = $self->app->repo->getTeamsRepository->filter( sub { $_->name eq $team_id } );
  }
  if ( !defined $team ) {
    $self->render( text => 'Team does not exist.', status => 404 );
    return;
  }

  my @members = map { $_->author } $team->memberships_all;
  my @team_tags;
  foreach my $member (@members) {
    my @papers = map { $_->entry } $member->authorships_all;
    foreach my $paper (@papers) {
      my @subset_tags = map { $_->tag } $paper->labelings_all;
      push @subset_tags, @team_tags;
    }
  }


  my @tagc_cloud_arr;
  my @sorted_tagc_cloud_arr;

  foreach my $tag (@team_tags) {
    my $tag_name = $tag->name;
    $tag_name =~ s/_/\ /g;

    my $url = $self->url_for('lyp')->query( team => $team->name, tag => $tag_name, title => '1', navbar => '1' );

    my $tag_cloud_obj = MTagCloud->new(
      tag   => $tag->name,
      url   => $url,
      count => "-1",         # FIXME!
      name  => $tag_name,
    );
    push @tagc_cloud_arr, $tag_cloud_obj;
  }

  @sorted_tagc_cloud_arr = reverse sort { $a->{count} <=> $b->{count} } @tagc_cloud_arr;

  ### old code

  $self->stash( tags => \@team_tags, author => $team, tcarr => \@sorted_tagc_cloud_arr );
  $self->render( template => 'tags/author_tags_read' );

}
####################################################################################
sub get_authors_for_tag {
  my $self = shift;
  my $id   = $self->param('tid');

  my $tag = $self->app->repo->getTagsRepository->find( sub { $_->id == $id } );
  if ( !defined $tag ) {
    $self->render( text => 'Tag does not exist.', status => 404 );
    return;
  }

  my @papers = map { $_->entry } $tag->labelings_all;
  my @authors;
  foreach my $paper (@papers) {
    my @subset_authors = map { $_->author } $paper->authorships_all;
    push @subset_authors, @authors;
  }

  $self->stash( tag => $tag, authors => \@authors );
  $self->render( template => 'tags/authors_having_tag' );
}
####################################################################################

sub delete {
  my $self = shift;
  my $id   = $self->param('id');

  my $tag = $self->app->repo->getTagsRepository->find( sub { $_->id == $id } );
  if ($tag) {
    my $name = $tag->name;

    ## TODO: refactor these blocks nicely!
    ## Deleting labelings
    my @labelings = $tag->labelings_all;
    # for each entry, remove labeling in this team
    foreach my $labeling ( @labelings ){
        $labeling->entry->remove_labeling($labeling);
    }
    $self->app->repo->getLabelingsRepository->delete(@labelings);
    # remove all labelings for this team
    $tag->labelings_clear;
    # finally delete tag
    $self->app->repo->getTagsRepository->delete($tag);

    $self->flash( msg_type => 'success', msg => "Tag $name has been deleted." );
    $self->app->logger->info("Tag $name has been deleted.");
  }
  else {
    $self->flash( msg_type => 'danger', msg => "Tag $id can not be deleted." );
  }

  $self->redirect_to( $self->get_referrer );
}
####################################################################################
1;
