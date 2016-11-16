package BibSpace::Functions::FSet;

use strict;
use warnings;
use Data::Dumper;
use utf8;
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010;    #because of ~~
use DBI;

use Set::Scalar;

use BibSpace::Controller::Core;
use BibSpace::Model::MTeam;
use BibSpace::Model::MEntry;

use Exporter;
our @ISA = qw( Exporter );

our @EXPORT = qw(
    Fget_set_of_all_team_ids
    Fget_set_of_papers_for_team
    Fget_set_of_papers_with_exceptions
    Fget_set_of_tagged_papers
    Fget_set_of_papers_for_all_authors_of_team_id
    Fget_set_of_authors_for_team
    Fget_set_of_teams_for_author_id_w_year
    Fget_set_of_papers_for_author_id
    Fget_set_of_papers_for_team_and_tag
    Fget_set_of_teams_for_author_id
);

sub Fget_set_of_all_team_ids {
    my $dbh = shift;

    return Set::Scalar->new( map { $_->{id} } MTeam->static_all($dbh) );
}

sub Fget_set_of_papers_for_team {
    my $dbh = shift;
    my $tid = shift;

    my $set = new Set::Scalar;

    my @params;

    my $qry
        = "SELECT DISTINCT Entry.bibtex_key, Entry.id, Entry.bib, Entry.year, Entry.html, Entry.bibtex_type
                FROM Entry
                LEFT JOIN Exceptions_Entry_to_Team  ON Entry.id = Exceptions_Entry_to_Team.entry_id
                LEFT JOIN Entry_to_Author ON Entry.id = Entry_to_Author.entry_id 
                LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 
                LEFT JOIN Author_to_Team ON Entry_to_Author.author_id = Author_to_Team.author_id 
                LEFT JOIN OurType_to_Type ON OurType_to_Type.bibtex_type = Entry.bibtex_type 
                LEFT JOIN Entry_to_Tag ON Entry.id = Entry_to_Tag.entry_id 
                WHERE Entry.bibtex_key IS NOT NULL ";

    push @params, $tid;
    push @params, $tid;

    $qry
        .= "AND ((Exceptions_Entry_to_Team.team_id=? ) OR (Author_to_Team.team_id=? AND start <= Entry.year  AND (stop >= Entry.year OR stop = 0))) ";

    $qry .= "ORDER BY Entry.year DESC, Entry.bibtex_key ASC";

    my $sth = $dbh->prepare_cached($qry);
    $sth->execute(@params);

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $eid = $row->{id};

        $set->insert($eid);
    }
    return $set;
}

sub Fget_set_of_papers_with_exceptions {
    my $dbh = shift;
    my $set = new Set::Scalar;

    my @entries = MEntry->static_entries_with_exception( $dbh );
    map { $set->insert( $_->{id} ) } @entries;

    return $set;
}

sub Fget_set_of_tagged_papers {
    my $dbh = shift;

    my $set = new Set::Scalar;

    my $qry = "SELECT DISTINCT entry_id FROM Entry_to_Tag";
    my $sth = $dbh->prepare($qry);
    $sth->execute();

    my @array;
    while ( my $row = $sth->fetchrow_hashref() ) {
        my $eid = $row->{entry_id};
        $set->insert($eid);
    }

    return $set;
}

# sub Fget_set_of_papers_with_no_tags {
#     my $dbh = shift;

#     my $set = new Set::Scalar;

#     my $qry
#         = "SELECT DISTINCT id, key FROM Entry WHERE id NOT IN (SELECT DISTINCT entry_id FROM Entry_to_Tag);";
#     my $sth = $dbh->prepare($qry);
#     $sth->execute();

#     my @array;
#     while ( my $row = $sth->fetchrow_hashref() ) {
#         my $eid = $row->{id};
#         $set->insert($eid);
#     }

#     return $set;
# }

sub Fget_set_of_papers_for_all_authors_of_team_id {
    my $dbh = shift;
    my $tid = shift;

    my $set = new Set::Scalar;

    my $authors_set = Fget_set_of_authors_for_team( $dbh, $tid );

    while ( defined( my $aid = $authors_set->each ) ) {
        $set = $set + Fget_set_of_papers_for_author_id( $dbh, $aid );

    }

    return $set;
}

sub Fget_set_of_authors_for_team {
    my $dbh = shift;
    my $tid = shift;

    my $set = new Set::Scalar;

    my $qry = "SELECT author_id, team_id 
            FROM Author_to_Team 
            WHERE team_id=?";
    my $sth = $dbh->prepare($qry);
    $sth->execute($tid);

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $eid = $row->{author_id};

        $set->insert($eid);
    }
    return $set;
}

sub Fget_set_of_papers_for_author_id {
    my $dbh = shift;
    my $aid = shift;

    my $set = new Set::Scalar;

    my $qry = "SELECT author_id, entry_id 
            FROM Entry_to_Author 
            WHERE author_id=?";
    my $sth = $dbh->prepare($qry);
    $sth->execute($aid);

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $eid = $row->{entry_id};
        $set->insert($eid);
    }

    return $set;
}

sub Fget_set_of_papers_for_team_and_tag {
    my $dbh    = shift;
    my $teamid = shift;
    my $tagid  = shift;

    # my @en_objs          = MEntry->static_get_filter(
    #     $dbh,              $test_master_id,  $test_year,
    #     $test_bibtex_type, $test_entry_type, $test_tagid,
    #     $test_teamid,      $test_visible,    $test_permalink,
    #     $test_hidden
    # );

    my @en_objs = MEntry->static_get_filter(
        $dbh,    undef, undef, undef, undef, $tagid,
        $teamid, undef, undef, undef
    );

    return Set::Scalar->new( map { $_->{id} } @en_objs );
}

sub Fget_set_of_teams_for_author_id_w_year {
    my $dbh  = shift;
    my $aid  = shift;
    my $year = shift;

    my $set = new Set::Scalar;

    my $qry = "SELECT author_id, team_id 
            FROM Author_to_Team 
            WHERE author_id=?
            AND start <= ?  AND (stop >= ? OR stop = 0)";
    my $sth = $dbh->prepare($qry);
    $sth->execute( $aid, $year, $year );

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $tid = $row->{team_id};

        $set->insert($tid);
    }
    return $set;
}

sub Fget_set_of_teams_for_author_id {
    my $dbh = shift;
    my $aid = shift;

    my $set = new Set::Scalar;

    my $qry = "SELECT author_id, team_id 
            FROM Author_to_Team 
            WHERE author_id=?";
    my $sth = $dbh->prepare($qry);
    $sth->execute($aid);

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $tid = $row->{team_id};

        $set->insert($tid);
    }
    return $set;
}

# sub Fget_set_of_authors_for_entry_id {    # TODO: refactor it away to MEntry!
#     my $dbh = shift;
#     my $eid = shift;
#     my $set = new Set::Scalar;
#     my $qry = "SELECT author_id FROM Entry_to_Author WHERE entry_id=?";
#     my $sth = $dbh->prepare($qry);
#     $sth->execute($eid);
#     while ( my $row = $sth->fetchrow_hashref() ) {
#         my $aid = $row->{author_id};
#         $set->insert($aid);
#     }
#     return $set;
# }

