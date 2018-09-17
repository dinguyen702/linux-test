#!/bin/bash

get_devkit_type()
{
    # SoCFPGA Stratix 10 SoCDK
    cat /proc/device-tree/model | cut -d ' ' -f 2-3 | tr -d ' '
}

get_ram_size()
{
   cat /proc/meminfo | grep MemTotal |awk '{ print $2 }'
}

ram_test()
{
   local err=0
case "$(get_devkit_type)" in
    Stratix10) ramsize=$STRATIX_DEVKIT ;;
    Stratix20) ramsize=$STRATIX_DEVKIT ;;
    * ) echo "unable to identify board(test applicable to arm64 only). exiting." ; exit 1 ;;
esac
   machine_type="$(get_devkit_type)"
   echo "machine_type = $machine_type"
   echo "RAM size = $DEVKIT_RAM_SIZE"

   if [ "$machine_type" == 'Stratix10' ] || [ "$machine_type" == 'Stratix20' ]; then
        if [ "$DEVKIT_RAM_SIZE" -lt "$ramsize" ]; then
             echo "RAM SIZE is less than 2GB"
             err=1
        fi
   fi
   return ${err}
}

STRATIX_DEVKIT=1048576
#===========================================================
echo "RAM size test"
echo

DEVKIT_RAM_SIZE="$(get_ram_size)"

ram_test

if [ $? -ne 0 ] ; then
    echo "FAIL"
else
    echo "PASS"
fi

exit 0
