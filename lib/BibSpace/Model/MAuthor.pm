package MAuthor;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           # because of ~~ and say
use DBI;
use Moose;
use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

has 'id'        => ( is => 'rw' );
has 'uid'       => ( is => 'rw' );
has 'display'   => ( is => 'rw', default => 0 );
has 'master'    => ( is => 'rw' );
has 'master_id' => ( is => 'rw' );

####################################################################################
sub static_all {
    my $self = shift;
    my $dbh  = shift;

    my $qry = "SELECT 
            id,
            uid,
            display,
            master,
            master_id
        FROM Author";
    my @objs;
    my $sth = $dbh->prepare($qry);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $obj = MAuthor->new(
            id        => $row->{id},
            uid       => $row->{uid},
            display   => $row->{display},
            master    => $row->{master},
            master_id => $row->{master_id}
        );
        push @objs, $obj;
    }
    return @objs;
}
####################################################################################
sub static_all_masters {
    my $self = shift;
    my $dbh  = shift;

    my $qry = "SELECT 
            id,
            uid,
            display,
            master,
            master_id
        FROM Author WHERE master_id=id";
    my @objs;
    my $sth = $dbh->prepare($qry);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $obj = MAuthor->new(
            id        => $row->{id},
            uid       => $row->{uid},
            display   => $row->{display},
            master    => $row->{master},
            master_id => $row->{master_id}
        );
        push @objs, $obj;
    }
    return @objs;
}

####################################################################################
sub static_get {
    my $self = shift;
    my $dbh  = shift;
    my $id   = shift;

    my $qry = "SELECT 
            id,
            uid,
            display,
            master,
            master_id
            FROM Author
          WHERE id = ?";

    my $sth = $dbh->prepare($qry);
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();

    if ( !defined $row ) {
        return undef;
    }

    return MAuthor->new(
        id        => $row->{id},
        uid       => $row->{uid},
        display   => $row->{display},
        master    => $row->{master},
        master_id => $row->{master_id}
    );
}
####################################################################################
sub static_get_filter {
    my $self = shift;
    my $dbh  = shift;

    my $visible = shift;
    my $letter  = shift;

    my @params;
    my $qry = "SELECT 
            id,
            uid,
            display,
            master,
            master_id
            FROM Author
          WHERE master IS NOT NULL";

    if ( defined $visible ) {
        $qry .= " AND display=? ";
        push @params, $visible;
    }
    if ( defined $letter and $letter ne '%' ) {
        push @params, $letter;
        $qry .= " AND substr(master, 1, 1) LIKE ? ";    # mysql
    }
    $qry .= " ORDER BY display DESC, master ASC";

    my $sth = $dbh->prepare_cached($qry);
    $sth->execute(@params);

    my @objs;
    while ( my $row = $sth->fetchrow_hashref() ) {
        my $obj = MAuthor->new(
            id        => $row->{id},
            uid       => $row->{uid},
            display   => $row->{display},
            master    => $row->{master},
            master_id => $row->{master_id}
        );
        push @objs, $obj;
    }
    return @objs;
}
####################################################################################
sub all_author_user_ids {
    my $self = shift;
    my $dbh  = shift;

    my $qry = "SELECT 
            id,
            uid,
            display,
            master,
            master_id
        FROM Author WHERE master_id=?";
    my @objs;
    my $sth = $dbh->prepare($qry);
    $sth->execute( $self->{master_id} );

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $obj = MAuthor->new(
            id        => $row->{id},
            uid       => $row->{uid},
            display   => $row->{display},
            master    => $row->{master},
            master_id => $row->{master_id}
        );
        push @objs, $obj;
    }
    return @objs;
}
################################################################################
sub static_all_with_tag_and_team {
    my $self         = shift;
    my $dbh          = shift;
    my $tag          = shift;
    my $team         = shift;
    my $current_year = shift // BibSpace::Controller::Core::get_current_year();

    my $qry = "SELECT DISTINCT Entry_to_Author.author_id
            FROM Entry_to_Author 
            LEFT JOIN Entry_to_Tag ON Entry_to_Author.entry_id = Entry_to_Tag.entry_id 
            LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 
            WHERE Entry_to_Tag.tag_id =? 
            AND Entry_to_Author.author_id IS NOT NULL
            AND Entry_to_Author.author_id IN (
                SELECT DISTINCT (author_id)
                FROM Author_to_Team 
                JOIN Author 
                ON Author.master_id = Author_to_Team.author_id
                WHERE team_id=?
                AND Author_to_Team.start <= ?
                AND ((Author_to_Team.stop = 0) OR (Author_to_Team.stop >= ?))
            )";

    my $sth = $dbh->prepare($qry);
    $sth->execute( $tag->{id}, $team->{id}, $current_year, $current_year );

    my @result;

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @result, MAuthor->static_get( $dbh, $row->{author_id}) ;

    }

    return @result;
}
####################################################################################
sub update {
    my $self = shift;
    my $dbh  = shift;

    my $result = "";

    if ( !defined $self->{id} ) {
        warn
            "Cannot update. MAuthor id not set. The entry may not exist in the DB. Returning -1. Should never happen!";
        return -1;
    }

    my $qry = "UPDATE Author SET
                uid=?,
                display=?,
                master=?,
                master_id=?
            WHERE id = ?";
    my $sth = $dbh->prepare($qry);
    $result = $sth->execute(
        $self->{uid},       $self->{display}, $self->{master},
        $self->{master_id}, $self->{id}
    );
    $sth->finish();

    return $result;
}
####################################################################################
sub insert {
    my $self   = shift;
    my $dbh    = shift;
    my $result = "";

    my $qry = "
        INSERT INTO Author(
            uid,
            display,
            master,
            master_id
        ) 
        VALUES (?,?,?,?);";
    my $sth = $dbh->prepare($qry);
    $result = $sth->execute(
        $self->{uid},    $self->{display},
        $self->{master}, $self->{master_id}
    );
    $self->{id} = $dbh->last_insert_id( '', '', 'Author', '' );
    $sth->finish();

    if ( !defined $self->{master} or $self->{master} eq '' ) {
        $self->assign_master( $dbh, $self );
    }
    return $self->{id};
}
####################################################################################
sub save {
    my $self = shift;
    my $dbh  = shift;

    warn "No database handle supplied!" unless defined $dbh;

    my $result = "";

    if ( defined $self->{id} and $self->{id} > 0 ) {
        return $self->update($dbh);
    }
    elsif ( defined $self and !defined $self->{uid} ) {
        warn "Cannot save MAuthor that has no uid (name)";
        return -1;
    }
    else {
        my $inserted_id = $self->insert($dbh);
        $self->{id} = $inserted_id;
        return $inserted_id;
    }
}
####################################################################################
sub delete {
    my $self = shift;
    my $dbh  = shift;

    my $qry    = "DELETE FROM Author WHERE id=?;";
    my $sth    = $dbh->prepare($qry);
    my $result = $sth->execute( $self->{id} );
    $self->{id} = undef;

    return $result;
}
####################################################################################
sub static_get_by_name {
    my $self = shift;
    my $dbh  = shift;
    my $name = shift;

    my $sth = $dbh->prepare("SELECT id, master_id FROM Author WHERE uid=?");
    $sth->execute($name);
    my $row = $sth->fetchrow_hashref();
    my $id = $row->{id} || -1;

    if ( $id > 0 ) {
        return MAuthor->static_get( $dbh, $id );
    }
    return undef;
}
####################################################################################
sub get_master {
    my $self = shift;
    my $dbh  = shift;


    return $self if $self->{id} == $self->{master_id};
    return MAuthor->static_get( $dbh, $self->{master_id} );
}
####################################################################################
sub static_get_by_master {
    my $self = shift;
    my $dbh  = shift;
    my $name = shift;

    my $sth = $dbh->prepare("SELECT id FROM Author WHERE master=? AND master_id=id");
    $sth->execute($name);
    my $row = $sth->fetchrow_hashref();
    my $id = $row->{id} || -1;

    if ( $id > 0 ) {
        return MAuthor->static_get( $dbh, $id );
    }
    return undef;
}
####################################################################################
sub joined_team {
    my $self = shift;
    my $dbh  = shift;
    my $team = shift;

    return -1 if !defined $team;

    my $qry = "SELECT DISTINCT author_id, team_id, start, stop
            FROM Author_to_Team 
            WHERE team_id=? AND author_id=?";

    my $sth = $dbh->prepare($qry);
    $sth->execute( $team->{id}, $self->{id} );

    return -1 if $sth->rows < 0;

    my @start_years;

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @start_years, $row->{start};
    }
    @start_years = sort @start_years;

    return shift @start_years;
}
####################################################################################
sub left_team {
    my $self = shift;
    my $dbh  = shift;
    my $team = shift;

    return -1 if !defined $team;


    my $qry = "SELECT DISTINCT author_id, team_id, start, stop
            FROM Author_to_Team 
            WHERE team_id=? AND author_id=?";

    my $sth = $dbh->prepare($qry);
    $sth->execute( $team->{id}, $self->{id} );

    return -1 if $sth->rows < 0;

    my @stop_years;

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @stop_years, $row->{stop};
    }
    @stop_years = sort reverse @stop_years;

    return shift @stop_years;
}
####################################################################################
sub assign_master {
    my $self          = shift;
    my $dbh           = shift;
    my $master_author = shift;

    $self->{master}    = $master_author->{uid};
    $self->{master_id} = $master_author->{id};
    $self->update($dbh);
}
####################################################################################
sub toggle_visibility {
    my $self = shift;
    my $dbh  = shift;

    if ( $self->{display} == 0 ) {
        $self->{display} = 1;
    }
    else {
        $self->{display} = 0;
    }
    $self->update($dbh);
}
####################################################################################
sub can_be_deleted {
    my $self = shift;
    my $dbh  = shift;

    return 0 if $self->{display} == 1;

    my @teams = $self->teams($dbh);

    return 1 if scalar @teams == 0 and $self->{display} == 0;
    return 0;
}
####################################################################################
sub entries {
    my $self = shift;
    my $dbh  = shift;

    warn "No database handle supplied!" unless defined $dbh;
    return () unless defined $dbh;
    return () if !defined $self->{id} or $self->{id} < 0;


    my $qry
        = "SELECT entry_id, author_id FROM Entry_to_Author WHERE author_id = ?";
    my $sth = $dbh->prepare_cached($qry);
    $sth->execute( $self->{id} );

    my @entries;

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $entry = MEntry->static_get( $dbh, $row->{entry_id} );

        push @entries, $entry if defined $entry;
    }
    return @entries;
}
####################################################################################
sub move_entries_from_author {
    my $self        = shift;
    my $dbh         = shift;
    my $from_author = shift;

    my $sth = $dbh->prepare(
            'UPDATE IGNORE Entry_to_Author SET author_id = ? WHERE author_id = ?'
    );
    $sth->execute( $self->{id}, $from_author->{id} );

    # $entry->remove_author( $dbh, $from_author );
    # $entry->assign_author( $dbh, $self );
}
##############################################################################################################
sub merge_authors {
    my $self   = shift;
    my $dbh    = shift;
    my $source_author = shift;

    if ( defined $source_author and $source_author->{id} != $self->{id} ) {

        # author with new_user_id already exist
        # move all entries of candidate to this author

        $self->move_entries_from_author( $dbh, $source_author );

        # necessary due to possible conflicts caused on ON UPDATE CASCADE
        $source_author->abandon_all_entries( $dbh ); 
        $source_author->abandon_all_teams( $dbh ); 

        $source_author->{master}    = $self->{master};
        $source_author->{master_id} = $self->{master_id};
        $source_author->save($dbh);
        return 1;

    }
    return 0;

}
##############################################################################################################
sub add_user_id {
    my $self        = shift;
    my $dbh         = shift;
    my $new_user_id = shift;

    my $author_candidate = MAuthor->static_get_by_name( $dbh, $new_user_id );


    if ( defined $author_candidate ) {
        # author with new_user_id already exist
        return 0; # no success
    }
    
   # we add a new user and assign master and master_id from the author_obj
   # create new user
   # assign it to master
    $author_candidate = MAuthor->new(
        uid       => $new_user_id,
        master    => $self->{master},
        master_id => $self->{master_id}
    );
    $author_candidate->save($dbh);
    return 1; # success

}
################################################################################
sub abandon_all_entries {
    my $self = shift;
    my $dbh  = shift;


    my $qry = "DELETE FROM Entry_to_Author
            WHERE author_id=?";

    my $sth = $dbh->prepare($qry);
    $sth->execute( $self->{id} );
}
################################################################################
sub abandon_all_teams {
    my $self = shift;
    my $dbh  = shift;


    my $qry = "DELETE FROM Author_to_Team
            WHERE author_id=?";

    my $sth = $dbh->prepare($qry);
    $sth->execute( $self->{id} );
}
################################################################################
sub add_to_team {
    my $self      = shift;
    my $dbh       = shift;
    my $team      = shift;


    return 0 if !defined $team and $team->{id} <=0;

    my $qry
        = "INSERT IGNORE INTO Author_to_Team(author_id, team_id) VALUES (?,?)";
    my $sth = $dbh->prepare($qry);
    return $sth->execute( $self->{master_id}, $team->{id} );

}
################################################################################
sub remove_from_team {
    my $self      = shift;
    my $dbh       = shift;
    my $team      = shift;

    return 0 if !defined $team and $team->{id} <=0;


    my $qry = "DELETE FROM Author_to_Team WHERE author_id=? AND team_id=?";
    my $sth = $dbh->prepare($qry);
    return $sth->execute( $self->{master_id}, $team->{id} );

}
################################################################################
sub teams { # this must remain as SQL query or object calls only withing this class. Reason: methods form other classes use it.
    my $self = shift;
    my $dbh  = shift;


    my $qry = "SELECT author_id, team_id, start, stop
            FROM Author_to_Team 
            WHERE author_id=?";

    my $sth = $dbh->prepare($qry);
    $sth->execute( $self->{id} );

    my @teams;
    while ( my $row = $sth->fetchrow_hashref() ) {
        my $team = MTeam->static_get( $dbh, $row->{team_id} )
            if defined $row->{team_id} and $row->{team_id} ne '';

        push @teams, $team if defined $team;

        # my $start = $row->{start};
        # my $stop  = $row->{stop};
    }
    return @teams;
}
####################################################################################
sub update_master_name {
    my $self       = shift;
    my $dbh        = shift;
    my $new_master = shift;


    my $new_master_author = MAuthor->static_get_by_master($dbh, $new_master);

    if( defined $new_master_author ){
        return $new_master_author->{id}; 
    }

    $self->{master} = $new_master;
    $self->{uid}    = $new_master;
    $self->save($dbh);


    return 0;
}
####################################################################################
sub tags {

    my $self = shift;
    my $dbh  = shift;
    my $type = shift || 1;

    my $qry = "SELECT DISTINCT Entry_to_Tag.tag_id, Tag.name 
            FROM Entry_to_Author 
            LEFT JOIN Entry_to_Tag ON Entry_to_Author.entry_id = Entry_to_Tag.entry_id 
            LEFT JOIN Tag ON Entry_to_Tag.tag_id = Tag.id 
            WHERE Entry_to_Author.author_id=? 
            AND Entry_to_Tag.tag_id IS NOT NULL
            AND Tag.type = ?
            ORDER BY Tag.name ASC";

    my $sth = $dbh->prepare($qry);
    $sth->execute( $self->{master_id}, $type );

    my @tags;

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $tag = MTag->static_get( $dbh, $row->{tag_id} );
        push @tags, $tag if defined $tag;

    }
    return @tags;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
