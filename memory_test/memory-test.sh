#!/bin/bash

usage()
{
    cat <<EOF
usage: $(basename $0) [--fast]

  --fast   : run a quick test, doesn't check all address lines

EOF
}

#========================================================================
if [ ! -f memtester ]; then
    echo "Could not find memtester.  Test blocked"
    exit 1
fi

while [ -n "$1" ]; do
    case $1 in
	--fast ) FAST=1 ;;
	-h|--help ) usage ; exit 1 ;;
	* ) echo "invalid parameter" ; echo ; usage ; exit 1 ;;
    esac
    shift
done

if [ "$FAST" == '1' ]; then
    MEMSIZE=64K
else
    MEMSIZE=550M
fi

echo "./memtester $MEMSIZE 1"
./memtester $MEMSIZE 1
ret=$?

echo "memtester exited with code $ret"

exit $ret
