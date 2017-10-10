#!/bin/sh

kver="$(uname -r | cut -c1-4)"

case $kver in
    3.10|3.11|3.12|3.13|3.14|3.15|3.16|3.17 )
    CYCONE5_BUTTONS="195 194 193 192"
    ARRIA5_BUTTONS="212 211 210 204"
    ;;

    # 3.18 has commit "gpio: Increase ARCH_NR_GPIOs to 512"
    # commit 7ca267faba8ad097f57cb71c32ae1865de83241a
    * )
    CYCONE5_BUTTONS="451 450 449 448"
    ARRIA5_BUTTONS="468 467 466 460"
    STRATIX10_BUTTONS="492 493"
    ;;
esac

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

case "$(get_devkit_type)" in
    ArriaV ) BUTTON_GPIOS="$ARRIA5_BUTTONS" ;;
    CycloneV ) BUTTON_GPIOS="$CYCONE5_BUTTONS" ;;
    Stratix10 ) BUTTON_GPIOS="$STRATIX10_BUTTONS" ;;
    * ) echo "unable to identify board. exiting." ; exit 1 ;;
esac

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

