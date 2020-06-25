#!/bin/bash


N=`node search-go.js | jq length`

if [ "$N" != "55" ]; then
    echo "Bad"
    exit 1
fi

M=`node search-go-big.js | jq length`

if [ "$M" != "1039" ]; then
    echo "Big Bad saw $M"
    exit 1
fi
