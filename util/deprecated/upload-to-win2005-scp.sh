#!/bin/bash

SRV=root@win2005
DIR=/home/piotr/perl/publiste2


scp -r $(find . -name '*' ! -path "./.git*" ! -path "./tmp*" ! -path "./.svn*" ! -name '*.db' ! -path "./backups*" ! -path "./log/*") $SRV:$DIR/

# mega slow!
# scp -r ./* $SRV:$DIR/

# rsync -rav --exclude 'bib.db' ./* $SRV:$DIR/

# WOW!!
# rsync -rav --exclude '*.db' --exclude 'backups/*' --exclude 'log/my.log' ./* $SRV:$DIR/
#rsync -rav ./* $SRV:$DIR/