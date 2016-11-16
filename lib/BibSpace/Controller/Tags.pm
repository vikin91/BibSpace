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

use BibSpace::Controller::Core;
use BibSpace::Functions::TagTypeObj;

# use BibSpace::Controller::Set;
use BibSpace::Functions::FSet;
use BibSpace::Functions::FPublications;
use BibSpace::Functions::FTags;

use BibSpace::Model::MTag;
use BibSpace::Model::MTagCloud;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;

####################################################################################

sub index {
    my $self   = shift;
    my $dbh    = $self->app->db;
    my $letter = $self->param('letter') || '%';
    my $type   = $self->param('type') || 1;

    if ( $letter ne '%' ) {
        $letter .= '%';
    }

    my @all_with_letter
        = MTag->static_get_all_w_letter( $dbh, $type, $letter );
    my @letters_arr = get_first_letters( $self, $type );

    $self->stash(
        otags       => \@all_with_letter,
        type        => $type,
        letters_arr => \@letters_arr
    );
    $self->render( template => 'tags/tags' );
}

####################################################################################
sub get_first_letters {
    my $self = shift;
    my $dbh  = $self->app->db;
    my $type = shift || 1;

    my @all_tags = MTag->static_all($dbh);

    return sort { lc($a) cmp lc($b) } uniq map {ucfirst substr $_->{name}, 0, 1 } @all_tags;
}

####################################################################################
sub add {
    my $self = shift;
    my $dbh  = $self->app->db;
    my $type = $self->param('type') || 1;

    $self->render( template => 'tags/add', type => $type );
}

####################################################################################
sub add_post {
    my $self = shift;

    my $dbh = $self->app->db;
    my $type = $self->param('type') || 1;

    my $tags_to_add = $self->param('new_tag');
    my @tags = add_tags_from_string( $dbh, $tags_to_add, $type );


    $self->flash( msg =>
            "The following tags (of type $type) were added successfully: <i>$tags_to_add</i> , ids: <i>"
            . join( ", ", map { $_->{id} } @tags )
            . "</i>" ) if scalar @tags > 0;
    
    $self->write_log(
        "tags added: $tags_to_add, ids: " . join( ", ", map { $_->{id} } @tags ) );

    $self->redirect_to( $self->url_for( 'all_tags', type=>$type ) );

    # $self->render(template => 'tags/add');
}

####################################################################################

sub add_and_assign {
    my $self        = shift;
    my $tags_to_add = $self->param('new_tag');
    my $eid         = $self->param('eid');
    my $type        = $self->param('type') || 1;
    my $dbh         = $self->app->db;

    my @tags = add_tags_from_string( $dbh, $tags_to_add, $type);

    foreach my $tag (@tags) {
        my $entry = MEtnry->static_get($dbh, $eid);
        $entry->assign_tag($dbh, $tag) if defined $entry and defined $tag;
    }

    $self->redirect_to( $self->get_referrer );
}

####################################################################################

sub edit {
    my $self  = shift;
    my $dbh   = $self->app->db;
    my $tagid = $self->param('id');

    my $new_name      = $self->param('new_tag')       || undef;
    my $new_permalink = $self->param('new_permalink') || undef;
    my $new_type      = $self->param('new_type')      || undef;
    my $saved         = 0;

    # the tag as it is stored in the db

    my $mtag = MTag->static_get( $dbh, $tagid );

    $mtag->{name}      = $new_name      if defined $new_name;
    $mtag->{permalink} = $new_permalink if defined $new_permalink;
    $mtag->{type}      = $new_type      if defined $new_type;
    $saved             = $mtag->save($dbh);

    $self->stash( tagobj => $mtag, saved => $saved );
    $self->render( template => 'tags/edit' );

}

####################################################################################
sub get_authors_for_tag_read {
    my $self    = shift;
    my $dbh     = $self->app->db;
    my $tag_id  = $self->param('tid');
    my $team_id = $self->param('team');

    my $team_by_name = MTeam->static_get_by_name( $dbh, $team_id );
    my $team_by_id = MTeam->static_get( $dbh, $team_id );
    my $team = undef;
    $team = $team_by_name if defined $team_by_name;
    $team = $team_by_id   if defined $team_by_id;

    my $tag_by_name = MTag->static_get_by_name( $dbh, $tag_id );
    my $tag_by_id = MTag->static_get( $dbh, $tag_id );
    my $tag = undef;
    $tag = $tag_by_name if defined $tag_by_name;
    $tag = $tag_by_id   if defined $tag_by_id;

    if ( !defined $tag ) {
        $self->render( text => "Tag $tag_id does not exist", status => 404 );
        return;
    }
    if ( defined $team_id and !defined $team ) {
        $self->render(
            text   => "Team $team_id does not exist",
            status => 404
        );
        return;
    }

    my @authors = $tag->get_authors($dbh);
    if ( defined $team ) {
        @authors = MAuthor->static_all_with_tag_and_team($dbh, $tag, $team);
    }

    $self->stash(
        tag        => $tag,
        authors    => \@authors
    );
    $self->render( template => 'tags/authors_having_tag_read' );
}
####################################################################################
sub get_tags_for_author_read {

    my $self      = shift;
    my $dbh       = $self->app->db;
    my $author_id = $self->param('author_id');

    my $author;
    $author = MAuthor->static_get_by_name( $dbh, $author_id );
    $author = MAuthor->static_get( $dbh, $author_id ) if !defined $author; # given master id instead of name

    my @author_tags  = ();
    @author_tags  = $author->tags( $dbh ) if defined $author;


    ### here list of objects should be created

    my @tagc_cloud_arr;
    my @sorted_tagc_cloud_arr;

    foreach my $tag (@author_tags) {
        

        my $tag_name = $tag->{name};
        $tag_name =~ s/_/\ /g;
        my @objs = Fget_publications_main_hashed_args( $self,
            { hidden => 0, author => $author->{id}, tag => $tag->{id} } );
        my $count = scalar @objs;

        my $url = $self->url_for('lyp')->query(
            author => $author->{master},
            tag    => $tag_name,
            title  => '1',
            navbar => '1'
        );

        my $tag_cloud_obj = MTagCloud->new();
        $tag_cloud_obj->{tag}   = $tag->{name};
        $tag_cloud_obj->{url}   = $url;
        $tag_cloud_obj->{count} = $count;
        $tag_cloud_obj->{name}  = $tag_name;

        push @tagc_cloud_arr, $tag_cloud_obj;
    }

    @sorted_tagc_cloud_arr = reverse sort { $a->{count} <=> $b->{count} } @tagc_cloud_arr;

    ### old code

    $self->stash(
        tags      => \@author_tags,
        author    => $author,
        tcarr     => \@sorted_tagc_cloud_arr
    );
    $self->render( template => 'tags/author_tags_read' );

}
####################################################################################
sub get_tags_for_team_read {
    my $self = shift;
    my $team_id = $self->param('tid');
    my $dbh = $self->app->db;

    my $team = MTeam->static_get( $dbh, $team_id );
    $team = MTeam->static_get_by_name( $dbh, $team_id ) if !defined $team; # given team name instead of id

    my @team_tags  = ();
    @team_tags  =  $team->tags( $dbh ) if defined $team;
    

    my @tagc_cloud_arr;
    my @sorted_tagc_cloud_arr;

    foreach my $tag (@team_tags) {


        my $tag_name = $tag->{name};
        $tag_name =~ s/_/\ /g;

        my @entry_objs = MEntry->static_get_filter(
            $dbh,    undef, undef, undef, undef, $tag->{id},
            $team_id, undef, undef, undef
        );

        my $url = $self->url_for('lyp')->query(
            team   => $team->{name},
            tag    => $tag_name,
            title  => '1',
            navbar => '1'
        );

        my $tag_cloud_obj = MTagCloud->new();
        $tag_cloud_obj->{tag}   = $tag->{name};
        $tag_cloud_obj->{url}   = $url;
        $tag_cloud_obj->{count} = scalar @entry_objs;
        $tag_cloud_obj->{name}  = $tag_name;

        push @tagc_cloud_arr, $tag_cloud_obj;
    }

    @sorted_tagc_cloud_arr = reverse sort { $a->{count} <=> $b->{count} } @tagc_cloud_arr;

    ### old code

    $self->stash(
        tags      => \@team_tags,
        author    => $team,
        tcarr     => \@sorted_tagc_cloud_arr
    );
    $self->render( template => 'tags/author_tags_read' );

}
####################################################################################
sub get_authors_for_tag {
    my $self   = shift;
    my $dbh    = $self->app->db;
    my $tag_id = $self->param('tid');

    my $mtag = MTag->static_get( $self->app->db, $tag_id );
    if ( !defined $mtag ) {
        $self->render( text => 'Tag does not exist.', status => 404 );
        return;
    }
    
    my @authors = $mtag->get_authors($dbh);

    $self->stash( tag => $mtag, authors => \@authors );
    $self->render( template => 'tags/authors_having_tag' );
}
####################################################################################

sub delete {
    my $self = shift;
    my $dbh  = $self->app->db;
    my $tag_to_delete = $self->param('id_to_delete');

    my $tag = MTag->static_get( $dbh, $tag_to_delete );

    if ( defined $tag ) {

        $self->write_log("Deleting tag $tag->{name} id $tag->{id}.");
        $tag->delete($dbh);
    }

    $self->redirect_to( $self->get_referrer );
}
####################################################################################
1;
