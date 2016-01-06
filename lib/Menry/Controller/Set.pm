package Menry::Controller::Set;

use Data::Dumper;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; #because of ~~
use strict;
use warnings;
use DBI;

use Menry::Controller::Core;

use Set::Scalar;

use Exporter;
our @ISA= qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw( 
    get_set_of_papers_for_author_id
    get_set_of_authors_for_team
    get_set_of_papers_for_all_authors_of_team_id
    get_set_of_papers_for_team
    get_set_of_all_papers
    get_ids_arr_of_unassigned_tags
    get_set_of_papers_with_no_tags
    get_set_of_tagged_papers
    get_set_of_teams_for_author_id
    get_set_of_teams_for_author_id_w_year
    get_set_of_teams_for_entry_id
    get_set_of_all_teams
    get_set_of_papers_for_author_and_tag
    get_set_of_papers_for_author_and_team
    get_set_of_papers_for_team_and_tag
    get_set_of_papers_with_exceptions
   );


####################################################################################

sub get_ids_arr_of_unassigned_tags {
    my $self = shift;
    my $eid = shift;
    my $dbh = $self->app->db;

    

    my ($all_tags_arrref, $all_ids_arrref, $all_parents_arrref) = get_all_tags($dbh);
    my ($tags_arrref, $ids_arrref, $parents_arrref) = get_tags_for_entry($dbh, $eid);

    my $set_all_tags = Set::Scalar->new(@$all_ids_arrref);
    my $set_assigned_tags = Set::Scalar->new(@$ids_arrref);
    # probles with sorting when using sets!


    my @result;

    for my $t (@$all_ids_arrref){
        if ( !grep( /^$t$/, @$ids_arrref ) ) {
            push @result, $t;
        }
    }

    # @result = ($set_all_tags - $set_assigned_tags)->members;
    return @result;
    
}
####################################################################################

sub get_set_of_all_teams {
    my $self = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;


    my @params;

    my $qry = "SELECT DISTINCT id
                FROM Team
                WHERE name IS NOT NULL ";

    my $sth = $dbh->prepare_cached( $qry );  
    $sth->execute(@params); 

    while(my $row = $sth->fetchrow_hashref()) {
      my $team_id = $row->{id};

      $set->insert($team_id);
    }

    return $set;
}
####################################################################################

sub get_set_of_all_papers {
    my $self = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;


    my @params;

    my $qry = "SELECT DISTINCT id
                FROM Entry
                WHERE bibtex_key IS NOT NULL ";
    $qry .= "ORDER BY year DESC, bibtex_key ASC";

    my $sth = $dbh->prepare_cached( $qry );  
    $sth->execute(@params); 

    while(my $row = $sth->fetchrow_hashref()) {
      my $eid = $row->{id};

      $set->insert($eid);
    }

    return $set;
}

####################################################################################

sub get_set_of_papers_for_team {
    my $self = shift;
    my $tid = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;


    my @params;

    my $qry = "SELECT DISTINCT Entry.bibtex_key, Entry.id, bib, html, Entry.bibtex_type
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
    # push @params, $tid;
    # $qry .= "AND ((Exceptions_Entry_to_Team.team_id=? ) OR Author.display = 1) ";
    $qry .= "AND ((Exceptions_Entry_to_Team.team_id=? ) OR (Author_to_Team.team_id=? AND start <= Entry.year  AND (stop >= Entry.year OR stop = 0))) ";
    
    $qry .= "ORDER BY Entry.year DESC, Entry.bibtex_key ASC";

    my $sth = $dbh->prepare_cached( $qry );  
    $sth->execute(@params); 

    while(my $row = $sth->fetchrow_hashref()) {
      my $eid = $row->{id};

      $set->insert($eid);
    }

    return $set;
}


####################################################################################

sub get_set_of_papers_with_exceptions {
    my $self = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;


    my @params;

    my $qry = "SELECT DISTINCT entry_id FROM Exceptions_Entry_to_Team WHERE team_id>-1";
    my $sth = $dbh->prepare_cached( $qry );  
    $sth->execute(); 

    while(my $row = $sth->fetchrow_hashref()) {
      my $eid = $row->{entry_id};
      $set->insert($eid);
    }

    return $set;
} 

####################################################################################

sub get_set_of_tagged_papers {
    my $self = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;


    my $qry = "SELECT DISTINCT entry_id FROM Entry_to_Tag";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute(); 

    my @array;
    while(my $row = $sth->fetchrow_hashref()) {
        my $eid = $row->{entry_id};
        $set->insert($eid);
    } 

    return $set;
} 
####################################################################################

sub get_set_of_papers_with_no_tags {
    my $self = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;


    my $qry = "SELECT DISTINCT id, key FROM Entry WHERE id NOT IN (SELECT DISTINCT entry_id FROM Entry_to_Tag)";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute(); 

    my @array;
    while(my $row = $sth->fetchrow_hashref()) {
        my $eid = $row->{id};
        $set->insert($eid);
    } 

    return $set;
} 

####################################################################################

sub get_set_of_papers_for_all_authors_of_team_id {
    my $self = shift;
    my $tid = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;

    my $authors_set = get_set_of_authors_for_team($self, $tid);

    while (defined(my $aid = $authors_set->each)){
        $set = $set + get_set_of_papers_for_author_id($self, $aid);

    }

    return $set;
}
####################################################################################

sub get_set_of_authors_for_team {
    my $self = shift;
    my $tid = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;


    my $qry = "SELECT author_id, team_id 
            FROM Author_to_Team 
            WHERE team_id=?";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($tid); 

    while(my $row = $sth->fetchrow_hashref()) {
      my $eid = $row->{author_id};

      $set->insert($eid);
    }
    # print "Authors for team: ", $set, "\n";
    return $set;
 }
####################################################################################

sub get_set_of_papers_for_author_id {
    my $self = shift;
    my $aid = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;


    my $qry = "SELECT author_id, entry_id 
            FROM Entry_to_Author 
            WHERE author_id=?";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($aid); 

    while(my $row = $sth->fetchrow_hashref()) {
      my $eid = $row->{entry_id};

      $set->insert($eid);
    }
    # print "Papers for author $aid: ", $set, "\n";
    return $set;
 }


 ####################################################################################

sub get_set_of_papers_for_tag {
    my $self = shift;
    my $tid = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;


    my $qry = "SELECT entry_id
            FROM Entry_to_Tag 
            WHERE tag_id=?";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($tid); 

    while(my $row = $sth->fetchrow_hashref()) {
      my $eid = $row->{entry_id};

      $set->insert($eid);
    }
    print "Papers for tag $tid: ", $set, "\n";
    return $set;
 }
####################################################################################

sub get_set_of_papers_for_author_and_tag {
    my $self = shift;
    my $aid = shift;
    my $tid = shift;
    my $dbh = $self->app->db;

    say "This function (get_set_of_papers_for_author_and_tag) may be deprecated! It does not take into account hidden!";

    my $set_author_papers = get_set_of_papers_for_author_id($self, $aid);
    my $set_tag_papers = get_set_of_papers_for_tag($self, $tid);
    
    return $set_tag_papers * $set_author_papers;
 }

####################################################################################

sub get_set_of_papers_for_team_and_tag {
    my $self = shift;
    my $teamid = shift;
    my $tagid = shift;
    my $dbh = $self->app->db;

    my $set_tag_papers = get_set_of_papers_for_tag($self, $tagid);
    my $set_team_papers = get_set_of_papers_for_team($self, $teamid);
    
    return $set_tag_papers * $set_team_papers;
 }
####################################################################################
sub get_set_of_papers_for_author_and_team{
    my $self = shift;
    my $aid = shift;
    my $tid = shift;
    my $dbh = $self->app->db;

    my $set_author_papers = get_set_of_papers_for_author_id($self, $aid);
    my $set_team_papers = get_set_of_papers_for_team($self, $tid);

    return $set_team_papers * $set_author_papers;

}
####################################################################################

sub get_set_of_teams_for_author_id_w_year {
    my $self = shift;
    my $aid = shift;
    my $year = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;


    my $rs = $dbh->resultset('AuthorToTeam')->search(
    {
        '-and' => [
            'author_id' => $aid,
            'start' => {'<=', $year},
            '-or' => [
                'stop' => 0,
                'stop' => {'>=', $year},
            ]
        ]
    })->get_column('team_id');

    for my $tid ($rs->all) {
        $set->insert($tid);
    }

    
    print "Teams for author $aid: ", $set, "\n";
    return $set;
 }
####################################################################################

sub get_set_of_teams_for_author_id {
    my $self = shift;
    my $aid = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;


    my $rs = $self->app->db->resultset('AuthorToTeam')->search({author_id => $aid})->get_column('team_id');

    for my $tid ($rs->all) {
        $set->insert($tid);
    }
    print "Teams for author $aid: ", $set, "\n";
    return $set;
 }
####################################################################################

sub get_set_of_authors_for_entry_id {
    my $self = shift;
    my $eid = shift;
    my $dbh = $self->app->db;

    my $set = new Set::Scalar;


    my $rs = $self->app->db->resultset('EntryToAuthor')->search({entry_id => $eid})->get_column('author_id');


    for my $aid ($rs->all) {
      $set->insert($aid);
    }
    print "Authors of entry $eid: ", $set, "\n";
    return $set;
 }
####################################################################################
sub get_set_of_teams_for_entry_id {
    my $self = shift;
    my $eid = shift;
    my $dbh = $self->app->db;

    my $rs = $self->app->db->resultset('Entry')->search({id => $eid})->get_column('year');
    my $entry_year = $rs->first;

    my $teams_for_paper = new Set::Scalar;

    my $authors_set = get_set_of_authors_for_entry_id($self,$eid);

    while (defined(my $aid = $authors_set->each)){
        $teams_for_paper = $teams_for_paper + get_set_of_teams_for_author_id_w_year($self, $aid, $entry_year);
    }

    print "Teams for paper $eid: ", $teams_for_paper, "\n";
    return $teams_for_paper;
 }



1;