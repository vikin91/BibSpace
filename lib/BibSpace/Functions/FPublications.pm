package BibSpace::Functions::FPublications;

use 5.010; #because of ~~
use strict;
use warnings;
use Data::Dumper;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use DBI;

use BibSpace::Controller::Core;
use BibSpace::Model::MEntry;

use Exporter;
our @ISA= qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
    Fget_single_publication
    Ffix_months
    Fbibtex_key_exists
    Fget_html_preview
    Fget_entry_id_for_bibtex_key
    );

####################################################################################
sub Fget_single_publication {
    my $pub_id = shift;
    my $dbh = shift;

    say "CALL: FPUblications::get_single_publication";

    my $en = MEntry->new();
    my $mentry = $en->get($dbh, $pub_id);
    return $mentry;
};
####################################################################################
sub Ffix_months {
    my $dbh = shift;

    say "CALL: FPUblications::fix_months";

    my $en = MEntry->new();
    my @objs = $en->all($dbh);
    my $num_checks = 0;
    my $num_fixes = 0;

    for my $o (@objs){
        # say " checking fix month $num_checks";
        $num_fixes = $num_fixes + $o->fix_month();
        $num_checks = $num_checks + 1;
    }

    return ($num_checks, $num_fixes);
};
####################################################################################
sub Fbibtex_key_exists {
    my $dbh = shift;
    my $key = shift;

    my @ary = $dbh->selectrow_array("SELECT COUNT(*) FROM Entry WHERE bibtex_key = ?", undef, $key);
    my $key_exists = $ary[0];
    return $key_exists;
};
####################################################################################
sub Fget_html_preview {
    my $new_bib = shift;
    
    my $e_dummy = MEntry->new();
    $e_dummy->{bib} = $new_bib;
    $e_dummy->populate_from_bib();
    my ($html, $html_bib) = $e_dummy->generate_html();
    return $html, $html_bib;
};
####################################################################################
sub Fget_entry_id_for_bibtex_key{
   my $dbh = shift;
   my $key = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Entry WHERE bibtex_key=?" );     
   $sth->execute($key);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id};
   return -1 unless defined $id;
   print "ID = -1 for key $key\n" unless defined $id;
   return $id;
};
####################################################################################