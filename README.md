# README #

BibSpace is an Online Bibtex Publications Management Software for Authors and Research Groups. Read about its features on the [BibSpace @ the Error Blog](https://blog.hex64.com/bibspace-online-bibtex-publications-management-software-for-authors-and-research-groups/).

## Build status ##

[![Build Status](https://travis-ci.org/vikin91/BibSpace.svg?branch=master)](https://travis-ci.org/vikin91/BibSpace) [![Coverage Status](https://coveralls.io/repos/github/vikin91/BibSpace/badge.svg?branch=master)](https://coveralls.io/github/vikin91/BibSpace?branch=master)

## Installation ##
* See [INSTALL.md](INSTALL.md)

## Using BibSpace with Docker ##

### Testing

To run BibSpace tests (inside Docker), run the following commands.

```
docker-compose build
docker-compose  -f docker-compose.yml -f docker-compose.test.yml up
```

### Running

To run BibSpace in production mode, run the following commands:

```
docker-compose build
docker-compose -f docker-compose.yml up -d
```

Thats it! Point you browser to http://localhost:8083/ to open BibSpace.

You may stop the container with

```
docker-compose down
```

The MySQL data is stored in `db_data`, whereas preferences and stats in `json_data`.

## Updating

Make sure to backup your data (regular backup + copy all `json` files) before updating.

### From Version <=0.5.2 to 0.6.x

1) *Important*: Update to version 0.5.3 first - this will enable JSON backups.
2) Backup your data to JSON format and make sure that data can be restored correctly.
3) Replace code with version 0.6.0 and restore data from the JSON backup.

### From Version 0.5.0 to >0.5.0

1) Update normally by replacing the code with newer version
2) Execute the following commands:

```
mkdir -p json_data
mv *.json json_data/
```

## TODOs ##

I currently work on BibSpace to improve severl things.
I ship code in coding sessions that happen rather rarely - once, twice per year.
In each session I implement things according to the following priority list:
- [ ] Fix bugs from open issues
- [ ] Increase test coverage
- [ ] Implement features

Moreover, I keep redesigning BibSpace to increase the quality of code.
Remeber that this was a `perl` and `Mojolicious` sandobx, so not all parts were written poperly in the past.
The following elements will be improved as the work progresses:
- Fixing the ugliest backend API and refactoring it to adhere to REST API best practices
- Separate backend and frontent code into separate code modules or even projects
- Applying modern frontend framework
