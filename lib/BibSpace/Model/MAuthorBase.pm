package MAuthorBase;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           # because of ~~ and say
use DBI;

use Moose;
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );


has 'id'      => ( is => 'rw', isa     => 'Int' );
has 'uid'     => ( is => 'rw', isa     => 'Str' );
has 'display' => ( is => 'rw', default => 0 );
has 'master'  => ( 
        is => 'rw', 
        isa => 'Maybe[Str]', 
        default => sub { shift->{uid} } 
);
has 'master_id' => ( is => 'rw', isa => 'Int' );
has 'masterObj' => ( is => 'rw', isa => 'MAuthor', default => sub {shift} );

has 'bteams' => (
    is      => 'rw',
    isa     => 'ArrayRef[MTeam]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        teams_all        => 'elements',
        teams_add        => 'push',
        teams_map        => 'map',
        teams_filter     => 'grep',
        teams_find       => 'first',
        teams_find_index => 'first_index',
        teams_delete     => 'delete',
        teams_clear      => 'clear',
        teams_get        => 'get',
        teams_join       => 'join',
        teams_count      => 'count',
        teams_has        => 'count',
        teams_has_no     => 'is_empty',
        teams_sorted     => 'sort',
    },
);

has 'bentries' => (
    is      => 'rw',
    isa     => 'ArrayRef[MEntry]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        entries_all        => 'elements',
        entries_add        => 'push',
        entries_map        => 'map',
        entries_filter     => 'grep',
        entries_find       => 'first',
        entries_find_index => 'first_index',
        entries_delete     => 'delete',
        entries_clear      => 'clear',
        entries_get        => 'get',
        entries_join       => 'join',
        entries_count      => 'count',
        entries_has        => 'count',
        entries_has_no     => 'is_empty',
        entries_sorted     => 'sort',
    },
);

####################################################################################
sub equals {
    my $self = shift;
    my $obj  = shift;

    return 0 if !defined $obj or !defined $self;
    return $self->{uid} eq $obj->{uid};
}

####################################################################################
sub get_master {
    my $self = shift;
    my $dbh  = shift;


    return $self if $self->{id} == $self->{master_id};
    return MAuthor->static_get( $dbh, $self->{master_id} );
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
sub entries_old {
    my $self = shift;
    my $dbh  = shift;

    warn "No database handle supplied!" if !defined $dbh;
    return if !defined $dbh or !defined $self->{id} or $self->{id} < 0;


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
sub entries {
    my $self = shift;
    return $self->entries_all;
}

####################################################################################
sub has_entry {
    my $self = shift;
    my $e = shift;

    my $exists = $self->entries_find_index( sub { $_->equals($e) } ) > -1;
    return $exists;
}
####################################################################################
sub assign_entry {
    my ($self, @entries)   = @_;

    my $added = 0;
    foreach my $e ( @entries ){
        if( !$self->has_entry( $e ) ){
            $self->entries_add( $e );
            ++$added;
            if( !$e->has_author($self) ){
                $e->assign_author($self);
            }
        }

    }
    return $added;

}
####################################################################################
sub remove_entry {
    my $self   = shift;
    my $entry = shift;

    my $index = $self->entries_find_index( sub { $_->equals($entry) } );
    return 0 if $index == -1;
    return 1 if $self->entries_delete($index);
    return 0;
}
####################################################################################
sub remove_all_entries {
    my $self = shift;

    $self->entries_clear;
}
####################################################################################
sub move_entries_from_author {
    my $self        = shift;
    my $dbh         = shift;
    my $from_author = shift;

    my $sth
        = $dbh->prepare(
        'UPDATE IGNORE Entry_to_Author SET author_id = ? WHERE author_id = ?'
        );
    $sth->execute( $self->{id}, $from_author->{id} );

    # $entry->remove_author( $dbh, $from_author );
    # $entry->assign_author( $dbh, $self );
}
##############################################################################################################
sub merge_authors {
    my $self          = shift;
    my $dbh           = shift;
    my $source_author = shift;

    if ( defined $source_author and $source_author->{id} != $self->{id} ) {

        # author with new_user_id already exist
        # move all entries of candidate to this author

        $self->move_entries_from_author( $dbh, $source_author );

        # necessary due to possible conflicts caused on ON UPDATE CASCADE
        $source_author->abandon_all_entries($dbh);
        $source_author->abandon_all_teams($dbh);

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
        return 0;    # no success
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
    return 1;    # success

}
################################################################################
sub abandon_all_entries {
    my $self = shift;
    my $dbh  = shift;

    $self->remove_all_entries;


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
    my $self = shift;
    my $dbh  = shift;
    my $team = shift;


    return 0 if !defined $team and $team->{id} <= 0;

    my $qry
        = "INSERT IGNORE INTO Author_to_Team(author_id, team_id) VALUES (?,?)";
    my $sth = $dbh->prepare($qry);
    return $sth->execute( $self->{master_id}, $team->{id} );

}
################################################################################
sub remove_from_team {
    my $self = shift;
    my $dbh  = shift;
    my $team = shift;

    return 0 if !defined $team and $team->{id} <= 0;


    my $qry = "DELETE FROM Author_to_Team WHERE author_id=? AND team_id=?";
    my $sth = $dbh->prepare($qry);
    return $sth->execute( $self->{master_id}, $team->{id} );

}
################################################################################
sub teams
{ # this must remain as SQL query or object calls only withing this class. Reason: methods form other classes use it.
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


    my $new_master_author
        = MAuthor->static_get_by_master( $dbh, $new_master );

    if ( defined $new_master_author ) {
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
