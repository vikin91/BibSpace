package TagTypeObj;

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
        comment  => $args->{comment} || "",
    };
    return bless $self, $class;
}

sub getById{
    my $self = shift;
    my $dbh = shift;
    my $id = shift;
    
    my $qry = "SELECT DISTINCT id, name, comment
               FROM TagType
               WHERE id = ?";

    my $sth = $dbh->prepare( $qry );  
    $sth->execute($id);  

  
    my $row = $sth->fetchrow_hashref();
    my $obj = TagTypeObj->new({id => $row->{id},
                                name => $row->{name},
                                comment => $row->{comment},
                            });

    return $obj;
}

sub getAll{
    my $self = shift;
    my $dbh = shift;

    my $qry = "SELECT DISTINCT id, name, comment FROM TagType ORDER BY id ASC";
    my $sth = $dbh->prepare($qry);  
    $sth->execute();  

    my @objs;

    while(my $row = $sth->fetchrow_hashref()) {
        my $obj = TagTypeObj->new({id => $row->{id},
                                name => $row->{name},
                                comment => $row->{comment},
                            });
        push @objs, $obj;
    }
    return @objs;
}



1;