package BibSpace::Controller::Authors;


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

use BibSpace::Model::MAuthor;

use BibSpace::Controller::Core;
use BibSpace::Controller::Publications;

use BibSpace::Functions::FPublications;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';

##############################################################################################################
sub show {    # refactored
    my $self    = shift;
    my $dbh     = $self->app->db;
    my $visible = $self->param('visible');
    my $search  = $self->param('search') || '%';
    my $letter  = $self->param('letter') || '%';

    if ( $letter ne '%' ) {
        $letter .= '%';
    }

    my @authors = MAuthor->static_get_filter( $dbh, $visible, $letter );

    my @letters = $self->get_set_of_first_letters($visible);

    $self->stash(
        authors => \@authors,
        letters => \@letters,
        visible => $visible
    );

    $self->render( template => 'authors/authors' );
}
##############################################################################################################
sub add_author {
    my $self = shift;

    my $dbh = $self->app->db;

    $self->stash( master => '', id => '' );
    $self->render( template => 'authors/add_author' );
}

##############################################################################################################
sub add_post {
    my $self       = shift;
    my $dbh        = $self->app->db;
    my $new_master = $self->param('new_master');

    if ( defined $new_master ) {

        my $a = MAuthor->static_get_by_name( $dbh, $new_master );

        if ( !defined $a ) {    # no such user exists yet

            $a = MAuthor->new( uid => $new_master );
            $a->save($dbh);

            if ( !defined $a->{id} ) {
                $self->flash(
                    type => 'danger',
                    msg =>
                        "Error saving author. Saving to the database returned no insert row id."
                );
                $self->redirect_to( $self->url_for('add_author') );
                return;
            }
            $self->write_log(
                "Added new author with master: $new_master. Author id is "
                    . $a->{id} );
            $self->flash(
                type => 'success',
                msg  => "Author added successfully!"
            );
            $self->redirect_to(
                $self->url_for( 'edit_author', id => $a->{id} ) );
            return;
        }
        else {    # such user already exists!
            $self->write_log(
                "Author with master: $new_master already exists!");
            $self->flash(
                msg_type => 'warning',
                msg =>
                    "Author with proposed master: $new_master already exists! Pick a different one."
            );
            $self->redirect_to( $self->url_for('add_author') );
            return;
        }
    }

    $self->redirect_to( $self->url_for('add_author') );
}
##############################################################################################################
sub edit_author {
    my $self = shift;
    my $id   = $self->param('id');

    my $dbh = $self->app->db;
    my $author = MAuthor->static_get( $dbh, $id );


    if ( !defined $author ) {
        $self->flash(
            msg      => "Author with id $id does not exist!",
            msg_type => "danger"
        );
        $self->redirect_to( $self->url_for('all_authors') );
    }
    else {

        my @all_teams    = MTeam->static_all($dbh);
        my @author_teams = $author->teams($dbh);
        my @author_tags  = $author->tags($dbh);

        my @minor_authors = $author->all_author_user_ids($dbh);

        $self->stash(
            author        => $author,
            minor_authors => \@minor_authors,
            teams         => \@author_teams,
            exit_code     => '',
            tags          => \@author_tags,
            all_teams     => \@all_teams
        );
        $self->render( template => 'authors/edit_author' );
    }
}
##############################################################################################################
sub can_be_deleted {
    my $self = shift;
    my $id   = shift;
    my $dbh  = $self->app->db;

    my $author = MAuthor->static_get( $dbh, $id );
    my $visibility = $author->{display};

    my $num_teams = scalar $author->teams($dbh);

    return 1 if $num_teams == 0 and $visibility == 0;
    return 0;
}
##############################################################################################################
sub add_to_team {
    my $self      = shift;
    my $dbh       = $self->app->db;
    my $master_id = $self->param('id');
    my $team_id   = $self->param('tid');

    add_team_for_author( $self, $master_id, $team_id );

    $self->redirect_to( $self->get_referrer );
}
##############################################################################################################
sub remove_from_team {
    my $self      = shift;
    my $dbh       = $self->app->db;
    my $master_id = $self->param('id');
    my $team_id   = $self->param('tid');

    remove_team_for_author( $self, $master_id, $team_id );

    $self->redirect_to( $self->get_referrer );
}
##############################################################################################################
sub remove_uid {
    my $self      = shift;
    my $dbh       = $self->app->db;
    my $master_id = $self->param('masterid');
    my $minor_id  = $self->param('uid');

    my $author_master = MAuthor->static_get( $dbh, $master_id );
    my $author_minor  = MAuthor->static_get( $dbh, $minor_id );

   # my $sth = $dbh->prepare('DELETE FROM Author WHERE id=? AND master_id=?');
   # $sth->execute( $minor_id, $master_id );

    if ( $author_master == $author_minor ) {
        $self->flash(
            msg =>
                "Cannot remove user_id $minor_id. Reason: it is a master_id.",
            msg_type => "danger"
        );
    }
    else {


        $author_minor->{master_id} = $author_minor->{id};
        $author_minor->{master}    = $author_minor->{uid};
        $author_minor->save($dbh);
        $author_master->move_entries_from_author( $dbh, $author_minor );
        $author_minor->delete($dbh);

    }
    $self->redirect_to( $self->get_referrer );
}
##############################################################################################################
sub merge_authors {
    my $self           = shift;
    my $dbh            = $self->app->db;
    my $destination_id = $self->param('destination_id');
    my $source_id      = $self->param('source_id');

    my $author_destination = MAuthor->static_get( $dbh, $destination_id );
    my $author_source      = MAuthor->static_get( $dbh, $source_id );

    $author_destination->merge_authors( $dbh, $author_source );

    $self->redirect_to( $self->get_referrer );
}


##############################################################################################################
sub edit_post {
    my $self        = shift;
    my $dbh         = $self->app->db;
    my $id          = $self->param('id');
    my $new_master  = $self->param('new_master');
    my $new_user_id = $self->param('new_user_id');

    my $visibility = $self->param('visibility');

    my $author = MAuthor->static_get( $dbh, $id );

    if ( defined $author ) {
        if ( defined $new_master ) {
            my $status = $author->update_master_name( $dbh, $new_master );

            # status = 0 OK
            # status > 0 existing master id

            if ( $status == 0 ) {
                $self->flash(
                    msg      => "Master name has been updated sucesfully.",
                    msg_type => "success"
                );
                $self->redirect_to(
                    $self->url_for( 'edit_author', id => $status ) );
            }
            elsif ( $status != $id ) {
                my $existing_author = MAuthor->static_get( $dbh, $status );
                $self->flash(
                    msg => "This master name is already taken by <a href=\""
                        . $self->url_for( 'edit_author', id => $status )
                        . "\">"
                        . $existing_author->{master} . "</a>.",
                    msg_type => "danger"
                );
                $self->redirect_to(
                    $self->url_for( 'edit_author', id => $id ) );
            }
            else {
                $self->flash(
                    msg      => "Master name has not changed.",
                    msg_type => "info"
                );
            }

        }
        elsif ( defined $visibility ) {
            $author->toggle_visibility($dbh);
        }
        elsif ( defined $new_user_id ) {
            my $success = $author->add_user_id( $dbh, $new_user_id );
            if ( !$success ) {
                $self->flash(
                    msg =>
                        "Cannot add user ID $new_user_id. Such ID already exist. Maybe you wan to merge authors?",
                    msg_type => "warning"
                );
            }
        }
    }
    $self->redirect_to( $self->url_for( 'edit_author', id => $id ) );
}
##############################################################################################################
sub post_edit_membership_dates {
    my $self = shift;
    my $dbh  = $self->app->db;

    my $aid       = $self->param('aid');
    my $tid       = $self->param('tid');
    my $new_start = $self->param('new_start');
    my $new_stop  = $self->param('new_stop');

    $self->write_log(
        "post_edit_membership_dates: aid $aid, tid $tid, new_start $new_start, new_stop $new_stop"
    );

    if ( defined $aid and $aid > 0 and defined $tid and $tid > 0 ) {
        if ( $new_start >= 0 and $new_stop >= 0 ) {
            if ( $new_stop == 0 or $new_start <= $new_stop ) {
                $self->write_log(
                    "post_edit_membership_dates: input valid. Changing");
                $self->do_edit_membership_dates( $aid, $tid, $new_start,
                    $new_stop );
            }
            else {
                $self->write_log(
                    "post_edit_membership_dates: input INVALID. start later than stop"
                );
            }
        }
        else {
            $self->write_log(
                "post_edit_membership_dates: input INVALID. start or stop negative"
            );
        }
    }
    else {
        $self->write_log(
            "post_edit_membership_dates: input INVALID. author_id or team_id invalid"
        );
    }
    $self->redirect_to( $self->url_for('/authors/edit/') . $aid );
}
##############################################################################################################
sub do_edit_membership_dates {
    my $self      = shift;
    my $aid       = shift;
    my $tid       = shift;
    my $new_start = shift;
    my $new_stop  = shift;
    my $dbh       = $self->app->db;

    # double check!
    if (    defined $aid
        and $aid > 0
        and defined $tid
        and $tid > 0
        and defined $new_start
        and $new_start >= 0
        and defined $new_stop
        and $new_stop >= 0
        and ( $new_stop == 0 or $new_start <= $new_stop ) )
    {
        my $sth
            = $dbh->prepare(
            'UPDATE Author_to_Team SET start=?, stop=? WHERE author_id=? AND team_id=?'
            );
        $sth->execute( $new_start, $new_stop, $aid, $tid );
    }
}
##############################################################################################################
sub delete_author {
    my $self = shift;
    my $dbh  = $self->app->db;
    my $id   = $self->param('id');

    if ( defined $id and $id != -1 and can_be_deleted( $self, $id ) == 1 ) {
        delete_author_force( $self, $id );
        return;
    }

    $self->redirect_to( $self->get_referrer );

}
##############################################################################################################
sub delete_author_force {
    my $self = shift;
    my $dbh  = $self->app->db;
    my $id   = $self->param('id');

    do_delete_author_force( $self, $id );

    $self->flash( msg => "Author with id $id removed successfully." );
    $self->write_log("Author with id $id removed successfully.");

    $self->redirect_to( $self->get_referrer );

}
##############################################################################################################
sub do_delete_author_force {
    my $self = shift;
    my $dbh  = $self->app->db;
    my $id   = shift;


    if ( defined $id and $id != -1 ) {
        my $sth = $dbh->prepare('DELETE FROM Author WHERE master_id=?');
        $sth->execute($id);

        my $sth2 = $dbh->prepare('DELETE FROM Author WHERE id=?');
        $sth2->execute($id);

        my $sth3
            = $dbh->prepare('DELETE FROM Entry_to_Author WHERE author_id=?');
        $sth3->execute($id);

        my $sth4
            = $dbh->prepare('DELETE FROM Author_to_Team WHERE author_id=?');
        $sth4->execute($id);
    }
}
##############################################################################################################
sub add_new_user_id_to_master {
    my $self        = shift;
    my $id          = shift;
    my $new_user_id = shift;
    my $dbh         = $self->app->db;

    say "call: add_new_user_id_to_master id=$id new_user_id=$new_user_id";

    # Check if Author with $id can have added the $new_user_id

    # candidate
    my $author_candidate = MAuthor->static_get_by_name( $dbh, $new_user_id );

    # existing author
    my $author_obj = MAuthor->static_get( $dbh, $id );

    if ( defined $author_candidate ) {

        # author with new_user_id already exist
        # move all entries of candidate to this author
        $author_obj->move_entries_from_author( $dbh, $author_candidate );

        $author_candidate->{master}    = $author_obj->{master};
        $author_candidate->{master_id} = $author_obj->{master_id};

        # TODO: cleanup author_candidate teams?

        # return add_new_user_id_to_master_force( $self, $id, $new_user_id );
    }
    else {
       # we add a new user and assign master and master_id from the author_obj
       # create new user
       # assign it to master
        my $author_candidate = MAuthor->new(
            uid       => $new_user_id,
            master    => $author_obj->{master},
            master_id => $author_obj->{master_id}
        );
        $author_candidate->save($dbh);
        return 0;
    }

}


##############################################################################################################

sub get_set_of_first_letters {
    my $self    = shift;
    my $dbh     = $self->app->db;
    my $visible = shift or undef;

    my $sth = undef;
    if ( defined $visible and $visible eq '1' ) {

# $sth = $dbh->prepare( "SELECT DISTINCT substr(master, 0, 2) as let FROM Author WHERE display=1 ORDER BY let ASC" );
        $sth
            = $dbh->prepare(
            "SELECT DISTINCT substr(master, 1, 1) as let FROM Author WHERE display=1 ORDER BY let ASC"
            );
    }
    else {
# $sth = $dbh->prepare( "SELECT DISTINCT substr(master, 0, 2) as let FROM Author ORDER BY let ASC" );
        $sth
            = $dbh->prepare(
            "SELECT DISTINCT substr(master, 1, 1) as let FROM Author ORDER BY let ASC"
            );
    }
    $sth->execute();

    my @letters;
    while ( my $row = $sth->fetchrow_hashref() ) {
        my $letter = $row->{let} || "*";
        push @letters, uc($letter);
    }
    @letters = uniq(@letters);
    my @sorted_letters = sort(@letters);
    return @sorted_letters;
}
##############################################################################################################
sub get_visibility_by_name {
    my $self = shift;
    my $name = shift;

    my $dbh = $self->app->db;

    my $sth;
    $sth = $dbh->prepare(
        "SELECT display FROM Author WHERE master=? AND uid=?");
    $sth->execute( $name, $name );

    my $row  = $sth->fetchrow_hashref();
    my $disp = $row->{display};

    return $disp;

}
##############################################################################################################
sub reassign_authors_to_entries {
    my $self = shift;
    my $dbh  = $self->app->db;

    Fhandle_author_uids_change_for_all_entries( $self->app->db, 0 );

    $self->flash( msg => 'Reassignment complete.' );
    $self->redirect_to( $self->get_referrer );
}
##############################################################################################################
sub reassign_authors_to_entries_and_create_authors {
    my $self = shift;
    my $dbh  = $self->app->db;

    my ( $num_authors_created, $num_authors_assigned )
        = Fhandle_author_uids_change_for_all_entries( $self->app->db, 1 );
    $self->flash( msg =>
            "Reassignment with author creation has finished. $num_authors_created authors have been created and $num_authors_assigned assigned to their entries."
    );
    $self->redirect_to( $self->get_referrer );
}

##############################################################################################################

sub toggle_visibility {    # refactored
    my $self = shift;
    my $dbh  = $self->app->db;
    my $id   = $self->param('id');

    my $author = MAuthor->static_get( $dbh, $id );
    $author->toggle_visibility($dbh);


    $self->redirect_to( $self->get_referrer );
}

##############################################################################################################

1;
