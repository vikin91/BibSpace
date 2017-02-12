
## BibSpace Installation ##
The installation procedure is not tested well yet. The package has been build using Dist::Zilla, so you can follow the standard way of installing it.

### Quick installation for Debian-based operating systems ###
```bash
cd ~
sudo aptitude update
sudo aptitude upgrade
sudo aptitude install git curl vim cpanminus mysql-server mysql-client libssl-dev bibtex2html libbtparse-dev libdbd-mysql-perl

git clone https://github.com/vikin91/BibSpace.git --depth 1
cd BibSpace

sudo cpanm --quiet --notest --skip-satisfied Dist::Zilla
dzil authordeps --missing | cpanm -S
dzil listdeps | cpanm -nq -S
# config mysql
mysql -u root -p --execute="CREATE DATABASE IF NOT EXISTS bibspace; GRANT ALL PRIVILEGES ON bibspace.* TO 'bibspace_user'@'localhost' IDENTIFIED BY 'passw00rd'; FLUSH PRIVILEGES;"
# test
prove -lt t/
# passed tests meant that the system is ready for use
# This is a very short installation procedure. Head to the sections below to configure your system.
```

### Normal installation with comments for Debian-based operating systems ###
```bash
cd ~
# as root
aptitude update
aptitude upgrade
aptitude install sudo git curl vim cpanminus 
# now you may just use sudo as normal user

# Install mysql as prerequisite
sudo aptitude install mysql-server mysql-client
# SSL is required for perl modules to communicate with Mailgun API
sudo aptitude install libssl-dev 
# Libraries required for handling database and BibTeX
sudo aptitude install bibtex2html libbtparse-dev libdbd-mysql-perl

# Download code. Last commit is enough
git clone https://github.com/vikin91/BibSpace.git --depth 1
cd BibSpace
git checkout master # or any other version that you want to use
# Install Dist::Zilla to handle the package
sudo cpanm --quiet --notest --skip-satisfied Dist::Zilla
# Install Dist::Zilla package prerequisites
dzil authordeps --missing | cpanm -S
# Now install prerequisites of BibSpace
dzil listdeps | cpanm -nq -S
# Should be ready to use!

# configure your database
mysql -u root -p --execute="CREATE DATABASE IF NOT EXISTS bibspace;"
mysql -u root -p --execute="GRANT ALL PRIVILEGES ON bibspace.* TO 'bibspace_user'@'localhost' IDENTIFIED BY 'passw00rd';"
mysql -u root -p --execute="FLUSH PRIVILEGES;"
# test the installation
prove -lt t/
# if you changed the mysql database name, user and password (you should!) then configure the credentials in config file
editor lib/BibSpace/files/config/default.conf
# repeat the test
BIBSPACE_CONFIG=lib/BibSpace/files/config/default.conf prove -lt t/
# if you see
All tests successful.
Files=6, Tests=200....
Result: PASS
# then everything went okay and BibSpace is ready for use
# You may ignore the warnings with Mysql version. The passed test means everything is okay

### TODO: provide test suite that do not use DB `prove -lt t/`
```

### Running BibSpace ###

If all tests are passed then you may finally **start BibSpace**

```bash
hypnotoad ./bin/bibspace
```
You may provide your custom config file like this:

```bash
BIBSPACE_CONFIG=lib/BibSpace/files/config/default.conf hypnotoad ./bin/bibspace
```
or using system variable

```bash
export BIBSPACE_CONFIG=lib/BibSpace/files/config/default.conf # please, use absolute path here
hypnotoad ./bin/bibspace
```
To **stop BibSpace** 
```bash
hypnotoad -s ./bin/bibspace
```


you may also run it in **developer mode** to see errors, debug messages etc.
```bash
morbo -l http://*:8080 ./bin/bibspace
```


Finally, you mah head to your browser, **login, and use the system**
```
http://YOUR_SERVER_IP:8080
Admin login: pub_admin
Admin password: asdf
```
Remeber to cofigure your firewall if you cannot connect to the port 8080.

### Running BibSpace in Production ###

#### TODO ####
* Configure reverse proxy nginx
* Configure reverse proxy apache2




