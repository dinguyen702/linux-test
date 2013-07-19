#!/bin/bash

TRACING=/sys/kernel/debug/tracing

usage()
{
    cat <<EOF
$(basename $0) - set filter functions and enable/disable tracing"

usage:
  1. set the functions and start tracing
  $(basename $0) -f list-of-functions.txt -u list-of-functions-updated.txt

  2. run your unit test.

  3. dump the results to a file
  $(basename $0) -d > ~/trace.txt

wiki page:
  http://sw-wiki.altera.com/twiki/bin/view/Software/HPSLinuxTestPlanCodeCoverage

EOF
}

set_functions()
{
    funcs=$1
    updated=$2
    good_list=
    for foo in $(cat $funcs); do
	if echo $foo > /sys/kernel/debug/tracing/set_ftrace_filter; then
	    echo "GOOD - $foo"
	    good_list="$good_list $foo"
	else
	    echo "BAD  - $foo"
	fi
    done
    echo
    echo "$good_list" > /sys/kernel/debug/tracing/set_ftrace_filter
    echo
    echo "final list read back:"
    if [ -z "$updated" ]; then
	cat /sys/kernel/debug/tracing/set_ftrace_filter
    else
	cat /sys/kernel/debug/tracing/set_ftrace_filter |tee $updated
    fi
}

tracing_off()
{
    echo 0 > $TRACING/tracing_on
}

tracing_on()
{
    echo 1 > $TRACING/tracing_on
}

current_tracer()
{
    echo $1 > $TRACING/current_tracer
}

#============================================================================

if [ -z "$1" ]; then
    usage
    exit 1
fi

dump=
funcs=
updated=
for foo in $@; do
    case $1 in
	-h|--help ) usage; exit 1 ;;
	-d|--dump ) dump=1 ;;
	-f|--func* ) funcs=$2 ; shift ;;
	-u|--updated ) updated=$2 ; shift ;;
    esac
    shift
done

if [ -n "$dump" ] && [ -n "$funcs" ]; then
    echo "Please either specify dump or function list, not both"
    exit 1
fi

if [ -n "$funcs" ]; then
    tracing_off
    current_tracer nop
    set_functions $funcs $updated
    current_tracer function
    tracing_on
    echo "Tracing is ON... now run your unit tests..."
    exit 0
fi

if [ -n "$dump" ]; then
    tracing_off
    cat $TRACING/trace
    exit 0
fi

exit 0
