package MEntryMySQL;

use BibSpace::Model::MEntryBase;
use BibSpace::Model::MTag;
use BibSpace::Model::MTagType;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           #because of ~~ and say
use DBI;
use Try::Tiny;
use TeX::Encode;
use Encode;
use Moose;
use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

extends 'MEntryBase';


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
sub static_get_by_bibtex_key {
    my $self       = shift;
    my $dbh        = shift;
    my $bibtex_key = shift;

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
          WHERE bibtex_key = ?";

    my $sth = $dbh->prepare($qry);
    $sth->execute($bibtex_key);
    my $row = $sth->fetchrow_hashref();

    if ( !defined $row ) {
        return undef;
    }

    my $e = MEntry->new(
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
    $e->decodeLatex();
    return $e;
}
####################################################################################
sub bump_modified_time {
    my $self = shift;
    my $dbh  = shift;

    return -1 unless defined $self->{id};

    my $qry = "UPDATE Entry SET
                modified_time=NOW()
                WHERE id = ?";

    my $sth = $dbh->prepare($qry);
    my $result;
    try {
        $result = $sth->execute( $self->{id} );
        $sth->finish();
    }
    catch {
        warn "MEntry update exception: $_";
    };
    return $result;
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
                need_html_regen=?
                WHERE id = ?";

    # po tags_str
    # creation_time=?,
    # modified_time=NOW(),
    # przed need_html_regen=?

    my $sth = $dbh->prepare($qry);
    my $result = "";
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
        $self->bump_modified_time($dbh) if $need_modified_update;
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

        # say "Mentry save: inserting. inserted_id = ".$self->{id};
        return $inserted_id;
    }
    elsif ( defined $self->{id} and $self->{id} > 0 ) {

        # say "Mentry save: updating ID = ".$self->{id};
        return $self->update($dbh);
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
sub authors {
    my $self = shift;
    my $dbh  = shift;

    die "MEntry::authors Calling authors on undefined or empty entry!"
        if !defined $self->{id}
        or $self->{id} < 0;
    die "MEntry::authors Calling authors with no database hande!"
        unless defined $dbh;


    my $qry
        = "SELECT entry_id, author_id FROM Entry_to_Author WHERE entry_id = ?";
    my $sth = $dbh->prepare_cached($qry);
    $sth->execute( $self->{id} );

    my @authors;

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $author = MAuthor->static_get( $dbh, $row->{author_id} );

        push @authors, $author if defined $author;
    }
    return @authors;
}
####################################################################################
sub teams {
    my $self = shift;
    my $dbh  = shift;

    die "MEntry::teams Calling authors on undefined or empty entry!"
        if !defined $self->{id}
        or $self->{id} < 0;
    die "MEntry::teams Calling authors with no database handle!"
        unless defined $dbh;

    my %final_teams;
    foreach my $author ( $self->authors($dbh) ) {
        foreach my $team ( $author->teams($dbh) ) {
            if ($author->joined_team( $dbh, $team ) <= $self->{year}
                and (  $author->left_team( $dbh, $team ) > $self->{year}
                    or $author->left_team( $dbh, $team ) == 0 )
                )
            {
                # $final_teams{$team}       = 1; # BAD: $team gets stringified
                $final_teams{ $team->{id} } = $team;
            }
        }
    }
    return values %final_teams;
}
####################################################################################
sub exceptions {
    my $self = shift;
    my $dbh  = shift;

    die "MEntry::exceptions Calling authors on undefined or empty entry!"
        if !defined $self->{id}
        or $self->{id} < 0;
    die "MEntry::exceptions Calling authors with no database handle!"
        unless defined $dbh;


    my $qry
        = "SELECT team_id, entry_id FROM Exceptions_Entry_to_Team WHERE entry_id = ?";
    my $sth = $dbh->prepare_cached($qry);
    $sth->execute( $self->{id} );

    my %teams;
    while ( my $row = $sth->fetchrow_hashref() ) {
        my $team = MTeam->static_get( $dbh, $row->{team_id} );
        $teams{ $team->{id} } = $team;
    }

    return values %teams;
}
####################################################################################
sub remove_exception {
    my $self      = shift;
    my $dbh       = shift;
    my $exception = shift;

    return 0
        if !defined $exception
        or !defined $self->{id}
        or $self->{id} < 0;

    my $sth
        = $dbh->prepare(
        "DELETE FROM Exceptions_Entry_to_Team WHERE entry_id=? AND team_id=?"
        );
    return $sth->execute( $self->{id}, $exception->{id} );
}
####################################################################################
sub assign_exception {
    my $self      = shift;
    my $dbh       = shift;
    my $exception = shift;

    return 0
        if !defined $exception
        or !defined $self->{id}
        or $self->{id} < 0;

    my $sth
        = $dbh->prepare(
        'INSERT IGNORE INTO Exceptions_Entry_to_Team(entry_id, team_id) VALUES(?, ?)'
        );
    $sth->execute( $self->{id}, $exception->{id} );
    return 1;
}
####################################################################################
sub static_entries_with_exception {
    my $self = shift;
    my $dbh  = shift;

    die
        "MEntry::static_entries_with_exception Calling authors with no database handle!"
        unless defined $dbh;


    my $qry
        = "SELECT DISTINCT entry_id FROM Exceptions_Entry_to_Team WHERE team_id>-1";
    my $sth = $dbh->prepare_cached($qry);
    $sth->execute();

    my @objs;
    while ( my $row = $sth->fetchrow_hashref() ) {
        my $entry = MEntry->static_get( $dbh, $row->{entry_id} );
        push @objs, $entry;
    }

    return @objs;
}
####################################################################################
sub assign_author {
    my $self   = shift;
    my $dbh    = shift;
    my $author = shift;

    if ( defined $author ) {
        my $sth
            = $dbh->prepare(
            'INSERT IGNORE INTO Entry_to_Author(author_id, entry_id) VALUES(?, ?)'
            );
        $sth->execute( $author->{id}, $self->{id} );
        return 1;
    }
    return 0;
}
####################################################################################
sub remove_author {
    my $self   = shift;
    my $dbh    = shift;
    my $author = shift;

    if ( defined $author ) {

        my $sth
            = $dbh->prepare(
            'DELETE FROM Entry_to_Author WHERE entry_id = ? AND author_id = ?'
            );
        $sth->execute( $self->{id}, $author->{id} );
        return 1;
    }
    return 0;
}
####################################################################################
sub remove_all_authors {
    my $self = shift;
    my $dbh  = shift;

    if ( defined $self->{id} ) {
        my $sth
            = $dbh->prepare('DELETE FROM Entry_to_Author WHERE entry_id = ?');
        $sth->execute( $self->{id} );
    }
}
####################################################################################

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
sub has_tag_named {
    my $self        = shift;
    my $dbh         = shift;
    my $tag_to_find = shift;

    my $mtag = MTag->static_get_by_name( $dbh, $tag_to_find );
    return 0 if !defined $mtag;
    return 0 if defined $mtag and $mtag->{id} < 0;

    my $tag_id = $mtag->{id};
    my $qry
        = "SELECT COUNT(*) FROM Entry_to_Tag WHERE entry_id = ? AND tag_id = ?";
    my @ary = $dbh->selectrow_array( $qry, undef, $self->{id}, $tag_id );
    my $key_exists = $ary[0];

    #my $sth = $dbh->prepare( $qry );
    #$sth->execute($self->{id}, $tag_id);

    return $key_exists == 1;

}
####################################################################################
sub tags {
    my $self     = shift;
    my $dbh      = shift;
    my $tag_type = shift;    # optional

    return () if !defined $self->{id} or $self->{id} < 0;

    my $qry = "SELECT entry_id, tag_id 
                FROM Entry_to_Tag 
                LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id
                WHERE entry_id = ?";
    my $sth;
    if ( defined $tag_type ) {
        $qry .= " AND Tag.type = ?";
        $sth = $dbh->prepare_cached($qry);
        $sth->execute( $self->{id}, $tag_type );
    }
    else {
        $sth = $dbh->prepare_cached($qry);
        $sth->execute( $self->{id} );
    }


    my @tags = ();

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $tag_id = $row->{tag_id};
        my $mtag = MTag->static_get( $dbh, $tag_id );
        push @tags, $mtag if defined $mtag;
    }
    return @tags;
}
####################################################################################
sub add_tags {
    my $self              = shift;
    my $dbh               = shift;
    my $tag_names_arr_ref = shift;
    my $tag_type          = shift // 1;
    my @tag_names         = @$tag_names_arr_ref;

    my $num_added = 0;

    return 0 if !defined $self->{id} or $self->{id} < 0;

    # say "MEntry add_tags type $tag_type. Tags: " . join(", ", @tag_names);

    foreach my $tn (@tag_names) {
        my $t = MTag->static_get_by_name( $dbh, $tn );
        if ( !defined $t ) {
            $t = MTag->new( name => $tn, type => $tag_type );
            $t->save($dbh);
        }
        $t = MTag->static_get_by_name( $dbh, $tn );
        $num_added = $num_added + $self->assign_tag( $dbh, $t );
    }
    return $num_added;
}
####################################################################################
sub assign_tag {
    my $self = shift;
    my $dbh  = shift;
    my $tag  = shift;

    my $num_added = 0;

    return 0
        if !defined $self->{id}
        or $self->{id} < 0
        or !defined $tag
        or $tag->{id} <= 0;

    my $sth = $dbh->prepare(
        "INSERT IGNORE INTO Entry_to_Tag( entry_id, tag_id) VALUES (?,?)");
    $num_added = $sth->execute( $self->{id}, $tag->{id} );
    return $num_added;
}
####################################################################################
sub remove_tag {
    my $self = shift;
    my $dbh  = shift;
    my $tag  = shift;

    return 0 if !defined $tag or !defined $self->{id} or $self->{id} < 0;

    my $sth = $dbh->prepare(
        "DELETE FROM Entry_to_Tag WHERE entry_id=? AND tag_id=?");

    return $sth->execute( $self->{id}, $tag->{id} );
}
####################################################################################
sub remove_tag_by_id {
    my $self   = shift;
    my $dbh    = shift;
    my $tag_id = shift;

    return $self->remove_tag( $dbh, MTag->static_get( $dbh, $tag_id ) );
}
####################################################################################
sub remove_tag_by_name {
    my $self     = shift;
    my $dbh      = shift;
    my $tag_name = shift;

    return $self->remove_tag( $dbh,
        MTag->static_get_by_name( $dbh, $tag_name ) );
}
####################################################################################

no Moose;
__PACKAGE__->meta->make_immutable;
1;
