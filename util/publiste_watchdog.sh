#!/bin/bash

STATUS=`/home/piotr/perl/publiste3/util/test_server_alive.sh`
STATUS_OK=`/home/piotr/perl/publiste3/util/test_server_OK.sh`

RESTART=false

if [ $STATUS -ne 200 ]; then
	$RESTART=true
fi
if [ $STATUS_OK -ne 200 ]; then
    $RESTART=true
fi

if [ "$RESTART" = true ]; then
    pkill -9 -f /home/piotr/perl/git_publiste/script/hex64-publications
    /usr/bin/hypnotoad /home/piotr/perl/publiste3/script/hex64-publications
fi

_timestamp=`date`
echo "$_timestamp Status RUNNING/FUNCTIONING was: $STATUS / $STATUS_OK" 
