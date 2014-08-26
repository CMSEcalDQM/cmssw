#!/bin/bash

if [ -z "$CMSSW_BASE" ]; then
    echo "CMSSW_BASE not set"
    exit 1
fi

INSTALLDIR=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

DIRS=""
for MAJOR in $(ls $INSTALLDIR); do
    [ $MAJOR = "README.md" -o $MAJOR = "install.sh" ] && continue
    for MINOR in $(ls $INSTALLDIR/$MAJOR); do
        DIRS=$DIRS"$MAJOR/$MINOR "
    done
done

for DIR in $DIRS; do
    if [ ! -d $CMSSW_BASE/src/$DIR ]; then
        echo "$CMSSW_BASE/src/$DIR does not exist. Check out the package with git-cms-addpkg first."
        exit 1
    fi
done

for DIR in $DIRS; do
    echo $DIR
    rm -rf $CMSSW_BASE/src/$DIR/*
    cp -r $INSTALLDIR/$DIR/* $CMSSW_BASE/src/$DIR/
done
