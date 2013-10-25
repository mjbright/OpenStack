#!/bin/bash

##############################################################################
# Description: Helper script to facilitate file diff management
#              on a DevStack installation
#
# TODO: Adapt to other proceses
#

COPYDIR=/home/mjb/devstack_diffs
VERBOSE=1

STACKDIR=/opt/stack

NOVA=/opt/stack/nova/nova

FILES="$NOVA/quota.py $NOVA/compute/api.py $NOVA/db/sqlalchemy/api.py"

########################################
# Functions:

PROG=$0
# FATAL: Exit with error message and non-zero return code
FATAL() {
    echo "$PROG: FATAL - $*" >&2
    echo `caller` >&2
    exit 1
}

makeCopyDirFilename() {
    _FILE=$1

    __FILE=$COPYDIR/`echo $FILE | sed -e 's/\///' -e 's/\//_/g'`
}

function yesno
{
    resp=""
    default=""
    [ ! -z "$2" ] && default="$2"

    while [ 1 ]; do
        if [ ! -z "$default" ];then
            echo -n "$1 [yYnNqQ] [$default]:"
            read resp
            [ -z "$resp" ] && resp="$default"
        else
            echo -n "$1 [yYnNqQ]:"
            read resp
        fi
        [ \( "$resp" = "q" \) -o \( "$resp" = "Q" \) ] && exit 0
        [ \( "$resp" = "y" \) -o \( "$resp" = "Y" \) ] && return 0
        [ \( "$resp" = "n" \) -o \( "$resp" = "N" \) ] && return 1
    done
}

CP() {
    FROM=$1
    TO=$2
 
    echo "CP $FROM $TO"
    [ ! -f $FROM ] && FATAL "NO such file as '$FROM'"
    [ ! -f $TO ] && {
        cp $FROM $TO;
        return $?;
    }

    yesno "WARNING: destination file exists - show diffs?"  || {
        echo diff $FROM $TO;
        diff $FROM $TO;
    } || echo "NOT SHOWING DIFFS"
    
    yesno "WARNING: destination file exists - continue?"  && {
        cp $FROM $TO;
        return $?;
    }
    return 1
}

########################################
# Process cmd-line args:

#[ `id -un` = "root" ] && FATAL "Must be run as non-root user"
[ `id -un` != "root" ] && FATAL "Must be run as root user"

OP_RM_DIFFS=0

OP_DIFFS_BAK=0
OP_DIFFS_ORIG=0
OP_DIFFS_COPY=0

OP_COPY_ORIG=0
OP_COPY_BAK=0
OP_COPY_COPY=0

OP_REVERT_ORIG=0
OP_REVERT_BAK=0
OP_REVERT_COPY=0

while [ ! -z "$1" ];do
    case $1 in
        -0) VERBOSE=0;;
        -v) let VERBOSE=VERBOSE=1;;

        -rm) OP_RM_DIFFS=1;;

        -copy) OP_COPY_ORIG=1;;
        -copy_bak) OP_COPY_BAK=1;;
        -copy_copy) OP_COPY_COPY=1;;

        -rev) OP_REVERT_ORIG=1;;
        -rev_bak) OP_REVERT_BAK=1;;
        -rev_copy) OP_REVERT_COPY=1;;

        -diff) OP_DIFFS_ORIG=1;;
        -diff_bak) OP_DIFFS_BAK=1;;
        -diff_copy) OP_DIFFS_COPY=1;;

        #-bg) BACKGROUND=1;;
        #-fg) BACKGROUND=0;;
        *) FATAL "Unknown option: $1";;
    esac
    shift
done

for FILE in $FILES;do
    [ ! -f ${FILE} ] && FATAL "NO such file as $FILE"
done

[ ! -f $COPYDIR ] && mkdir -p $COPYDIR

if [ $OP_RM_DIFFS -eq 1 ];then
    echo
    echo "Removing monitored files:"
    for FILE in $FILES;do
        echo "mv $FILE ${FILE}.bak"
        mv $FILE ${FILE}.bak
    done
fi

if [ $OP_COPY_ORIG -eq 1 ];then
    echo
    echo "Copy monitored files: => .orig"
    for FILE in $FILES;do
        CP $FILE ${FILE}.orig;
        #[ -f ${FILE}.orig ] && {
        #    echo "EXISTS: Skipping cp $FILE ${FILE}.orig";
        #    #cp $FILE ${FILE}.orig;
        #} || {
        #    echo "cp $FILE ${FILE}.orig";
        #    cp $FILE ${FILE}.orig;
        #}
    done
fi

if [ $OP_COPY_BAK -eq 1 ];then
    echo
    echo "Copy monitored files: => .bak"
    for FILE in $FILES;do
        CP $FILE ${FILE}.bak;
        #[ -f ${FILE}.bak ] && {
        #    echo "EXISTS: Skipping cp $FILE ${FILE}.bak";
        #    #cp $FILE ${FILE}.bak;
        #} || {
        #    echo "cp $FILE ${FILE}.bak";
        #    cp $FILE ${FILE}.bak;
        #}
    done
fi

if [ $OP_COPY_COPY -eq 1 ];then
    echo
    echo "Copy monitored files: => $COPYDIR/path_file"
    for FILE in $FILES;do
        makeCopyDirFilename $FILE;COPYFILE=$__FILE
        CP $FILE ${__FILE};
        #[ -f ${__FILE} ] && {
        #    echo "EXISTS: Skipping cp $FILE ${__FILE}";
        #    #cp $FILE ${__FILE};
        #} || {
        #    echo "cp $FILE ${__FILE}";
        #    cp $FILE ${__FILE};
        #}
    done
fi

if [ $OP_REVERT_ORIG -eq 1 ];then
    echo
    echo "Copy monitored files: => .orig"
    for FILE in $FILES;do
        CP ${FILE}.orig ${FILE};
    done
fi

if [ $OP_REVERT_BAK -eq 1 ];then
    echo
    echo "Copy monitored files: => .bak"
    for FILE in $FILES;do
        CP ${FILE}.bak ${FILE};
    done
fi

if [ $OP_REVERT_COPY -eq 1 ];then
    echo
    echo "Copy monitored files: => $COPYDIR/path_file"
    for FILE in $FILES;do
        makeCopyDirFilename $FILE;COPYFILE=$__FILE
        CP ${__FILE} ${FILE};
    done
fi

if [ $OP_DIFFS_ORIG -eq 1 ];then
    echo
    echo "Diff monitored files: current <-> original"
    for FILE in $FILES;do
        echo "diff $FILE ${FILE}.orig"
        diff $FILE ${FILE}.orig
    done
fi

if [ $OP_DIFFS_BAK -eq 1 ];then
    echo
    echo "Diff monitored files: current <-> bak"
    for FILE in $FILES;do
        echo "diff $FILE ${FILE}.bak"
        diff $FILE ${FILE}.bak
    done
fi

if [ $OP_DIFFS_COPY -eq 1 ];then
    echo
    echo "Diff monitored files: current <-> COPY"
    #FATAL "TODO"
    for FILE in $FILES;do
        makeCopyDirFilename $FILE;COPYFILE=$__FILE
        echo "diff $FILE ${__FILE}"
        diff $FILE ${__FILE}
    done
fi

########################################
# Main:
echo

exit 0

##############################################################################


BACKGROUND=1

# Location of nova-api script in my DevStack installation:
BIN_DIR=/usr/local/bin

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
        ./$PROCESS
        return
    fi

    ./$PROCESS > /tmp/$PROCESS 2>&1 &

    if ! timeout $TIMEOUT sh -c "while ! wget --no-proxy -q -O- $CHECK_URL; do sleep 1; done"; then
        echo "$PROCESS did not start after $TIMEOUT secs"
        exit 1
    fi
}

########################################
# Process cmd-line args:

[ `id -un` = "root" ] && FATAL "Must be run as non-root user"

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

