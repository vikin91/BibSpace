package Hex64Publications::Controller::DB;

use utf8;
use DateTime;
use strict;
use warnings;
use v5.10;
use Try::Tiny;

use Exporter;
our @ISA= qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw( 
    create_backup_table
    create_main_db
    prepare_token_table_mysql
    prepare_user_table_mysql
    prepare_cron_table
    populate_tables
    );



our $bibtex2html_tmp_dir = "./tmp";
##########################################################################################
sub prepare_cron_table{
    my $dbh = shift;
    try {
        $dbh->do("CREATE TABLE IF NOT EXISTS Cron(
            type INTEGER PRIMARY KEY,
            last_run_time TIMESTAMP DEFAULT '0000-00-00 00:00:00'
            )");
    }
    catch{
        $dbh->do("CREATE TABLE IF NOT EXISTS Cron(
            type INTEGER PRIMARY KEY,
            last_run_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )");
    };

    try {
      $dbh->do("INSERT IGNORE INTO Cron (type) VALUES (0)");
      $dbh->do("INSERT IGNORE INTO Cron (type) VALUES (1)");
      $dbh->do("INSERT IGNORE INTO Cron (type) VALUES (2)");
      $dbh->do("INSERT IGNORE INTO Cron (type) VALUES (3)");  
    }
    catch{
      $dbh->do("REPLACE INTO Cron (type) VALUES (0)");
      $dbh->do("REPLACE INTO Cron (type) VALUES (1)");
      $dbh->do("REPLACE INTO Cron (type) VALUES (2)");
      $dbh->do("REPLACE INTO Cron (type) VALUES (3)");  
    };
    
};
####################################################################################
sub create_backup_table{
    my $dbh = shift;
    say "CALL: create_backup_table";

    $dbh->do("CREATE TABLE IF NOT EXISTS `Backup`(
            id INTEGER(5) PRIMARY KEY AUTO_INCREMENT,
            creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            filename VARCHAR(250),
            CONSTRAINT backup_filename_unique UNIQUE(filename)
      )");
}
####################################################################################
sub create_main_db{
    say "CALL: create_main_db";
    my $self = shift;
    my $dbh = shift;


   $dbh->do("CREATE TABLE IF NOT EXISTS `Author`(
         id INTEGER(5) PRIMARY KEY AUTO_INCREMENT, 
         uid VARCHAR(250), 
         display INTEGER(1) DEFAULT 0,
         master TEXT(250) DEFAULT NULL,
         master_id INTEGER(8),
         CONSTRAINT author_uid_unique UNIQUE(uid),
         FOREIGN KEY(master_id) REFERENCES Author(id) ON UPDATE CASCADE  ON DELETE CASCADE
         )");
   $dbh->do("CREATE TABLE IF NOT EXISTS `Team`(
         id INTEGER(8) PRIMARY KEY AUTO_INCREMENT,
         name VARCHAR(250) NOT NULL,
         parent VARCHAR(250) DEFAULT NULL,
         CONSTRAINT team_name_unique UNIQUE(name)
         )");
   $dbh->do("CREATE TABLE IF NOT EXISTS `Author_to_Team`(
         author_id INTEGER, 
         team_id INTEGER, 
         start INTEGER DEFAULT 0,
         stop INTEGER DEFAULT 0,
         FOREIGN KEY(author_id) REFERENCES Author(master_id) ON UPDATE CASCADE ON DELETE CASCADE,
         FOREIGN KEY(team_id) REFERENCES Team(id) ON UPDATE CASCADE ON DELETE CASCADE,
         PRIMARY KEY (author_id, team_id)
         )");



    try {
        # version for new Mysql
        $dbh->do("CREATE TABLE IF NOT EXISTS `Entry`(
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
          sort_month SMALLINT UNSIGNED DEFAULT 0,
          teams_str TEXT,
          people_str TEXT,
          tags_str TEXT,
          creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          modified_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          need_html_regen INTEGER DEFAULT 1,
          CONSTRAINT UNIQUE(bibtex_key),
          KEY idx_bibtex_key (bibtex_key)
          )");
    } catch {
        warn "Caught table creation error. Probably there is MySQL older than 5.6. Applying workaround!";
           # version for old Mysql
        $dbh->do("CREATE TABLE IF NOT EXISTS `Entry`(
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
          sort_month SMALLINT UNSIGNED DEFAULT 0,
          teams_str TEXT,
          people_str TEXT,
          tags_str TEXT,
          creation_time TIMESTAMP DEFAULT '0000-00-00 00:00:00',
          modified_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          need_html_regen INTEGER DEFAULT 1,
          CONSTRAINT UNIQUE(bibtex_key),
          KEY idx_bibtex_key (bibtex_key)
          )");
    };
   
   # creation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
   # creation_time TIMESTAMP DEFAULT '0000-00-00 00:00:00',

   
   $dbh->do("CREATE TABLE IF NOT EXISTS `Entry_to_Author`(
         entry_id INTEGER NOT NULL, 
         author_id INTEGER NOT NULL, 
         FOREIGN KEY(entry_id) REFERENCES Entry(id) ON UPDATE CASCADE ON DELETE CASCADE, 
         FOREIGN KEY(author_id) REFERENCES Author(master_id) ON UPDATE CASCADE ON DELETE CASCADE,
         PRIMARY KEY (entry_id, author_id),
         KEY idx_e2a_entry (entry_id),
         KEY idx_e2a_author (author_id)
         )");
   $dbh->do("CREATE TABLE IF NOT EXISTS `TagType`(
        name TEXT,
        comment TEXT,
        id INTEGER(8) PRIMARY KEY AUTO_INCREMENT
        )");
   $dbh->do("CREATE TABLE IF NOT EXISTS `TagType`(
        name TEXT,
        comment TEXT,
        id INTEGER(8) PRIMARY KEY AUTO_INCREMENT
        )");
   $dbh->do("CREATE TABLE IF NOT EXISTS `Tag`(
            name VARCHAR(250) NOT NULL,
            id INTEGER PRIMARY KEY AUTO_INCREMENT,
            type INTEGER DEFAULT 1,
            permalink TEXT,
            CONSTRAINT FOREIGN KEY(type) REFERENCES TagType(id),
            CONSTRAINT UNIQUE(name)
        )");
   $dbh->do("CREATE TABLE IF NOT EXISTS `Entry_to_Tag`(
         entry_id INTEGER(8) NOT NULL, 
         tag_id INTEGER(8) NOT NULL, 
         FOREIGN KEY(entry_id) REFERENCES Entry(id) ON UPDATE CASCADE ON DELETE CASCADE, 
         FOREIGN KEY(tag_id) REFERENCES Tag(id) ON UPDATE CASCADE ON DELETE CASCADE,
         PRIMARY KEY (entry_id, tag_id)
         )");
   $dbh->do("CREATE TABLE IF NOT EXISTS `Exceptions_Entry_to_Team`(
         entry_id INTEGER,
         team_id INTEGER,
         FOREIGN KEY(entry_id) REFERENCES Entry(id) ON DELETE CASCADE,
         FOREIGN KEY(team_id) REFERENCES Team(id) ON DELETE CASCADE,
         PRIMARY KEY (entry_id, team_id)
         )");
   $dbh->do("CREATE TABLE IF NOT EXISTS `OurType_to_Type`(
         bibtex_type VARCHAR(250), 
         our_type VARCHAR(250), 
         description TEXT DEFAULT NULL, 
         landing INTEGER DEFAULT 0,
         PRIMARY KEY (bibtex_type, our_type)
         )");

    # $dbh->do("ALTER TABLE Entry CHANGE type bibtex_type varchar(50) DEFAULT NULL");
    # $dbh->do("ALTER TABLE Entry ADD entry_type ENUM('paper', 'talk') NOT NULL AFTER id");
    # $dbh->do("ALTER TABLE Entry ADD hidden TINYINT UNSIGNED DEFAULT 0 AFTER title");
    # $dbh->do("ALTER TABLE Entry ADD month TINYINT UNSIGNED DEFAULT 0 AFTER year");
    # $dbh->do("ALTER TABLE Entry ADD sort_month SMALLINT UNSIGNED DEFAULT 0 AFTER year");

    $self->prepare_token_table_mysql($dbh);
    $self->prepare_user_table_mysql($dbh);
    $self->populate_tables($dbh);

};

####################################################################################################
sub prepare_token_table_mysql{ 
    my $self = shift;
    my $user_dbh = shift;

      $user_dbh->do("CREATE TABLE IF NOT EXISTS `Token`(
        id INTEGER(5) PRIMARY KEY AUTO_INCREMENT,
        token VARCHAR(250) NOT NULL,
        email VARCHAR(250) NOT NULL,
        requested TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT login_token_unique UNIQUE(token)
      )");
};
####################################################################################################
sub prepare_user_table_mysql{ 
    my $self = shift;
    my $user_dbh = shift;

    try{
        $user_dbh->do("CREATE TABLE IF NOT EXISTS `Login`(
            id INTEGER(5) PRIMARY KEY AUTO_INCREMENT,
            registration_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
          )");
    } catch {
        warn "Caught table creation error. Probably there is MySQL older than 5.6. Applying workaround!";
           # version for old Mysql
        $user_dbh->do("CREATE TABLE IF NOT EXISTS `Login`(
            id INTEGER(5) PRIMARY KEY AUTO_INCREMENT,
            registration_time TIMESTAMP DEFAULT '0000-00-00 00:00:00',
            last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
          )");
    };
   

   $self->prepare_token_table_mysql($user_dbh);

};


sub populate_tables{
    my $self = shift;
    my $dbh = shift;
    try {
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('incollection','inproceedings',NULL,1)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('incollection','bibtex-incollection',NULL,0)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('inproceedings','bibtex-inproceedings',NULL,0)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('inbook','book',NULL,0)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('mastersthesis','theses',NULL,1)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('phdthesis','theses',NULL,1)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('phdthesis','volumes',NULL,1)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('proceedings','volumes',NULL,1)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('article','article',NULL,1)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('book','book',NULL,0)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('inbook','inbook',NULL,0)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('incollection','incollection',NULL,0)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('inproceedings','inproceedings',NULL,1)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('manual','manual','Manuals',1)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('mastersthesis','mastersthesis',NULL,0)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('misc','misc',NULL,1)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('phdthesis','phdthesis',NULL,0)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('proceedings','proceedings',NULL,0)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('techreport','techreport',NULL,1)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('unpublished','unpublished',NULL,0)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('book','volumes',NULL,0)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('mastersthesis','supervised_theses','Supervised Theses',0)");
      $dbh->do("INSERT IGNORE INTO OurType_to_Type VALUES('phdthesis','supervised_theses','Supervised Theses',0)"); 
    }
    catch{
      warn "Data already exist. Doing nothing.";
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('incollection','inproceedings',NULL,1)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('incollection','bibtex-incollection',NULL,0)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('inproceedings','bibtex-inproceedings',NULL,0)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('inbook','book',NULL,0)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('mastersthesis','theses',NULL,1)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('phdthesis','theses',NULL,1)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('phdthesis','volumes',NULL,1)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('proceedings','volumes',NULL,1)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('article','article',NULL,1)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('book','book',NULL,0)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('inbook','inbook',NULL,0)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('incollection','incollection',NULL,0)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('inproceedings','inproceedings',NULL,1)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('manual','manual','Manuals',1)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('mastersthesis','mastersthesis',NULL,0)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('misc','misc',NULL,1)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('phdthesis','phdthesis',NULL,0)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('proceedings','proceedings',NULL,0)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('techreport','techreport',NULL,1)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('unpublished','unpublished',NULL,0)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('book','volumes',NULL,0)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('mastersthesis','supervised_theses','Supervised Theses',0)");
      # $dbh->do("REPLACE INTO OurType_to_Type VALUES('phdthesis','supervised_theses','Supervised Theses',0)");  
    };
}

1;