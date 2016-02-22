#!/bin/bash

SRV=pir14hw@info2-ssh.informatik.uni-wuerzburg.de
DIR=/HOME/pir14hw/perl/publiste2


FILES=`find . -name '*' ! -path "./.git*" ! -path "./tmp*" ! -path "./.svn*" ! -name '*.db' ! -path "./backups*" ! -path "./public/uploads*" ! -path "./log/*"`
#echo $FILES

# for F in $FILES 
# do
#     #echo "$F $DIR/$F"
#     scp $F $SRV:$DIR/$F
# done


# mega slow!
# scp $FILES $SRV:$DIR/


# WOW!!
rsync -rav --exclude '*.db' --exclude 'backups/*' --exclude 'log/*' --exclude 'public/uploads/*' ./* $SRV:$DIR/
