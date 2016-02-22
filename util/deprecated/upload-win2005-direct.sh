#!/bin/bash

SRV=piotr@win2005
DIR=/home/piotr/perl/publiste3


# mega slow!
# scp -r ./* $SRV:$DIR/

# rsync -rav --exclude 'bib.db' ./* $SRV:$DIR/


# only code!!
rsync -rav ./lib/ $SRV:$DIR/lib/

# WOW!!
# rsync -rav --exclude '*.db' --exclude 'backups/*' --exclude 'log/*' --exclude 'public/uploads/*' ./* $SRV:$DIR/
#rsync -rav ./* $SRV:$DIR/