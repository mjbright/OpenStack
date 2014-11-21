#!/bin/bash

set -o nounset # Force error on unset variables
#set -x

LOAD_CONFIG_SH=/root/tripleo/tripleo-incubator/scripts/hp_ced_load_config.sh

RELEASE=0
BUILD_TAG="Unknown Helion build"

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
    ./init_undercloud.sh |& stdbuf -oL tee $LOG

    echo "Number of CREATE_FAIL in LOG FILE $LOG:"
    grep -c CREATE_FAIL $LOG
}

checkVersion() {
    BUILD_TAG_FILE=/root/tripleo/build_tag

    [ ! -f $BUILD_TAG_FILE ] && die "No such build_tag file as '$BUILD_TAG_FILE'"

    # v1.0.1:
    # jenkins-installer-build-corvallis-ee-1.0.x-hlinux-ironic-7: Thu Oct 30 10:02:43 PDT 2014
    M_V101="jenkins-installer-build-corvallis-ee-1.0.x-hlinux-ironic-7:"
    M_V100="jenkins-installer-build-corvallis-ee-1.0-hlinux-ironic-13:"

    export BUILD_TAG=$(cat $BUILD_TAG_FILE)

    grep $M_V101 $BUILD_TAG_FILE && { echo "Installing Helion EE version 1.0.1";
        export BUILD=EE100;
        return 0;
    }
    grep $M_V100 $BUILD_TAG_FILE && { echo "Installing Helion EE version 1.0.0";
        export BUILD=EE101;
        return 0;
    }

    die "Failed to determine Helion version from $BUILD_TAG file contents:
        $(cat $BUILD_TAG)"
}

sourceVariables() {
    JSON_DIR=/root/tripleo/config
    JSON_FILE=kvm-custom-ips.json

    case "$BUILD" in
        EE100)
          . ./env_vars
          . ./VARS
          ;;
        EE101)
          source $LOAD_CONFIG_SH $JSON_DIR/$JSON_FILE
          . ./VARS
          ;;
        *)
          die "Unsupported release '$BUILD' $BUILD_TAG";
          ;;
    esac
}

createSeed() {
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
}

checkVersion

sourceVariables

[ `id -un` != 'root' ] && die "Must be run as root"


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

createSeed

INSTALLER


