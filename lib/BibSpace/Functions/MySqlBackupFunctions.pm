package BibSpace::Functions::MySqlBackupFunctions;

use BibSpace::Functions::FDB;
use BibSpace::Functions::Core;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;

# use File::Slurp;
use File::Find;

use Try::Tiny;
use v5.16;           #because of ~~
use Cwd;
use strict;
use warnings;

use Exporter;
our @ISA = qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
  dump_mysql_to_file
);

sub dump_mysql_to_file {
  my $fname  = shift;
  my $config = shift;

  my $db_host     = $config->{db_host};
  my $db_user     = $config->{db_user};
  my $db_database = $config->{db_database};
  my $db_pass     = $config->{db_pass};

  my @ignored_tables = ("Token", "Backup");

  my $ignored_tables_string = "";
  for my $ign_tab (@ignored_tables) {
    $ignored_tables_string .= " --ignore-table=$db_database.$ign_tab";
  }

  my $command_prefix = "mysqldump --skip-comments --no-autocommit";

  try {
    if ($db_pass =~ /^\s*$/) {    # password empty
      `$command_prefix -u $db_user $db_database $ignored_tables_string > $fname`;
    }
    else {
      `$command_prefix -u $db_user -p$db_pass $db_database $ignored_tables_string > $fname`;
    }
  }
  catch {

  };
  return $fname;
}

1;
