#!/bin/bash

echo `date`
STATUS=`/home/piotr/perl/publiste3/util/test_server_alive.sh`
STATUS_OK=`/home/piotr/perl/publiste3/util/test_server_OK.sh`

if [ $STATUS -ne 200 ]; then
	echo "Killing Hypnotoad, status was 404 or 500"
	#/home/piotr/perl/publiste3/kill_hypnotoad.sh
	pkill -9 -f /home/piotr/perl/git_publiste/script/hex64-publications
	/usr/bin/hypnotoad /home/piotr/perl/publiste3/script/hex64-publications
fi
echo "Server status (alive) was: $STATUS" 
echo "Testing status (OK)." 

if [ $STATUS_OK -ne 200 ]; then
    echo "Killing Hypnotoad, status was 404 or 500"
    #/home/piotr/perl/publiste3/kill_hypnotoad.sh
    pkill -9 -f /home/piotr/perl/git_publiste/script/hex64-publications
    /usr/bin/hypnotoad /home/piotr/perl/publiste3/script/hex64-publications
fi
echo "Server STATUS_OK was: $STATUS_OK" 