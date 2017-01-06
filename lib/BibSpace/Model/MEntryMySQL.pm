package MEntryMySQL;

use BibSpace::Model::MEntryBase;
use BibSpace::Model::MTag;
use BibSpace::Model::MTagType;
use BibSpace::Model::Persistent;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           #because of ~~ and say
use DBI;
use Try::Tiny;
use TeX::Encode;
use Encode;
use Moose;

extends 'MEntryBase';
with 'Persistent';

####################################################################################
sub load {
    my $self = shift;
    my $dbh  = shift;

    $self->bauthors( [ $self->load_authors($dbh) ] );
    $self->btags( [ $self->load_tags($dbh) ] );
    $self->bexceptions( [ $self->load_exceptions($dbh) ] );
}
####################################################################################

sub load_authors {
    my $self = shift;
    my $dbh  = shift;

    die "Undefined or empty entry!"
        if !defined $self->{id}
        or $self->{id} < 0;
    die "No database handle provided!"
        unless defined $dbh;

    my $qry = "SELECT 
                Author.id,
                Author.uid,
                Author.display,
                Author.master,
                Author.master_id
                FROM Author
                LEFT JOIN Entry_to_Author ON Author.id = Entry_to_Author.author_id 
                WHERE Entry_to_Author.entry_id = ? ";
    my @objs;
    my $sth = $dbh->prepare($qry);
    $sth->execute($self->{id});

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs, MAuthor->new(
            id        => $row->{id},
            uid       => $row->{uid},
            display   => $row->{display},
            master    => $row->{master},
            master_id => $row->{master_id}
        );
    }
    return @objs;
}
####################################################################################
sub load_tags {
    my $self = shift;
    my $dbh  = shift;

    die "Undefined or empty entry!"
        if !defined $self->{id}
        or $self->{id} < 0;
    die "No database handle provided!"
        unless defined $dbh;

    my $qry = "SELECT 
            Tag.id,
            Tag.name,
            Tag.type,
            Tag.permalink, 
            Entry_to_Tag.entry_id, 
            Entry_to_Tag.tag_id 
            FROM Entry_to_Tag 
            LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id
            WHERE Entry_to_Tag.entry_id = ?";
    
    my $sth = $dbh->prepare_cached($qry);
    $sth->execute( $self->{id} );
    
    my @objs;
    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs,
            MTag->new(
            id        => $row->{id},
            name      => $row->{name},
            type      => $row->{type},
            permalink => $row->{permalink},
            );
    }
    return @objs;
}
####################################################################################
sub load_exceptions {
    my $self = shift;
    my $dbh  = shift;

    die "Undefined or empty entry!"
        if !defined $self->{id}
        or $self->{id} < 0;
    die "No database handle provided!"
        unless defined $dbh;

    my $qry = "SELECT
                Team.id,
                Team.name,
                Team.parent, 
                Exceptions_Entry_to_Team.team_id, 
                Exceptions_Entry_to_Team.entry_id 
                FROM Exceptions_Entry_to_Team 
                LEFT JOIN Team ON Team.id = Exceptions_Entry_to_Team.team_id
                WHERE entry_id = ?";

    my @objs;
    my $sth = $dbh->prepare($qry);
    $sth->execute($self->{id});

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs, MTeam->new(
            id     => $row->{id},
            name   => $row->{name},
            parent => $row->{parent}
        );
    }
    return @objs;
    
}
####################################################################################
sub static_all {
    my $self = shift;
    my $dbh  = shift;

    my $qry = "SELECT
              id,
              entry_type,
              bibtex_key,
              bibtex_type,
              bib,
              html,
              html_bib,
              abstract,
              title,
              hidden,
              year,
              month,
              sort_month,
              teams_str,
              people_str,
              tags_str,
              creation_time,
              modified_time,
              need_html_regen
          FROM Entry";
    my @objs = ();
    my $sth  = $dbh->prepare($qry);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs,
            MEntry->new(
            id              => $row->{id},
            entry_type      => $row->{entry_type},
            bibtex_key      => $row->{bibtex_key},
            bibtex_type     => $row->{bibtex_type},
            bib             => $row->{bib},
            html            => $row->{html},
            html_bib        => $row->{html_bib},
            abstract        => $row->{abstract},
            title           => $row->{title},
            hidden          => $row->{hidden},
            year            => $row->{year},
            month           => $row->{month},
            sort_month      => $row->{sort_month},
            teams_str       => $row->{teams_str},
            people_str      => $row->{people_str},
            tags_str        => $row->{tags_str},
            creation_time   => $row->{creation_time},
            modified_time   => $row->{modified_time},
            need_html_regen => $row->{need_html_regen},
            );
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
              entry_type,
              bibtex_key,
              bibtex_type,
              bib,
              html,
              html_bib,
              abstract,
              title,
              hidden,
              year,
              month,
              sort_month,
              teams_str,
              people_str,
              tags_str,
              creation_time,
              modified_time,
              need_html_regen
          FROM Entry
          WHERE id = ?";

    my $sth = $dbh->prepare($qry);
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();

    if ( !defined $row ) {
        return undef;
    }

    my $e = MEntry->new(
        id              => $id,
        entry_type      => $row->{entry_type},
        bibtex_key      => $row->{bibtex_key},
        bibtex_type     => $row->{bibtex_type},
        bib             => $row->{bib},
        html            => $row->{html},
        html_bib        => $row->{html_bib},
        abstract        => $row->{abstract},
        title           => $row->{title},
        hidden          => $row->{hidden},
        year            => $row->{year},
        month           => $row->{month},
        sort_month      => $row->{sort_month},
        teams_str       => $row->{teams_str},
        people_str      => $row->{people_str},
        tags_str        => $row->{tags_str},
        creation_time   => $row->{creation_time},
        modified_time   => $row->{modified_time},
        need_html_regen => $row->{need_html_regen}
    );
    $e->decodeLatex();
    return $e;
}
####################################################################################
sub update {
    my $self = shift;
    my $dbh  = shift;

    return -1 unless defined $self->{id};


    # update field 'modified_time' only if needed
    my $need_modified_update
        = not $self->equals_bibtex( MEntry->static_get( $dbh, $self->{id} ) );

    my $qry = "UPDATE Entry SET
                entry_type=?,
                bibtex_key=?,
                bibtex_type=?,
                bib=?,
                html=?,
                html_bib=?,
                abstract=?,
                title=?,
                hidden=?,
                year=?,
                month=?,
                sort_month=?,
                teams_str=?,
                people_str=?,
                tags_str=?,
                need_html_regen=?";
    $qry .= ", modified_time=NOW()" if $need_modified_update;
    $qry .= "WHERE id = ?";

    # po tags_str
    # creation_time=?,
    # modified_time=NOW(),
    # przed need_html_regen=?

    my $sth = $dbh->prepare($qry);
    my $result;
    try {
        $result = $sth->execute(
            $self->{entry_type},  $self->{bibtex_key},
            $self->{bibtex_type}, $self->{bib},
            $self->{html},        $self->{html_bib},
            $self->{abstract},    $self->{title},
            $self->{hidden},      $self->{year},
            $self->{month},       $self->{sort_month},
            $self->{teams_str},   $self->{people_str},
            $self->{tags_str},    $self->{need_html_regen},
            $self->{id}
        );
        $sth->finish();
    }
    catch {
        warn "MEntry update exception: $_";
    };
    return $result;
}
####################################################################################
sub insert {
    my $self = shift;
    my $dbh  = shift;

    my $result = "";

    my $qry = "
    INSERT INTO Entry(
    entry_type,
    bibtex_key,
    bibtex_type,
    bib,
    html,
    html_bib,
    abstract,
    title,
    hidden,
    year,
    month,
    sort_month,
    teams_str,
    people_str,
    tags_str,
    creation_time,
    modified_time,
    need_html_regen
    ) 
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW(),NOW(),?);";
    my $sth = $dbh->prepare($qry);
    $result = $sth->execute(
        $self->{entry_type}, $self->{bibtex_key}, $self->{bibtex_type},
        $self->{bib}, $self->{html}, $self->{html_bib}, $self->{abstract},
        $self->{title}, $self->{hidden}, $self->{year}, $self->{month},
        $self->{sort_month}, $self->{teams_str}, $self->{people_str},
        $self->{tags_str},

        # $self->{creation_time},
        # $self->{modified_time},
        $self->{need_html_regen},
    );
    my $inserted_id = $dbh->last_insert_id( '', '', 'Entry', '' );
    $self->{id} = $inserted_id;

    # say "Mentry insert. inserted_id = $inserted_id";
    $sth->finish();
    return $inserted_id;    #or $result;
}
####################################################################################
sub insert_authors {
    my $self = shift;
    my $dbh  = shift;


    my $sth = $dbh->prepare('DELETE FROM Entry_to_Author WHERE entry_id = ?');
    $sth->execute($self->{id});

    foreach my $author ($self->authors_all){
        my $author_id = $author->{master_id} or $author->{id};
        my $sth2 = $dbh->prepare(
            'INSERT IGNORE INTO Entry_to_Author(author_id, entry_id) VALUES(?, ?)'
            );
        $sth2->execute( $author_id, $self->{id} );
    }
}
####################################################################################
sub insert_tags {
    my $self = shift;
    my $dbh  = shift;


    my $sth = $dbh->prepare('DELETE FROM Entry_to_Tag WHERE entry_id = ?');
    $sth->execute($self->{id});

    foreach my $tag ($self->tags_all){
        my $sth2 = $dbh->prepare(
            'INSERT IGNORE INTO Entry_to_Tag(tag_id, entry_id) VALUES(?, ?)'
            );
        $sth2->execute( $tag->{id}, $self->{id} );
    }
}
####################################################################################
sub insert_exceptions {
    my $self = shift;
    my $dbh  = shift;


    my $sth = $dbh->prepare('DELETE FROM Exceptions_Entry_to_Team WHERE entry_id = ?');
    $sth->execute($self->{id});

    foreach my $exception_team ($self->exceptions_all){
        my $sth2 = $dbh->prepare(
            'INSERT IGNORE INTO Exceptions_Entry_to_Team(team_id, entry_id) VALUES(?, ?)'
            );
        $sth2->execute( $exception_team->{id}, $self->{id} );
    }
}
####################################################################################
sub save {
    my $self = shift;
    my $dbh  = shift;

    my $result = "";

    $self->decodeLatex();
    $self->populate_from_bib();

    $self->{creation_time} = '1970-01-01 00:00:00'
        if !defined $self->{creation_time}
        or $self->{creation_time} eq ''
        or $self->{creation_time} eq '0000-00-00 00:00:00';

    if ( !defined $self->{id} or $self->{id} <= 0 ) {
        my $inserted_id = $self->insert($dbh);
        $self->{id} = $inserted_id;
        $self->insert_authors($dbh);
        $self->insert_tags($dbh);
        $self->insert_exceptions($dbh);

        # say "Mentry save: inserting. inserted_id = ".$self->{id};
        return $inserted_id;
    }
    elsif ( defined $self->{id} and $self->{id} > 0 ) {

        # say "Mentry save: updating ID = ".$self->{id};
        my $result = $self->update($dbh);
        $self->insert_authors($dbh);
        $self->insert_tags($dbh);
        $self->insert_exceptions($dbh);
        return $result;
    }
    else {
        warn "Mentry save: cannot either insert nor update :( ID = "
            . $self->{id};
    }
}
####################################################################################
sub delete {
    my $self = shift;
    my $dbh  = shift;

    my $qry    = "DELETE FROM Entry WHERE id=?;";
    my $sth    = $dbh->prepare($qry);
    my $result = $sth->execute( $self->{id} );

    return $result;
}

####################################################################################
sub static_get_filter {
    my $self = shift;
    my $dbh  = shift;

    my $master_id   = shift;
    my $year        = shift;
    my $bibtex_type = shift;
    my $entry_type  = shift;
    my $tagid       = shift;
    my $teamid      = shift;
    my $visible     = shift || 0;
    my $permalink   = shift;
    my $hidden      = shift;



    my @params;

    my $qry = "SELECT DISTINCT          
                      Entry.id,
                      Entry.entry_type,
                      Entry.bibtex_key,
                      Entry.bibtex_type,
                      Entry.bib,
                      Entry.html,
                      Entry.html_bib,
                      Entry.abstract,
                      Entry.title,
                      Entry.hidden,
                      Entry.month,
                      Entry.year,
                      Entry.sort_month,
                      Entry.teams_str,
                      Entry.people_str,
                      Entry.tags_str,
                      Entry.creation_time,
                      Entry.modified_time,
                      Entry.need_html_regen
                FROM Entry
                LEFT JOIN Exceptions_Entry_to_Team  ON Entry.id = Exceptions_Entry_to_Team.entry_id
                LEFT JOIN Entry_to_Author ON Entry.id = Entry_to_Author.entry_id 
                LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 
                LEFT JOIN Author_to_Team ON Entry_to_Author.author_id = Author_to_Team.author_id 
                LEFT JOIN OurType_to_Type ON OurType_to_Type.bibtex_type = Entry.bibtex_type 
                LEFT JOIN Entry_to_Tag ON Entry.id = Entry_to_Tag.entry_id 
                LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id 
                WHERE Entry.bibtex_key IS NOT NULL ";
    if ( defined $hidden ) {
        push @params, $hidden;
        $qry .= "AND Entry.hidden=? ";
    }
    if ( defined $visible and $visible eq '1' ) {
        $qry .= "AND Author.display=1 ";
    }
    if ( defined $master_id ) {
        push @params, $master_id;
        $qry .= "AND Entry_to_Author.author_id=? ";
    }
    if ( defined $year ) {
        push @params, $year;
        $qry .= "AND Entry.year=? ";
    }
    if ( defined $bibtex_type ) {
        push @params, $bibtex_type;
        $qry .= "AND OurType_to_Type.our_type=? ";
    }
    if ( defined $entry_type ) {
        push @params, $entry_type;
        $qry .= "AND Entry.entry_type=? ";
    }
    if ( defined $teamid ) {
        push @params, $teamid;
        push @params, $teamid;

        # push @params, $teamid;
        # $qry .= "AND Exceptions_Entry_to_Team.team_id=?  ";
        $qry
            .= "AND ((Exceptions_Entry_to_Team.team_id=? ) OR (Author_to_Team.team_id=? AND start <= Entry.year  AND (stop >= Entry.year OR stop = 0))) ";
    }
    if ( defined $tagid ) {
        push @params, $tagid;
        $qry .= "AND Entry_to_Tag.tag_id LIKE ?";
    }
    if ( defined $permalink ) {
        push @params, $permalink;
        $qry .= "AND Tag.permalink LIKE ?";
    }
    $qry
        .= "ORDER BY Entry.year DESC, Entry.sort_month DESC, Entry.creation_time DESC, Entry.modified_time DESC, Entry.bibtex_key ASC";

    # print $qry."\n";

    my $sth = $dbh->prepare_cached($qry);
    $sth->execute(@params);

    my @objs;

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $obj = MEntry->new(
            id              => $row->{id},
            entry_type      => $row->{entry_type},
            bibtex_key      => $row->{bibtex_key},
            bibtex_type     => $row->{bibtex_type},
            bib             => $row->{bib},
            html            => $row->{html},
            html_bib        => $row->{html_bib},
            abstract        => $row->{abstract},
            title           => $row->{title},
            hidden          => $row->{hidden},
            year            => $row->{year},
            month           => $row->{month},
            sort_month      => $row->{sort_month},
            teams_str       => $row->{teams_str},
            people_str      => $row->{people_str},
            tags_str        => $row->{tags_str},
            creation_time   => $row->{creation_time},
            modified_time   => $row->{modified_time},
            need_html_regen => $row->{need_html_regen}
        );
        $obj->decodeLatex();
        push @objs, $obj;
    }

    # {
    #      no warnings 'uninitialized';
    #     say " MEntry static_get_filter
    #             master_id $master_id
    #             year $year
    #             bibtex_type $bibtex_type
    #             entry_type $entry_type
    #             tagid $tagid
    #             teamid $teamid
    #             visible $visible
    #             permalink $permalink
    #             hidden $hidden
    #             num results = " . (scalar @objs) ."
    #     ";
    # }
    return @objs;
}
####################################################################################

no Moose;
__PACKAGE__->meta->make_immutable;
1;
