#!/bin/sh

# Exit if a command fails.
set -e

SELF=$(basename $0)
DIRSELF="$(dirname $0)"
SEED_STRING="01234567891011121314151617181920212223242526272829303132333435"
TEMP_PATH="/tmp/uart_seed.data"
SEED_ITERATIONS=1000
TTY="ttyS0"

usage()
{
    cat <<EOF
Test the TX threshold capability of the Altera
enhanced 16550 Soft IP.
This test generates a seed file then prints this to the 
serial terminal.
The Serial IRQ count is captured before and after the
file is printed to the terminal. The file size divided
by the number of serial IRQ determines the bytes transmitted
per serial IRQ.
Compare the Bytes Per IRQ to the value set in the tx-threshold
device tree field of the Altera Soft IP UART node - they should
within 1 byte of each other (because of round-off errors, etc).

Usage: $(SELF) [-h] [-p TTY]

i.e.:
 $  $(SELF)
  Run the UART TX Threshold test on the default ${TTY} port

 $  $(SELF) -p ttyS1
  Run the UART TX Threshold test on ttyS1 port

 $  $(SELF) -h
  Print this message.

EOF
}

get_serial_irq_num()
{
	# Old kernels had "serial" while newer kernels have ttyS0
	cat /proc/interrupts | grep -e "serial" -e "ttyS0" | awk '{ print $2 }'
}

generate_data()
{
        local num=0
        while [ $num -lt ${SEED_ITERATIONS} ]
        do
                echo ${SEED_STRING} >> ${TEMP_PATH}
                num=$(($num+1))
        done
}

while [ -n "$1" ]; do
    case $1 in
	-h|--help ) usage ; exit ;;
	-p ) TTY=$2 ; shift ;;
	* ) echo "unknown parameter: $1" ; echo ; usage ; exit ;;
    esac
    shift
done

# Test for an empty TTY
if [ -z ${TTY} ]; then echo "Missing arg"; usage; exit; fi

# Ensure the port is valid.
if [ ! -c "/dev/${TTY}" ]; then
	echo "Error! UART selection not found [/dev/${TTY}]"; echo; usage; exit;
fi

# Check the compatibility string.
if [ "$( cat /sys/class/tty/${TTY}/device/of_node/compatible | grep "altr,16550-FIFO32" | wc -l )" -eq "0" ]; then
	echo "Error! UART compatible string doesn't match [/dev/${TTY}]"; echo; usage; exit;
fi

# Check if there is a tx-threshold property
if [ "$( ls /sys/class/tty/${TTY}/device/of_node/ | grep "tx-threshold" | wc -l )" -eq "0" ]; then
	echo "Error! UART doesn't have programmable TX Threshold [/dev/${TTY}]"; echo; usage; exit;
fi

# create the new file
if [ -f "${TEMP_PATH}" ]; then
	rm ${TEMP_PATH}
fi
echo "Generating data file - this may take awhile..."
generate_data

# Get the starting Serial IRQ count
START_IRQ_COUNT="$(get_serial_irq_num)"

# Send the data
cat ${TEMP_PATH} > /dev/${TTY}

# Get the ending Serial IRQ count
END_IRQ_COUNT="$(get_serial_irq_num)"
IRQ_COUNT_DIFF=$((${END_IRQ_COUNT}-${START_IRQ_COUNT}))
IRQ_COUNT_DIFF2=$((${IRQ_COUNT_DIFF}/2))

echo "Start IRQ count is " ${START_IRQ_COUNT}
echo "End IRQ count is " ${END_IRQ_COUNT}
echo "IRQ Count difference is ${IRQ_COUNT_DIFF}"

TEMP_SIZE=$(ls -al ${TEMP_PATH} | awk '{ print $5 }')
echo "File Size is ${TEMP_SIZE}"

# Fix round-off error
TEMP_SIZE=$((${TEMP_SIZE}+${IRQ_COUNT_DIFF2}))
BYTES_PER_IRQ=$(((${TEMP_SIZE}+${IRQ_COUNT_DIFF2})/${IRQ_COUNT_DIFF}))

echo "Bytes per IRQ is => ${BYTES_PER_IRQ}"
