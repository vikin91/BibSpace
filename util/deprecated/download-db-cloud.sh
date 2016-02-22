#!/bin/bash

SRV=piotr@146.185.144.116
DIR=/home/piotr/perl/publiste2


# mega slow!
# scp -r ./* $SRV:$DIR/

# rsync -rav --exclude 'bib.db' ./* $SRV:$DIR/

# WOW!!
rsync -rav  $SRV:$DIR/*.db .
#rsync -rav ./* $SRV:$DIR/