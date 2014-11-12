#!/bin/bash

function synchdir()
{
    local SUBDIR=$1
    local SOURCE=$2
    local DEST=$3
    local FLAG=$4

    local VERSIONED=
    for OBJ in $(ls $SOURCE/$SUBDIR); do
        [[ $OBJ =~ \.pyc$ || $OBJ =~ ~$ || $OBJ = "__init__.py" ]] && continue
        [ -f $SOURCE/$SUBDIR/$OBJ ] || continue
        [[ $OBJ =~ \.CMSSW_[0-9]+_[0-9]+_X$ ]] || continue
        SERIES=$(sed 's/.*[.]\(CMSSW_[0-9]*_[0-9]*_\)X$/\1/' <<< $OBJ)
        [[ $CMSSW_VERSION =~ $SERIES ]] || continue
        FILENAME=$(sed 's/\(.*\)[.]CMSSW_[0-9]*_[0-9]*_X$/\1/' <<< $OBJ)
        VERSIONED="$VERSIONED $SOURCE/$SUBDIR/$FILENAME"
    done                

    for OBJ in $(ls $SOURCE/$SUBDIR); do
        [[ $OBJ =~ \.pyc$ || $OBJ =~ ~$ || $OBJ = "__init__.py" ]] && continue

        if [ -d $SOURCE/$SUBDIR/$OBJ ]; then
            synchdir $OBJ $SOURCE/$SUBDIR $DEST/$SUBDIR $FLAG
        else
            [[ $OBJ =~ \.CMSSW_[0-9]+_[0-9]+_X$ ]] && continue
            
            FILENAME=$OBJ
            if (echo $VERSIONED | grep $SOURCE/$SUBDIR/$FILENAME > /dev/null); then
                OBJ=$FILENAME.$(sed 's/^\(CMSSW_[0-9]*_[0-9]*_\).*/\1X/' <<< $CMSSW_VERSION)
            fi
            
            diff $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$FILENAME > /dev/null 2>&1 && continue
            
            if [ "$FLAG" = "-t" ]; then
                FILES=$FILES$'\n'"diff $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$FILENAME"
            elif [ "$FLAG" = "-f" ]; then
                cp $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$FILENAME
                FILES=$FILES$'\n'"cp $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$FILENAME"
            else
                echo "copy $SOURCE/$SUBDIR/$OBJ ? y/d/N:"
                while read RESPONSE; do
                    case $RESPONSE in
                        y)
                            cp $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$FILENAME
                            FILES=$FILES$'\n'"cp $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$FILENAME"
                            break
                            ;;
                        d)
                            diff $SOURCE/$SUBDIR/$OBJ $DEST/$SUBDIR/$FILENAME
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

    for OBJ in $(ls $DEST/$SUBDIR); do
        [[ $OBJ =~ \.pyc$ || $OBJ =~ ~$ || $OBJ = "__init__.py" || $OBJ =~ \.CMSSW_[0-9]+_[0-9]+_X$ ]] && continue

        [ -e $SOURCE/$SUBDIR/$OBJ ] && continue

        if [ "$FLAG" = "-t" ]; then
            FILES=$FILES$'\n'"rm $DEST/$SUBDIR/$OBJ"
        elif [ "$FLAG" = "-f" ]; then
            rm -rf $DEST/$SUBDIR/$OBJ
            FILES=$FILES$'\n'"rm $DEST/$SUBDIR/$OBJ"
        else
            echo "remove $DEST/$SUBDIR/$OBJ ? y/N:"
            while read RESPONSE; do
                case $RESPONSE in
                    y)
                        rm $DEST/$SUBDIR/$OBJ
                        FILES=$FILES$'\n'"rm $DEST/$SUBDIR/$OBJ"
                        break
                        ;;
                    N)
                        break
                        ;;
                    *)
                        echo "Answer in y/N."
                        ;;
                esac
            done
        fi
    done
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
        synchdir $DIR $CMSSW_BASE/src $INSTALLDIR $FLAG
    else
        if $TEST; then
            FLAG="-t"
        else
            FLAG="-f"
        fi
        synchdir $DIR $INSTALLDIR $CMSSW_BASE/src $FLAG
    fi
done

echo "install: $FILES"

