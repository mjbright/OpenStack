
ACTION="power status"

LEVEL="-L USER"
LEVEL=""

CSVFILE=baremetal.csv
[ ! -f $CSVFILE ] && CSVFILE=/home/user/CONFIG/baremetal.csv
[ ! -f $CSVFILE ] && CSVFILE=/home/user/baremetal.csv
[ ! -f $CSVFILE ] && CSVFILE=/root/baremetal.csv

STATUS_FILE=$HOME/tmp/ipmitool_status.$$

VERBOSE=1
VERBOSE=0

################################################################################
# Functions:

die() {
    echo "$0: die - $*" >&2
    exit 1
}

detectChanges() {
    SLEEP=2

    while true;do
        [ -f $STATUS_FILE ] && cp $STATUS_FILE ${STATUS_FILE}.bak
        doAction power status > $STATUS_FILE
        if [ -f ${STATUS_FILE}.bak ];then
            diff -q $STATUS_FILE ${STATUS_FILE}.bak || {
                echo; echo "Status at $(date):";
                diff $STATUS_FILE ${STATUS_FILE}.bak | grep "< " | sed 's/^< //';
            }
        else
            echo; echo "Status at $(date):"
            cat $STATUS_FILE
        fi
        sleep $SLEEP;
    done
}

doAction() {
    ACTION=$*; set --

    for line in `sed 's/ *, */,/g' $CSVFILE `;do
        IFS=',' read -a array <<< $line
        mac=${array[0]}
        user=${array[1]}
        pass=${array[2]}
        NODE=${array[3]}
        cpu=${array[4]}
        ram=${array[5]}
        disk=${array[6]}
    
        LOGIN="$LEVEL -U $user -P $pass"

        [ "$ACTION" = "check_ilo_ssh" ] && {
            [ $VERBOSE -ne 0 ] && echo "ssh ${user}@${NODE} exit"
            ssh ${user}@${NODE} exit >/dev/null 2>&1
            echo "ssh ${user}@${NODE} ==> $?"
            continue # Next in loop
        }

        [ $VERBOSE -ne 0 ] && echo "ipmitool -I lanplus -H $NODE $LOGIN $ACTION"
        [ $DO_CMD -ne 0 ] && {
            OP=$(ipmitool -I lanplus -H $NODE $LOGIN $ACTION);
            echo "$NODE[$ACTION] ==> $OP";
        }
    done
}

################################################################################
# Args:

DO_CMD=1

while [ ! -z "$1" ];do
    case $1 in
        -ssh)         ACTION="check_ilo_ssh";;
        -change)      ACTION="status_changes";;

        -stat*|stat*) LEVEL="-L USER"; ACTION="power status";;
        -on|on)       ACTION="power on";;
        -off|off)     ACTION="power off";;

        -a|--action) shift; ACTION=$*; set --;;

        -csv|-f)    shift; CSVFILE=$1;;

        -n) DO_CMD=0;;
        +v) VERBOSE=0;;
        -v) VERBOSE=1;;

        *) die "Unknown option <$1>";;
    esac
    shift
done

[ ! -f $CSVFILE ] && die "No such csv file as '$CSVFILE'"
echo "Using CSV file '$CSVFILE'"

################################################################################
# Main:

#for NODE in $NODES;do
    #echo "$NODE[$ACTION] ==> " `ipmitool -I lanplus -H $NODE $LOGIN $ACTION`
#done

if [ "$ACTION" = "status_changes" ];then
    detectChanges
    exit 0
fi

#echo doAction $ACTION
doAction $ACTION



