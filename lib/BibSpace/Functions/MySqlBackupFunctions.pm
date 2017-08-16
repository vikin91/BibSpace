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

# This is the old function (version <0.5) used to restroee backups.
# It does not work with all MySQL server configurations, so we dont use it.
# sub do_restore_backup_from_file {
#     my $app       = shift;
#     my $dbh       = shift;
#     my $file_path = shift;
#     my $config    = shift;

#     # I assume that $file_path is the SQL dump that I want to restore

#     my $file_exists = 0;
#     if ( -e $file_path ) {
#         $file_exists = 1;
#     }
#     else {
#         $app->logger->warn("Cannot restore database from file $file_path. I stop now.");
#         return;
#     }

#     try{
#         $dbh->{mysql_auto_reconnect} = 0;
#         $dbh->disconnect();
#     }
#     catch{
#         $app->logger->error("Cannot disconnect: $_");
#     };

#     my $db_host     = $config->{db_host};
#     my $db_user     = $config->{db_user};
#     my $db_database = $config->{db_database};
#     my $db_pass     = $config->{db_pass};

#     my $cmd = "mysql -u $db_user -p$db_pass $db_database  < $file_path";
#     if ( $db_pass =~ /^\s*$/ ) {    # password empty
#         $cmd = "mysql -u $db_user $db_database  < $file_path";
#     }
#     my $command_output = "";
#     try {
#         $command_output = `$cmd`;
#     }
#     catch {
#         $app->logger->error("Restoring DB failed from file $file_path. Reason: $_. Status? $?. Command_output: $command_output.");
#         db_connect($db_host, $db_user, $db_database, $db_pass);
#         $app->db; # this will reconnect
#         $app->db->{mysql_auto_reconnect} = 1;
#     };

#     $app->db(); # this will reconnect
#     $app->db->{mysql_auto_reconnect} = 1;

#     if ( $? == 0 ) {
#         $app->repo->hardReset;
#         $app->setup_repositories;

#         $app->logger->info("Restoring backup succeeded from file $file_path");
#         return 1;
#     }
#     else {
#         $app->logger->error("Restoring backup FAILED from file $file_path");
#         return;
#     }
# }

1;
