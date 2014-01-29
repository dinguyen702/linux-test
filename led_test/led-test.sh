#!/bin/bash

SLEEP_TIME=1
SYS_LEDS=/sys/class/leds/

usage()
{
    cat <<EOF
Test will blink some leds.

Usage: $(basename $0) [-h]

EOF
}

delay_for_user()
{
    if [ -n "$SLEEP_TIME" ]; then
	sleep $SLEEP_TIME
    else
	read line
    fi
}

# Param 1 = led # (0, 1, 2, 3)
# Param 2 = 0 for off; 1 for on
set_brightness()
{
    echo "setting led $1 to $2"
    led_brightness=/sys/class/leds/hps_led${1}/brightness
    echo $2 > $led_brightness
    bright="$(cat $led_brightness)"
    if [ "$2" != "$bright" ]; then
	echo "ERROR : brightness read back != brightness set"
    fi
}

#=============================================================

while [ -n "$1" ]; do
    case $1 in
	-h|--help ) usage ; exit ;;
	* ) echo "unknown parameter: $1" ; echo ; usage ; exit ;;
    esac
    shift
done

#=============================================================
for led in 0 1 2 3; do
    set_brightness $led 0
done
for onoff in 1 0 1; do
    for led in 0 1 2 3; do
	set_brightness $led $onoff
        delay_for_user
    done
done

echo "Done!"
