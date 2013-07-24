#!/bin/bash

TRACING=/sys/kernel/debug/tracing

usage()
{
    cat <<EOF
$(basename $0) - set filter functions and enable/disable tracing"

 -d|--dump     : stop tracing and dump the results to stdout
 -f|--func*    : name of file that lists functions to try to trace
 -u|--updated  : name of file to dump list of functions that were found to be
               : tracable (i.e. not inlined by the compiler)
 -b buff sz kb : set a larger trace buffer (in kb)

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

check_config()
{
    for foo in set_ftrace_filter tracing_on current_tracer buffer_size_kb; do
	bar=$TRACING/$foo
	if [ ! -e $bar ]; then
	    echo "Not found: $bar."
	    echo "Are you sure ftrace is enabled in your kconfig?"
	    exit 1
	fi
    done

    stats_files="$(find $TRACING/per_cpu -name 'stats')"
    if [ -z "$stats_files" ]; then
	echo "Not found: $TRACING/per_cpu/*/stats"
	echo "Are you sure ftrace is enabled in your kconfig?"
	exit 1
    fi
}

set_functions()
{
    echo "Setting the set_ftrace_filter, eliminating inlined functions..."
    funcs=$1
    updated=$2
    good_list=
    for foo in $(cat $funcs); do
	if echo $foo > $TRACING/set_ftrace_filter 2>/dev/null; then
	    echo "GOOD - $foo"
	    good_list="$good_list $foo"
	else
	    echo "BAD  - $foo"
	fi
    done
    echo
    echo "$good_list" > $TRACING/set_ftrace_filter
    echo
    echo " * * final list read back: * *"
    if [ -z "$updated" ]; then
	cat $TRACING/set_ftrace_filter
    else
	cat $TRACING/set_ftrace_filter |tee $updated
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

buffer_size()
{
    if [ -z "$1" ]; then
	return;
    fi
    echo $1 > $TRACING/buffer_size_kb
}

check_overrun()
{
    stats_files="$(find $TRACING/per_cpu -name 'stats')"
    overrun_err=
    for stats in $stats_files ; do
	overrun="$(grep '^overrun:' $stats)"
	if [ "$overrun" != 'overrun: 0' ]; then
	    overrun_err=1
	fi
    done

    if [ -n "$overrun_err" ]; then
	echo "Trace buffer overrun.  Some trace was lost.  You may want to" >&2
	echo "edit the most frequently called functions out of your functions" >&2
	echo "list and run your test again." >&2
    fi
}

#============================================================================


if [ -z "$1" ]; then
    usage
    exit 1
fi

dump=
funcs=
updated=
buff_size=
for foo in $@; do
    case $1 in
	-h|--help ) usage; exit 1 ;;
	-d|--dump ) dump=1 ;;
	-f|--func* ) funcs=$2 ; shift ;;
	-u|--updated ) updated=$2 ; shift ;;
	-b ) buff_size=$2; shift ;;
    esac
    shift
done

check_config

if [ -n "$dump" ] && [ -n "$funcs" ]; then
    echo "Please either specify dump or function list, not both"
    exit 1
fi

if [ -n "$funcs" ]; then
    tracing_off
    current_tracer nop
    buffer_size $buff_size
    set_functions $funcs $updated
    current_tracer function
    tracing_on
    echo "Tracing is ON... now run your unit tests..."
    exit 0
fi

if [ -n "$dump" ]; then
    check_overrun
    tracing_off
    cat $TRACING/trace
    exit 0
fi

exit 0
