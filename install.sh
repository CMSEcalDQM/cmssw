#!/bin/bash

function diff-cp()
{
    local SUBDIR=$1
    local SOURCE=$2
    local DEST=$3
    local FORCE=$4

    local COPIED=""

    for OBJ in $(ls $SOURCE/$SUBDIR); do
        [[ $OBJ =~ \.pyc$ || $OBJ =~ ~$ || $OBJ = "__init__.py" ]] && continue

        if [ -d $SOURCE/$SUBDIR/$OBJ ]; then
            COPIED=$COPIED$(diff-cp $OBJ $SOURCE/$SUBDIR $DEST/$SUBDIR $FORCE)
        elif ! (diff $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$OBJ > /dev/null 2>&1); then
            if [ "$FORCE" != "-f" ]; then
                echo "copy $SOURCE/$SUBDIR/$OBJ ? y/d/N:"
                while read RESPONSE; do
                    case $RESPONSE in
                        y)
                            cp $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$OBJ
                            COPIED=$COPIED$'\n'$SOURCE/$SUBDIR/$OBJ
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
            else
                cp $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$OBJ
                COPIED=$COPIED$'\n'$SOURCE/$SUBDIR/$OBJ
            fi
        fi
    done

    echo "$COPIED"
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

COPIED=""
for DIR in $DIRS; do
    if $REVERSE; then
        COPIED=$COPIED$(diff-cp $DIR $CMSSW_BASE/src $INSTALLDIR)
    else
        COPIED=$COPIED$(diff-cp $DIR $CMSSW_BASE/src $INSTALLDIR -f)
    fi
done

echo "Copied: $COPIED"