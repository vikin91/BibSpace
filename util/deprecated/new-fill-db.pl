#!/usr/bin/perl -w

use Text::BibTeX; # parsing bib files
use List::MoreUtils 'uniq'; # making string arr uniqe
use Sort::Naturally; # sorting by strings
use utf8;
use YAML::Tiny;
use 5.010; #because of ~~
use Cwd;
use File::Slurp;
use Getopt::Long;
#use strict;
#use warnings;
use DBI;

sub usage{
  print "\nUsage: $0 --mode <mode> --bib <bib_file> --nohtml\n";
  print "\t --mode\n";
  print "\t destroy = destroy the DB and fill it again from the bib and config files\n";
  print "\t update = add entries from file if they don't exists yet\n";
  print "\t --bib = file with bibtex input\n";
  print "\t --nohtml = do not generate html \n";
  
  print "\t\n";
  exit (2);
}




our $tmpdir = "./tmp";
system("mkdir $tmpdir");
system("chmod 777 $tmpdir");

unlink "out.html";# or die "You need to correct the access rights!";
unlink "out_bib.html";# or die "You need to correct the access rights!";




print "================================================================================\n";
print "FILL-DB.PL script
Issue the commands to install required libraries:
sudo aptitude install bibtex2html libmojolicious-perl libsort-naturally-perl liblist-moreutils-perl libtext-bibtex-perl libclass-dbi-sqlite-perl libyaml-tiny-perl libdatetime-perl libfile-slurp-perl
";
print "================================================================================\n";


# install Text::BibTeX
# install DBI
# install DBD::SQLite
# install Data::Dumper
# install YAML::Tiny
# install Sort::Naturally

our $skip_html = 0;
our $in_file_name = "bib.bib";

our $bibfile = new Text::BibTeX::File $in_file_name;

my $conf_file = "../conf/SDQgroups.conf.yml";

our $mode = "update";

GetOptions ("mode=s" => \$mode, 
            "bib=s" => \$in_file_name,
            "nohtml" => \$skip_html
            )
or die usage();


# if ($mode eq 'destroy'){  
#    print "
#    ********************************
#    This script will destroy the database and replace any table with a fresh version.
#    If you are sure that you want to do this, enter the PI number with 7 decimal digits. 
#    If not, use the script in update version.
#    ********************************\n";

#    my $input = <STDIN>;
#    $input =~ /3.1415926/ or die "Died for safety reasons. PI was wrong.";
# }



my $dsn = 'dbi:SQLite:dbname=bib.db';
$dbh = DBI->connect($dsn, '', '') or die $DBI::errstr;


if($mode eq 'destroy'){
   drop_tables($dbh);   
}

prepare_db($dbh); # harmless


read_config_master_author($conf_file, $dbh);
read_config_teams($conf_file, $dbh);

read_bib_file_into_db($dbh);
process_entries($dbh);
#sets the visibility
read_config_people($conf_file, $dbh);  


# must be after authors and masters
read_config_author_to_team($conf_file, $dbh);

read_config_exceptions($conf_file, $dbh);





### Postprocessing
# post_process_Entry_to_Author($dbh);

if( $skip_html == 1){
   print "Skipping html generation due to skip_html = $skip_html\n";
}
elsif($mode eq 'destroy'){
   generate_html_for_keys($dbh, get_all_keys($dbh));   
}


$dbh->disconnect();



sub drop_tables{
   my $dbh = shift;

   $dbh->do("DROP TABLE IF EXISTS Author_to_Team");
   $dbh->do("DROP TABLE IF EXISTS Entry_to_Author");
   $dbh->do("DROP TABLE IF EXISTS Author");
   $dbh->do("DROP TABLE IF EXISTS Authors");
   $dbh->do("DROP TABLE IF EXISTS Entry_to_Tag");
   $dbh->do("DROP TABLE IF EXISTS Tag");
   $dbh->do("DROP TABLE IF EXISTS Tags");
   $dbh->do("DROP TABLE IF EXISTS Entry");
   $dbh->do("DROP TABLE IF EXISTS Entries");
   $dbh->do("DROP TABLE IF EXISTS Exceptions_Entry_to_Team");
   $dbh->do("DROP TABLE IF EXISTS Team");
   $dbh->do("DROP TABLE IF EXISTS Teams");
}


sub prepare_db{
   my $dbh = shift;


   $dbh->do("CREATE TABLE IF NOT EXISTS Tag(
      name TEXT,
      id INTEGER PRIMARY KEY,
      UNIQUE(name) ON CONFLICT IGNORE
      )");

   $dbh->do("CREATE TABLE IF NOT EXISTS Entry(
      id INTEGER PRIMARY KEY,
      key TEXT, 
      type TEXT, 
      bib TEXT, 
      html TEXT, 
      html_bib TEXT,
      abstract TEXT,
      title TEXT,
      year INTEGER,
      teams_str TEXT,
      people_str TEXT,
      tags_str TEXT,
      creation_time INTEGER,
      modified_time INTEGER,
      need_html_regen INTEGER DEFAULT 1,
      UNIQUE(key) ON CONFLICT IGNORE
      )");

      $dbh->do("CREATE TABLE IF NOT EXISTS OurType_to_Type(
         bibtex_type TEXT, 
         our_type TEXT,
         PRIMARY KEY (bibtex_type, our_type)
         )");

      $dbh->do("CREATE TABLE IF NOT EXISTS Team(
         id INTEGER PRIMARY KEY,
         name TEXT NOT NULL,
         parent TEXT DEFAULT NULL,
         UNIQUE(name) ON CONFLICT IGNORE,
         FOREIGN KEY(parent) REFERENCES Team(id) ON DELETE CASCADE
         )");

      
      $dbh->do("CREATE TABLE IF NOT EXISTS Author_to_Team(
         author_id INTEGER, 
         team_id INTEGER, 
         start INTEGER DEFAULT 0,
         stop INTEGER DEFAULT 0,
         FOREIGN KEY(author_id) REFERENCES Author(master_id) ON DELETE CASCADE,
         FOREIGN KEY(team_id) REFERENCES Team(id) ON DELETE CASCADE,
         PRIMARY KEY (author_id, team_id)
         )");

      print "Preparing Author table\n";
      $dbh->do("CREATE TABLE Author(
         id INTEGER PRIMARY KEY, 
         uid TEXT, 
         display INTEGER DEFAULT 0,
         master TEXT DEFAULT NULL,
         master_id INTEGER,
         UNIQUE(uid) ON CONFLICT REPLACE,
         FOREIGN KEY(master_id) REFERENCES Author(id) ON DELETE CASCADE
         )");

      print "Preparing Entry_to_Author table\n";
      $dbh->do("CREATE TABLE IF NOT EXISTS Entry_to_Author(
         entry_id INTEGER NOT NULL, 
         author_id INTEGER NOT NULL, 
         FOREIGN KEY(entry_id) REFERENCES Entry(id) ON DELETE CASCADE, 
         FOREIGN KEY(author_id) REFERENCES Author(master_id) ON DELETE CASCADE,
         PRIMARY KEY (entry_id, author_id)
         )");

      print "Preparing Tags table\n";
      $dbh->do("CREATE TABLE IF NOT EXISTS Tag(
         id INTEGER, 
         tag TEXT PRIMARY KEY
         )");

      print "Preparing Entry_to_Tag table\n";
      $dbh->do("CREATE TABLE IF NOT EXISTS Entry_to_Tag(
         entry_id INTEGER NOT NULL, 
         tag_id INTEGER NOT NULL, 
         FOREIGN KEY(entry_id) REFERENCES Entry(id) ON DELETE CASCADE, 
         FOREIGN KEY(tag_id) REFERENCES Tag(id) ON DELETE CASCADE,
         PRIMARY KEY (entry_id, tag_id)
         )");
      
      $dbh->do("CREATE TABLE IF NOT EXISTS Exceptions_Entry_to_Team(
         entry_id INTEGER,
         team_id INTEGER DEFAULT NULL,
         FOREIGN KEY(entry_id) REFERENCES Entry(id) ON DELETE CASCADE,
         FOREIGN KEY(team_id) REFERENCES Team(id) ON DELETE CASCADE,
         PRIMARY KEY (entry_id, team_id)
         )"); 

      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('incollection', 'inproceedings')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('incollection', 'bibtex-incollection')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('inproceedings', 'inproceedings')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('inproceedings', 'bibtex-inproceedings')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('inbook', 'book')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('mastersthesis', 'theses')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('phdthesis', 'theses')");

      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('phdthesis', 'volumes')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('proceedings', 'volumes')");


      # ORIGINAL BIBTEX TYPES
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('article', 'article')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('book', 'book')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('inbook', 'inbook')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('incollection', 'incollection')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('inproceedings', 'inproceedings')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('manual', 'manual')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('mastersthesis', 'mastersthesis')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('misc', 'misc')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('phdthesis', 'phdthesis')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('proceedings', 'proceedings')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('techreport', 'techreport')");
      $dbh->do("REPLACE INTO OurType_to_Type(bibtex_type, our_type) VALUES('unpublished', 'unpublished')");

   # http://zetcode.com/db/sqlite/datamanipulation/
}


##########################################################################
sub get_entry_id{
   my $dbh = shift;
   my $key = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Entry WHERE key=?" );     
   $sth->execute($key);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id} || -1;
   return $id;
}
##########################################################################
sub get_author_id_for_uid{
   my $dbh = shift;
   my $uid = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Author WHERE uid=?" );     
   $sth->execute($uid);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id} || -1;
   return $id;
}
##########################################################################
sub get_author_id_by_master{
   my $dbh = shift;
   my $master = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Author WHERE master=?" );     
   $sth->execute($master);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id} || -1;
   return $id;
}
##########################################################################
sub get_team_id{
   my $dbh = shift;
   my $team = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Team WHERE name=?" );     
   $sth->execute($team);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id} || -1;
   return $id;
}
##########################################################################
sub get_tag_id{
   my $dbh = shift;
   my $tag = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Tag WHERE name=?" );     
   $sth->execute($tag);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id} || -1;
   return $id;
}
##########################################################################


sub read_bib_file_into_db{
   	my $dbh = shift;

	open (BIBFILE_IN, $in_file_name);
	my $counter=0;
	while (my $entry = new Text::BibTeX::Entry ($in_file_name, \*BIBFILE_IN))
	{
		if($entry->parse_ok==0){
			die "ERROR by parsing of entry ".$entry->key." \n";
		}
		next unless $entry->parse_ok;
		next if $entry->metatype == 4;

		my $key = $entry->key;

      # change / and : in key into -
      $key =~ s/\//-/g;
      $key =~ s/:/-/g;

      $entry->set_key($key);
      

		my $year = $entry->get('year');
      my $title = $entry->get('title') || '';
		my $abstract = $entry->get('abstract') || undef;
		my $content = $entry->print_s;

		my $tags_str = $entry->get('tags');
		$tags_str =~ s/\,/;/g if defined $tags_str;
		$tags_str =~ s/^\s+|\s+$//g if defined $tags_str;


		my $type = $entry->type;
      
      
      
      my @ary = $dbh->selectrow_array("SELECT bib FROM Entry WHERE key = ?", undef, $key);  
      my @ary2 = $dbh->selectrow_array("SELECT COUNT(*) FROM Entry WHERE key = ?", undef, $key);  

      my $bib_from_db = $ary[0];
      my $num = $ary2[0];
      my $key_exists = $num;

      # print "KEY $key exists? : $key_exists\n";


      

      if($key_exists==0){
            print "Adding new the entry with key: $key\n";
      		my $sth2 = $dbh->prepare( "INSERT INTO Entry(title, key, bib, year, tags_str, type, abstract, creation_time, modified_time) VALUES(?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))" );  
   			$sth2->execute($title, $key, $content, $year, $tags_str, $type, $abstract);

      		# $insert_query .= 'INSERT INTO Entry(key, bib, year, teams_str, type, creation_time, modified_time) VALUES(';
      		# $insert_query .= "$key, $content, $year, $tags_str_2db, $type, datetime('now'), datetime('now'))";
		}
		else{
       # checking if update is needed
       my $id = get_entry_id($dbh, $key);

         if($mode eq 'update' and $bib_from_db ne $content){
            print "Updating bib code of the entry: $key\n";
            my $sth2 = $dbh->prepare( "UPDATE Entry SET bib=?, need_html_regen=1, modified_time=datetime('now') WHERE id=?" );  
            $sth2->execute($content, $id);   

            if( $skip_html != 1){
               generate_html_for_key($dbh, $entry->key);
            }
         }
         elsif($mode eq 'destroy'){
            my $sth2 = $dbh->prepare( "REPLACE INTO Entry(title, key, bib, year, tags_str, type, abstract, modified_time) VALUES(?, ?, ?, ?, ?, ?, ?, datetime('now'))" );  
            $sth2->execute($title, $key, $content, $year, $tags_str, $type, $abstract);
         }
         else{
            # no update is needed!
         }
		}
		

      	# print $insert_query."\n";

      	# $dbh->do($insert_query);

     
		##### filling tags table
		my @tags = ();
		@tags = split(';', $tags_str) if defined $tags_str;
		for my $t (@tags){
			$t =~ s/^\s+|\s+$//g;
			$t =~ s/\ /_/g if defined $t;
			# $t = $dbh->quote($t);

			my $sth2 = $dbh->prepare( "INSERT OR IGNORE INTO Tag(name) VALUES(?)" );  
   			$sth2->execute($t);
			# $dbh->do("REPLACE INTO Tags(name) VALUES($t)");
		}
      	$counter++;
   }
   close(BIBFILE_IN);
   print "DB-Feed: Read $counter entries from file: $in_file_name into database.\n";

   #print Dumper(\%latexKeytoYear);
}




####################################################################################
####################################################################################
####################################################################################

sub process_entries{
   my $dbh = shift;

   print "Postprocessing entries: extracting authors and tags.\n";

   my $sth = $dbh->prepare( "SELECT bib FROM Entry" );  
   $sth->execute();

   my @ary = $dbh->selectrow_array("");  
   my $row;
   while($row = $sth->fetchrow_hashref()) {
      my $entry_string = $row->{bib};
      process_entry($dbh, $entry_string);
   }

   
}

sub process_entry{
   my $dbh = shift;
   my $entry_str = shift;

   my $entry = new Text::BibTeX::Entry;
   $entry->parse_s ($entry_str);

   die unless $entry->parse_ok;

   process_authors($dbh, $entry);
   process_tags($dbh, $entry);
}


sub process_authors{
   my $dbh = shift;
   my $entry = shift;

   

   my $key = $entry->key;

   my $eid = get_entry_id($dbh, $key);

   say "process_authors for key: $key, eid: $eid";


   my @names;

   if($entry->exists('author')){
      my @authors = $entry->split('author');
      my (@n) = $entry->names('author');
      @names = @n;
   }
   elsif($entry->exists('editor')){
      my @authors = $entry->split('editor');
      my (@n) = $entry->names('editor');
      @names = @n;
   }

   # authors need to be added to have their ids!!
   for my $name (@names){
      my $uid = create_user_id($name);

      my $aid = get_author_id_for_uid($dbh, $uid);


      my $sth = $dbh->prepare('INSERT OR IGNORE INTO Author(uid, master) VALUES(?, ?)');
      $sth->execute($uid, $uid) if $aid eq '-1';

      $aid = get_author_id_for_uid($dbh, $uid);
      my $mid = get_master_id_for_author_id($dbh, $aid);

      # if author was not in the uid2muid config, then mid = aid
      if($mid eq -1){
         $mid = $aid;
      }
      
      my $sth2 = $dbh->prepare('UPDATE Author SET master_id=? WHERE id=?');
      $sth2->execute($mid, $aid);


   }
   
   for my $name (@names){
      my $uid = create_user_id($name);
      my $aid = get_author_id_for_uid($dbh, $uid);
      my $mid = get_master_id_for_author_id($dbh, $aid);       #there tables are not filled yet!!

      say "\t !!! entry $eid -> uid $uid, aid $aid, mid $mid";
   
      my $sth3 = $dbh->prepare('INSERT OR IGNORE INTO Entry_to_Author(author_id, entry_id) VALUES(?, ?)');
      # my $sth3 = $dbh->prepare('UPDATE Entry_to_Author SET author_id = ? WHERE entry_id = ?');
      $sth3->execute($mid, $eid);

      
      # my $tid = get_team_id($dbh, "NOTEAM");
      # my $sth2 = $dbh->prepare("INSERT OR IGNORE INTO Author_to_Team(author_id, team_id, start, stop) Values (?, ?, ?, ?)");
      # $sth2->execute($aid, $tid, 0, 0);
   }

}

##########################################################################################
sub get_master_id_for_author_id{
   my $dbh = shift;
   my $id = shift;

   my $sth = $dbh->prepare( "SELECT master_id FROM Author WHERE id=?" );     
   $sth->execute($id);

   my $row = $sth->fetchrow_hashref();
   my $mid = $row->{master_id} || -1;
   print "ID = -1 for author aid $id\n" unless defined $id;
   return $mid;
}
##########################################################################################
sub get_author_id_for_uid{
   my $dbh = shift;
   my $master = shift;

   my $sth = $dbh->prepare( "SELECT id FROM Author WHERE uid=?" );     
   $sth->execute($master);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{id} || -1;
   print "ID = -1 for author $master\n" unless defined $id;
   return $id;
}

##########################################################################################
##########################################################################################


sub process_tags{
   my $dbh = shift;
   my $entry = shift;

   

   my $entry_key = $entry->key;
   my $key = $entry_key;
   my $eid = get_entry_id($dbh, $key);

   # my $sth2 = $dbh->prepare( "INSERT OR IGNORE INTO Tag(name) VALUES(?)" );  
   # $sth2->execute("ALL");  

   # my $tagid = get_tag_id($dbh, "ALL");

   # $sth2 = $dbh->prepare( "INSERT OR IGNORE INTO Entry_to_Tag(entry_id, tag_id) VALUES(?, ?)" );  
   # $sth2->execute($eid, $tagid);
   




   if($entry->exists('tags')){
      my $tags_str = $entry->get('tags');
      $tags_str =~ s/\,/;/g if defined $tags_str;
      $tags_str =~ s/^\s+|\s+$//g if defined $tags_str;

      
      my @tags = split(';', $tags_str) if defined $tags_str;

      for my $tag (@tags){
         $tag =~ s/^\s+|\s+$//g;
         $tag =~ s/\ /_/g if defined $tag;

         

         # $dbh->do("REPLACE INTO Tags VALUES($tag)");
         my $sth3 = $dbh->prepare( "INSERT OR IGNORE INTO Tag(name) VALUES(?)" );  
         $sth3->execute($tag);
         my $tagid2 = get_tag_id($dbh, $tag);

         # $dbh->do("INSERT INTO Entry_to_Tag(entry, tag) VALUES($entry_key, $tag)");
         $sth3 = $dbh->prepare( "INSERT OR IGNORE INTO Entry_to_Tag(entry_id, tag_id) VALUES(?, ?)" );  
         $sth3->execute($eid, $tagid2);
      }

   }
}


##########################################################################################
##########################################################################################




# returns the list that contains muids resulted from intesection of the PEOPLE array and the authors of the latex key
# sub get_all_people_as_string_for_key{
#    my ($key) = @_;
#    my @tmp;
#    for my $item (@{ $latexKeytoMasterUID{$key} }){
#       if($item ~~ @people_MasterUID){
#          push @tmp, $item;
#       }
#    }
#    my $str = join('; ', @tmp);
#    return $str;
# }

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





##################################################################
####################### SUBS #####################################
##################################################################

sub read_config_master_author{
   my($fname, $dbh) = @_;

   my $yml = YAML::Tiny->new;
   my $yml_out = YAML::Tiny->new;

   $yml = YAML::Tiny->read( $fname );
   
   my %yaml_struct;
   # copying YAML struct to something nicer to use
   for (my $i = 0; $i <= $#{ $yml }; $i+=2) {
      if($i%2==0){
         $yaml_struct{$yml->[$i]} = $yml->[$i+1];
      }
   }

   my %UIDtoMasterUID; 
   # filling UIDtoMasterUID hash
   while( my($k,$v) = each %{$yaml_struct{'MASTER_UID_TO_UID'}}){
      for my $elem (@{$v}){
         $UIDtoMasterUID{$elem} = $k;
      }
   }

   # print Dumper \%UIDtoMasterUID;

   # add master
   # get master_id
   # add uid;s
   # set master and master_id

   foreach my $key (keys %UIDtoMasterUID){
      my $uid = $key;
      $uid =~ s/^\s+|\s+$//g;
      my $master = $UIDtoMasterUID{$key};
      $master =~ s/^\s+|\s+$//g;

      my $sth = $dbh->prepare('INSERT INTO Author(uid, master) VALUES(?, ?)');
      $sth->execute($uid, $master);

      my $sth2 = $dbh->prepare('INSERT INTO Author(uid, master) VALUES(?, ?)');
      $sth2->execute($master, $master);

      my $aid = get_author_id_for_uid($dbh, $uid);

      say "\tLOOP 1 MASTER_UID_TO_UID: \t uid: $uid, master: $master, uid: $aid";

      
   }

   foreach my $key (keys %UIDtoMasterUID){
      my $uid = $key;
      $uid =~ s/^\s+|\s+$//g;
      my $master = $UIDtoMasterUID{$key};
      $master =~ s/^\s+|\s+$//g;

      my $aid = get_author_id_for_uid($dbh, $uid);
      my $mid = get_author_id_for_uid($dbh, $master); 

      if($mid eq -1){
         $mid = $aid;
      }

      say "\tLOOP 2 MASTER_UID_TO_UID: \t mid: $mid, aid $aid, uid: $uid, master: $master, ";
      
      my $sth2 = $dbh->prepare('UPDATE Author SET master_id=? WHERE id=?');
      $sth2->execute($mid, $aid);

      # now update mappings of Author and Entries
      my $sth3 = $dbh->prepare('UPDATE Entry_to_Author SET author_id=? WHERE author_id=?');
      $sth3->execute($mid, $aid);
      
   }

   foreach my $key (keys %UIDtoMasterUID){
      my $uid = $key;
      $uid =~ s/^\s+|\s+$//g;
      my $master = $UIDtoMasterUID{$key};
      $master =~ s/^\s+|\s+$//g;

      my $aid = get_author_id_for_uid($dbh, $uid);
      my $mid = get_author_id_for_uid($dbh, $master);

      # now update mappings of Author and Entries
      my $sth3 = $dbh->prepare('UPDATE Entry_to_Author SET author_id=? WHERE author_id=?');
      $sth3->execute($mid, $aid);
            
      # we add uid and set master and master_id (master and master_id exist already!)
      # my $sth = $dbh->prepare('INSERT OR IGNORE INTO Author(uid, master, master_id) VALUES(?, ?, ?)');
      # $sth->execute($uid, $master, $mid);

      # my $aid = get_author_id_for_uid($dbh, $uid);

      # my $master_id = get_author_id_for_uid($dbh, $master);

      # $sth = $dbh->prepare("UPDATE Author SET master=? WHERE uid=?");
      # $sth->execute($master, $uid);

      # my $aid = get_author_id_for_uid($dbh, $uid);
      # my $sth2 = $dbh->prepare('UPDATE Author SET master_id=? WHERE id=?');
      # $sth2->execute($aid, $aid);
    
   }
}


sub read_config_people{
   my($fname, $dbh) = @_;

   return unless $mode eq 'destroy';  # in update mode, we dont update the visibility of authors

   my $yml = YAML::Tiny->new;
   my $yml_out = YAML::Tiny->new;

   $yml = YAML::Tiny->read( $fname );
   
   my %yaml_struct;
   # copying YAML struct to something nicer to use
   for (my $i = 0; $i <= $#{ $yml }; $i+=2) {
      if($i%2==0){
         $yaml_struct{$yml->[$i]} = $yml->[$i+1];
      }
   }

   my @people = @{$yaml_struct{'PEOPLE'}};

   
   for my $uid (@people){
      my $master = getMasterUID_from_DB($dbh, $uid);

      my $aid = get_author_id_by_master($dbh, $master);
      my $mid = get_master_id_for_author_id($dbh, $aid);


      if($aid eq -1 and $mid eq -1){
         my $sth0 = $dbh->prepare('INSERT INTO Author(uid, master) VALUES(?, ?)');
         $sth0->execute($master, $master);

         $aid = get_author_id_by_master($dbh, $master);

         my $sth0b = $dbh->prepare('UPDATE Author SET master_id=? WHERE id=?');
         $sth0b->execute($aid, $aid);

         $mid = get_master_id_for_author_id($dbh, $aid);
         # say "\t -1 poprawka: setting visibility to 1 for master: $master, mid: $mid, aid: $aid";
      }
      
      my $sth = $dbh->prepare("UPDATE Author SET display=1 WHERE master_id=?");
      $sth->execute($mid) if $mid ne -1;
      
      say "\t set visibility to 1 for master: $master, mid: $mid, aid: $aid";

   }
}


sub read_config_teams{
   my($fname, $dbh) = @_;

   my $yml = YAML::Tiny->new;
   my $yml_out = YAML::Tiny->new;

   $yml = YAML::Tiny->read( $fname );
   
   my %yaml_struct;
   # copying YAML struct to something nicer to use
   for (my $i = 0; $i <= $#{ $yml }; $i+=2) {
      if($i%2==0){
         $yaml_struct{$yml->[$i]} = $yml->[$i+1];
      }
   }

   # filling hashes masterUIDtoGroups and groupstoMasterUID
   my @Teams_real;   #here are the teams that have been read from TEAM_TO_UID table from conf file
   foreach my $team (keys %{$yaml_struct{'TEAM_TO_UID'}}){

      my $sth = $dbh->prepare("INSERT OR IGNORE INTO Team(name, parent) Values (?, NULL)");
      $sth->execute($team);

   }
}


sub read_config_author_to_team{
   my($fname, $dbh) = @_;

   my $yml = YAML::Tiny->new;
   my $yml_out = YAML::Tiny->new;

   $yml = YAML::Tiny->read( $fname );
   
   my %yaml_struct;
   # copying YAML struct to something nicer to use
   for (my $i = 0; $i <= $#{ $yml }; $i+=2) {
      if($i%2==0){
         $yaml_struct{$yml->[$i]} = $yml->[$i+1];
      }
   }

   while( my($team, $line) = each %{$yaml_struct{'TEAM_TO_UID'}}){
      

      for my $elem (@{$line}){

         # $elem = UID [YYYY[-YYYY]]
         
         my $local_uid = $elem;
         my $lyear_start = 0;
         my $lyear_stop = 0;
         

         if($elem =~ /.* (\d)+-(\d)+/){
            my @larr = split(' ', $elem);
            my $luid = $larr[0]; # ok, checked
            $local_uid = $luid;

            my @lyears = split('-', $larr[1]);
            $lyear_start = $lyears[0];
            $lyear_stop = $lyears[1];

            $group_years_hash{'start'} = $lyear_start;
            $group_years_hash{'stop'} = $lyear_stop;            

         }

         my $master = getMasterUID_from_DB($dbh, $local_uid);
         my $muid = get_master_id_for_master($dbh, $master);

         my $teamid = get_team_id($dbh, $team);

         my $sth = $dbh->prepare("INSERT OR IGNORE INTO Author_to_Team(author_id, team_id, start, stop) Values (?, ?, ?, ?)");
         $sth->execute($muid, $teamid, $lyear_start, $lyear_stop) if $muid ne -1;

         say "\t TEAM: $team, tid: $teamid, muid: $muid, master: $master" if $muid ne -1;

         

      }
   }
}

sub get_master_id_for_master{
   my $dbh = shift;
   my $master = shift;

   my $sth = $dbh->prepare( "SELECT master_id FROM Author WHERE master=?" );     
   $sth->execute($master);

   my $row = $sth->fetchrow_hashref();
   my $id = $row->{master_id} || -1;
   print "ID = -1 for author $master\n" unless defined $id;
   return $id;
}


sub read_config_exceptions{
   my($fname, $dbh) = @_;

   my $yml = YAML::Tiny->new;
   my $yml_out = YAML::Tiny->new;

   $yml = YAML::Tiny->read( $fname );
   
   my %yaml_struct;
   # copying YAML struct to something nicer to use
   for (my $i = 0; $i <= $#{ $yml }; $i+=2) {
      if($i%2==0){
         $yaml_struct{$yml->[$i]} = $yml->[$i+1];
      }
   }

   while( my($key, $teams) = each %{$yaml_struct{'EXCEPTIONS_KEY_TO_GROUP'}}){

      my $eid = get_entry_id($dbh, $key);

      for my $team (@{$teams}){
         # print "key: $key, team: $team \n";
         my $teamid = get_team_id($dbh, $team);


         my $sth = $dbh->prepare("INSERT OR IGNORE INTO Exceptions_Entry_to_Team(entry_id, team_id) Values (?, ?)");
         $sth->execute($eid, $teamid);
      }
   }
}


sub getMasterUID_from_DB{
   my $dbh = shift;
   my $uid = shift;

   my $muid = undef;

   my $sth = $dbh->prepare( "SELECT master FROM Author WHERE uid = ?" );  
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

   my $sth = $dbh->prepare( "SELECT uid FROM Author" );  
   $sth->execute();

   my @arr = ();
   while(my $row = $sth->fetchrow_hashref()) {
      
      push @arr, $row->{uid};
   }
   

   return @arr;
}


sub post_process_Entry_to_Author{
   my $dbh = shift;

   my @authors = get_all_author_ids($dbh);

   foreach my $author (@authors){
      my $master = getMasterUID_from_DB($dbh, $author);

      my $aid = get_author_id_for_uid($dbh, $author);
      my $mid = get_author_id_by_master($dbh, $master);

      # say "aid $aid, mid $mid";

      # print "POST_PROCESSING UID \'$author\' MASTER: $master \n";
      # Entry_to_Author has mapping of uid to key. Naw it needs to be changed to master -> key
      my $sth2 = $dbh->prepare('UPDATE Entry_to_Author SET author_id = ? WHERE author_id = ?');
      $sth2->execute($mid, $aid);
   }
}



################################################################################
################################ html generator part
################################################################################



sub get_all_keys{
   my $dbh = shift;

   my @key_arr = ();

   # my $sth = $dbh->prepare( "SELECT DISTINCT key FROM Entry WHERE year = 2012" );
   my $sth = $dbh->prepare( "SELECT DISTINCT key FROM Entry" );
   $sth->execute(); 
   while(my $row = $sth->fetchrow_hashref()) {
      push @key_arr, $row->{key};
   }
   return @key_arr;
}


sub generate_html_for_keys{
   my ($dbh, @keys) = @_;

   foreach my $key (@keys){
      generate_html_for_key($dbh, $key);      
   }

   # system("rm data.bib out.html out_bib.html");
}

sub generate_html_for_key{
   my $dbh = shift;
   my $key = shift;
   my $id = get_entry_id($dbh,$key);

   

   my $sth = $dbh->prepare( "SELECT DISTINCT need_html_regen, key, bib, html 
         FROM Entry 
         WHERE id = ?" );  
   $sth->execute($id); 

   
   my $bib = undef;
   my $old_html = undef;
   my $entry_needs_html_regeration = undef;
   
   while(my $row = $sth->fetchrow_hashref()) {
      $bib = $row->{bib};
      $old_html = $row->{html};
      $entry_needs_html_regeration = $row->{need_html_regen};
   }
   if( $skip_html == 1){
      # print "Skipping html generation due to skip_html = $skip_html\n";
   }
   elsif(!defined $old_html or $entry_needs_html_regeration==1){
      
         my ($html, $htmlbib) = get_html_for_bib($bib, $key);

         my $sth2 = $dbh->prepare( "UPDATE Entry
            SET html = ? , html_bib = ?, need_html_regen = 0
            WHERE id = ?" );  
         $sth2->execute($html, $htmlbib, $id); 
   }
};



sub get_html_for_bib{
   my $bib_str = shift;
   my $key = shift || 'no-bibtex-key';

   open (MYFILE, '>data.bib');
   print MYFILE $bib_str;
   close (MYFILE); 

    my $cwd = getcwd();

   # -nokeys  --- no number in brackets by entry
   # -nodoc   --- dont generate document but a part of it - to omit html head body headers
   # -single  --- does not provide links to pdf, html and bib but merges bib with html output
   my $bibtex2html_command = "bibtex2html -s ".$cwd."/descartes2 -nf slides slides -d -r --revkeys -no-keywords -no-header -nokeys --nodoc  -no-footer -o out data.bib";
   # my $tune_html_command = "./tuneSingleHtmlFile.sh out.html";

   # print "COMMAND: $bibtex2html_command\n";

   system("export TMPDIR=".$tmpdir." && ".$bibtex2html_command);
   # system($tune_html_command);

   my $html =     read_file("out.html");
   my $htmlbib =  read_file("out_bib.html");

   $htmlbib =~ s/<h1>data.bib<\/h1>//g;

   $htmlbib =~ s/<a href="out.html#(.*)">(.*)<\/a>/$1/g;
   $htmlbib =~ s/<a href=/<a target="blank" href=/g;

   $html = tune_html($html, $key, $htmlbib);
   

   
   # now the output jest w out.html i out_bib.html

   return $html, $htmlbib;
}


sub tune_html{
   my $s = shift;
   my $key = shift;
   my $htmlbib = shift || "";

   # my $DIR="/var/www/html/publications-new";
   # my $DIRBASE="/var/www/html/";
   # #edit those two above always together!
   # my $WEBPAGEPREFIX="http://sdqweb.ipd.kit.edu/";
   # my $WEBPAGEPREFIXLONG="http://sdqweb.ipd.kit.edu/publications";

   # BASH CODE:
   # # replace links
   # sed -e s_"$DIR"_"$WEBPAGEPREFIXLONG"_g $FILE > $TMP && mv -f $TMP $FILE
   # # changes /var/www/html/publications-new to http://sdqweb.ipd.kit.edu/publications_new
   # $s =~ s/"$DIR"/"$WEBPAGEPREFIXLONG"/g;

   $s =~ s/out_bib.html#(.*)/\/publications\/get\/bibtex\/$1/g;
   
   # FROM .pdf">.pdf</a>&nbsp;]
   # TO   .pdf" target="blank">.pdf</a>&nbsp;]
   # $s =~ s/.pdf">/.pdf" target="blank">/g;


   $s =~ s/>.pdf<\/a>/ target="blank">.pdf<\/a>/g;
   $s =~ s/>http<\/a>/ target="blank">http<\/a>/g;
   $s =~ s/>.http<\/a>/ target="blank">http<\/a>/g;
   $s =~ s/>DOI<\/a>/ target="blank">DOI<\/a>/g;

   $s =~ s/<a (.*)>bib<\/a>/BIB_LINK_ID/g;
   
   

   # # for old system use:
   # #for x in `find $DIR -name "*.html"`;do sed 's_\[\&nbsp;<a href=\"_\[\&nbsp;<a href=\"http:\/\/sdqweb.ipd.kit.edu\/publications\/_g' $x > $TMP; mv $TMP $x; done

   # # replace &lt; and &gt; b< '<' and '>' in Samuel's files.
   # sed 's_\&lt;_<_g' $FILE > $TMP && mv -f $TMP $FILE
   # sed 's_\&gt;_>_g' $FILE > $TMP && mv -f $TMP $FILE
   $s =~ s/\&lt;/</g;
   $s =~ s/\&gt;/>/g;


   # ### insert JavaScript hrefs to show/hide abstracts on click ###
   # #replaces every newline command with <NeueZeile> to insert the Abstract link in the next step properly 
   # perl -p -i -e "s/\n/<NeueZeile>/g" $FILE
   $s =~ s/\n/<NeueZeile>/g;

   # #inserts the link to javascript
   # sed 's_\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">_\&nbsp;\|\&nbsp;<a href=\"javascript:showAbstract(this);\" onclick=\"showAbstract(this)\">Abstract</a><noscript> (JavaScript required!)</noscript>\&nbsp;\]<div style=\"display:none;\"><blockquote id=\"abstractBQ\">_g' $FILE > $TMP && mv -f $TMP $FILE
   # sed 's_</font></blockquote><NeueZeile><p>_</blockquote></div>_g' $FILE > $TMP && mv -f $TMP $FILE
   # $s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a href=\"javascript:showAbstract(this);\" onclick=\"showAbstract(this)\">Abstract<\/a><noscript> (JavaScript required!)<\/noscript>\&nbsp;\]<div style=\"display:none;\"><blockquote id=\"abstractBQ\">/g;

   
   #$s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a class="abstract-a" onclick=\"showAbstract(\'$key\')\">Abstract<\/a>\&nbsp; \]<div id=\"$key\" style=\"display:none;\"><blockquote id=\"abstractBQ\">/g;
   $s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a class="abstract-a" onclick=\"showAbstract(\'$key\')\">Abstract<\/a>\&nbsp; \] <div id=\"$key\" style=\"display:none;\"><blockquote id=\"abstractBQ\">/g;
   $s =~ s/<\/font><\/blockquote><NeueZeile><p>/<\/blockquote><\/div>/g;

   #inserting bib DIV marker
   $s =~ s/\]/\] BIB_DIV_ID/g;

   # handling BIB_DIV_ID marker
   $s =~ s/BIB_DIV_ID/<div id="bib-of-$key" class="inline-bib" style=\"display:none;\">$htmlbib<\/div>/g;
   # handling BIB_LINK_ID marker
   $s =~ s/BIB_LINK_ID/<a class="abstract-a" onclick=\"showAbstract(\'bib-of-$key\')\">bib<\/a>/g;

   # #undo the <NeueZeile> insertions
   # perl -p -i -e "s/<NeueZeile>/\n/g" $FILE
   $s =~ s/<NeueZeile>/\n/g;

   $s;
}
