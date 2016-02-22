#!/bin/bash

echo "Was: "
ps aux | grep "script/hex64-publications"
echo "killing hypnotoad with pkill"
echo "callink pkill"
pkill -9 -f /home/piotr/perl/git_publiste/script/hex64-publications
echo "Waiting few seconds for hypnotoad to be dead"
sleep 5
echo "Killing done. Verificartion: "
ps aux | grep "script/hex64-publications"
echo "waiting again"
sleep 5
echo "Starting Hypnotoad"
/usr/bin/hypnotoad /home/piotr/perl/publiste3/script/hex64-publications
echo "Done. Verificartion: "
ps aux | grep "script/hex64-publications"
