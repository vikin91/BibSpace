
# BibSpace Installation

## Native Installation

Tested for Debian-based operating systems.

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

## Running Natively-installed BibSpace

If all tests are passed then you may finally start BibSpace.

Due to incompatibility with perfork, I recomend using the *build-in server* for BibSpace `v0.5.x`:

```bash
export BIBSPACE_CONFIG=lib/BibSpace/files/config/default.conf
bin/bibspace daemon -m production -l http://*:8080
```

However, for other versions, in particular `0.6.x`, the `hypnotoad` may be used:

```bash
export BIBSPACE_CONFIG=lib/BibSpace/files/config/default.conf
hypnotoad ./bin/bibspace
```

To **stop BibSpace**
```bash
hypnotoad -s ./bin/bibspace
```

Bibspace may also be run in **developer mode** to see all errors and debug messages.

```bash
morbo -l http://*:8080 ./bin/bibspace
# or alternatively
bin/bibspace daemon -m development -l http://*:8080
```

Finally, you mah head to your browser, **login, and use the system**

```
http://YOUR_SERVER_IP:8080
Admin login: pub_admin
Admin password: asdf
```

Configure your firewall allow traffic on port 8080 if you cannot connect to the port 8080.
