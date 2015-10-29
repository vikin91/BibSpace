# README #

This README would normally document whatever steps are necessary to get your application up and running. However, it is still not ready...

### License ###

"Hex64 Publication List Manager" is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

"Hex64 Publication List Manager" is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with "Hex64 Publication List Manager".  If not, see <http://www.gnu.org/licenses/>.

### Installation ###

```

### Prepare your system (tested on Debian 8.1 x64)
cd ~
aptitude update
aptitude upgrade
aptitude install sudo # as root
sudo aptitude install git curl cpanminus build-essential unzip nano bibtex2html


### Download code
git clone https://git@bitbucket.org/vikin9/hex64publicationlistmanager.git
cd hex64publicationlistmanager
mkdir backups

### Install Mojolicious
curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Mojolicious

### Install Perl libraries
sudo cpanm Time::Piece Data::Dumper Crypt::Eksblowfish::Bcrypt Cwd \ 
File::Find DateTime File::Copy  Scalar::Util utf8 File::Slurp DBI \
Exporter Set::Scalar Session::Token LWP::UserAgent Net::Address::IP::Local Text::BibTeX  
sudo cpanm -n Crypt::Random
sudo cpanm Test::Differences Test::MockModule WWW::Mailgun

sudo cpanm DBD::SQLite # will be obsolete soon, but still needed for backup functions


### Set permissions
chmod 777 ./tmp
chmod 555 ./log
chmod 555 ./backups

### Install mysql database and establish root password
aptitude install mysql-server 
# remeber the root password!

### Create mysql database and tables
mysql -u root -p
# Enter your mysql_root password and type then in mysql console
    CREATE DATABASE hex64publicationlistmanager;
    CREATE USER 'hex64plm'@'localhost' IDENTIFIED BY 'secret_password';
    GRANT ALL PRIVILEGES ON hex64publicationlistmanager.* TO 'hex64plm'@'localhost';
    FLUSH PRIVILEGES;
    quit;
# Then again in linux shell
mysql -u hex64plm -p hex64publicationlistmanager < mysql_schema_user.sql 
mysql -u hex64plm -p hex64publicationlistmanager < mysql_schema.sql
# enter your hex64plm mysql password (originally: secret_password)

### Edit config file
nano ./config/default.conf
# set: 
    db_host         => "localhost",
    db_user         => "hex64plm",
    db_database     => "hex64publicationlistmanager",
    db_pass         => "secret_password", # or any other selected by you

### Run it!
hypnotoad ./script/admin_api

### Stop it (if you need to)
hypnotoad -s ./script/admin_api

### Run in developer mode
morbo -l http://*:8080 ./script/admin_api

### See it in a browser
http://YOUR_SERVER_IP:8080
Admin login: pub_admin
Admin password: asdf

```


### Changelog ###

#### v1.4.1 28.10.2015 ####

* Minor bugfixes
* Installation procedure

#### v1.4 19.10.2015 ####

* Mojolicious updated to 6.24
* Talks introduced. Every entry is now described with *entry_type*. Possible types are: paper, talk.
* Filtering filed *type* **has been removed**. The fields *entry_type* and *bibtex_type* should be used now.
* Added field *month* and *sort_month* to DB. Normally sort_month = month. For now, *sort_month* cannot be set other as via setting *month* field in bibtex. This may change in the future.
* Publications and talks are now sorted first by year, then by month. If month does not exist in Bibtex then month=0
* All entries without field month can be listed
* Adding talks by assigning *Talk* tag is now **deprecated**
* User management view added (admin only)
* Automatic assignment of *entry_type* based on *talk* tag. This function can turn paper into talk, but not otherwise.
* Automatic extraction of month field for all papers - based on *month* bibtex field.
* Logging-in is now based on mysql database (connector errors are not a problem anymore). Sqlite is deprecated now.
* Various bugfixes
* **Known issues**
    * Talks are not shown on landing pages with years if *entry_type* is not specified (as requested by Samuel/Jürgen)
    * *ISBN* field of *incollection* is not printed (Bibtex does not support such field as isbn)
    * Several minor antipatterns are still left in code