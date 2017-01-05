package BibSpace::Controller::Tagtypes;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010;           #because of ~~
use strict;
use warnings;
use DBI;

use BibSpace::Controller::Core;
use BibSpace::Model::MTagType;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;

####################################################################################
sub index {
    my $self = shift;
    my $dbh  = $self->app->db;

    my @objs = MTagType->static_all($dbh);

    $self->render( template => 'tagtypes/tagtypes', tagtypes => \@objs );
}

####################################################################################
sub add {
    my $self = shift;
    my $dbh  = $self->app->db;

    $self->render( template => 'tagtypes/add' );
}

####################################################################################
sub add_post {
    my $self    = shift;
    my $dbh     = $self->app->db;
    my $name    = $self->param('new_name');
    my $comment = $self->param('new_comment');

    my $tt = MTagType->static_get_by_name($dbh, $name);
    if ( defined $tt ){
        $self->flash(
            msg_type => 'error',
            msg      => 'Tag type with such name already exists.'
        );
    }

    $tt = MTagType->new(name => $name, comment => $comment);
    $tt->save($dbh);
    $self->flash(
        msg_type => 'success',
        msg      => 'Tag type added.'
    );
    $self->redirect_to( $self->url_for( 'all_tag_types' ) );
}

####################################################################################
sub delete {
    my $self = shift;
    my $dbh  = $self->app->db;
    my $id   = $self->param('id');

    # we do not allow to delete the two first tag types!
    if ( $id == 1 or $id == 2 ) {
        $self->flash(
            msg_type => 'error',
            msg      => 'Tag Types 1 or 2 are essential and cannot be deleted.'
        );
        $self->redirect_to( $self->url_for( 'all_tag_types' ) );
        return;
    }

    my $tt = MTagType->static_get($dbh, $id);



    for my $t ( MTag->static_all_type($dbh, $id) ){
        $t->delete($dbh);
    }
    $tt->delete($dbh);

    $self->flash(
        msg_type => 'success',
        msg      => 'Tag type deleted.'
    );

    $self->redirect_to( $self->get_referrer );
}

####################################################################################
sub edit {
    my $self = shift;
    my $dbh  = $self->app->db;
    my $id   = $self->param('id');

    my $name    = $self->param('new_name');
    my $comment = $self->param('new_comment');
    my $saved   = 0;

    my $tt = MTagType->static_get($dbh, $id);

    if ( !defined $tt ) {
        $self->flash(
            msg_type => 'error',
            msg      => 'Tag Type does not exist.'
        );
        $self->redirect_to( $self->url_for( 'all_tag_types' ) );
        return;
    }

    if ( defined $name or defined $comment ) {
        $tt->{name} = $name if defined $name;
        $tt->{comment} = $comment if defined $comment;
        $tt->save($dbh);

        $self->flash(
            msg_type => 'success',
            msg      => 'Update successful.'
        );
        $self->redirect_to( $self->url_for( 'all_tag_types' ) );
        return;
    }
    else{
        $self->flash(
            msg_type => 'warning',
            msg      => 'No change made or empty input.'
        );
    }

    $self->stash( obj => $tt );
    $self->render( template => 'tagtypes/edit' );
    

}
####################################################################################
1;
