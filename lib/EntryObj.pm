package EntryObj;

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

sub new
{
    my ($class, $args) = @_;
    my $self = {
        id    => $args->{id},
        key  => $args->{key} || "",
        type  => $args->{type} || "",
        bib  => $args->{bib} || "",
        html => $args->{html} || "no HTML for key ".$args->{key},
        mtime  => $args->{mtime} || 0,
        ctime  => $args->{ctime} || 0,
        year  => $args->{year} || 0,
    };
    return bless $self, $class;
}

sub initFromDB{
    my $self = shift;
    my $dbh = shift;

    my $qry = "SELECT DISTINCT id, key, type, bib, html, modified_time, creation_time
               FROM Entry
               WHERE id = ?";

    my $sth = $dbh->prepare( $qry );  
    $sth->execute($self->{id});  

  
    my $row = $sth->fetchrow_hashref();
    $self->{key} = $row->{key};
    $self->{year} = $row->{year};
    $self->{type} = $row->{type} || "";
    $self->{bib} = $row->{bib} || "";
    $self->{html} = $row->{html} || "nohtml";
    $self->{ctime} = $row->{creation_time} || 0;
    $self->{mtime} = $row->{modified_time} || 0;



}
########################################################################################################################
########################################################################################################################
sub getAll{
    my $self = shift;
    my $dbh = shift;

    my $qry = "SELECT id, key, type, bib, html, modified_time, creation_time
                FROM Entry 
                WHERE key NOT NULL 
                ORDER BY year DESC, modified_time ASC";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute();  

    my @objs;

    while(my $row = $sth->fetchrow_hashref()) {
        my $obj = EntryObj->new({id => $row->{id},
                                key => $row->{key},
                                year => $row->{year},
                                type => $row->{type},
                                bib => $row->{bib},
                                html => $row->{html},
                                ctime => $row->{creation_time},
                                mtime => $row->{modified_time},
                            });
        push @objs, $obj;
    }
    return @objs;
}
########################################################################################################################
########################################################################################################################
sub getFromArray{
    my $self = shift;
    my $dbh = shift;
    my $arr_ref = shift; 
    my @arr = @{$arr_ref}; 

    my $sort = shift;
    $sort = 1 unless defined $sort;

    my $placeholders = "";
    my $arr_size = scalar @arr;
    # say "arr size: $arr_size";
    # say "arr ".join(" ", @arr);

    if($arr_size >= 1){
        $placeholders = "?";
    }

    for (2..$arr_size){
        $placeholders .= ",?";
    }


    my @objs;

    if(defined $sort and $sort==1){
        my $qry = "SELECT id, key, type, bib, html, modified_time, creation_time
                FROM Entry 
                WHERE key NOT NULL 
                AND id IN (".$placeholders.")";
        if (defined $sort and $sort==1){
            $qry .= "ORDER BY year DESC, modified_time ASC";
        }
        my $sth = $dbh->prepare_cached( $qry );  
        $sth->execute(@arr);  
        while(my $row = $sth->fetchrow_hashref()) {
            my $obj = EntryObj->new({id => $row->{id},
                                key => $row->{key},
                                year => $row->{year},
                                type => $row->{type},
                                bib => $row->{bib},
                                html => $row->{html},
                                ctime => $row->{creation_time},
                                mtime => $row->{modified_time},
            });
            push @objs, $obj;
        }
    }
    else{ # TODO: pobieranie po jednym argumencie i dodawanie do tablicy objs krok po kroku aby utrzymac order!

        # for my $eid (@arr){
        #      my $qry = "SELECT id, key, type, bib, html, modified_time, creation_time FROM Entry WHERE key NOT NULL 
        #         AND id=?";
        #     my $sth = $dbh->prepare_cached( $qry );  
        #     $sth->execute($eid);  
        #     my $row = $sth->fetchrow_hashref();
        #     my $obj = EntryObj->new({id => $row->{id},
        #                         key => $row->{key},
        #                         year => $row->{year},
        #                         type => $row->{type},
        #                         bib => $row->{bib},
        #                         html => $row->{html},
        #                         ctime => $row->{creation_time},
        #                         mtime => $row->{modified_time},
        #     });
        #     push @objs, $obj;
        # }

        my $qry = "SELECT id, key, type, bib, html, modified_time, creation_time
                FROM Entry 
                WHERE key NOT NULL 
                AND id IN (".$placeholders.") ORDER BY CASE id ";

        my $i = 1;
        for my $eid (@arr){
            $qry .= "WHEN $eid THEN $i ";
            $i=$i+1;
        }
        $qry .= "END";
        
        my $sth = $dbh->prepare_cached($qry);
        $sth->execute(@arr); 

        while(my $row = $sth->fetchrow_hashref()) {
            my $obj = EntryObj->new({id => $row->{id},
                                key => $row->{key},
                                year => $row->{year},
                                type => $row->{type},
                                bib => $row->{bib},
                                html => $row->{html},
                                ctime => $row->{creation_time},
                                mtime => $row->{modified_time},
            });
            push @objs, $obj;
        }

    }
    
    


    return @objs;
}
########################################################################################################################
########################################################################################################################


sub getByFilter{
    my $self = shift;
    my $dbh = shift;

    my $mid = shift;
    my $year = shift;
    my $type = shift;
    my $tagid = shift;
    my $teamid = shift;
    my $visible = shift || 0;
    my $permalink = shift;

    my @params;

    my $qry = "SELECT DISTINCT Entry.key, Entry.id, bib, html, Entry.type, Entry.year, modified_time, creation_time
                FROM Entry
                LEFT JOIN Exceptions_Entry_to_Team  ON Entry.id = Exceptions_Entry_to_Team.entry_id
                LEFT JOIN Entry_to_Author ON Entry.id = Entry_to_Author.entry_id 
                LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 
                LEFT JOIN Author_to_Team ON Entry_to_Author.author_id = Author_to_Team.author_id 
                LEFT JOIN OurType_to_Type ON OurType_to_Type.bibtex_type = Entry.type 
                LEFT JOIN Entry_to_Tag ON Entry.id = Entry_to_Tag.entry_id 
                LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id 
                WHERE Entry.key NOT NULL ";
    if(defined $visible and $visible eq '1'){
        $qry .= "AND Author.display=1 ";
    }
    if(defined $mid){
        push @params, $mid;
        $qry .= "AND Entry_to_Author.author_id=? ";
    }
    if(defined $year){
        push @params, $year;
        $qry .= "AND Entry.year=? ";
    }
    if(defined $type){
        push @params, $type;
        $qry .= "AND OurType_to_Type.our_type=? ";
    }
    if(defined $teamid){
        push @params, $teamid;
        push @params, $teamid;
        # push @params, $teamid;
        # $qry .= "AND Exceptions_Entry_to_Team.team_id=?  ";
        $qry .= "AND ((Exceptions_Entry_to_Team.team_id=? ) OR (Author_to_Team.team_id=? AND start <= Entry.year  AND (stop >= Entry.year OR stop = 0))) ";
    }
    if(defined $tagid){
        push @params, $tagid;
        $qry .= "AND Entry_to_Tag.tag_id LIKE ?";
    }
    if(defined $permalink){
        push @params, $permalink;
        $qry .= "AND Tag.permalink LIKE ?";
    } 
    $qry .= "ORDER BY Entry.year DESC, Entry.key ASC";


    my $sth = $dbh->prepare_cached( $qry );  
    $sth->execute(@params); 

    my @objs;

    while(my $row = $sth->fetchrow_hashref()) {
        my $obj = EntryObj->new({id => $row->{id},
                                key => $row->{key},
                                year => $row->{year},
                                type => $row->{type},
                                bib => $row->{bib},
                                html => $row->{html},
                                ctime => $row->{creation_time},
                                mtime => $row->{modified_time},
                            });
        push @objs, $obj;
    }

    return @objs;
}

########################################################################################################################

1;