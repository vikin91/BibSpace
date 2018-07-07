# README #

BibSpace is an Online Bibtex Publications Management Software for Authors and Research Groups. Read about its features on the [BibSpace @ the Error Blog](https://blog.hex64.com/bibspace-online-bibtex-publications-management-software-for-authors-and-research-groups/).

## Build status ##

Branch | Status | Test coverage
--- | --- | ---
*master* | [![Build Status](https://travis-ci.org/vikin91/BibSpace.svg?branch=master)](https://travis-ci.org/vikin91/BibSpace) | [![Coverage Status](https://coveralls.io/repos/github/vikin91/BibSpace/badge.svg?branch=master)](https://coveralls.io/github/vikin91/BibSpace?branch=master)
*dev* | [![Build Status](https://travis-ci.org/vikin91/BibSpace.svg?branch=dev)](https://travis-ci.org/vikin91/BibSpace) | [![Coverage Status](https://coveralls.io/repos/github/vikin91/BibSpace/badge.svg?branch=dev)](https://coveralls.io/github/vikin91/BibSpace?branch=dev)

## Installation ##
* See [INSTALL.md](INSTALL.md)

## Using BibSpace with Docker ##

BibSpace has no official docker image on dockerhub (yet), thus you need to build it manually. However, an image with prerequisites exists to ease the process of building. Here are the commands to build BibSpace using docker.

```
# build BibSpace image
docker-compose build
# run it with docker-compose
docker-compose up -d
# thats it! Point you browser to http://localhost:8083/ to open BibSpace
# you may stop the container with
docker-compose down
```

Your MySQL data is stored in `db_data`, whereas preferences and stats in `json_data`.

## Updating

### From Version <=0.5.2 to 0.6.x

Update first to version 0.5.3.
Then backup your data to JSON format and make sure that data can be restored correctly.
Next, update to version 0.6.0 and restore data from the JSON backup.

## TODOs ##
BibSpace is currently undergoing serious refactoring.
Feel free to post an issue if you have a question or want to report a bug.
