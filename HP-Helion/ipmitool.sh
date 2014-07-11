
ACTION="power status"

CSVFILE=baremetal.csv

################################################################################
# Functions:

die() {
    echo "$0: die - $*" >&2
    exit 1
}

################################################################################
# Args:

while [ ! -z "$1" ];do
    case $1 in
        -stat*)  ACTION="power status";;
        -on)     ACTION="power on";;
        -off)    ACTION="power off";;
        -a|--action) shift; ACTION=$*; set --;;
        -csv)    shift; CSVFILE=$1;;

        *) die "Unknown option <$1>";;
    esac
    shift
done

[ ! -f $CSVFILE ] && die "No such csv file as '$CSVFILE'"

################################################################################
# Main:

#for NODE in $NODES;do
    #echo "$NODE[$ACTION] ==> " `ipmitool -I lanplus -H $NODE $LOGIN $ACTION`
#done

for line in `sed 's/ *, */,/g' $CSVFILE `;do
    IFS=',' read -a array <<< $line
    mac=${array[0]}
    user=${array[1]}
    pass=${array[2]}
    NODE=${array[3]}
    cpu=${array[4]}
    ram=${array[5]}
    disk=${array[6]}

    LOGIN="-U $user -P $pass"
    echo "$NODE[$ACTION] ==> " `ipmitool -I lanplus -H $NODE $LOGIN $ACTION`
done



