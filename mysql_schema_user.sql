DROP TABLE IF EXISTS Login;
DROP TABLE IF EXISTS Token;

CREATE TABLE IF NOT EXISTS `Login`(
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
      );

CREATE TABLE IF NOT EXISTS `Token`(
        id INTEGER(5) PRIMARY KEY AUTO_INCREMENT,
        token VARCHAR(250) NOT NULL,
        email VARCHAR(250) NOT NULL,
        requested TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT login_token_unique UNIQUE(token)
      );



