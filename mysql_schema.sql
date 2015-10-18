
DROP TABLE IF EXISTS Author_to_Team;
DROP TABLE IF EXISTS Entry_to_Author;
DROP TABLE IF EXISTS Entry_to_Tag;
DROP TABLE IF EXISTS Exceptions_Entry_to_Team;
DROP TABLE IF EXISTS OurType_to_Type;


DROP TABLE IF EXISTS Tag;
DROP TABLE IF EXISTS TagType;

DROP TABLE IF EXISTS Entry;
DROP TABLE IF EXISTS Team;
DROP TABLE IF EXISTS Author;


CREATE TABLE IF NOT EXISTS `Author`(
         id INTEGER(5) PRIMARY KEY AUTO_INCREMENT, 
         uid VARCHAR(250), 
         display INTEGER(1) DEFAULT 0,
         master TEXT(250) DEFAULT NULL,
         master_id INTEGER(8),
         CONSTRAINT author_uid_unique UNIQUE(uid),
         FOREIGN KEY(master_id) REFERENCES Author(id) ON UPDATE CASCADE  ON DELETE CASCADE
         );



CREATE TABLE IF NOT EXISTS `Team`(
         id INTEGER(8) PRIMARY KEY AUTO_INCREMENT,
         name VARCHAR(250) NOT NULL,
         parent VARCHAR(250) DEFAULT NULL,
         CONSTRAINT team_name_unique UNIQUE(name)
         );



CREATE TABLE IF NOT EXISTS `Author_to_Team`(
         author_id INTEGER, 
         team_id INTEGER, 
         start INTEGER DEFAULT 0,
         stop INTEGER DEFAULT 0,
         FOREIGN KEY(author_id) REFERENCES Author(master_id) ON UPDATE CASCADE ON DELETE CASCADE,
         FOREIGN KEY(team_id) REFERENCES Team(id) ON UPDATE CASCADE ON DELETE CASCADE,
         PRIMARY KEY (author_id, team_id)
         );


CREATE TABLE IF NOT EXISTS `Entry`(
      id INTEGER(8) PRIMARY KEY AUTO_INCREMENT,
      bibtex_key VARCHAR(250), 
      type VARCHAR(50), 
      bib TEXT, 
      html TEXT,
      html_bib TEXT,
      abstract TEXT,
      title TEXT,
      year INTEGER(4),
      teams_str TEXT,
      people_str TEXT,
      tags_str TEXT,
      creation_time TIMESTAMP DEFAULT '0000-00-00 00:00:00',
      modified_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      need_html_regen INTEGER DEFAULT 1,
      CONSTRAINT UNIQUE(bibtex_key),
      KEY idx_bibtex_key (bibtex_key)
      );



CREATE TABLE IF NOT EXISTS `Entry_to_Author`(
         entry_id INTEGER NOT NULL, 
         author_id INTEGER NOT NULL, 
         FOREIGN KEY(entry_id) REFERENCES Entry(id) ON UPDATE CASCADE ON DELETE CASCADE, 
         FOREIGN KEY(author_id) REFERENCES Author(master_id) ON UPDATE CASCADE ON DELETE CASCADE,
         PRIMARY KEY (entry_id, author_id),
         KEY idx_e2a_entry (entry_id),
         KEY idx_e2a_author (author_id)
         );

CREATE TABLE IF NOT EXISTS `TagType`(
        name TEXT,
        comment TEXT,
        id INTEGER(8) PRIMARY KEY AUTO_INCREMENT
        );

CREATE TABLE IF NOT EXISTS `Tag`(
            name VARCHAR(250) NOT NULL,
            id INTEGER PRIMARY KEY AUTO_INCREMENT,
            type INTEGER DEFAULT 1,
            permalink TEXT,
            CONSTRAINT FOREIGN KEY(type) REFERENCES TagType(id),
            CONSTRAINT UNIQUE(name)
        );

CREATE TABLE IF NOT EXISTS `Entry_to_Tag`(
         entry_id INTEGER(8) NOT NULL, 
         tag_id INTEGER(8) NOT NULL, 
         FOREIGN KEY(entry_id) REFERENCES Entry(id) ON UPDATE CASCADE ON DELETE CASCADE, 
         FOREIGN KEY(tag_id) REFERENCES Tag(id) ON UPDATE CASCADE ON DELETE CASCADE,
         PRIMARY KEY (entry_id, tag_id)
         );



CREATE TABLE IF NOT EXISTS `Exceptions_Entry_to_Team`(
         entry_id INTEGER,
         team_id INTEGER DEFAULT NULL,
         FOREIGN KEY(entry_id) REFERENCES Entry(id) ON DELETE CASCADE,
         FOREIGN KEY(team_id) REFERENCES Team(id) ON DELETE CASCADE,
         PRIMARY KEY (entry_id, team_id)
         );

CREATE TABLE IF NOT EXISTS `OurType_to_Type`(
         bibtex_type VARCHAR(250), 
         our_type VARCHAR(250), 
         description TEXT DEFAULT NULL, 
         landing INTEGER DEFAULT 0,
         PRIMARY KEY (bibtex_type, our_type)
         );





