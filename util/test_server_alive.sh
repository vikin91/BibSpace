#!/bin/bash

response=$(curl --write-out %{http_code} --silent -k --output /dev/null https://se2.informatik.uni-wuerzburg.de/pa/ly/p?team=SE-WUERZBURG)
echo $response
