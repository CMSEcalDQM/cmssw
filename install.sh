#!/bin/bash

function diff-cp()
{
    local SUBDIR=$1
    local SOURCE=$2
    local DEST=$3
    local FLAG=$4

    local FILES=""

    for OBJ in $(ls $SOURCE/$SUBDIR); do
        [[ $OBJ =~ \.pyc$ || $OBJ =~ ~$ || $OBJ = "__init__.py" ]] && continue

        if [ -d $SOURCE/$SUBDIR/$OBJ ]; then
            FILES=$FILES$(diff-cp $OBJ $SOURCE/$SUBDIR $DEST/$SUBDIR $FLAG)
        elif ! (diff $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$OBJ > /dev/null 2>&1); then
            if [ "$FLAG" = "-t" ]; then
                FILES=$FILES$'\n'$SOURCE/$SUBDIR/$OBJ
            elif [ "$FLAG" = "-f" ]; then
                cp $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$OBJ
                FILES=$FILES$'\n'$SOURCE/$SUBDIR/$OBJ
            else
                echo "copy $SOURCE/$SUBDIR/$OBJ ? y/d/N:"
                while read RESPONSE; do
                    case $RESPONSE in
                        y)
                            cp $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$OBJ
                            FILES=$FILES$'\n'$SOURCE/$SUBDIR/$OBJ
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
        fi
    done

    echo "$FILES"
}

REVERSE=false
TEST=false

while [ $# -gt 0 ]; do
    case $1 in
        -R)
            REVERSE=true
            shift
            ;;
        -t)
            TEST=true
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

FILES=""
for DIR in $DIRS; do
    if $TEST; then
        FLAG="-t"
    fi
    if $REVERSE; then
        FILES=$FILES$(diff-cp $DIR $CMSSW_BASE/src $INSTALLDIR $FLAG)
    else
        if $TEST; then
            FLAG="-t"
        else
            FLAG="-f"
        fi
        FILES=$FILES$(diff-cp $DIR $INSTALLDIR $CMSSW_BASE/src $FLAG)
    fi
done

echo "install: $FILES"