Branch | Status | Test coverage
--- | --- | ---
*master* | [![Build Status](https://travis-ci.org/vikin91/BibSpace.svg?branch=master)](https://travis-ci.org/vikin91/BibSpace) | [![Coverage Status](https://coveralls.io/repos/github/vikin91/BibSpace/badge.svg?branch=master)](https://coveralls.io/github/vikin91/BibSpace?branch=master)
*dev* | [![Build Status](https://travis-ci.org/vikin91/BibSpace.svg?branch=dev)](https://travis-ci.org/vikin91/BibSpace) | [![Coverage Status](https://coveralls.io/repos/github/vikin91/BibSpace/badge.svg?branch=dev)](https://coveralls.io/github/vikin91/BibSpace?branch=dev)
*experimental* | [![Build Status](https://travis-ci.org/vikin91/BibSpace.svg?branch=experimental)](https://travis-ci.org/vikin91/BibSpace) | [![Coverage Status](https://coveralls.io/repos/github/vikin91/BibSpace/badge.svg?branch=experimental)](https://coveralls.io/github/vikin91/BibSpace?branch=experimental)

# README #


### Running demo ###

Visit [hex64.com](http://www.hex64.com/) and click backend/frontend demo to have a quick overview of the running system. 

### Installation ###

```
cd ~
aptitude update
aptitude upgrade
aptitude install sudo git curl vim cpanminus 

git clone https://github.com/vikin91/BibSpace.git
cd BibSpace
git checkout master # or any other version that you want to use

#### Install prerequisites for package installation
# Install mysql  as prerequisite
sudo aptitude install mysql-server mysql-client
# SSL is required for perl modules to communicate with Mailgun API
sudo aptitude install libssl-dev 
sudo aptitude install bibtex2html libbtparse-dev libdbd-mysql-perl
# Required to run installdeps
sudo cpanm -nq Module::Build::Mojolicious Module::CPANfile DateTime
# The rest of prerequisites
sudo cpanm -nq --no-interactive --installdeps .


perl Build.PL 
./Build installdeps
./Build


# configure database
mysql -u root -p --execute="CREATE DATABASE IF NOT EXISTS bibspace;"
mysql -u root -p --execute="CREATE USER 'bibspace_user'@'localhost' IDENTIFIED BY 'passw00rd';"
mysql -u root -p --execute="GRANT ALL PRIVILEGES ON bibspace.* TO 'bibspace_user'@'localhost';"
mysql -u root -p --execute="FLUSH PRIVILEGES;"

# edit the default.config file and enter the credentials for database

# Run tests
./Build test
# You may ignore the warnings with Mysql version. The passed test means everything is okay

# If all tests are passed then you may finally start BibSpace
hypnotoad ./bin/bibspace

### Stop it (if you need to)
hypnotoad -s ./bin/bibspace

### Run in developer mode
morbo -l http://*:8080 ./script/bibspace

### Use custom config file
BIBSPACE_CONFIG=config/your_file.conf hypnotoad ./bin/bibspace

### See it in a browser
http://YOUR_SERVER_IP:8080
Admin login: pub_admin
Admin password: asdf

# TODO: add rules to cron
# TODO: configure reverse proxy in nginx

# In case of any failure install the dependencies using cpanminus
sudo cpanm -n Time::Piece Data::Dumper Crypt::Eksblowfish::Bcrypt Cwd Try::Tiny
sudo cpanm -n File::Find DateTime File::Copy  Scalar::Util utf8 File::Slurp DBI
sudo cpanm -n Exporter Set::Scalar Session::Token LWP::UserAgent 
sudo cpanm -n Text::BibTeX HTML::TagCloud::Sortable DBD::mysql Path::Tiny
sudo cpanm -n Crypt::Random Mojolicious::Plugin::RenderFile
sudo cpanm -n Test::Differences Test::MockModule WWW::Mechanize 
sudo cpanm -n Module::Build::CleanInstall Module::Build::Mojolicious

```

### Installation OLD###

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
sudo cpanm -n Exporter Set::Scalar Session::Token LWP::UserAgent 
sudo cpanm -n Text::BibTeX HTML::TagCloud::Sortable DBD::mysql Path::Tiny
sudo cpanm -n Crypt::Random
sudo cpanm -n Test::Differences Test::MockModule Mojolicious::Plugin::RenderFile

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
mysql -u root -p --execute="CREATE DATABASE IF NOT EXISTS bibspace;"
mysql -u root -p --execute="CREATE USER 'bibspace_user'@'localhost' IDENTIFIED BY 'passw00rd';"
mysql -u root -p --execute="GRANT ALL PRIVILEGES ON bibspace.* TO 'bibspace_user'@'localhost';"
mysql -u root -p --execute="FLUSH PRIVILEGES;"

### Edit config file
nano ./config/default.conf
# set: 
    db_host         => "localhost",
    db_user         => "bibspace_user",
    db_database     => "bibspace",
    db_pass         => "passw00rd", # or any other selected by you

### Run it!
BIBSPACE_CONFIG=config/your.conf hypnotoad ./script/bibspace

### Stop it (if you need to)
hypnotoad -s ./script/bibspace

### Run in developer mode
BIBSPACE_CONFIG=config/your.conf morbo -l http://*:8080 ./script/bibspace

### See it in a browser
http://YOUR_SERVER_IP:8080
Admin login: pub_admin
Admin password: asdf

```

### TODO ###
* perlcritic -4 `find ./lib -iname *.pm`

