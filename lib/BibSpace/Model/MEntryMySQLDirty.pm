package MEntryMySQLDirty;

use BibSpace::Model::MEntryMySQL;
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
use MooseX::Storage;


with Storage('format' => 'JSON', 'io' => 'File');

extends 'MEntryMySQL';

####################################################################################
# why do I need to write it? It should happen automatically!
sub load {
    my $self = shift;
    $self->SUPER::load(shift);
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
sub tags_from_DB {
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
        $num_added = $num_added + $self->assign_tag( $t );
    }
    return $num_added;
}
####################################################################################

no Moose;
__PACKAGE__->meta->make_immutable;
1;
