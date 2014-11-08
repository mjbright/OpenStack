
set -o nounset # Force error on unset variables
#set -x

press() {
    echo $*
    [ $PROMPT -eq 0 ] && return

    echo "Press <return>"
    read _DUMMY
    [ "$_DUMMY" = "q" ] && exit 0
    [ "$_DUMMY" = "Q" ] && exit 0
}

die() {
    echo "$0: die - $*" >&2
    exit 1
}

reset_net() {
    press "About to restore initial networking (direct to $BRIDGE_INTERFACE)"
    set -x
    ip addr del $BM_SEEDHOST/24 dev brbm
    ovs-vsctl del-port $BRIDGE_INTERFACE
    ovs-vsctl del-br brbm
    ip addr add $BM_SEEDHOST/24 dev $BRIDGE_INTERFACE scope global
    route add default gw $BM_GATEWAY dev $BRIDGE_INTERFACE
    set +x

    ERROR=0
    route -n | grep brbm && ERROR=1
    ip a | grep brbm && ERROR=1

    [ $ERROR -ne 0 ] && die "Network reset failed - brbm is still present!!"
}

add_route() {
    #press "About to replace ip route"
    echo; echo "Replacing ip route"
    set -x
    ip route replace ${BM_SUBNET}/24 dev brbm
    set +x

    echo; echo "Sleeping 30 secs"
    sleep 30
}

INSTALLER() {
    LOGIN="root@$BM_NETWORK_SEED_IP"
    echo "ssh $LOGIN ping $BM_GATEWAY"

    press "About to launch installer [ remember to launch ping GW from SEEDVM ]"
    START=$(date +%Y-%m-%d-%Hh%Mm%S)
    [ ! -d logs ] && mkdir logs
    LOG=logs/${START}-cloud_install.log
    echo; echo "Launching ./init_undercloud.sh (logging to $LOG)"
    ./init_undercloud.sh 2>&1 |& stdbuf -oL tee $LOG

    echo "Number of CREATE_FAIL in LOG FILE $LOG:"
    grep -c CREATE_FAIL $LOG
}

[ `id -un` != 'root' ] && die "Must be run as root"

. ./env_vars
. ./VARS

PROMPT=0
PROMPT=1

while [ $# -ne 0 ];do
    case $1 in
        -2) INSTALLER; exit 0;;
        -net) reset_net; exit 0;;

        -np) PROMPT=0; next;;

        *) die "Unknown option: '$1'";;
    esac
    shift
done

reset_net
echo; echo "About to restore seed-vm"
#press "About to restore seed-vm"
./init_seed.sh;

echo "########################################################################"
echo "########################################################################"
echo "##"
echo "##  INIT_SEED completed"
echo "##"
echo "########################################################################"
echo "########################################################################"

echo; echo "Sleeping 30 secs"
sleep 30

add_route

INSTALLER


