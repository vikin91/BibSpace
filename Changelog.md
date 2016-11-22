### Changelog ###

#### v0.4.7 22.2016 ####
* Code refactoring - separate code for landing pages for publications
* add Redis-based caching
* new look-and-feel for filtering publications on the landing pages


#### v0.4.6 15-10.2016 ####
* Code refactoring - removed small parts of unused code
* add systemd .service profile
* add cpanfile stub
* rebuild edit author page 
* fix remove user id from author 
* add function merge authors 
* add tab-pane with bibtex help for adding publications 
* minor fixes and improvements # i love to write this :P


#### v0.4.5 08-10.2016 ####
* Code refactoring - towards OO design and getting rid of core.pm - edit_author, authors, tags
* Various bugfixes, e.g., showing publications with no tag for autor no longer returns 404.


#### v0.4.4 18-09.2016 ####
* Code refactoring - towards OO design and getting rid of core.pm
* Bugfix - saving publication creates now authors and provides updated preview

#### v0.4.2 and 0.4.3 06-08.2016 ####
* Code refactoring
* Multiple improvements

#### v0.4.1 31.05.2016 ####
* Add function to change download urls from direct file paths to file serving function
* Add function to remove attachments
* Fixing multiple minor bugs

#### v0.4 22.05.2016 ####
* Fixing multiple minor bugs
* Improving code quality with perlcritic
* Packaging

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
