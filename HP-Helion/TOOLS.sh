
. VARS

PROMPTS=1

envrc=env_vars

#CONFIG_DIR=/home/user/CONFIG
CONFIG_DIR=.

ENVRC=$CONFIG_DIR/${envrc}
BM_CSV=$CONFIG_DIR/baremetal.csv
#BM_CSV=/home/user/baremetal.eth0.csv

########################################
#

press() {
    echo $*
    echo "Press <return> to continue"
    [ $PROMPTS -ne 0 ] && {
        read _dummy;
        [ "$_dummy" = "q" ] && exit 0;
        [ "$_dummy" = "Q" ] && exit 0;
    }
}

die() {
    echo "$0: die - $*" >&2
    exit 1
}

showSEEDVMIP() {
     echo "-- List of SEEDVM ips on subnet '$SEEDSUB' --" >&2
     ssh root@${VM_IP} ip a | grep ${SEEDSUB}.
     echo "--" >&2
}

assertRootUser() {
    [ `id -un` != "root" ] &&
        die "Must be run as root"
}

checkRunningOnSeedHost() {
    assertRootUser
    [ `hostname` != "helionseed" ] &&
        die "Must be run on seedhost (helionseed)"
    IPADDR=$(ip a | grep 10.3.160 | awk '{ print $2; }')
    SEEDHOST_24="${SEEDHOST}/24"
    [ ${IPADDR} != "${SEEDHOST_24}" ] &&
        die "IP address '$IPADDR' != '${SEEDHOST_24}'"
}

getUndercloudIP() {
    #UCIP=$(ssh -qt $VM_LOGIN ". stackrc; nova list | grep undercloud-undercloud | sed -e 's/.*ctlplane=//' -e 's/ .*//' -e 's/\r$//'")
    UCIP=$(ssh -qt $VM_LOGIN ". stackrc; nova list | grep undercloud-undercloud |  perl -pe 's/.*ctlplane=//; s/ .*//; s/\012//'")
    export UCIP
    echo "Undercloud IP='$UCIP'" >&2
}

overcloudNovaList() {
    getUndercloudIP;

    ssh -qt $VM_LOGIN "ssh -q heat-admin@${UCIP} 'sudo su - -c \". overcloud.stackrc; nova list\"'"
}

overcloudNovaBoot() {
    IDX=$1; shift

    getUndercloudIP;

    let idx=2+$IDX

    #echo idx=$idx
    ssh -qt $VM_LOGIN "ssh -q heat-admin@${UCIP} 'sudo su - -c \". overcloud.stackrc; glance image-list\"'" 
    #ssh -qt $VM_LOGIN "ssh -q heat-admin@${UCIP} 'sudo su - -c \". overcloud.stackrc; glance image-list\"'" | head -$idx

    IMAGEID=$(ssh -qt $VM_LOGIN "ssh -q heat-admin@${UCIP} 'sudo su - -c \". overcloud.stackrc; glance image-list\"'" | grep '^|' | head -$idx | tail -1 | awk '{print $2; }')
    echo "IMAGE_ID[$IDX]=$IMAGEID"

    DEFAULT_NETWORK_ID=$(ssh -qt $VM_LOGIN "ssh -q heat-admin@${UCIP} 'sudo su - -c \". overcloud.stackrc; neutron net-list\"'" | grep default-net | awk '{print $2; }')
    echo "DEFAULT_NETWORK_ID=$DEFAULT_NETWORK_ID"

    ssh -qt $VM_LOGIN "ssh -q heat-admin@${UCIP} 'sudo su - -c \". overcloud.stackrc; set -x; nova boot --key-name default --flavor m1.tiny --nic net-id=$DEFAULT_NETWORK_ID --image $IMAGEID demo\"'"

    ssh -qt $VM_LOGIN "ssh -q heat-admin@${UCIP} 'sudo su - -c \". overcloud.stackrc; nova list\"'"
}

overcloudGlanceList() {
    getUndercloudIP;

    ssh -qt $VM_LOGIN "ssh -q heat-admin@${UCIP} 'sudo su - -c \". overcloud.stackrc; glance image-list\"'"
}

getOvercloudIPs() {
    OCIPS=$(getOvercloudIP | perl -ne 'if (/ctlplane=(\d+\.\d+\.\d+\.\d+)/) { print "$1 "; }')
    export OCIPS
    echo "OvercloudIPs=$OCIPS"
    echo "UndercloudIP=$UCIP"
}

getOvercloudIP() {
    getUndercloudIP;

    IDX=""
    case "$1" in
        [0-9]) IDX=$1;
            OCIP=$(ssh -qt $VM_LOGIN "ssh -q heat-admin@${UCIP} 'sudo su - -c \". stackrc; nova list\"'" 2>/dev/null | getTableRow $IDX | sedIP);
            # MOVE OUTSIDE ==>> echo "Overcloud IP[$IDX]=$OCIP";
            export OCIP
            ;;
        "")
            ssh -qt $VM_LOGIN "ssh -q heat-admin@${UCIP} 'sudo su - -c \". stackrc; nova list\"'" 2>/dev/null;
            ;;
        *)
            [ -z "$2" ] &&
                ssh -qt $VM_LOGIN "ssh -q heat-admin@${UCIP} 'sudo su - -c \". stackrc; nova list\"'" 2>/dev/null | grep "^|" | grep "$1" ||
                ssh -qt $VM_LOGIN "ssh -q heat-admin@${UCIP} 'sudo su - -c \". stackrc; nova list\"'" 2>/dev/null | getTableRow $2 | sedIP
            ;;
    esac
}

getTableRow() {
    let _IDX=1+$1
    grep "^|"  | head -$_IDX | tail -1
}

sedIP() {
    sed -e 's/.*ctlplane=//' -e 's/ .*//'
}

getUC_OC_LOGSandCONFIG() {
    die "TODO"
}

overcloudSCPfrom() {
    echo "overcloudSCPfrom $*" >&2
    FROM=$1; shift;
    TO=$1; shift;


}

showOvercloudNodes() {
    ssh -t $VM_LOGIN ". stackrc;\
echo "Undercloud nodes[nova list]:";\
nova list"

    undercloudRootSSH ". stackrc;\
echo "Overcloud nodes[nova list]:";\
nova list;\
echo "Overcloud nodes[ironic node-list]:";\
ironic node-list;\
echo "Overcloud nodes[ironic port-list]:";\
ironic port-list"
}

overcloudAPI() {
    undercloudRootSSH ". overcloud.stackrc; $*"
}

undercloudRootSSH() {
    getUndercloudIP;
    #ssh -t $VM_LOGIN "ssh -t heat-admin@${UCIP} 'sudo su -'";
    [ -z "$1" ] && set -- bash
    ssh -t $VM_LOGIN "ssh -t heat-admin@${UCIP} 'sudo su - -c \"$*\"'";
}

undercloudSSH() {
    getUndercloudIP;
    ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} $*";
}

overcloudSSH() {
    echo "overcloudSSH $*" >&2
    #[ -z "$1" ] && {
    [ "${1#*[0-9]}" == "$1" ] && {
        shift;
        [ -z "$1" ] && set -- uptime
        #die "ocssh expected arg";
        echo "No numeric arg, running '$*' on all overcloud nodes(5 today)";
        for i in 1 2 3 4 5;do
            overcloudSSH $i uptime
        done;
        return;
    }
    #[ "${1#*[0-9]}" == "$1" ] && die "ocssh expected numeric arg";

    getOvercloudIP $1;
    shift;

    #echo "Running command '$*' on root@${OCIP}";
    #ssh -t $VM_LOGIN "ssh root@${OCIP} $*";
    [ -z "$1" ] && {
        echo "Opening shell on heat-admin@${OCIP}" >&2
        ssh -t $VM_LOGIN "ssh heat-admin@${OCIP}";
    } || {
        echo "Running command in BatchMode '$*' on heat-admin@${OCIP}" >&2
        ssh -t $VM_LOGIN "ssh -o BatchMode=yes -o StrictHostKeyChecking=no heat-admin@${OCIP} $*";
        RET=$?
        [ $RET -ne 0 ] && echo "==============> ERROR $RET" >&2 ||
                          echo "*************** OK" >&2
    }
}

undercloudNovaList() {
    ssh -t $VM_LOGIN ". stackrc; nova list"
}

overcloudCredentials() {
    ssh -qt $VM_LOGIN "grep OVERCLOUD_ADMIN_PASSWORD /root/tripleo/tripleo-overcloud-passwords ";
    getOvercloudIP;
    echo "Login to http://<OCIP> as admin with above passwd";
}

undercloudCredentials() {
    ssh -qt $VM_LOGIN "grep UNDERCLOUD_ADMIN_PASSWORD /root/tripleo/tripleo-undercloud-passwords ";
    getUndercloudIP;
    echo "Login to http://$UCIP as admin with above passwd";
}

undercloudLsLogs() {
    getUndercloudIP;
    ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} ls -altr /var/log/upstart/"
}

undercloudLog() {
    getUndercloudIP;
    ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} sudo tail -${LINES}${FOLLOW} /var/log/upstart/os-collect-config.log"
}

tarUndercloudLogs() {
    RUNDIR=$1; shift
    START=$1; shift

    getUndercloudIP;

    TAR_BZ2="/tmp/${START}.undercloud.logs.tbz2"
    ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} sudo tar cf - /var/log/upstart/ | bzip2 -9 > ${TAR_BZ2}"
    scp $VM_LOGIN:${TAR_BZ2} ${RUNDIR}/ 2>/dev/null
    #scp $VM_LOGIN:${TAR_BZ2} . 2>/dev/null
}

undercloudLastLog() {
    getUndercloudIP;
    LASTLOG=$(ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} ls -1tr /var/log/upstart/ | tail -1");
    LASTLOG="/var/log/upstart/"$(echo ${LASTLOG} | sed 's/\r$//')
    echo; date

    ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} ls -altr $LASTLOG"

    [ ! -z "$FOLLOW" ] &&
        press "About to tail '$LASTLOG' on Undercloud node $UCIP" ||
        echo "tail '$LASTLOG' on Undercloud node $UCIP" 

    ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} sudo tail -${LINES}${FOLLOW} $LASTLOG"
}

tailDhcpLogging() {
    #ssh -t $VM_LOGIN "tail -100f /var/log/syslog | grep -E 'DHCP|dnsmasq'"
    #ssh -t $VM_LOGIN "tail -100f /var/log/syslog | grep -E 'DHCP|DHCPOFFER|DHCPREQUEST'"
    while true; do
        echo ""; echo ""; echo "";
        echo "Following DHCP info in $VM_LOGIN:/var/log/syslog"
        ssh -t -o StrictHostKeyChecking=no $VM_LOGIN "tail -100f /var/log/syslog | grep -E 'DHCPOFFER|DHCPREQUEST'"
        sleep 10
        echo "Lost connection ... retrying ..."
    done
}

pingGW() {
    # Ping BM network gateway from seedhost:
    while true; do
        echo ""; echo ""; echo "";
        echo "Pinging [from $VM_LOGIN] baremetal network gateway $GW"
        ssh -t -o StrictHostKeyChecking=no $VM_LOGIN "ping $GW"
        sleep 10
        echo "Lost connection ... retrying ..."
    done
}

########################################
#

[ -z "$1" ] && set -- -np -12
#[ -z "$1" ] && die "Missing argument"

env | grep -E "BM_|FLOATING|OVERCLOUD|UNDERCLOUD|SEED" &&
    die "Careful - Helion variables seem to already be set"

ACTION=""
ACTION_ARGS=""
FOLLOW=""
LINES=100

while [ ! -z "$1" ] ;do
    case $1 in
        -np) PROMPTS=0;;

        -f) FOLLOW="f";;
        -lines) shift; LINES="$1";;

        -LOGS) shift; getUC_OC_LOGSandCONFIG $*; exit 0;;

        -uc) undercloudCredentials; exit 0;;
        -ucls) undercloudNovaList; exit 0;;
        -ucip) getUndercloudIP; exit 0;;
        -ucssh) shift; undercloudSSH $*; exit 0;;
        -ucr|-ucrssh) shift; undercloudRootSSH $*; exit 0;;

        -uapi) shift; undercloudAPI $*; exit 0;;
        -api) shift; overcloudAPI $*; exit 0;;
        -nodes) shift; showOvercloudNodes $*; exit 0;;

        -dhcp) shift; tailDhcpLogging; exit 0;;
        -pinggw) shift; pingGW; exit 0;;

        -uclogs) shift; undercloudLsLogs; exit 0;;
        -uclog) shift; undercloudLog; exit 0;;
        -ucllog) shift; undercloudLastLog; exit 0;;

        -ocip) shift; getOvercloudIP $1; exit 0;;
        -ocssh) shift; overcloudSSH $*; exit 0;;
        -ocr) shift; overcloudRootSSH $*; exit 0;;
        -oc) overcloudCredentials; exit 0;;
        -oclist) overcloudNovaList; exit 0;;
        -ocboot)
            shift;
            [ -z "$1" ] && set -- 1;
            overcloudNovaBoot $1; exit 0;; # Boot first glance image
        -ocglist) overcloudGlanceList; exit 0;;

        -sync|-scp) [ -z "$2" ] && {
           scp $0 $HOME_LOGIN: 2>/dev/null;} || {
               shift; scp -r $* $HOME_LOGIN: 2>/dev/null; }
           exit 0;
           ;;

        -x) set -x;;
        +x) set +x;;

        *) die "Unknown option '$1'";;
    esac
    shift
done


