# README #

This README would normally document whatever steps are necessary to get your application up and running. However, it is still not ready...

### License ###

This is private repository. No License is needed

### Status of this Readme file ###

    This file is still under construction and all information below this line should be treated as not ready yet.

### Installation ###

* TODO

### Changelog ###

#### v1.4 19.10.2015 ####

* Mojolicious updated to 6.24
* Talks introduced. Every entry is now described with entry_type. Possible types are: paper, talk.
* Filtering filed *type* has been removed. The fields *entry_type* and *bibtex_type* should be used now.
* Added field *month* and *sort_month* to DB. Normally sort_month = month. For now, *sort_month* cannot be set other as via setting *month* field in bibtex. This may change in the future.
* Publications and talks are now sorted first by year, then by month. If month does not exist in Bibtex, month=0
* Entries without field month are listed.
* Adding talks by assigning *Talk* tag is now **deprecated1**
* User management view added (admin only)
* Automatic assignement of entry_type based on *talk* tag. This function can turn paper into talk, but not otherwise.
* Automatic extraction of month field for all papers - based on *month* bibtex field.
* Various bugfixes
* **Known issues**
    * Talks are not shown on landing pages with years if *entry_type* is not specified (as requested by Samuel/Jürgen)
    * *ISBN* field of *incollection* is not printed (Bibtex does not support such field as isbn)
    * Several minor antipatterns are still left in code

