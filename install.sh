#!/bin/bash

if [ -z "$CMSSW_BASE" ]; then
    echo "CMSSW_BASE not set"
    return 1
fi

DIRS=""
for MAJOR in $(ls $PWD); do
    for MINOR in $(ls $PWD/$MAJOR); do
        DIRS=$DIRS"$MAJOR/$MINOR "
    done
done

for DIR in $DIRS; do
    if [ ! -d $CMSSW_BASE/src/$DIR ]; then
        echo "$CMSSW_BASE/src/$DIR does not exist. Check out the package with git-cms-addpkg first."
        return 1
    fi
done

for DIR in $DIRS; do
    echo $DIR
    rm -rf $CMSSW_BASE/src/$DIR/*
    cp -r $PWD/$DIR/* $CMSSW_BASE/src/$DIR/
done
