#!/bin/bash

STATUS=`/home/piotr/perl/publiste3/util/test_server_alive.sh`
STATUS_OK=`/home/piotr/perl/publiste3/util/test_server_OK.sh`

RESTART=false
if [ $STATUS -gt 399 ]; then
        RESTART=true
fi
if [ $STATUS_OK -gt 399 ]; then
    RESTART=true
fi

if [ "$RESTART" = true ]; then
    pkill -9 -f /home/piotr/perl/git_bibspace/bin/bibspace
    export BIBSPACE_CONFIG=/home/piotr/perl/publiste3/lib/BibSpace/files/config/production.conf
    /usr/bin/hypnotoad /home/piotr/perl/git_bibspace/bin/bibspace
fi

_timestamp=`date`
echo "$_timestamp Status RUNNING/FUNCTIONING was: $STATUS / $STATUS_OK"