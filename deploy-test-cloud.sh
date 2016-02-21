#!/bin/bash

SRV=piotr@hex64.com
DIR=/home/piotr/perl/publiste3


# WOW!!
rsync -rav --exclude 'bib.db' --exclude 'backup.db' --exclude 'backups/*' --exclude 'log/*' --exclude 'public/uploads/*' ./* $SRV:$DIR/ 
# rsync -rav --exclude 'backups/*' --exclude 'log/*' --exclude 'public/uploads/*' ./* $SRV:$DIR/
