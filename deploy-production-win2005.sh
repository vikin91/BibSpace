#!/bin/bash

# win2005 = 132.187.10.5

SRV=piotr@132.187.10.5
DIR=/home/piotr/perl/publiste3


# WOW!!
rsync -rav --exclude 'bib.db' --exclude 'backup.db' --exclude 'backups/*' --exclude 'log/*' --exclude 'public/uploads/*' ./* $SRV:$DIR/ 
# rsync -rav --exclude 'backups/*' --exclude 'log/*' --exclude 'public/uploads/*' ./* $SRV:$DIR/
