#!/bin/bash

cat out3a.txt | while read line; do 
    arr=(${line// / })
    id=${arr[0]}
    url=${arr[1]}

    echo $id
    echo $url

    wget --no-check-certificate $url -O paper-$id.pdf
done