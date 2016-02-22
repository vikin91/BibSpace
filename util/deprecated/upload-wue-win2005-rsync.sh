#!/bin/bash

SRV=piotr@132.187.10.5
DIR=/home/piotr/perl/publiste2


# WOW!!
rsync -rav --exclude '*.db' --exclude 'backups/*' --exclude 'log/*' --exclude 'public/uploads/*' ./* $SRV:$DIR/
