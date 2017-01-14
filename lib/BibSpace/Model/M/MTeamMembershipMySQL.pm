package MTeamMembershipMySQL;

use Data::Dumper;
use utf8;
use BibSpace::Model::M::MAuthor;
use BibSpace::Model::M::MTeam;
use BibSpace::Model::M::MTeamMembershipBase;
use 5.010;           #because of ~~ and say
use DBI;
use Moose;
use MooseX::Storage;
use BibSpace::Model::M::Persistent;


extends 'MTeamMembershipBase';
with 'Persistent';
####################################################################################
sub load {
    my $self = shift;
    my $dbh  = shift;
    my $storage  = shift; # dependency injection

    my $author = $self->load_author($dbh); 
    my $team = $self->load_team($dbh); 
    # there may be mess in DB (although it shouldn't) and some entries may miss author or team
    if($author and $team ){ 
        $author = $author->replaceFromStorage($storage);
        $team = $team->replaceFromStorage($storage);
        $self->author( $author );
        $self->team( $team );
    }
    else{
        # Membership with incomplete data makes no sense in the storage
        warn ref($self)." Author ".$self->author_id." from DB is undefined!" unless defined $author;
        warn ref($self)." Team ".$self->team_id." from DB is undefined!" unless defined $team;
        $storage->delete($self);
        return;
        
        

        # happens when:
        # mysql> select * from Author where id = 58;
        # Empty set (0.00 sec)
        # mysql> select * from Author_to_Team where author_id = 58;
        # +-----------+---------+-------+------+
        # | author_id | team_id | start | stop |
        # +-----------+---------+-------+------+
        # |        58 |       4 |  2013 |    0 |
        # |        58 |       6 |  2011 | 2013 |
        # +-----------+---------+-------+------+
        # 2 rows in set (0.00 sec)
    }
}
####################################################################################
sub load_author {
    my $self = shift;
    my $dbh  = shift;

    die "Undefined or empty author_id!"
        if !defined $self->{author_id}
        or $self->{author_id} < 0;
    die "No database handle provided!"
        unless defined $dbh;

    my $qry = "SELECT 
                id,
                uid,
                display,
                master,
                master_id
            FROM Author
            WHERE id = ? ";
    my @objs;
    my $sth = $dbh->prepare($qry);
    $sth->execute($self->{author_id});

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs, MAuthor->new(
            id        => $row->{id},
            uid       => $row->{uid},
            display   => $row->{display},
            master    => $row->{master},
            master_id => $row->{master_id}
        );
    }
    my $first = shift @objs;
    # there should be only 1 object!
    return $first;
}
################################################################################
sub load_team { 
    my $self = shift;
    my $dbh  = shift;

    die "Undefined or empty team_id!"
        if !defined $self->{team_id}
        or $self->{team_id} < 0;
    die "No database handle provided!"
        unless defined $dbh;

    my $qry = "SELECT 
                id, 
                name, 
                parent
            FROM Team 
            WHERE id = ?";

    my @objs;
    my $sth = $dbh->prepare($qry);
    $sth->execute( $self->{team_id} );

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs, MTeam->new(
            id     => $row->{id},
            name   => $row->{name},
            parent => $row->{parent}
        );
    }
    my $first = shift @objs;
    # there should be only 1 object!
    return $first;
}
####################################################################################
sub static_all {
    my $self = shift;
    my $dbh  = shift;

    my $qry = "SELECT author_id, team_id, start, stop
            FROM Author_to_Team";

    my $sth = $dbh->prepare($qry);
    $sth->execute( );

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
sub static_get {
    my $self = shift;
    my $dbh  = shift;
    my $team_id = shift;
    my $author_id = shift;

    my $qry = "SELECT author_id, team_id, start, stop
            FROM Author_to_Team
            WHERE team_id = ? AND author_id = ?";

    my $sth = $dbh->prepare($qry);
    $sth->execute( $team_id, $author_id );

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

    if(scalar @memberships > 1){
        warn "Mutliple Team memberships detected for author_id $author_id and team_id $team_id";
    }
    my $first = shift @memberships;
    # there should be only 1 object!
    return $first;
}
####################################################################################
sub update {
    my $self = shift;
    my $dbh  = shift;

    my $result = "";

    my $qry = "UPDATE Author_to_Team SET
                start = ?, 
                stop = ?
            WHERE author_id = ?  AND team_id = ? ";

    my $sth = $dbh->prepare($qry);
    $result = $sth->execute( 
        $self->{start},
        $self->{stop},
        $self->{author_id}, 
        $self->{team_id}, 
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
        INSERT INTO Author_to_Team(
        team_id,
        author_id,
        start,
        stop
        ) 
        VALUES (?,?,?,?);";
    my $sth = $dbh->prepare($qry);
    $result = $sth->execute( 
        $self->{team_id}, 
        $self->{author_id}, 
        $self->{start},
        $self->{stop},);
    $sth->finish();
    return $result;
}
####################################################################################
sub save {
    my $self = shift;
    my $dbh  = shift;

    warn "No database handle supplied!" unless defined $dbh;

    my $result = "";

    my $existing_obj = $self->static_get($dbh, $self->{team_id}, $self->{author_id} );

    if ( defined $existing_obj ) {
        return $self->update($dbh);
    }
    else {
        return $self->insert($dbh);
    }
}
####################################################################################
sub delete {
    my $self = shift;
    my $dbh  = shift;

    my $qry    = "DELETE FROM Author_to_Team WHERE team_id=? AND author_id = ?;";
    my $sth    = $dbh->prepare($qry);
    my $result = $sth->execute( $self->{team_id}, $self->{author_id} );

    return $result;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
