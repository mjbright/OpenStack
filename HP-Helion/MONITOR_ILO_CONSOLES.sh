
BAREMETAL_CSV=baremetal.csv
SESSION_NAME="ILO_UNKNOWN"
TMUX=tmux
#TMUX="echo XXX"
ILO_USER="UNKNOWN"

#ILOS="10.3.247.116 10.3.247.117 10.3.247.118 10.3.247.119 10.3.247.120 10.3.247.121 10.3.247.122 10.3.247.123"
#ILOS="ig9_1 ig9_2 ig9_3 ig9_4 ig9_5 ig9_6 ig9_7 ig9_8"

die() {
    echo "$0: die - $*" >&2
    exit 1
}

# Read ilo nodes from baremetal.csv
getILONodes() {
    CSVFILE=$1; shift

    ILOS=""
    for line in `sed 's/ *, */,/g' $CSVFILE`;do
        IFS=',' read -a array <<< $line
        mac=${array[0]}
        user=${array[1]}
        pass=${array[2]}
        NODE=${array[3]}
        cpu=${array[4]}
        ram=${array[5]}
        disk=${array[6]}
        ILOS+="$NODE "
    done
}

while [ ! -z "$1" ];do
    case $1 in
        -csv) shift; BAREMETAL_CSV=$1;;
        -s)   shift; SESSION_NAME=$1;;

        *)    die "Unknown option '$1'";;
    esac
    shift
done

[ ! -f $BAREMETAL_CSV ] && die "No baremetal.csv file $BAREMETAL_CSV"

getILONodes $BAREMETAL_CSV

echo "ILOS=$ILOS"
#exit 0


SSH_OPTS="-o MACS=hmac-sha1,hmac-md5 -i /home/mjb/.ssh/ILO_dsa -o StrictHostKeyChecking=no -o ServerAliveInterval=60"

echo "Old sessions:"
$TMUX ls

echo "Killing $SESSION_NAME sessions:"
$TMUX kill-session -t $SESSION_NAME

echo "Old sessions:"
$TMUX ls

echo
echo "Creating new-session $SESSION_NAME"
$TMUX new-session -s $SESSION_NAME -d 'bash'

DATETIME=$(date +%Y-%m-%d-%Hh%Mm%S)
DIR=/home/mjb/ILO/${DATETIME}_${SESSION_NAME}.logs

[ ! -d $DIR ] && mkdir -p $DIR

echo
for ILO in $ILOS;do
    WINDOW_NAME=${ILO##*.}
    WINDOW_NAME=${WINDOW_NAME##*_}
    echo $WINDOW_NAME

    ILO_USER=$(grep $ILO $BAREMETAL_CSV | awk -F, '{ print $2; }')

    $TMUX new-window -t ${SESSION_NAME}:${WINDOW_NAME} -d "while true;do ssh $SSH_OPTS ${ILO_USER}@${ILO} textcons |& stdbuf -oL tee -a $DIR/ILO.log.${ILO}.raw; done"
done

echo
echo "New sessions:"
$TMUX ls

