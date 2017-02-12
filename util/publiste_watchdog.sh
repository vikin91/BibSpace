#!/bin/bash
DIR="/home/piotr/perl/bibspace"

STATUS=`$DIR/util/test_server_alive.sh`
STATUS_OK=`$DIR/util/test_server_OK.sh`

RESTART=false
if [ $STATUS -gt 399 -o $STATUS -eq 0 ]; then
        RESTART=true
fi
if [ $STATUS_OK -gt 399 -o $STATUS_OK -eq 0 ]; then
    RESTART=true
fi

if [ "$RESTART" = true ]; then
    pkill -9 -f "$DIR/bin/bibspace"
    export BIBSPACE_CONFIG=/etc/bibspace.conf
    /usr/bin/hypnotoad "$DIR/bin/bibspace"
fi

_timestamp=`date`
echo "$_timestamp Status RUNNING/FUNCTIONING was: $STATUS / $STATUS_OK"
