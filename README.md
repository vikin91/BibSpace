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

### Status of this Readme file ###

    This file is still under construction and all information below this line should be treated as not ready yet.

### Installation ###

1. Install Mojolicious
    $ curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Mojolicious
2. Install Perl libraries
    sudo cpanm Time::Piece Data::Dumper Crypt::Eksblowfish::Bcrypt Crypt::Random Cwd File::Find DateTime File::Copy Scalar::Util Text::BibTeX utf8 File::Slurp DBI Exporter Set::Scalar Session::Token LWP::UserAgent
3. Copy files into a single location
    /home/xxx/hex64manager
    |- backups
    |- config
    |- lib
        |- ...
    |- log
    |- public
    |- script
    |- t
    |- templates
    |- tmp
    |- util
4. Set proper access rights
    chmod 777 /home/xxx/hex64manager/log
    ... todo
5. Install mysql and create mysql tables
  1. Sql commands are in files mysql_schema_user.sql and mysql_schema.sql
6. Configure the connection to the database by editing file `config/default.conf`
7. Run it!
    hypnotoad /home/xxx/hex64manager/script/admin_api
8. Stop it (if you need to)
    hypnotoad -s /home/xxx/hex64manager/script/admin_api
9. Run in developer mode
    morbo -l http://*:8080 /home/xxx/hex64manager/script/admin_api


### Changelog ###

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

