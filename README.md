Branch | Status
--- | --- 
*master* | [![Build Status](https://travis-ci.org/vikin91/BibSpace.svg?branch=master)](https://travis-ci.org/vikin91/BibSpace)
*dev* | [![Build Status](https://travis-ci.org/vikin91/BibSpace.svg?branch=dev)](https://travis-ci.org/vikin91/BibSpace)
 

# README #


### Running demo ###

Visit [hex64.com](http://www.hex64.com/) and click backend/frontend demo to have a quick overview of the running system. 

### Installation ###

```

### Prepare your system (tested on Debian 8.1 x64)
cd ~
aptitude update
aptitude upgrade
aptitude install sudo # as root
sudo aptitude install git curl cpanminus build-essential unzip nano bibtex2html libbtparse-dev libdbd-mysql-perl 

### Install mysql database and establish root password
sudo aptitude install mysql-server libmysqlclient-dev
# remeber the root password!



### Download code
git clone https://github.com/vikin91/BibSpace.git
cd BibSpace
mkdir backups
mkdir log
mkdir tmp

### Install Mojolicious
curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Mojolicious

### Install Perl libraries
sudo cpanm -n Time::Piece Data::Dumper Crypt::Eksblowfish::Bcrypt Cwd Try::Tiny
sudo cpanm -n  File::Find DateTime File::Copy  Scalar::Util utf8 File::Slurp DBI
sudo cpanm -n Exporter Set::Scalar Session::Token LWP::UserAgent Net::Address::IP::Local 
sudo cpanm -n Text::BibTeX HTML::TagCloud::Sortable DBD::mysql
sudo cpanm -n Crypt::Random
sudo cpanm -n Test::Differences Test::MockModule WWW::Mailgun Mojolicious::Plugin::RenderFile

Optionally for building package:
sudo cpanm --notest Module::Build::CleanInstall Module::Build::Mojolicious

sudo cpanm DBD::SQLite # will be obsolete soon, but still needed for backup functions


### Set permissions
chmod 777 ./tmp
chmod 555 ./log
chmod 555 ./backups



### Create mysql database and tables
mysql -u root -p
# Enter your mysql_root password and type then in mysql console
    CREATE DATABASE bibspace;
    CREATE USER 'bibspace_user'@'localhost' IDENTIFIED BY 'passw00rd';
    GRANT ALL PRIVILEGES ON bibspace.* TO 'bibspace_user'@'localhost';
    FLUSH PRIVILEGES;
    quit;

### Edit config file
nano ./config/default.conf
# set: 
    db_host         => "localhost",
    db_user         => "bibspace_user",
    db_database     => "bibspace",
    db_pass         => "passw00rd", # or any other selected by you

### Run it!
MOJO_MODE=production hypnotoad ./script/bibspace

### Stop it (if you need to)
hypnotoad -s ./script/bibspace

### Run in developer mode
MOJO_MODE=delevop morbo -l http://*:8080 ./script/bibspace

### See it in a browser
http://YOUR_SERVER_IP:8080
Admin login: pub_admin
Admin password: asdf

# TODO: Config Mailgun

```


### Changelog ###

#### v0.3.3 19.05.2016 ####
* Fixing multiple minor bugs
* Improve redirects
* Change name to BibSpace
* Fix Travis CI script
* Update installation and Readme
* Add license

#### v0.3.2 26.11.2015 ####

* Publications can now be hidden and unhidden without deleting them
* get_publications_main was replaced by get_publications_main_hashed_args. Calls to get_publications_main return now undef.

#### v0.3.1 28.10.2015 ####

* Minor bugfixes
* Installation procedure

#### v0.3 19.10.2015 ####

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

### Known issues ###
* If an entry is hidden, the pdf/slides can still be downloaded if url of the file is known
* Talks are not shown on landing pages with years if *entry_type* is not specified (as requested by Samuel/Jürgen)
* *ISBN* field of *incollection* is not printed (Bibtex does not support such field as isbn)
* Several minor antipatterns are still left in code
