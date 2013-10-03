#!/bin/bash

##############################################################################
# Description: Helper script to facilitate restarting of nova-api
#              process on a DevStack installation
#
# TODO: Adapt to other proceses
#

VERBOSE=1
BACKGROUND=1

# Location of nova-api script in my DevStack installation:
BIN_DIR=/usr/local/bin

LOG_DIR=/tmp

########################################
# Functions:

PROG=$0
# FATAL: Exit with error message and non-zero return code
FATAL() {
    echo "$PROG: FATAL - $*" >&2
    exit 1
}

# debug: Output debug messae if VERBOSE set to non-zero
debug() {
    [ $VERBOSE -ne 0 ] && echo "DEBUG: $*" >&2
}

# listprocs: List matching processes to stdout
listprocs() {
    PROCESS=$1;shift
    #echo "getpids $PROCESS => " `ps -fade | grep $PROCESS | grep -v grep`
    echo "getpids $PROCESS => "
    ps -fade | grep $PROCESS | grep -v grep
}

# getpids: Get pids of matching processes - echo to stdout
getpids() {
    PROCESS=$1;shift

    debug "getpids $PROCESS => " `ps -fade | grep $PROCESS | grep -v grep` 

    PIDS=`ps -fade | grep $PROCESS | grep -v grep | awk '{print $2;}'`
    echo $PIDS
}

# restart_proc: Restart specified process (only works for nova-api for now)
restart_proc() {
    PROCESS=$1;shift
    CHECK_URL=$1;shift
    TIMEOUT=60

    cd $BIN_DIR

    # Start in foreground:
    if [ $BACKGROUND -eq 0 ];then
        sudo -u stack ./$PROCESS
        return
    fi

    sudo -u stack ./$PROCESS > /tmp/$PROCESS 2>&1 &

    if ! timeout $TIMEOUT sh -c "while ! wget --no-proxy -q -O- $CHECK_URL; do sleep 1; done"; then
        echo "$PROCESS did not start after $TIMEOUT secs"
        exit 1
    fi
}

########################################
# Process cmd-line args:

while [ ! -z "$1" ];do
    case $1 in
        -0) VERBOSE=0;;
        -v) let VERBOSE=VERBOSE=1;;
        -bg) BACKGROUND=1;;
        -fg) BACKGROUND=0;;
        *) FATAL "Unknown option: $1";;
    esac
    shift
done

########################################
# Main:
echo
echo "Checking for nova-api processes"
NOVA_API_PIDS=`getpids nova-api`
#NOVA_API_PIDS=`ps -fade | grep nova-api | grep -v grep | awk '{print $2;}'`

if [ ! -z "$NOVA_API_PIDS" ];then
    echo
    echo "Killing nova-api processes: kill -9 $NOVA_API_PIDS"
    kill -9 $NOVA_API_PIDS

    echo
    echo "Checking there are no more nova-api processes"
    NOVA_API_PIDS=`getpids nova-api`
    [ ! -z "$NOVA_API_PIDS" ] && FATAL "Failed to kill nova-api processes" `VERBOSE=1 getpids`
fi


#ps -fade | grep nova-api | grep -v grep

echo
echo "Restarting nova-api processes"
restart_proc nova-api http://127.0.0.1:8774

echo
echo "Listing nova-api processes"
listprocs nova-api

#wget --no-proxy -q -O- http://127.0.0.1:8774
#ps -fade | grep nova-api | grep -v grep
#nova quota-show

exit 0

