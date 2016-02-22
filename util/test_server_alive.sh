#!/bin/bash

response=$(curl --write-out %{http_code} --silent --output /dev/null http://se2.informatik.uni-wuerzburg.de/pa/ly/p?team=SE-WUERZBURG)
echo $response
