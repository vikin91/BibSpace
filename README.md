# README

BibSpace is an Online Bibtex Publications Management Software for Authors and Research Groups.

## Archiving note

:warning: This repository is now archived and will be no longer maintained.

## Build Status

[![Build Status](https://travis-ci.org/vikin91/BibSpace.svg?branch=master)](https://travis-ci.org/vikin91/BibSpace) [![Coverage Status](https://coveralls.io/repos/github/vikin91/BibSpace/badge.svg?branch=master)](https://coveralls.io/github/vikin91/BibSpace?branch=master)

## Native Installation
* See [INSTALL.md](INSTALL.md)

## Using BibSpace with Docker

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

That's it! Point you browser to [http://localhost:8083/](http://localhost:8083/) to open BibSpace.

You may stop the container with

```
docker-compose down
```

The MySQL data is stored in `db_data`, whereas preferences and stats in `json_data`.

## Updating

### General update instructions

#### Any update of native installation (no Docker)

1. Make backup
2. Replace code with the code from a newer version:
  ```
  git clone --branch <version> https://github.com/vikin91/BibSpace.git
  ```
  Whereas `<version>` equals the name of a branch or release tag, for example: `v0.5.4`.

3. (Optional) Restore backup if any data got lost.

#### Any update of Docker  installation

1. Make backup
2. Stop Docker containers `docker-compose down`
3. Download `docker-compose.yml` file from Github
4. Change the image version of BibSpace in `docker-compose.yml`
  Locate the following part and remove the `build` part.
  ```
    bibspace:
    build:
      context: .
      dockerfile: Dockerfile
    depends_on:
      - db
  ```
  And add the `image` definition with respective version.
  For version `0.6.0` this will look as follows:
  ```
    bibspace:
    image: bibspace:0.6.0
    depends_on:
      - db
  ```
4. Run with `docker-compose up -d`
5. (Optional) Restore backup if any data got lost.

### Update instructions for particular versions

#### From Version `<=0.5.2` to `0.6.x`

1. *Important*: Update to version `0.5.3` or `0.5.4` first to enable JSON backups.
2. Backup your data to the *JSON format* and make sure that data can be restored correctly.
3. Replace code with version `0.6.0` and restore data from the JSON backup.

