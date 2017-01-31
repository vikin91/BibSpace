package BibSpace::Functions::Core;

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
require TeX::Encode;
use Encode;
use BibSpace::Functions::FPublications;

use Exporter;
our @ISA = qw( Exporter );
use List::MoreUtils qw(any uniq);

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
  split_bibtex_entries
  decodeLatex
  official_bibtex_types
  random_string
  create_user_id
  uniqlc
  get_generic_type_description
  nohtml
  clean_tag_name
  get_month_numeric
  get_current_year
  get_current_month
);

our $bibtex2html_tmp_dir = "./tmp";
####################################################################################
sub split_bibtex_entries {
    my $input = shift;

    my @bibtex_codes = ();
    $input =~ s/^\s+|\s+$//g;
    $input =~ s/^\t//g;

    for my $b_code ( split /@/, $input ) {
        next unless length($b_code) > 10;
        my $entry_code = "@" . $b_code;

        my $entry = new Text::BibTeX::Entry;
        $entry->parse_s($entry_code);
        if ( $entry->parse_ok ) {
            push @bibtex_codes, $entry_code;
        }
    }

    return @bibtex_codes;
}
################################################################################
sub decodeLatex {
    my $str = shift;

    use TeX::Encode;
    $str = decode( 'latex', $str );

    $str =~ s/\{(.)\}/$1/g;         # makes {x} -> x
    $str =~ s/\{\\\"(u)\}/ü/g;    # makes {\"x} -> xe
    $str =~ s/\{\\\"(U)\}/Ü/g;    # makes {\"x} -> xe
    $str =~ s/\{\\\"(o)\}/ö/g;    # makes {\"x} -> xe
    $str =~ s/\{\\\"(O)\}/Ö/g;    # makes {\"x} -> xe
    $str =~ s/\{\\\"(a)\}/ä/g;    # makes {\"x} -> xe
    $str =~ s/\{\\\"(A)\}/Ä/g;    # makes {\"x} -> xe

    $str =~ s/\{\"(u)\}/ü/g;      # makes {"x} -> xe
    $str =~ s/\{\"(U)\}/Ü/g;      # makes {"x} -> xe
    $str =~ s/\{\"(o)\}/ö/g;      # makes {"x} -> xe
    $str =~ s/\{\"(O)\}/Ö/g;      # makes {"x} -> xe
    $str =~ s/\{\"(a)\}/ä/g;      # makes {"x} -> xe
    $str =~ s/\{\"(A)\}/Ä/g;      # makes {"x} -> xe

    $str =~ s/\\\"(u)/ü/g;        # makes \"{x} -> xe
    $str =~ s/\\\"(U)/Ü/g;        # makes \"{x} -> xe
    $str =~ s/\\\"(o)/ö/g;        # makes \"{x} -> xe
    $str =~ s/\\\"(O)/Ö/g;        # makes \"{x} -> xe
    $str =~ s/\\\"(a)/ä/g;        # makes \"{x} -> xe
    $str =~ s/\\\"(A)/Ä/g;        # makes \"{x} -> xe


    $str =~ s/\{\\\'(.)\}/$1/g;     # makes {\'x} -> x
    $str =~ s/\\\'(.)/$1/g;         # makes \'x -> x
    $str =~ s/\'\'(.)/$1/g;         # makes ''x -> x
    $str =~ s/\"(.)/$1e/g;          # makes "x -> xe
    $str =~ s/\{\\ss\}/ss/g;        # makes {\ss}-> ss
    $str =~ s/\{(.*)\}/$1/g;        # makes {abc..def}-> abc..def
    $str =~ s/\\\^(.)(.)/$1$2/g;    # makes \^xx-> xx
    $str =~ s/\\\^(.)/$1/g;         # makes \^x-> x
    $str =~ s/\\\~(.)/$1/g;         # makes \~x-> x
    $str =~ s/\\//g;                # removes \



    $str =~ s/\{+//g;
    $str =~ s/\}+//g;
    return $str;
}
################################################################################
sub official_bibtex_types {

  ## defined by bibtex and constant

  return (
    'article',      'book',          'booklet',    'conference',    'inbook',
    'incollection', 'inproceedings', 'manual',     'mastersthesis', 'misc',
    'phdthesis',    'proceedings',   'techreport', 'unpublished'
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
  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime();
  return ( $mon + 1 );
}
################################################################################
sub get_current_year {
  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime();

  return ( $year + 1900 );
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
# ################################################################################
sub get_generic_type_description { 
  my $type_desc = shift;
  return "Talks " if $type_desc eq 'talk';
  return "Publications of type " . $type_desc;
}
################################################################################

sub create_user_id {
  my ($name) = @_;

  my @first_arr = $name->part('first');
  @first_arr = grep {defined $_ } @first_arr;
  my $first = join( ' ', @first_arr );

  my @von_arr = $name->part('von');
  my $von     = $von_arr[0];

  my @last_arr = $name->part('last');
  my $last     = $last_arr[0];

  my @jr_arr = $name->part('jr');
  my $jr     = $jr_arr[0];

  my $userID;
  $userID .= $von   if defined $von;
  $userID .= $last;
  $userID .= $first if defined $first;
  $userID .= $jr    if defined $jr;

  $userID =~ s/\\k\{a\}/a/g;    # makes \k{a} -> a
  $userID =~ s/\\l/l/g;         # makes \l -> l
  $userID =~ s/\\r\{u\}/u/g;    # makes \r{u} -> u # FIXME: make sure that the letter is caught
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
  $userID =~ s/\\\^(.)/$1/g;         # makes \^x-> x
  $userID =~ s/\\\~(.)/$1/g;         # makes \~x-> x
  $userID =~ s/\\//g;                # removes \

  $userID =~ s/\{//g;                # removes {
  $userID =~ s/\}//g;                # removes }

  $userID =~ s/\(.*\)//g;            # removes everything between the brackets and the brackets also

  # print "$userID \n";
  return $userID;
}
################################################################################

1;
