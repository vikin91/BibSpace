# README #

BibSpace is an Online Bibtex Publications Management Software for Authors and Research Groups. Read about its features on the [BibSpace @ the Error Blog](https://blog.hex64.com/bibspace-online-bibtex-publications-management-software-for-authors-and-research-groups/).

## Build status ##

Branch | Status | Test coverage
--- | --- | ---
*master* | [![Build Status](https://travis-ci.org/vikin91/BibSpace.svg?branch=master)](https://travis-ci.org/vikin91/BibSpace) | [![Coverage Status](https://coveralls.io/repos/github/vikin91/BibSpace/badge.svg?branch=master)](https://coveralls.io/github/vikin91/BibSpace?branch=master)
*dev* | [![Build Status](https://travis-ci.org/vikin91/BibSpace.svg?branch=dev)](https://travis-ci.org/vikin91/BibSpace) | [![Coverage Status](https://coveralls.io/repos/github/vikin91/BibSpace/badge.svg?branch=dev)](https://coveralls.io/github/vikin91/BibSpace?branch=dev)

## Demo ##

Visit [hex64.com](http://www.hex64.com/) and click backend/frontend demo to have a quick overview of the running system. 

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

## TODOs ##
BibSpace is currently undergoing serious refactoring. I try to keep current status up to date in [BibSpace Trelo Board](https://trello.com/b/yQ2VPiQ3/bibspace)

Goals of the ongoing refactoring:
- [x] provide clean MVC without SQL in the controller
- [x] Apply Perl Object-Oriented code design 
- [~] Improve code orthogonality
- [~] Remove code duplication
- [~] Simplify templates thanks to OO
- [] Allow BibSpace to run without Smart* layer
- [] Provide BibSpace API and separate frontend and backend (Future)



### Handbook TODO ###
- [] Describe nginx and apache2 configuration
- [] Describe cron setup
- [] Describe HTML embedding

