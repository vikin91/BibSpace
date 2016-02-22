#!/usr/bin/perl -w

use utf8;
use 5.010; #because of ~~
use File::Slurp;
use strict;
use warnings;
use DBI;


our $in_file_name = "bib.bib";

my $dsn = 'dbi:SQLite:dbname=bib.db';
my $dbh = DBI->connect($dsn, '', '') or die $DBI::errstr;

################################################################################################

my @authors = get_all_author_ids($dbh);
foreach my $author (@authors){
   my $master = getMasterUID_from_DB($author, $dbh);
   my $sth = $dbh->prepare("INSERT OR IGNORE INTO Author_to_Team(author, team) Values (?, ?)");
   $sth->execute($master, 'NOTEAM');
}

my @keys = get_all_entry_keys($dbh);
foreach my $key (@keys){
   my $sth = $dbh->prepare("INSERT OR IGNORE INTO Entry_to_Tag(entry, tag) Values (?, ?)");
   $sth->execute($key, 'ALL');
}

$dbh->do("DELETE FROM Author_to_Team WHERE team='NOTEAM'");  #### NO INFLUENCE!!!!


$dbh->do("DELETE FROM Entry_to_Tag WHERE tag='ALL'");   ### UNCOMMENTING causes that only tagged entries are shown


add_team($dbh, "SE-WUERZBURG");
add_team($dbh, "DESCARTES");
add_team($dbh, "DESCARTES_ALUMNI");
add_team($dbh, "WROCLAW");
add_team($dbh, "FORMER-INFO-2");

################################################################################################

set_ourtype_to_bibtextype($dbh, "incollection","inproceedings");
set_ourtype_to_bibtextype($dbh, "incollection","bibtex_incollection");
set_ourtype_to_bibtextype($dbh, "inproceedings","bibtex_inproceedings");
set_ourtype_to_bibtextype($dbh, "inbook","book");
set_ourtype_to_bibtextype($dbh, "mastersthesis","theses");
set_ourtype_to_bibtextype($dbh, "phdthesis","theses");
set_ourtype_to_bibtextype($dbh, "article","article");
set_ourtype_to_bibtextype($dbh, "book","book");
set_ourtype_to_bibtextype($dbh, "inbook","inbook");
set_ourtype_to_bibtextype($dbh, "incollection","incollection");
set_ourtype_to_bibtextype($dbh, "inproceedings","inproceedings");
set_ourtype_to_bibtextype($dbh, "manual","manual");
set_ourtype_to_bibtextype($dbh, "mastersthesis","mastersthesis");
set_ourtype_to_bibtextype($dbh, "misc","misc");
set_ourtype_to_bibtextype($dbh, "phdthesis","phdthesis");
set_ourtype_to_bibtextype($dbh, "proceedings","proceedings");
set_ourtype_to_bibtextype($dbh, "techreport","techreport");
set_ourtype_to_bibtextype($dbh, "unpublished","unpublished");

################################################################################################

add_author_to_team($dbh, "SE-WUERZBURG", "BrosigFabian", 0, 0);
add_author_to_team($dbh, "SE-WUERZBURG", "HerbstNikolas", 0, 0);
add_author_to_team($dbh, "SE-WUERZBURG", "HuberNikolaus", 0, 0);
add_author_to_team($dbh, "SE-WUERZBURG", "MilenkoskiAleksandar", 2013, 0);
add_author_to_team($dbh, "SE-WUERZBURG", "RygielskiPiotr", 2013, 0);
add_author_to_team($dbh, "SE-WUERZBURG", "KounevSamuel", 0, 0);
add_author_to_team($dbh, "SE-WUERZBURG", "SpinnerSimon", 0, 0);
add_author_to_team($dbh, "SE-WUERZBURG", "WalterJuergen", 0, 0);
add_author_to_team($dbh, "SE-WUERZBURG", "vonKistowskiJoakim", 2013, 0);
add_author_to_team($dbh, "SE-WUERZBURG", "NehmeierMarco", 0, 0);
add_author_to_team($dbh, "SE-WUERZBURG", "WolfvonGudenbergJuergen", 0, 0);

add_author_to_team($dbh, "SE-WUERZBURG", "NoorshamsQais", 0, 0);
add_author_to_team($dbh, "SE-WUERZBURG", "KrebsRouven", 0, 0);

add_author_to_team($dbh, "WROCLAW", "RygielskiPiotr", 0, 2012);

add_author_to_team($dbh, "DESCARTES", "BrosigFabian", 0, 0);
add_author_to_team($dbh, "DESCARTES", "HerbstNikolas", 0, 0);
add_author_to_team($dbh, "DESCARTES", "HuberNikolaus", 0, 0);
add_author_to_team($dbh, "DESCARTES", "MilenkoskiAleksandar", 2013, 0);
add_author_to_team($dbh, "DESCARTES", "RygielskiPiotr", 2013, 0);
add_author_to_team($dbh, "DESCARTES", "KounevSamuel", 0, 0);
add_author_to_team($dbh, "DESCARTES", "SpinnerSimon", 0, 0);
add_author_to_team($dbh, "DESCARTES", "WalterJuergen", 0, 0);
add_author_to_team($dbh, "DESCARTES", "vonKistowskiJoakim", 2013, 0);
add_author_to_team($dbh, "DESCARTES", "NehmeierMarco", 0, 0);
add_author_to_team($dbh, "DESCARTES", "WolfvonGudenbergJuergen", 0, 0);

add_author_to_team($dbh, "DESCARTES", "NoorshamsQais", 0, 0);
add_author_to_team($dbh, "DESCARTES", "KrebsRouven", 0, 0);

add_author_to_team($dbh, "FORMER-INFO-2", "NehmeierMarco", 0, 0);
add_author_to_team($dbh, "FORMER-INFO-2", "WolfvonGudenbergJuergen", 0, 0);

################################################################################################

set_all_authors_invisible($dbh);

set_author_visible($dbh, "BrosigFabian");
set_author_visible($dbh, "HerbstNikolas");
set_author_visible($dbh, "HuberNikolaus");
set_author_visible($dbh, "MilenkoskiAleksandar");
set_author_visible($dbh, "RygielskiPiotr");
set_author_visible($dbh, "KounevSamuel");
set_author_visible($dbh, "SpinnerSimon");
set_author_visible($dbh, "WalterJuergen");
set_author_visible($dbh, "vonKistowskiJoakim");

set_author_visible($dbh, "NehmeierMarco");
set_author_visible($dbh, "WolfvonGudenbergJuergen");

set_author_visible($dbh, "NoorshamsQais");
set_author_visible($dbh, "KrebsRouven");

################################################################################################

set_master_for_uid($dbh, "WolffvonGudenbergJuergen", "WolfvonGudenbergJuergen");

################################################################################################

set_exception_to_group($dbh, "SE-WUERZBURG", "sp2002-SPEC-SPECjAppServer2002");
set_exception_to_group($dbh, "SE-WUERZBURG", "sp2002-SPEC-SPECjAppServer2001");
set_exception_to_group($dbh, "SE-WUERZBURG", "sp2005-SPEC-SPECjbb2005");
set_exception_to_group($dbh, "SE-WUERZBURG", "sp2004-SPEC-SPECjAppServer2004");
set_exception_to_group($dbh, "SE-WUERZBURG", "sp2007-SPEC-SPECjms2007");

set_exception_to_group($dbh, "DESCARTES", "sp2002-SPEC-SPECjAppServer2002");
set_exception_to_group($dbh, "DESCARTES", "sp2002-SPEC-SPECjAppServer2001");
set_exception_to_group($dbh, "DESCARTES", "sp2005-SPEC-SPECjbb2005");
set_exception_to_group($dbh, "DESCARTES", "sp2004-SPEC-SPECjAppServer2004");
set_exception_to_group($dbh, "DESCARTES", "sp2007-SPEC-SPECjms2007");

################################################################################################

$dbh->disconnect();

# Schulss.


################################################################################################
################################################################################################
################################################################################################

sub set_ourtype_to_bibtextype{
   my ($dbh, $our, $bibtex) = @_;

   my $sth = $dbh->prepare("INSERT OR IGNORE INTO OurTypes_to_Types VALUES(?,?)");
   $sth->execute($our, $bibtex);
   
}

################################################################################################

sub add_team{
   my ($dbh, $team) = @_;

   my $sth = $dbh->prepare("INSERT OR IGNORE INTO Teams(name, parent) Values (?, NULL)");
   $sth->execute($team);
   
}

################################################################################################

sub add_author_to_team{
   my ($dbh, $team, $author, $start, $stop) = @_;

   my $sth = $dbh->prepare("INSERT OR IGNORE INTO Author_to_Team(author, team, start, stop) Values (?, ?, ?, ?)");
   $sth->execute($author, $team, $start, $stop);

   set_master_for_uid($dbh, $author, $author);
   
}

################################################################################################

sub set_master_for_uid{
   my ($dbh, $master, $uid) = @_;

   my $sth = $dbh->prepare('INSERT OR IGNORE INTO Authors(author_id) VALUES(?)');
   $sth->execute($uid);
   $sth = $dbh->prepare('INSERT OR IGNORE INTO Authors(author_id, master) VALUES(?, ?)');
   $sth->execute($master, $master);
   $sth = $dbh->prepare("UPDATE Authors SET master=? WHERE author_id=?");
   $sth->execute($master, $uid);
}

################################################################################################

sub set_author_visible{
   my ($dbh, $author) = @_;

   my $master = getMasterUID_from_DB($author, $dbh);
   my $sth = $dbh->prepare("UPDATE Authors SET display=1 WHERE master=?");
   $sth->execute($master);
}

################################################################################################

sub set_author_invisible{
   my ($dbh, $author) = @_;

   my $master = getMasterUID_from_DB($author, $dbh);
   my $sth = $dbh->prepare("UPDATE Authors SET display=0 WHERE master=?");
   $sth->execute($master);
}

################################################################################################

sub set_exception_to_group{
   my ($dbh, $group, $exception) = @_;

   my $sth = $dbh->prepare("INSERT OR IGNORE INTO Exceptions_Entry_to_Team(key, team) Values (?, ?)");
   $sth->execute($exception, $group);
   
}

################################################################################################



sub set_all_authors_invisible{
   my $dbh = shift;

   my @authors = get_all_author_ids($dbh);

   foreach my $author (@authors){
      my $master = getMasterUID_from_DB($author, $dbh);

      set_author_invisible($dbh, $master);
   }
}







sub getMasterUID_from_DB{
   my $uid = shift;
   my $dbh = shift;

   my $muid = undef;

   my $sth = $dbh->prepare( "SELECT master FROM Authors WHERE author_id = ?" );  
   $sth->execute($uid);

   my $ret = $sth->fetch();
   foreach my $row (@$ret) {
      $muid = $row;
   } 

   if (!defined $muid){
      # print "UID $uid, has no MUID!!\n";
      return $uid;
   }
   
   return $muid;
}

sub get_all_author_ids{
   my $dbh = shift;

   my $sth = $dbh->prepare( "SELECT author_id FROM Authors" );  
   $sth->execute();

   my @arr = ();
   while(my $row = $sth->fetchrow_hashref()) {
      
      push @arr, $row->{author_id};
   }
   

   return @arr;
}

sub get_all_entry_keys{
   my $dbh = shift;

   my $sth = $dbh->prepare( "SELECT key FROM Entries" );  
   $sth->execute();

   my @arr = ();
   while(my $row = $sth->fetchrow_hashref()) {
      
      push @arr, $row->{key};
   }

   return @arr;
}


sub post_process_Entry_to_Authors{
   my $dbh = shift;

   my @authors = get_all_author_ids($dbh);

   foreach my $author (@authors){
      my $master = getMasterUID_from_DB($author, $dbh);

      # print "POST_PROCESSING UID \'$author\' MASTER: $master \n";
      # Entry_to_Author has mapping of uid to key. Naw it needs to be changed to master -> key
      my $sth2 = $dbh->prepare('UPDATE OR IGNORE Entry_to_Author SET author = ? WHERE author = ?');
      $sth2->execute($master, $author);
   }
}





sub create_user_id {
   my ($name) = @_;

   my @first_arr = $name->part('first');
   my $first = join(' ', @first_arr);
   #print "$first\n";

   my @von_arr = $name->part ('von');
   my $von = $von_arr[0];
   #print "$von\n" if defined $von;

   my @last_arr = $name->part ('last');
   my $last = $last_arr[0];
   #print "$last\n";

   my @jr_arr = $name->part ('jr');
   my $jr = $jr_arr[0];
   #print "$jr\n";
   
   my $userID;
   $userID.=$von if defined $von;
   $userID.=$last;
   $userID.=$first if defined $first;
   $userID.=$jr if defined $jr;

   $userID =~ s/\\k\{a\}/a/g;   # makes \k{a} -> a
   $userID =~ s/\\l/l/g;   # makes \l -> l

   $userID =~ s/\{(.)\}/$1/g;   # makes {x} -> x
   $userID =~ s/\{\\\"(.)\}/$1e/g;   # makes {\"x} -> xe
   $userID =~ s/\{\"(.)\}/$1e/g;   # makes {"x} -> xe
   $userID =~ s/\\\"(.)/$1e/g;   # makes \"{x} -> xe
   $userID =~ s/\{\\\'(.)\}/$1/g;   # makes {\'x} -> x
   $userID =~ s/\\\'(.)/$1/g;   # makes \'x -> x
   $userID =~ s/\{\\ss\}/ss/g;   # makes {\ss}-> ss
   $userID =~ s/\{(.*)\}/$1/g;   # makes {abc..def}-> abc..def
   $userID =~ s/\\\^(.)(.)/$1$2/g;   # makes \^xx-> xx
   # I am not sure if the next one is necessary
   $userID =~ s/\\\^(.)/$1/g;   # makes \^x-> x 
   $userID =~ s/\\\~(.)/$1/g;   # makes \~x-> x
   $userID =~ s/\\//g;   # makes \l -> l
   
   # print "$userID \n";
   return $userID;
}