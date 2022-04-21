#!/bin/sh

get_devkit_type()
{
    # Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
    # Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
    # Altera SOCFPGA Arria 10 ==> Arria10
    # SoCFPGA Stratix 10 SoCDK ==> 10SoCDK
    # SoCFPGA Agilex SoCDK ==> Agilex SoCDK
    cat /proc/device-tree/model | sed 's/Altera //' | cut -d ' ' -f 2-3 | tr -d ' '
}

LCD_DEVNODE=ttyLCD0
SLEEP_TIME=
SYS_DEVICES_SOC=

machine_type="$(get_devkit_type)"
echo "machine_type = $machine_type"

if [ "$machine_type" == 'Stratix10' ] || [ "$machine_type" == 'AgilexSoCDK' ] || [ "$machine_type" == 'Arria10' ]; then
        echo "LCD test is only  applicable for Cyclone5"
        exit 1
fi
cd /sys/devices
for foo in 'soc.0' 'soc' 'platform/soc'; do
    if [ -e "$foo" ]; then    
        SYS_DEVICES_SOC=$PWD/$foo
        break
    fi
done
echo $SYS_DEVICES_SOC
if [ -z "$SYS_DEVICES_SOC" ]; then
    echo "Error, did not find normal sysfs paths"
    exit 1
fi
cd /
LCD_DEVICE="$(find $SYS_DEVICES_SOC -name '0-0028')"
if [ -z "$LCD_DEVICE" ]; then
    echo "Error, did not find 0-0028 under $SYS_DEVICES_SOC"
    exit 1
fi

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
    SYS_LCD_BRIGHTNESS=${LCD_DEVICE}/brightness
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

# get boot messages minus the '[    0.229804]'-style timestamp
lcd_dmesg="$(dmesg | grep lcd | sed -r 's,\[[ 0-9.]*\] ,,')"
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
