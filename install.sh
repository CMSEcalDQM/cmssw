#!/bin/bash

function diff-cp()
{
    local SUBDIR=$1
    local SOURCE=$2
    local DEST=$3

    for OBJ in $(ls $SOURCE/$SUBDIR); do
        [[ $OBJ =~ \.pyc$ || $OBJ =~ ~$ || $OBJ = "__init__.py" ]] && continue

        if [ -d $SOURCE/$SUBDIR/$OBJ ]; then
            diff-cp $OBJ $SOURCE/$SUBDIR $DEST/$SUBDIR
        elif ! (diff $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$OBJ > /dev/null 2>&1); then
            echo "copy $SOURCE/$SUBDIR/$OBJ ? y/d/N:"
            while read RESPONSE; do
                if [ "$RESPONSE" = "y" ]; then
                    cp $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$OBJ
                    break
                elif [ "$RESPONSE" = "d" ]; then
                    diff $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$OBJ
                    echo "y/d/N:"
                elif [ "$RESPONSE" = "N" ]; then
                    break
                else
                    echo "Answer in y/d/N."
                fi
            done
        fi
    done
}

REVERSE=false

while [ $# -gt 0 ]; do
    case $1 in
        -R)
            REVERSE=true
            shift
            ;;
        *)
            echo "Unrecognized option $1"
            shift
            ;;
    esac
done

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
    if $REVERSE; then
        diff-cp $DIR $CMSSW_BASE/src $INSTALLDIR
    else
        echo $DIR
        rm -rf $CMSSW_BASE/src/$DIR/*
        cp -r $INSTALLDIR/$DIR/* $CMSSW_BASE/src/$DIR/
    fi
done
