#!/bin/bash

STRING=""
NUM_GEN_ERRORS=1

usage()
{
    cat <<EOF
Test will introduce an single bit error or double bit error in the 
SDRAM. A single bit error is correctable and will print a warning
message. A double bit error is uncorrectable and will cause a 
kernel panic.
   
   To use this test, the kernel must be compiled with EDAC support
   and EDAC debug.
   Device Drivers -> EDAC (Error Detection & Correction) reporting
      - EDAC legacy sysfs
      - Debugging
      - Main Memory EDAC
      - Altera SDRAM Memory Controller EDAC

This script calls "/sys/kernel/debug/edac/mc0/inject_ctrl" with
the following command for single bit errors:
   echo "1" > /sys/kernel/debug/edac/mc0/inject_ctrl
or the following command for double bit errors:
   echo "12" > /sys/kernel/debug/edac/mc0/inject_ctrl
   
Usage: $(basename $0) [-h][-e <# of errors> [ 1 | 2 ]

i.e.:
 $  $(basename $0) -h
  This usage message

 $  $(basename $0) -e 1
  Cause a single bit error.
  Output:
  EDAC MC0: 2 CE on sdramedac.5 on mc#0csrow#0channel#0 (csrow:0 channel:0 
     page:<pageaddr> offset:<offsetaddr> grain:8 syndrome:0x0)

 $  $(basename $0) -e 2
  Cause a double bit error.
  Output:
  Kernel panic - not syncing:
  EDAC: (2 Uncorrectable errors @ <error address>
  <kernel dump goes here>

EOF
}


while [ -n "$1" ]; do
    case $1 in
	-h|--help ) usage ; exit ;;
	-e ) NUM_GEN_ERRORS=$2 ; shift ;;
	* ) echo "unknown parameter: $1" ; echo ; usage ; exit ;;
    esac
    shift
done

if [ -n "$NUM_GEN_ERRORS" ]; then
    echo "Perform this test by generating $NUM_GEN_ERRORS errors."
else
    echo "Number of errors was not specified."
    echo
    exit;
fi

#=============================================================
# Set to an insanely high iteration number if 0
if [ "$NUM_GEN_ERRORS" -eq 2 ]; then
	STRING="12"
else
	STRING="1"
fi

echo $STRING > /sys/kernel/debug/edac/mc0/inject_ctrl
echo

echo "Done!"
echo
