#!/bin/bash

SRV=root@win2005
DIR=/home/piotr/perl/publiste2


# mega slow!
# scp -r ./* $SRV:$DIR/

# rsync -rav --exclude 'bib.db' ./* $SRV:$DIR/

# WOW!!
rsync -rav  ./*.db $SRV:$DIR/
#rsync -rav ./* $SRV:$DIR/