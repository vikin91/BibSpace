package MAuthorMySQL;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           # because of ~~ and say
use DBI;
use Try::Tiny;
use Devel::StackTrace;

use BibSpace::Model::MAuthorBase;
use BibSpace::Model::Persistent;
use BibSpace::Model::StorageBase;

use Moose;
extends 'MAuthorBase';
with 'Persistent';

####################################################################################
sub load {
    my $self = shift;
    my $dbh  = shift;
    my $storage  = shift; # dependency injection

    my @authorMemberships = $self->load_memberships($dbh); # authors from DB
    # in case there is a mess in DB
    @authorMemberships = grep { defined $_->team_id and defined $_->author_id } @authorMemberships;
    @authorMemberships = map {$_->replaceFromStorage($storage) } @authorMemberships;
    map { $_->load($dbh, $storage) } @authorMemberships;
    $self->bteamMemberships( [ @authorMemberships ] );
    

    # now, there are teams loaded from storage
    my @myTeams = map{ $_->team } grep { defined $_->team } $self->teamMemberships_all;
    $self->bteams( [ @myTeams ] );
}
####################################################################################
sub load_memberships {
    my $self = shift;
    my $dbh  = shift;

    my $qry = "SELECT author_id, team_id, start, stop
            FROM Author_to_Team
            WHERE author_id = ?";

    my $sth = $dbh->prepare($qry);
    $sth->execute( $self->{id} );

    my @memberships;
    while ( my $row = $sth->fetchrow_hashref() ) {
        my $mem = MTeamMembership->new( 
            team_id => $row->{team_id},
            author_id => $row->{author_id},
            start => $row->{start},
            stop => $row->{stop}
        );
        push @memberships, $mem;
    }
    return @memberships;
}
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
        if( $obj->{master_id} != $obj->{id} ){
            $obj->{masterObj} = MAuthor->static_get($dbh, $obj->{master_id});
        }
        else{
            $obj->{masterObj} = $obj;
        }

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
        if( $obj->{master_id} != $obj->{id} ){
            $obj->{masterObj} = MAuthor->static_get($dbh, $obj->{master_id});
        }
        else{
            $obj->{masterObj} = $obj;
        }
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

    my $obj = MAuthor->new(
        id        => $row->{id},
        uid       => $row->{uid},
        display   => $row->{display},
        master    => $row->{master},
        master_id => $row->{master_id}
    );
    if( $obj->{master_id} != $obj->{id} ){
        $obj->{masterObj} = MAuthor->static_get($dbh, $obj->{master_id});
    }
    else{
        $obj->{masterObj} = $obj;
    }
    return $obj;
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
        if( $obj->{master_id} != $obj->{id} ){
            $obj->{masterObj} = MAuthor->static_get($dbh, $obj->{master_id});
        }
        else{
            $obj->{masterObj} = $obj;
        }
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
        if( $obj->{master_id} != $obj->{id} ){
            $obj->{masterObj} = MAuthor->static_get($dbh, $obj->{master_id});
        }
        else{
            $obj->{masterObj} = $obj;
        }
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

    my $sth;
    try{
        $sth = $dbh->prepare($qry);
        $result = $sth->execute(
            $self->{uid},       $self->{display}, $self->{master},
            $self->{master_id}, $self->{id}
        );
    }
    catch{
        my $trace = Devel::StackTrace->new;
        print "\n=== TRACE ===\n" . $trace->as_string . "\n=== END TRACE ===\n"; # like carp
    };
    $sth->finish();

    return $result;
}
####################################################################################
sub insert {
    my $self   = shift;
    my $dbh    = shift;
    my $result = "";

    my $qry = "
        INSERT IGNORE INTO Author(
            uid,
            display,
            master,
            master_id
        ) 
        VALUES (?,?,?,?);";
    my $sth = $dbh->prepare($qry);
    try{ 
        $result = $sth->execute(
            $self->{uid},    $self->{display},
            $self->{master}, $self->{master_id}
        );
    }
    catch{
        my $trace = Devel::StackTrace->new;
        print "\n=== TRACE ===\n" . $trace->as_string . "\n=== END TRACE ===\n"; # like carp
    };
    $self->{id} = $dbh->last_insert_id( '', '', 'Author', '' );
    $sth->finish();

    if ( !defined $self->{master} or $self->{master} eq '' ) {
        $self->set_master( $self );
    }
    return $self->{id};
}
####################################################################################
sub insert_entries {
    my $self = shift;
    my $dbh  = shift;


    my $sth = $dbh->prepare('DELETE FROM Entry_to_Author WHERE author_id = ?');
    $sth->execute($self->{id});

    my $qry = 'INSERT IGNORE INTO Entry_to_Author(author_id, entry_id) VALUES(?, ?)';

    foreach my $entry ($self->entries_all){

        my $sth2 = $dbh->prepare($qry);
        $sth2->execute( $self->{id}, $entry->{id} );
    }
}
####################################################################################
sub save {
    my $self = shift;
    my $dbh  = shift;

    warn "No database handle supplied!" unless defined $dbh;

    my $result = "";

    if ( defined $self->{id} and $self->{id} > 0 ) {
        my $result = $self->update($dbh);
        $self->insert_entries($dbh);
        return $result;
    }
    elsif ( defined $self and !defined $self->{uid} ) {
        warn "Cannot save MAuthor that has no uid (name)";
        return -1;
    }
    else {
        my $inserted_id = $self->insert($dbh);
        $self->insert_entries($dbh);
        $self->{id} = $inserted_id;
        return $inserted_id;
    }
}
####################################################################################
sub delete {
    my $self = shift;
    my $dbh  = shift;

    $self->abandon_all_entries($dbh);
    $self->abandon_all_teams($dbh);

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
no Moose;
__PACKAGE__->meta->make_immutable;
1;
