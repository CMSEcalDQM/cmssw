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
                case $RESPONSE in
                    y)
                        cp $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$OBJ
                        break
                        ;;
                    d)
                        diff $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$OBJ
                        echo "y/d/N:"
                        ;;
                    N)
                        break
                        ;;
                    *)
                        echo "Answer in y/d/N."
                        ;;
                esac
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
        echo "$CMSSW_BASE/src/$DIR does not exist. Check out package? [y/N]"
        while read RESPONSE; do
            case $RESPONSE in
                y)
                    CWD=$PWD
                    cd $CMSSW_BASE/src
                    git cms-addpkg $DIR
                    cd $CWD
                    break
                    ;;
                N)
                    break
                    ;;
                *)
                    echo "Please answer in y/N."
                    ;;
            esac
        done
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
