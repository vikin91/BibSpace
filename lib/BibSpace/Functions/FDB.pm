package BibSpace::Functions::FDB;

use utf8;
use DateTime;
use strict;
use warnings;
use v5.16;
use Try::Tiny;
use Data::Dumper;
use Exporter;
use DBIx::Connector;
use DBI;
our @ISA = qw( Exporter );

our @EXPORT = qw(
  db_connect
  create_main_db
  reset_db_data
  prepare_token_table_mysql
  prepare_user_table_mysql
  prepare_cron_table
  populate_tables

);

sub db_connect {
  my ($db_host, $db_user, $db_database, $db_pass) = @_;

  my $conn = undef;
  my %attr = (RaiseError => 1, AutoCommit => 1, mysql_auto_reconnect => 1);
  try {
    $conn = DBI->connect_cached("DBI:mysql:database=$db_database;host=$db_host",
      $db_user, $db_pass, \%attr);
  }
  catch {
    warn "db_connect: could not connect to the database: $_";
    warn "Trying to recreate database...";

    try {
      my $drh = DBI->install_driver("mysql");
      $drh->func('createdb', $db_database, $db_host, $db_user, $db_pass,
        'admin');
    }
    catch {
      die "FATAL: DB Recreation failed: $_";
    };
  };
  return $conn;
}

sub reset_db_data {
  my ($dbh) = @_;

  my @table_names
    = qw(Author Team Entry Tag TagType Login Author_to_Team Entry_to_Author Entry_to_Tag Exceptions_Entry_to_Team OurType_to_Type );

  try {
    $dbh->do(q{SET FOREIGN_KEY_CHECKS = 0;});
    foreach my $table_name (@table_names) {
      $dbh->do(q{TRUNCATE TABLE } . $table_name);
    }
  }
  catch {
    warn "Truncation unsuccessful, error: $_";
  }
  finally {
    $dbh->do(q{SET FOREIGN_KEY_CHECKS = 1;});
  };
  return $dbh;
}

sub create_main_db {
  my $dbh = shift;

  say "Recreating DB schema";

  $dbh->do(
    "CREATE TABLE IF NOT EXISTS `Author`(
         id INTEGER(5) PRIMARY KEY AUTO_INCREMENT,
         uid VARCHAR(250),
         display INTEGER(1) DEFAULT 0,
         master TEXT(250) DEFAULT NULL,
         master_id INTEGER(8),
         CONSTRAINT author_uid_unique UNIQUE(uid),
         FOREIGN KEY(master_id) REFERENCES Author(id) ON UPDATE CASCADE  ON DELETE CASCADE
         )"
  );
  $dbh->do(
    "CREATE TABLE IF NOT EXISTS `Team`(
         id INTEGER(8) PRIMARY KEY AUTO_INCREMENT,
         name VARCHAR(250) NOT NULL,
         parent VARCHAR(250) DEFAULT NULL,
         CONSTRAINT team_name_unique UNIQUE(name)
         )"
  );
  $dbh->do(
    "CREATE TABLE IF NOT EXISTS `Author_to_Team`(
         author_id INTEGER,
         team_id INTEGER,
         start INTEGER DEFAULT 0,
         stop INTEGER DEFAULT 0,
         FOREIGN KEY(author_id) REFERENCES Author(master_id) ON UPDATE CASCADE ON DELETE CASCADE,
         FOREIGN KEY(team_id) REFERENCES Team(id) ON UPDATE CASCADE ON DELETE CASCADE,
         PRIMARY KEY (author_id, team_id)
         )"
  );

  try {
    # version for new Mysql - tested on 5.6 and 5.7
    $dbh->do(
      "CREATE TABLE IF NOT EXISTS `Entry`(
          id INTEGER(8) PRIMARY KEY AUTO_INCREMENT,
          entry_type ENUM('paper', 'talk') NOT NULL,
          bibtex_key VARCHAR(250),
          bibtex_type VARCHAR(50)DEFAULT NULL,
          bib TEXT,
          html TEXT,
          html_bib TEXT,
          abstract TEXT,
          title TEXT,
          hidden TINYINT UNSIGNED DEFAULT 0,
          year INTEGER(4),
          month TINYINT UNSIGNED DEFAULT 0,
          creation_time TIMESTAMP NOT NULL DEFAULT '1970-01-01 01:01:01',
          modified_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          need_html_regen INTEGER DEFAULT 1,
          CONSTRAINT UNIQUE(bibtex_key),
          KEY idx_bibtex_key (bibtex_key)
          )"
    );

    # was: creation_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  }
  catch {
    say "Probably MySQL is older than 5.6. Applying workaround!";

    $dbh->do(
      "CREATE TABLE IF NOT EXISTS `Entry`(
          id INTEGER(8) PRIMARY KEY AUTO_INCREMENT,
          entry_type ENUM('paper', 'talk') NOT NULL,
          bibtex_key VARCHAR(250),
          bibtex_type VARCHAR(50)DEFAULT NULL,
          bib TEXT,
          html TEXT,
          html_bib TEXT,
          abstract TEXT,
          title TEXT,
          hidden TINYINT UNSIGNED DEFAULT 0,
          year INTEGER(4),
          month TINYINT UNSIGNED DEFAULT 0,
          creation_time TIMESTAMP NOT NULL DEFAULT '1970-01-01 01:01:01',
          modified_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          need_html_regen INTEGER DEFAULT 1,
          CONSTRAINT UNIQUE(bibtex_key),
          KEY idx_bibtex_key (bibtex_key)
          )"
    );
  };

  # creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  # creation_time TIMESTAMP DEFAULT '0000-00-00 00:00:00',

  $dbh->do(
    "CREATE TABLE IF NOT EXISTS `Entry_to_Author`(
         entry_id INTEGER NOT NULL,
         author_id INTEGER NOT NULL,
         FOREIGN KEY(entry_id) REFERENCES Entry(id) ON UPDATE CASCADE ON DELETE CASCADE,
         FOREIGN KEY(author_id) REFERENCES Author(master_id) ON UPDATE CASCADE ON DELETE CASCADE,
         PRIMARY KEY (entry_id, author_id),
         KEY idx_e2a_entry (entry_id),
         KEY idx_e2a_author (author_id)
         )"
  );
  $dbh->do(
    "CREATE TABLE IF NOT EXISTS `TagType`(
        name TEXT,
        comment TEXT,
        id INTEGER(8) PRIMARY KEY AUTO_INCREMENT
        )"
  );
  $dbh->do(
    "CREATE TABLE IF NOT EXISTS `Tag`(
            name VARCHAR(250) NOT NULL,
            id INTEGER PRIMARY KEY AUTO_INCREMENT,
            type INTEGER DEFAULT 1,
            permalink TEXT,
            CONSTRAINT FOREIGN KEY(type) REFERENCES TagType(id),
            CONSTRAINT UNIQUE(name)
        )"
  );
  $dbh->do(
    "CREATE TABLE IF NOT EXISTS `Entry_to_Tag`(
         entry_id INTEGER(8) NOT NULL,
         tag_id INTEGER(8) NOT NULL,
         FOREIGN KEY(entry_id) REFERENCES Entry(id) ON UPDATE CASCADE ON DELETE CASCADE,
         FOREIGN KEY(tag_id) REFERENCES Tag(id) ON UPDATE CASCADE ON DELETE CASCADE,
         PRIMARY KEY (entry_id, tag_id)
         )"
  );
  $dbh->do(
    "CREATE TABLE IF NOT EXISTS `Exceptions_Entry_to_Team`(
         entry_id INTEGER,
         team_id INTEGER,
         FOREIGN KEY(entry_id) REFERENCES Entry(id) ON DELETE CASCADE,
         FOREIGN KEY(team_id) REFERENCES Team(id) ON DELETE CASCADE,
         PRIMARY KEY (entry_id, team_id)
         )"
  );
  $dbh->do(
    "CREATE TABLE IF NOT EXISTS `OurType_to_Type`(
         bibtex_type VARCHAR(250),
         our_type VARCHAR(250),
         description TEXT DEFAULT NULL,
         landing INTEGER DEFAULT 0,
         PRIMARY KEY (bibtex_type, our_type)
         )"
  );

  # prepare_token_table_mysql($dbh);
  prepare_cron_table($dbh);
  prepare_user_table_mysql($dbh);
  apply_migrations($dbh);
}

# sub prepare_token_table_mysql {
#   my $user_dbh = shift;

#   $user_dbh->do(
#     "CREATE TABLE IF NOT EXISTS `Token`(
#         id INTEGER(5) PRIMARY KEY AUTO_INCREMENT,
#         token VARCHAR(250) NOT NULL,
#         email VARCHAR(250) NOT NULL,
#         requested TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
#         CONSTRAINT login_token_unique UNIQUE(token)
#       )"
#   );
# }

sub prepare_cron_table {
  my $dbh = shift;
  try {
    $dbh->do(
      "CREATE TABLE IF NOT EXISTS Cron(
            type INTEGER PRIMARY KEY,
            last_run_time TIMESTAMP DEFAULT '1970-01-01 01:01:01'
            )"
    );
  }
  catch {
    $dbh->do(
      "CREATE TABLE IF NOT EXISTS Cron(
            type INTEGER PRIMARY KEY,
            last_run_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )"
    );
  };

  try {
    $dbh->do("INSERT IGNORE INTO Cron (type) VALUES (0)");
    $dbh->do("INSERT IGNORE INTO Cron (type) VALUES (1)");
    $dbh->do("INSERT IGNORE INTO Cron (type) VALUES (2)");
    $dbh->do("INSERT IGNORE INTO Cron (type) VALUES (3)");
  }
  catch { };

}

sub prepare_user_table_mysql {
  my $dbh = shift;

  try {
    $dbh->do(
      "CREATE TABLE IF NOT EXISTS `Login`(
      id INTEGER(5) PRIMARY KEY AUTO_INCREMENT,
      registration_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      last_login TIMESTAMP DEFAULT '1970-01-01 01:01:01',
      login VARCHAR(250) NOT NULL,
      real_name VARCHAR(250) DEFAULT 'unnamed',
      email VARCHAR(250) NOT NULL,
      pass VARCHAR(250) NOT NULL,
      pass2 VARCHAR(250) NOT NULL,
      pass3 VARCHAR(250),
      rank INTEGER(3) DEFAULT 0,
      master_id INTEGER(8) DEFAULT 0,
      tennant_id INTEGER(8) DEFAULT 0,
      CONSTRAINT login_unique UNIQUE(login)
    )"
    );
  }
  catch {
    say "Probably MySQL is older than 5.6. Applying workaround!";

    # version for old Mysql
    $dbh->do(
      "CREATE TABLE IF NOT EXISTS `Login`(
      id INTEGER(5) PRIMARY KEY AUTO_INCREMENT,
      registration_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      last_login TIMESTAMP DEFAULT '1970-01-01 01:01:01',
      login VARCHAR(250) NOT NULL,
      real_name VARCHAR(250) DEFAULT 'unnamed',
      email VARCHAR(250) NOT NULL,
      pass VARCHAR(250) NOT NULL,
      pass2 VARCHAR(250) NOT NULL,
      pass3 VARCHAR(250),
      rank INTEGER(3) DEFAULT 0,
      master_id INTEGER(8) DEFAULT 0,
      tennant_id INTEGER(8) DEFAULT 0,
      CONSTRAINT login_unique UNIQUE(login)
    )"
    );
  };
}

sub apply_migrations {
  my $dbh = shift;
  try {
    say "Attempt to migrate table Login";
    $dbh->do(
      "ALTER TABLE `Login` ADD COLUMN `forgot_pass_token` VARCHAR(250) DEFAULT NULL"
    );
  }
  catch {
    say "Migration not necessary or failed: $_";
  };
  try {
    $dbh->do("ALTER TABLE `Login` DROP COLUMN `pass3`");
  }
  catch {
    say "Migration not necessary or failed: $_";
  };
  try {
    say "Attempt to migrate table Author";
    $dbh->do(
      "ALTER TABLE `Author` DROP PRIMARY KEY, MODIFY id INTEGER(8) PRIMARY KEY AUTO_INCREMENT"
    );
  }
  catch {
    say "Migration not necessary or failed: $_";
  };
}

1;
