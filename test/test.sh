#!/bin/bash


N=`node search-go.js | jq length`

if [ "$N" != "338" ]; then
    echo "Bad search-go.js, want $N"
    exit 1
fi

M=`node search-go-big.js | jq length`

if [ "$M" != "3042" ]; then
    echo "Bad search-go-big.js, want $M"
    exit 1
fi

O=`node search-nested-go.js | jq length`

if [ "$O" != "396" ]; then
    echo "Bad search-nested-go.js, want $O"
    exit 1
fi




