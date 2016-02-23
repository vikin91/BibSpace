#!/bin/bash

#GIT_DIR="/home/piotr/perl/git_publiste/.git"
GIT_DIR="./.git"
revisioncount=`git --git-dir=$GIT_DIR log --oneline | wc -l | tr -d ' ' `
projectversion=`git describe --tags --long --always`
cleanversion=${projectversion%%-*}

echo "$projectversion-$revisioncount"
#echo "$cleanversion.$revisioncount"
