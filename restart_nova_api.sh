#!/bin/bash

VERBOSE=1
BIN_DIR=/usr/local/bin
LOG_DIR=/tmp

PROG=$0
die() {
    echo "$PROG: die - $*" >&2
    exit 1
}

debug() {
    echo "DEBUG: $*" >&2
}

listprocs() {
    PROCESS=$1;shift
    #echo "getpids $PROCESS => " `ps -fade | grep $PROCESS | grep -v grep`
    echo "getpids $PROCESS => "
    ps -fade | grep $PROCESS | grep -v grep
}

getpids() {
    PROCESS=$1;shift

    [ $VERBOSE -ne 0 ] &&
        debug "getpids $PROCESS => " `ps -fade | grep $PROCESS | grep -v grep` 

    PIDS=`ps -fade | grep $PROCESS | grep -v grep | awk '{print $2;}'`
    echo $PIDS
}

restart_proc() {
    PROCESS=$1;shift
    CHECK_URL=$1;shift
    TIMEOUT=60

    cd $BIN_DIR
    ./$PROCESS > /tmp/$PROCESS 2>&1 &

    if ! timeout $TIMEOUT sh -c "while ! wget --no-proxy -q -O- $CHECK_URL; do sleep 1; done"; then
        echo "$PROCESS did not start after $TIMEOUT secs"
        exit 1
    fi
}


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
    [ ! -z "$NOVA_API_PIDS" ] && die "Failed to kill nova-api processes" `VERBOSE=1 getpids`
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

