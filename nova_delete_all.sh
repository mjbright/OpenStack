

################################################################################
# Functions:

function die
{
    echo "$0: die - $*" >&2
    exit 1
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

function getNovaList {
    MATCH=$1

    IFS=$'\n'
    if [ -z "$MATCH" ];then
        VMS=( $( nova list ) )
    else
        VMS=( $( nova list | grep -iE "$MATCH" ) )
    fi
    
    VMIDs=""
    VMNAMEs=""
    
    for VMline in ${VMS[@]}; do
        ## echo $VMline;
        IFS=' ';
        FIELDS=( $VMline );
        VMID="${FIELDS[1]}";
        VMNAME="${FIELDS[3]}";
        ## echo "VMID=$VMID"
        ## echo "VMNAME=$VMNAME"
        if [ "$VMID" = "ID" ];then
            continue
        fi
    
        VMIDs+=" ${VMID}"
        VMNAMEs+=" ${VMNAME}"
    done
}

################################################################################
# Args:

YES=0
MATCH=""

while [ ! -z "$1" ];do
    case $1 in
        -y)     YES=1;;
        -match) shift; MATCH=$1;;
        *)      die "Unknown option <$1>";
    esac
    shift
done

################################################################################
# Main:

getNovaList $MATCH

[ $YES -eq 0 ] && {
    yesno "Delete VMs[$VMNAMEs]?" && YES=1;
    #[ $? -eq 0 ] && { YES=1; }
}

[ $YES -ne 0 ] && {
    #echo "nova delete <$VMNAMEs>"
    echo "nova delete <$VMIDs>";
    nova delete $VMIDs;
}

exit 0

