#!/bin/bash
DIR="/home/piotr/perl/bibspace"

echo "Currnet status: "
ps aux | grep "bin/bibspace"
echo "killing hypnotoad with pkill"
echo "callink pkill"
pkill -9 -f "$DIR/bin/bibspace"
echo "Waiting few seconds for hypnotoad to be dead"
sleep 5
echo "Killing done. Verification: "
ps aux | grep "bin/bibspace"
echo "waiting again"
sleep 5
echo "Starting Hypnotoad"
export BIBSPACE_CONFIG=/etc/bibspace.conf
/usr/bin/hypnotoad "$DIR/bin/bibspace"
echo "Done. Verification: "
ps aux | grep "bin/bibspace"
