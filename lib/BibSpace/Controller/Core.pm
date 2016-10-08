package BibSpace::Controller::Core;

use BibSpace::Functions::FDB;
use BibSpaceBibtexToHtml::BibSpaceBibtexToHtml;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;
use File::Find;
use Time::Piece;
use 5.010;           #because of ~~
use Cwd;
use strict;
use warnings;

# for latex decode
use TeX::Encode;
use Encode;
use BibSpace::Functions::FPublications;

use Exporter;
our @ISA = qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
    random_string
    create_user_id

    get_team_members
    add_team_for_author
    remove_team_for_author
    uniq
    uniqlc
    get_team_for_id
    get_team_id
    get_all_our_types
    get_all_bibtex_types
    get_all_existing_bibtex_types
    get_types_for_landing_page
    get_bibtex_types_for_our_type
    get_description_for_our_type
    get_type_description
    get_landing_for_our_type
    toggle_landing_for_our_type
    nohtml
    add_field_to_bibtex_code
    clean_tag_name
    get_exceptions_for_entry_id
    get_year_for_entry_id
    prepare_backup_table
    get_month_numeric
    get_current_year
    get_current_month
);

our $bibtex2html_tmp_dir = "./tmp";
################################################################################
sub get_all_existing_bibtex_types {

    ## defined by bibtex and constant

    return (
        'article',       'book',         'booklet',       'conference',
        'inbook',        'incollection', 'inproceedings', 'manual',
        'mastersthesis', 'misc',         'phdthesis',     'proceedings',
        'techreport',    'unpublished'
    );
}
####################################################################################
sub random_string {
    my $len = shift;

    my @set = ( '0' .. '9', 'A' .. 'Y' );
    my $str = join '' => map $set[ rand @set ], 1 .. $len;
    $str;
}
################################################################################
sub get_current_month {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst )
        = localtime();
    return $mon;
}
################################################################################
sub get_current_year {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst )
        = localtime();

    return $year + 1900;
}
################################################################################
sub get_month_numeric {
    my $str = shift;
    $str = lc($str);
    $_   = $str;

    return 1  if /jan/ or /january/   or /januar/   or /1/  or /01/;
    return 2  if /feb/ or /february/  or /februar/  or /2/  or /02/;
    return 3  if /mar/ or /march/     or /3/        or /03/;
    return 4  if /apr/ or /april/     or /4/        or /04/;
    return 5  if /may/ or /mai/       or /maj/      or /5/  or /05/;
    return 6  if /jun/ or /june/      or /juni/     or /6/  or /06/;
    return 7  if /jul/ or /july/      or /juli/     or /7/  or /07/;
    return 8  if /aug/ or /august/    or /8/        or /08/;
    return 9  if /sep/ or /september/ or /sept/     or /9/  or /09/;
    return 10 if /oct/ or /october/   or /oktober/  or /10/ or /010/;
    return 11 if /nov/ or /november/  or /11/       or /011/;
    return 12 if /dec/ or /december/  or /dezember/ or /12/ or /012/;

    return 0;
}
################################################################################
sub clean_tag_name {
    my $tag = shift;
    $tag =~ s/^\s+|\s+$//g;
    $tag =~ s/\s/_/g;
    $tag =~ s/\./_/g;
    $tag =~ s/_$//g;
    $tag =~ s/\///g;
    $tag =~ s/\?/_/g;

    return ucfirst($tag);
}
################################################################################
sub uniq {
    return keys %{ { map { $_ => 1 } @_ } };
}
################################################################################
sub uniqlc {
    return keys %{ { map { lc $_ => 1 } @_ } };
}
################################################################################
sub nohtml {
    my $key  = shift // "key-unknown";
    my $type = shift // "no-type";
    return
          "<span class=\"label label-danger\">"
        . "NO HTML "
        . "</span><span class=\"label label-default\">"
        . "($type) $key</span>" . "<BR>";
}



################################################################################
################################################################################
sub get_types_for_landing_page {    #TODO: refactor to MType
    my $dbh = shift;

    my $qry
        = "SELECT DISTINCT our_type FROM OurType_to_Type WHERE landing=1 ORDER BY our_type ASC";
    my $sth = $dbh->prepare($qry) or die $dbh->errstr;
    $sth->execute();

    my @otypes;

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $otype = $row->{our_type};
        push @otypes, $otype if defined $otype;
    }

    # @otypes = uniq @otypes;
    return @otypes;

# my @otypes = ('article', 'volumes', 'inproceedings', 'techreport', 'misc', 'theses');

    # return @otypes;
}
################################################################################
sub get_bibtex_types_for_our_type {
    my $dbh  = shift;
    my $type = shift;

    my $qry = "SELECT bibtex_type
           FROM OurType_to_Type
           WHERE our_type=?
           ORDER BY bibtex_type ASC";
    my $sth = $dbh->prepare($qry);
    $sth->execute($type);

    my @btypes;

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $btype = $row->{bibtex_type};
        push @btypes, $btype if defined $btype;
    }
    return @btypes;
}
################################################################################
sub get_description_for_our_type {    #TODO: refactor to MType
    my $dbh  = shift;
    my $type = shift;

    my $qry = "SELECT description
           FROM OurType_to_Type
           WHERE our_type=?";
    my $sth = $dbh->prepare($qry);
    $sth->execute($type);

    my $row = $sth->fetchrow_hashref();
    my $description
        = $row->{description} || get_type_description( $dbh, $type );
    return $description;
}
################################################################################
sub get_landing_for_our_type {    #TODO: refactor to MType
    my $dbh  = shift;
    my $type = shift;

    my $qry = "SELECT landing
           FROM OurType_to_Type
           WHERE our_type=?";
    my $sth = $dbh->prepare($qry);
    $sth->execute($type);

    my $row = $sth->fetchrow_hashref();
    my $landing = $row->{landing} || 0;
    return $landing;
}
################################################################################
sub set_landing_for_our_type {    #TODO: refactor to MType

    my $dbh  = shift;
    my $type = shift;
    my $val  = shift;

    say "set type $type val $val";

    if ( defined $val and ( $val == 0 or $val == 1 ) ) {
        my $qry = "UPDATE OurType_to_Type SET landing=? WHERE our_type=?";
        my $sth = $dbh->prepare($qry);
        $sth->execute( $val, $type );
    }
}

################################################################################
sub toggle_landing_for_our_type {    #TODO: document this or make clearer
    my $dbh  = shift;
    my $type = shift;

    my $curr = get_landing_for_our_type( $dbh, $type );

    if ( $curr == 0 ) {
        set_landing_for_our_type( $dbh, $type, '1' );
    }
    elsif ( $curr == 1 ) {
        set_landing_for_our_type( $dbh, $type, '0' );
    }
}
################################################################################
sub get_DB_description_for_our_type {    #TODO: refactor to MType
    my $dbh  = shift;
    my $type = shift;

    my $qry = "SELECT description
           FROM OurType_to_Type
           WHERE our_type=?";
    my $sth = $dbh->prepare($qry);
    $sth->execute($type);

    my $row = $sth->fetchrow_hashref();
    my $description = $row->{description} || undef;
    return $description;
}

################################################################################
sub get_all_bibtex_types {    #TODO: refactor to MType
    my $dbh = shift;

    my $qry = "SELECT DISTINCT bibtex_type, our_type
           FROM OurType_to_Type
           ORDER BY our_type ASC";
    my $sth = $dbh->prepare($qry);
    $sth->execute();

    my @btypes;

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $btype = $row->{bibtex_type};

        push @btypes, $btype if defined $btype;
    }

    return @btypes;
}
################################################################################
sub get_all_our_types {    #TODO: refactor to MType
    my $dbh = shift;

    my $qry = "SELECT DISTINCT our_type
           FROM OurType_to_Type
           ORDER BY our_type ASC";
    my $sth = $dbh->prepare($qry);
    $sth->execute();

    my @otypes;

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $otype = $row->{our_type};

        push @otypes, $otype if defined $otype;
    }

    return @otypes;
}

################################################################################
sub get_type_description {    #TODO: refactor to MType
    my $dbh  = shift;
    my $type = shift;

    my $db_type = get_DB_description_for_our_type( $dbh, $type );
    return $db_type if defined $db_type;

    # in case of no secription, the name is the description itself
    return "Publications of type " . $type;
}
# ################################################################################
# sub get_all_teams {           #TODO: refactor to MType
#     my $dbh = shift;

#     my $qry = "SELECT DISTINCT id, name FROM Team";
#     my $sth = $dbh->prepare($qry);
#     $sth->execute();

#     my @teams;
#     my @ids;

#     while ( my $row = $sth->fetchrow_hashref() ) {
#         my $tid  = $row->{id};
#         my $team = $row->{name};

#         push @teams, $team if defined $team;
#         push @ids,   $tid  if defined $tid;
#     }

#     return ( \@teams, \@ids );
# }
##########################################################################
sub get_year_for_entry_id
{    #TODO: refactor to MEntry. it should be there for a long time!
    my $dbh = shift;
    my $eid = shift;

    my $sth = $dbh->prepare("SELECT year FROM Entry WHERE id=?");
    $sth->execute($eid);

    my $row  = $sth->fetchrow_hashref();
    my $year = $row->{year};
    return $year;
}
##########################################################################
sub get_exceptions_for_entry_id { # TODO: refactor into MEntry
    my $dbh = shift;
    my $eid = shift;

    my $sth = $dbh->prepare(
        "SELECT team_id FROM Exceptions_Entry_to_Team  WHERE entry_id=?");
    $sth->execute($eid);

    my @exceptions;

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $team_id = $row->{team_id};
        push @exceptions, $team_id;
    }

    return @exceptions;
}

##########################################################################
########################################################################## # here optimize further
##########################################################################
##########################################################################
sub get_team_id {
    my $dbh  = shift;
    my $team_name = shift;

    my $team = MTeam->static_get_by_name($dbh, $team_name);
    return -1 unless defined $team;
    return $team->{id};
}
##########################################################################
sub get_team_for_id {
    my $dbh = shift;
    my $id  = shift;

    my $team = MTeam->static_get($dbh, $id);
    return undef unless defined $team;
    return $team->{name};
}
################################################################################
sub add_team_for_author {
    my $self      = shift;
    my $master_id = shift;
    my $teamid    = shift;

    my $dbh = $self->app->db;

    my $qry
        = "INSERT IGNORE INTO Author_to_Team(author_id, team_id) VALUES (?,?)";
    my $sth = $dbh->prepare($qry);
    $sth->execute( $master_id, $teamid );

    $self->write_log(
        "Author with master id $master_id becomes a member of team with id $teamid."
    );
}
################################################################################
sub remove_team_for_author {
    my $self      = shift;
    my $master_id = shift;
    my $teamid    = shift;

    my $dbh = $self->app->db;

    my $qry = "DELETE FROM Author_to_Team WHERE author_id=? AND team_id=?";
    my $sth = $dbh->prepare($qry);
    $sth->execute( $master_id, $teamid );

    $self->write_log(
        "Author with master id $master_id IS NO LONGER a member of team with id $teamid."
    );
}

################################################################################
sub get_team_members {
    my $self   = shift;
    my $teamid = shift;
    my $dbh    = $self->app->db;

    my @author_ids;
    my @start_arr;
    my @stop_arr;

    my $qry = "SELECT DISTINCT (author_id), start, stop, Author.display
            FROM Author_to_Team 
            JOIN Author 
            ON Author.master_id = Author_to_Team.author_id
            WHERE team_id=?
            ORDER BY display DESC";    #, uid ASC";

    my $sth = $dbh->prepare($qry);
    $sth->execute($teamid);

    my $disp;
    while ( my $row = $sth->fetchrow_hashref() ) {
        my $aid   = $row->{author_id};
        my $start = $row->{start};
        my $stop  = $row->{stop};

        push @author_ids, $aid   if defined $aid;
        push @start_arr,  $start if defined $start;
        push @stop_arr,   $stop  if defined $stop;
    }
    return ( \@author_ids, \@start_arr, \@stop_arr );
}

################################################################################

sub add_field_to_bibtex_code {
    my $dbh   = shift;
    my $eid   = shift;
    my $field = shift;
    my $value = shift;

    my $mentry = MEntry->static_get( $dbh, $eid );

    my $entry = new Text::BibTeX::Entry();
    $entry->parse_s($mentry->{bib});
    return -1 unless $entry->parse_ok;
    my $key = $entry->key;
    $entry->set( $field, $value );
    my $new_bib = $entry->print_s;

    $mentry->{bib} = $new_bib;
    $mentry->populate_from_bib();
    $mentry->save($dbh);
}
####################################################################################
# sub has_bibtex_field {
#     my $dbh   = shift;
#     my $eid   = shift;
#     my $field = shift;

#     my @ary = $dbh->selectrow_array( "SELECT bib FROM Entry WHERE id = ?",
#         undef, $eid );
#     my $entry_str = $ary[0];

#     my $entry = new Text::BibTeX::Entry();
#     $entry->parse_s($entry_str);
#     return -1 unless $entry->parse_ok;
#     my $key = $entry->key;

#     return $entry->exists($field);
# }
################################################################################

sub create_user_id {
    my ($name) = @_;

    my @first_arr = $name->part('first');
    my $first = join( ' ', @first_arr );

    #print "$first\n";

    my @von_arr = $name->part('von');
    my $von     = $von_arr[0];

    #print "$von\n" if defined $von;

    my @last_arr = $name->part('last');
    my $last     = $last_arr[0];

    #print "$last\n";

    my @jr_arr = $name->part('jr');
    my $jr     = $jr_arr[0];

    #print "$jr\n";

    my $userID;
    $userID .= $von   if defined $von;
    $userID .= $last;
    $userID .= $first if defined $first;
    $userID .= $jr    if defined $jr;

    $userID =~ s/\\k\{a\}/a/g;    # makes \k{a} -> a
    $userID =~ s/\\l/l/g;         # makes \l -> l
    $userID =~ s/\\r\{u\}/u/g
        ;    # makes \r{u} -> u # FIXME: make sure that the letter is caught
     # $userID =~ s/\\r{u}/u/g;   # makes \r{u} -> u # the same but not escaped

    $userID =~ s/\{(.)\}/$1/g;         # makes {x} -> x
    $userID =~ s/\{\\\"(.)\}/$1e/g;    # makes {\"x} -> xe
    $userID =~ s/\{\"(.)\}/$1e/g;      # makes {"x} -> xe
    $userID =~ s/\\\"(.)/$1e/g;        # makes \"{x} -> xe
    $userID =~ s/\{\\\'(.)\}/$1/g;     # makes {\'x} -> x
    $userID =~ s/\\\'(.)/$1/g;         # makes \'x -> x
    $userID =~ s/\'\'(.)/$1/g;         # makes ''x -> x
    $userID =~ s/\"(.)/$1e/g;          # makes "x -> xe
    $userID =~ s/\{\\ss\}/ss/g;        # makes {\ss}-> ss
    $userID =~ s/\{(.*)\}/$1/g;        # makes {abc..def}-> abc..def
    $userID =~ s/\\\^(.)(.)/$1$2/g;    # makes \^xx-> xx
                                  # I am not sure if the next one is necessary
    $userID =~ s/\\\^(.)/$1/g;    # makes \^x-> x
    $userID =~ s/\\\~(.)/$1/g;    # makes \~x-> x
    $userID =~ s/\\//g;           # removes \

    $userID =~ s/\{//g;           # removes {
    $userID =~ s/\}//g;           # removes }

    $userID =~ s/\(.*\)//g
        ;    # removes everything between the brackets and the brackets also

    # print "$userID \n";
    return $userID;
}
################################################################################

1;
