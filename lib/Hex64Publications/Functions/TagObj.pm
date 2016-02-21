package TagObj;

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
        name  => $args->{name} || "",
        permalink  => $args->{permalink} || "",
        type  => $args->{type} || 1,
    };
    return bless $self, $class;
}

sub initFromDB{
    my $self = shift;
    my $dbh = shift;
    my $qry = "SELECT DISTINCT id, name, type, permalink
               FROM Tag
               WHERE id = ?";

    my $sth = $dbh->prepare( $qry );  
    $sth->execute($self->{id});  

  
    my $row = $sth->fetchrow_hashref();
    $self->{name} = $row->{name};
    $self->{type} = $row->{type} || -1;
    $self->{permalink} = $row->{permalink};
}

##########################################################################
sub get_tag_name_for_permalink{
    my $self = shift;
    my $dbh = shift;
    my $permalink = shift;

    my $sth = $dbh->prepare( "SELECT name FROM Tag WHERE permalink=?" );     
    $sth->execute($permalink);

    my $row = $sth->fetchrow_hashref();
    my $name = $row->{name} || -1;
    return $name;
}


##########################################################################
sub getByName{
    my $self = shift;
    my $dbh = shift;
    my $name = shift;

    my $sth = $dbh->prepare( "SELECT id FROM Tag WHERE name=?" );     
    $sth->execute($name);

    my $row = $sth->fetchrow_hashref();
    my $id = $row->{id} || -1;

    my $obj = TagObj->new({id => $row->{id}});
    $obj->initFromDB($dbh);

    return $obj;

}
##########################################################################
sub getAll{
    my $self = shift;
    my $dbh = shift;
    my $type = shift || 1;

    my $qry = "SELECT DISTINCT id, name, type, permalink FROM Tag WHERE name NOT NULL AND type = ? ORDER BY name ASC";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($type);  

    my @objs;

    while(my $row = $sth->fetchrow_hashref()) {
        my $obj = TagObj->new({id => $row->{id},
                                name => $row->{name},
                                type => $row->{type},
                                permalink => $row->{permalink},
                            });
        push @objs, $obj;
    }
    return @objs;
}

sub getAllwLetter{
    my $self = shift;
    my $dbh = shift;
    my $type = shift || 1;
    my $letter = shift || '%';


    my @params;
    # my $qry = "SELECT DISTINCT id, name, type, permalink, substr(name, 0, 2) as let FROM Tag WHERE name NOT NULL AND type = ? ";
    my $qry = "SELECT DISTINCT id, name, type, permalink FROM Tag WHERE name IS NOT NULL AND type = ? ";
    push @params, $type;
    if(defined $letter){
        push @params, $letter;
        $qry .= "AND substr(name, 1, 1) LIKE ? ";
    }
    $qry .= "ORDER BY name ASC";

    my $sth = $dbh->prepare_cached( $qry );  
    $sth->execute(@params);  

    my @objs;

    while(my $row = $sth->fetchrow_hashref()) {
        push @objs, TagObj->new({id => $row->{id},
                                name => $row->{name},
                                type => $row->{type},
                                permalink => $row->{permalink},
                                });
    }
    return @objs;
}


sub getTagsOfTypeForPaper{
    my $self = shift;
    my $dbh = shift;
    my $eid = shift;
    my $type = shift || 1;

    my $qry = "SELECT Entry.id, Tag.id, Tag.name, Tag.type, Tag.permalink
                FROM Entry
                LEFT JOIN Entry_to_Tag ON Entry.id = Entry_to_Tag.entry_id 
                LEFT JOIN Tag ON Entry_to_Tag.tag_id = Tag.id 
                WHERE Entry.id = ?
                AND Tag.type = ?
                ORDER BY Tag.name";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($eid, $type); 

    my @objs;
    while(my $row = $sth->fetchrow_hashref()) {
        push @objs, TagObj->new({id => $row->{id},
                                name => $row->{name},
                                type => $row->{type},
                                permalink => $row->{permalink},
                                });
    }

    return @objs;
}

sub getUnassignedTagsOfTypeForPaper{
    my $self = shift;
    my $dbh = shift;
    my $eid = shift;
    my $type = shift || 1;

    my $qry = "SELECT id, name, type, permalink
                FROM Tag
                WHERE type = ? 
                AND id NOT IN (
                    SELECT tag_id 
                    FROM Entry_to_Tag
                    WHERE entry_id = ?
                )
                ORDER BY name";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($type, $eid); 

    my @objs;
    while(my $row = $sth->fetchrow_hashref()) {
        push @objs, TagObj->new({id => $row->{id},
                                name => $row->{name},
                                type => $row->{type},
                                permalink => $row->{permalink},
                                });
    }

    return @objs;
}

1;