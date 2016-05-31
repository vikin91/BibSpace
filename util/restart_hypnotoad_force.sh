#!/bin/bash

echo "Was: "
ps aux | grep "bin/bibspace"
echo "killing hypnotoad with pkill"
echo "callink pkill"
pkill -9 -f /home/piotr/perl/git_bibspace/bin/bibspace
echo "Waiting few seconds for hypnotoad to be dead"
sleep 5
echo "Killing done. Verificartion: "
ps aux | grep "bin/bibspace"
echo "waiting again"
sleep 5
echo "Starting Hypnotoad"
/usr/bin/hypnotoad /home/piotr/perl/publiste3/bin/bibspace
echo "Done. Verificartion: "
ps aux | grep "bin/bibspace"
