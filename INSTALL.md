
## BibSpace Installation ##


### Quick installation for Debian-based operating systems ###
```bash
cd ~
sudo aptitude update
sudo aptitude upgrade
sudo aptitude install build-essential make git curl vim cpanminus mysql-server mysql-client libssl-dev bibtex2html libbtparse-dev libdbd-mysql-perl

# get code
git clone https://github.com/vikin91/BibSpace.git --depth 1
cd BibSpace

# install prerequisites
cpanm -nq --no-interactive --installdeps .

# config mysql
mysql -u root -p --execute="CREATE DATABASE IF NOT EXISTS bibspace; GRANT ALL PRIVILEGES ON bibspace.* TO 'bibspace_user'@'localhost' IDENTIFIED BY 'passw00rd'; FLUSH PRIVILEGES;"
# test
prove -lr
# if all tests pass then the system is ready for use
```


### Running BibSpace ###

If all tests are passed then you may finally **start BibSpace**

```bash
# provide config
export BIBSPACE_CONFIG=lib/BibSpace/files/config/default.conf
# using hypnotoad (currently not recomended for version 0.5.0 due to prefork)
hypnotoad ./bin/bibspace
# using built-in server
bin/bibspace daemon -m production -l http://*:8080
```

To **stop BibSpace**
```bash
hypnotoad -s ./bin/bibspace
```


you may also run it in **developer mode** to see errors, debug messages etc.
```bash
morbo -l http://*:8080 ./bin/bibspace
# or
bin/bibspace daemon -m development -l http://*:8080
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
- [] Configure reverse proxy nginx
- [] Configure reverse proxy apache2




