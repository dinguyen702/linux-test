#!/bin/bash

LCD_DEVNODE=ttyLCD0
SLEEP_TIME=
SYS_LCD_BRIGHTNESS=/sys/devices/soc.0/ffc04000.i2c/i2c-0/0-0028/brightness

usage()
{
    cat <<EOF
Test will send text to the I2C LCD module.  At the same time, the serial console
will display messages showing what the LCD should be displaying.

Usage: $(basename $0) [-h][-d <delay in seconds>][-t devnode such as ttyLCD0]

i.e.:
 $  $(basename $0)
  Default is to wait for user to hit 'enter' after each LCD update.

 $  $(basename $0) -d 3
  Wait 3 seconds between LCD updates.

 $  $(basename $0) -t ttyLCD500
  Run this test on /dev/ttyLCD500.  Note that this tty currently probably does not exist!

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

display_looks_like()
{
    echo '================'
    echo "$1"
    echo "$2"
    echo '================'
    delay_for_user
}

set_brightness()
{
    echo $1 > $SYS_LCD_BRIGHTNESS
    bright="$(cat $SYS_LCD_BRIGHTNESS)"
    if [ "$1" != "$bright" ]; then
	echo "ERROR : brightness read back != brightness set"
    fi
}

#=============================================================

while [ -n "$1" ]; do
    case $1 in
	-h|--help ) usage ; exit ;;
	-d ) SLEEP_TIME=$2 ; shift ;;
	-t ) TTY_DEVNODE=$2 ; shift ;;
	* ) echo "unknown parameter: $1" ; echo ; usage ; exit ;;
    esac
    shift
done

if [ -n "$SLEEP_TIME" ]; then
    echo "Test will delay $SLEEP_TIME second(s) between test cases."
    echo
else
    echo "Test will pause for the user to hit the ENTER key between test cases."
    echo
fi

lcd_dmesg="$(dmesg | grep lcd)"
if [ "$lcd_dmesg" != 'lcd-comm 0-0028: LCD driver initialized' ]; then
    echo "FAIL got unexpected boot up message"
    echo "$lcd_dmesg"
    exit 1
fi

#=============================================================
# Clear display
printf '\e[2J' > /dev/$LCD_DEVNODE
display_looks_like '' ''

printf '\ntilda: \x7e' > /dev/$LCD_DEVNODE
printf '\nbackslash: \x5c' > /dev/$LCD_DEVNODE
display_looks_like 'tilda: ~' 'backslash: \'

printf '\nThis is line # 1\nThis is line # 2' > /dev/$LCD_DEVNODE
display_looks_like 'This is line # 1' 'This is line # 2'

# Since cursor is at the end of line, all other text will overwrite
# the last character of this line.
printf '0' > /dev/$LCD_DEVNODE
display_looks_like 'This is line # 1' 'This is line # 0'

printf '\nWe scrolled' > /dev/$LCD_DEVNODE
display_looks_like 'This is line # 0' 'We scrolled'

printf ' up!' > /dev/$LCD_DEVNODE
display_looks_like 'This is line # 0' 'We scrolled up!'

printf '\nNow a new line!' > /dev/$LCD_DEVNODE
display_looks_like 'We scrolled up!' 'Now a new line!'

# Clear current line
printf '\e[2K' > /dev/$LCD_DEVNODE
display_looks_like 'We scrolled up!' ''

printf 'New! New!' > /dev/$LCD_DEVNODE
display_looks_like 'We scrolled up!' 'New! New!'

# Testing backspace.  This will reposition the cursor, but not
# change the display until we send more text.
printf '\b\b\b\b' > /dev/$LCD_DEVNODE
echo "Display will not appear changed, so it still has:"
display_looks_like 'We scrolled up!' 'New! New!'

set_brightness 4
echo "Display will look dimmer."
delay_for_user

set_brightness 8
echo "Display will look bright again."
delay_for_user

printf 'Improved!' > /dev/$LCD_DEVNODE
display_looks_like 'We scrolled up!' 'New! Improved!'

# Clear display
printf '\e[2J' > /dev/$LCD_DEVNODE
display_looks_like '' ''

echo "Done!"
