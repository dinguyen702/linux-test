#!/bin/sh

usage()
{
    cat <<EOF
Test will:
 1. export the gpios for the buttons
 2. enable the interrupts (either rising edge, falling edge or both
    depending on the button).
 3. display the interrupt counts from /proc/interrupt once a second
    while tester hits the buttons.

Usage: $(basename $0) [-h]

EOF
}

setedge()
{
    # Some boards have < 4 buttons
    if [ -z "$2" ]; then
	return
    fi
    echo $1 > /sys/class/gpio/gpio${2}/edge
    if [ "$1" != "$(cat /sys/class/gpio/gpio${2}/edge)" ]; then
        echo "FAIL could not set gpio interrupt edge $1 for gpio $2"
        exit
    fi
}

get_devkit_type()
{
    # SoCFPGA Stratix 10 SoCDK
    grep -sq 'Stratix 10 SoCDK' /proc/device-tree/model
    if [ $? -eq 0 ]; then
	echo 'Stratix10'
	return
    fi
    
    # Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
    # Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
    cat /proc/device-tree/model | cut -d ' ' -f 3-4 | tr -d ' '
}

export_gpio()
{
    if [ ! -d /sys/class/gpio/gpio${1} ]; then
        echo $1 > /sys/class/gpio/export
    fi
    if [ ! -d /sys/class/gpio/gpio${1} ]; then
        echo "FAIL: did not export gpio $1"
        exit
    fi
}

#---------------------------------------------------------------------
while [ -n "$1" ]; do
    case $1 in
	-h|--help ) usage ; exit ;;
	* ) echo "unknown parameter: $1" ; echo ; usage ; exit ;;
    esac
    shift
done

devkit="$(get_devkit_type)"

# Assuming max of 512 gpios.  These numbers are adjusted below.
CYCONE5_BUTTONS="451 450 449 448"
ARRIA5_BUTTONS="468 467 466 460"
STRATIX10_BUTTONS="492 493"

case "${devkit}" in
    ArriaV ) BUTTON_GPIOS="$ARRIA5_BUTTONS" ;;
    CycloneV ) BUTTON_GPIOS="$CYCONE5_BUTTONS" ;;
    Stratix10 ) BUTTON_GPIOS="$STRATIX10_BUTTONS" ;;
    Arria10 ) echo "$devkit not supported for this test (no buttons)"; exit 1;;
    * ) echo "unable to identify board ($devkit). exiting." ; exit 1 ;;
esac

# For the oldest branches gpios are numbered starting at (256 - ngpio)
# 3.18 has commit "gpio: Increase ARCH_NR_GPIOs to 512", so (512 - ngpio)
# 4.13 ==> (2048 - ngpio)
cd /sys/class/gpio
top_gpiochip="$(ls -d -1 gpiochip* | tail -1 | sed 's/gpiochip//')"
gpio_offset=0
if [ -z "$top_gpiochip" ]; then
    echo "Error - could not find /sys/class/gpio/gpiochip*"
    exit 1
elif [ $top_gpiochip -lt 256 ]; then
    # Assuming max of 256 gpios, subtract 256 from gpio numbers
    gpio_offset=-256
elif [ $top_gpiochip -gt 1024 ]; then
    # Assuming max of 2048 gpios, add (2048 - 512)
    gpio_offset=1536
fi

temp_gpios="$BUTTON_GPIOS"
BUTTON_GPIOS=
for foo in $temp_gpios; do
    let gpio=foo+gpio_offset
    if [ -z "$BUTTON_GPIOS" ]; then
	BUTTON_GPIOS=$gpio
    else
	BUTTON_GPIOS="$BUTTON_GPIOS $gpio"
    fi
done
echo "$BUTTON_GPIOS"

for foo in $BUTTON_GPIOS; do
    export_gpio $foo
done
echo

echo "Setting interrupt edge for each button gpio:"
gpio1="$(echo $BUTTON_GPIOS | cut -d' ' -f1)"
gpio2="$(echo $BUTTON_GPIOS | cut -d' ' -f2)"
gpio3="$(echo $BUTTON_GPIOS | cut -d' ' -f3)"
gpio4="$(echo $BUTTON_GPIOS | cut -d' ' -f4)"
setedge both $gpio1
setedge rising $gpio2
setedge falling $gpio3
setedge falling $gpio4

for foo in $BUTTON_GPIOS; do
    echo "$foo : $(cat /sys/class/gpio/gpio${foo}/edge)"
done

echo "for the last part of the test, script will print out interrupt"
echo "counts for gpios once a second.  Hit gpio buttons and watch the"
echo "counts change"
echo
echo "Hit Enter key to start..."
read line
clear

while true; do
    echo "Hit ctrl-c when done."
    echo
    head -n1 /proc/interrupts
    grep gpio /proc/interrupts
    echo
    sleep 1
    clear
done

