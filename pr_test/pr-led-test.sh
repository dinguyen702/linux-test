#!/bin/bash

SLEEP_TIME=1
SYS_LEDS=/sys/class/leds/
LEDS="$(ls $SYS_LEDS)"

usage()
{
    cat <<EOF
Test will find all leds under $SYS_LEDS and blink them.

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

# Param 1 = led ; Param 2 = 1 for on, 0 for off
set_brightness()
{
    echo "setting led $1 to $2"
    led_brightness=/sys/class/leds/${1}/brightness
    echo $2 > $led_brightness
    bright="$(cat $led_brightness)"
    if [ "$2" != "$bright" ]; then
	echo "ERROR : brightness read back != brightness set"
    fi
}

set_leds()
{
    led_pattern=$1
    for led in $LEDS; do
	let val=$(( $led_pattern & 1 ))
	set_brightness $led $val
	let led_pattern=led_pattern/2
    done
}

#====================================================================

while [ -n "$1" ]; do
    case $1 in
	-h|--help ) usage ; exit ;;
	* ) echo "unknown parameter: $1" ; echo ; usage ; exit ;;
    esac
    shift
done

for pattern in 1 3 1 3 3 15; do
    set_leds $pattern
    delay_for_user
done

echo "Done!"
