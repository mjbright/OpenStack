#!/bin/bash

#
# NOTE: hp_ced_load_config.sh checks whether it is invoked from a bash shell ($0 = *bash)
#       and assumes it is mistakenly called from a script if this is not the case.
#
#       To get around this check we source hp_ced_load_config.sh from scripts called *bash.
#       e.g. we copy init.sh to the seed vm as init-bash
#            we check if this script is invoked as INSTALL-bash, if not we check if this link
#            exists, and if not we link this script to INSTALL-bash prior to invoking it.
#
#
# USAGE:
#    Launch this script as
#      ./INSTALL.sh        ## to reset network then perform seedVM creation followed by installation
#      ./INSTALL.sh -2     ## to perform installation only
#      ./INSTALL.sh -net   ## to reset network only
#

set -o nounset # Force error on unset variables (must be disabled before call to LOAD_CONFIG_SH)
#set -x

START=$(date +%Y-%m-%d-%Hh%Mm%S)

LOG1=logs/INSTALL.sh.log
LOG2=logs/${START}-cloud_install.log

LOAD_CONFIG_SH=/root/tripleo/tripleo-incubator/scripts/hp_ced_load_config.sh
ARGS=$*

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
    [ ! -d logs ] && mkdir logs
    #echo; echo "Launching ./init_undercloud.sh (logging to $LOG)"
    #./init_undercloud.sh |& stdbuf -oL tee $LOG2

    echo; echo "Launching INIT_UNDERCLOUD [Logging to $LOG2]:"
    INIT_UNDERCLOUD |& stdbuf -oL tee $LOG2

    echo "Number of CREATE_FAIL in LOG FILE $LOG2:"
    grep -c CREATE_FAIL $LOG2
    grep -q "No valid host" $LOG2 && {
        echo "Error 'No valid host' seen in $LOG2"
    }
}

installJQ() {
    jq '.' /dev/null 2>/dev/null || { echo "Installing jq ..."; apt-get install jq; }
}

syntaxCheckJSON() {
    local JSON=$1; shift

    jq '.' $JSON  >/dev/null || die "Syntax error in JSON file '$JSON'"
}

INIT_UNDERCLOUD() {
    SCRIPTS_DIR=/root/tripleo/tripleo-incubator/scripts

    JSON_DIR=/root/tripleo/configs
    JSON_FILE=kvm-custom-ips.json
    export JSON=$JSON_DIR/$JSON_FILE

    installJQ
    syntaxCheckJSON $JSON

    #SRCDIR=/root
    SRCDIR=.

    VM_LOGIN=root@${BM_NETWORK_SEED_IP}

    ########################################
    # Modify and transfer hp_ced_functions.sh script to seed VM:
    HP_C_F=hp_ced_functions.sh
    NODE_MIN_DISK=200
    cp -a /root/tripleo/tripleo-incubator/scripts/$HP_C_F $SRCDIR/$HP_C_F
    sed -i.bak -e "s/^NODE_MIN_DISK=.*$/NODE_MIN_DISK=$NODE_MIN_DISK/g" $SRCDIR/$HP_C_F
    ls -altr $SRCDIR/$HP_C_F $SRCDIR/${HP_C_F}.bak
    diff $SRCDIR/$HP_C_F $SRCDIR/${HP_C_F}.bak
    scp -o StrictHostKeyChecking=no $SRCDIR/hp_ced_functions.sh ${VM_LOGIN}:$SCRIPTS_DIR/hp_ced_functions.sh

    ########################################
    # Transfer files to seed VM:
    scp -o StrictHostKeyChecking=no $SRCDIR/baremetal.csv ${VM_LOGIN}:/root/
    [ -f $JSON            ] && scp -o StrictHostKeyChecking=no $JSON                 ${VM_LOGIN}:$JSON
    [ -f $SRCDIR/env_vars ] && scp -o StrictHostKeyChecking=no $SRCDIR/env_vars      ${VM_LOGIN}:/root/

    # See above NOTE about *bash checks:
    scp -o StrictHostKeyChecking=no $SRCDIR/init.sh       ${VM_LOGIN}:/root/init-bash

    # undercloud/overcloud dns:
    HP_PASS=/root/tripleo/hp_passthrough/

    for json in $HP_PASS/undercloud_neutron_dhcp_agent.json $HP_PASS/overcloud_neutron_dhcp_agent.json; do
        syntaxCheckJSON $json
        scp -o StrictHostKeyChecking=no $json ${VM_LOGIN}:$json
    done

    press "Will now launch installer"

    ########################################
    # Launch installer:
    INIT
}

INIT() {
    # See above NOTE about *bash checks:
    ssh -o StrictHostKeyChecking=no ${VM_LOGIN} "JSON=$JSON LOAD_CONFIG_SH=$LOAD_CONFIG_SH ./init-bash"
}

checkVersion() {
    BUILD_TAG_FILE=/root/tripleo/build_tag

    [ ! -f $BUILD_TAG_FILE ] && die "No such build_tag file as '$BUILD_TAG_FILE'"

    # v1.0.1:
    # jenkins-installer-build-corvallis-ee-1.0.x-hlinux-ironic-7: Thu Oct 30 10:02:43 PDT 2014
    M_V101="jenkins-installer-build-corvallis-ee-1.0.x-hlinux-ironic-7:"
    M_V100="jenkins-installer-build-corvallis-ee-1.0-hlinux-ironic-13:"

    export BUILD_TAG=$(cat $BUILD_TAG_FILE)
    #echo $BUILD_TAG

    grep $M_V100 $BUILD_TAG_FILE && { echo "Installing Helion EE version 1.0.0";
        export BUILD=EE100;
        return 0;
    }
    grep $M_V101 $BUILD_TAG_FILE && { echo "Installing Helion EE version 1.0.1";
        export BUILD=EE101;
        return 0;
    }

    die "Failed to determine Helion version from $BUILD_TAG file contents:
        $(cat $BUILD_TAG)"
}

sourceVariables() {
    JSON_DIR=/root/tripleo/configs
    JSON_FILE=kvm-custom-ips.json

    env > .env.0.txt

    case "$BUILD" in
        EE100)
          . ./env_vars
          . ./VARS
          die "No more v.1.0"
          ;;
        EE101)
          set +o nounset # Force error on unset variables
          source $LOAD_CONFIG_SH $JSON_DIR/$JSON_FILE
          set -o nounset # Force error on unset variables
          . ./VARS
          ;;
        *)
          die "Unsupported release '$BUILD' $BUILD_TAG";
          ;;
    esac

    env > .env.txt
    env | grep -q BM_NETWORK_SEED_IP || die "Missing variable definitions"
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

checkLaunchedAsInstallBash() {

    # See above NOTE about *bash checks:
    if [[ "$0" != *"bash" ]] ; then
        DIR=${0%/*}
        I_BASH=$DIR/INSTALL-bash
        [ -h $I_BASH ] || {
            echo "Creating link from $0 to $I_BASH";
            set -x; ln -s $0 $I_BASH; set +x;
        }
        
        ls -altr $I_BASH
        #die exec $I_BASH
        [ -f $LOG1 ] && die "'$LOG1' already exists, please rename/delete"
        echo "[Logging to $LOG1]: exec $I_BASH $ARGS"
        exec $I_BASH $ARGS |& stdbuf -oL tee $LOG1
tee INSTALL.sh.log
    fi
}

checkLaunchedAsInstallBash

checkVersion

sourceVariables

[ `id -un` != 'root' ] && die "Must be run as root"


PROMPT=0
PROMPT=1
#SET_X=0

while [ $# -ne 0 ];do
    case $1 in
        #-x) set -x; SET_X=1;;
        #+x) set +x;;

        -2) INSTALLER; exit 0;;
        -net) reset_net; exit 0;;

        -np) PROMPT=0; next;;

        *) die "Unknown option: '$1'";;
    esac
    shift
done

createSeed

INSTALLER


