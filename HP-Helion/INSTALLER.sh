
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
     echo "-- List of SEEDVM ips on subnet '$BM_SEEDSUB' --" >&2
     ssh root@${VM_IP} ip a | grep ${BM_SEEDSUB}.
     echo "--" >&2
}

reinit_network() {
  echo;echo "Routes before:"; route -n
#ip addr del 10.3.160.10/24 dev brbm
#ovs-vsctl del-port eth0
#ovs-vsctl del-br brbm
#ip addr add 10.3.160.10/24 dev eth0 scope global
#route add default gw 10.3.160.1 dev eth0
  set -x
    ip addr del $BM_SEEDHOST/24 dev brbm
    ovs-vsctl del-port eth0
    ovs-vsctl del-br brbm
    ip addr add $BM_SEEDHOST/24 dev eth0 scope global
    route add default gw $GW dev eth0
  set +x
  echo;echo "Routes after:"; route -n
}

remove_seedvm() {
  echo;echo "VMs before:"; virsh list --all
  set -x
    virsh destroy seed
    virsh undefine seed
  set +x
  echo;echo "VMs after:"; virsh list --all
}

createSeed() {
    time bash -x /root/work/tripleo/tripleo-incubator/scripts/hp_ced_host_manager.sh --create-seed
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
    BM_SEEDHOST_24="${BM_SEEDHOST}/24"
    [ ${IPADDR} != "${BM_SEEDHOST_24}" ] &&
        die "IP address '$IPADDR' != '${BM_SEEDHOST_24}'"
}

waitOnSSH() {
    LOGIN=$1; shift
    echo; echo "Waiting for ssh connectivity to seed VM ($LOGIN)"
    showSEEDVMIP
    #sleep 60
    SSH_ARGS=""
    until ssh $SSH_ARGS $LOGIN uptime >/dev/null 2>&1; do
        echo -n '.'
        sleep 10
    done
    echo
}

UNUSED_checkRunningOnSeedVM() {
    assertRootUser
    [ `hostname` != "hLinux" ] &&
        die "Must be run on seedVM (hLinux)"
    IPADDR=$(ip a | grep 10.3.160 | awk '{ print $2; }')
    VM_24="${VM_IP}/24"
    [ ${IPADDR} != "${VM_24}" ] &&
        die "IP address '$IPADDR' != '${VM_24}'"
}

STEP1_CreateSeedVM() {
    checkRunningOnSeedHost

    #press "Reinitialzing network"
    echo "Reinitialzing network"
    reinit_network

    #press "Removing seedvm"
    echo "Removing seedvm"
    remove_seedvm

    ls -ald /root/work/tripleo

    [ ! -f $ENVRC ] && die "No such file as '$ENVRC'"
    #pause "Sourcing $ENVRC [ NOTE: you might consider a login/logout first ]"
    . $ENVRC

    [ ! -f VARS ] && die "No such file as 'VARS'"
    . VARS

    createSeed
    virsh list --all

    showSEEDVMIP
}

STEP2_Install() {
    checkRunningOnSeedHost

    [ ! -f $ENVRC ] && die "No such file as '$ENVRC'"
    #press "Sourcing $ENVRC [ NOTE: you might consider a login/logout first ]"
    . $ENVRC

    waitOnSSH $VM_LOGIN

    echo; echo "Copying $ENVRC, $BM_CSV to $VM_LOGIN:"
    rsync $ENVRC $VM_LOGIN:
    rsync $BM_CSV $VM_LOGIN:baremetal.csv

    NODE_MIN_DISK=200

    #press "About to modify install files:"
    echo "About to modify install files:"

    FILE=/root/tripleo/tripleo-incubator/scripts/hp_ced_functions.sh
    ORG_FILE=${FILE}.orig
    ssh -t $VM_LOGIN "[ ! -f $ORG_FILE ] && cp -a $FILE $ORG_FILE; set -x; sed -ie 's/^NODE_MIN_DISK=.*$/NODE_MIN_DISK=$NODE_MIN_DISK/g' $FILE; ls -altr $FILE $ORG_FILE; diff $FILE $ORG_FILE"
    ## exit 0

    press "About to invoke installation:"
    ssh -t $VM_LOGIN uptime

    INS_START_S=$(date +%s)
    ssh -t $VM_LOGIN ". $envrc; [ ! -f $envrc ] && exit 1; uptime; date; echo y | bash -x /root/tripleo/tripleo-incubator/scripts/hp_ced_installer.sh 2>&1 |& tee cloud_install.log; echo \"Exit code=\$?\""
    INS_END_S=$(date +%s)
    let INS_TOOK_S=INS_END_S-INS_START_S

    START=$(date +%Y-%m-%d-%Hh%Mm%S)
    #echo "scp $ENVRC $VM_LOGIN:cloud_install.log ${START}.cloud_install.log"

    RUNDIR=RUNS/${START}
    mkdir -p $RUNDIR

    scp $VM_LOGIN:cloud_install.log ${RUNDIR}/cloud_install.log 2>/dev/null
    tarUndercloudLogs $RUNDIR $START
    set -x; cp -a $CONFIG_DIR/* ${RUNDIR}/; set +x
    echo
    echo "grep CREATE_FAIL ${RUNDIR}/cloud_install.log"
    grep CREATE_FAIL ${RUNDIR}/cloud_install.log 
    {
        echo; date;
        echo "Install step took $INS_TOOK_S secs";
        echo "grep CREATE_FAIL ${RUNDIR}/cloud_install.log";
        grep CREATE_FAIL ${RUNDIR}/cloud_install.log ;
        echo "grep hoc_hw_info.sh ${RUNDIR}/cloud_install.log";
        grep hoc_hw_info.sh ${RUNDIR}/cloud_install.log ;
        ls -altr baremetal.csv ${envrc};
        md5sum baremetal.csv ${envrc};
        echo "-- cat baremetal.csv";
        cat baremetal.csv;
        echo "-- cat ${envrc}";
        cat ${envrc};
    } >> MULTI.LOG
    

    press "About to copy log/config files"
    #cp $ENVRC ${RUNDIR}/$ENVRC
    #cp $BM_CSV ${RUNDIR}/$BM_CSV
    scp -r ${RUNDIR} ${HOME_LOGIN}:HELION_RUNS/ 2>/dev/null
    #ls -altr *.cloud_install.log
    #showSEEDVMIP

    ./GET_LOGS.sh -name HELION_INSTALL_LOGS
    mv /tmp/HELION_INSTALL_LOGS ${RUNDIR}/

    ls -altr ${RUNDIR}/

    #exit 0
}

tcpdumpOvercloudTraffic() {
    assertRootUser

    [ -z "$1" ] && {
        set -x; tcpdump -v -i eth0 -e "ether host 00:17:A4:77:3C:1C" 2>&1 | tee tcpdump.overcloudX.log
    }

    [ "$1" == "119" ] && {
        set -x; tcpdump -v -i eth0 -e "ether host 00:17:A4:77:3C:1C" 2>&1 | tee tcpdump.overcloud.119.log
    }
    [ "$1" == "120" ] && {
        set -x; tcpdump -v -i eth0 -e "ether host 00:17:A4:77:3C:0C" 2>&1 | tee tcpdump.overcloud.120.log
    }
    [ "$1" == "121" ] && {
        set -x; tcpdump -v -i eth0 -e "ether host 00:17:A4:77:3C:10" 2>&1 | tee tcpdump.overcloud.121.log
    }
    [ "$1" == "122" ] && {
        set -x; tcpdump -v -i eth0 -e "ether host 00:17:A4:77:3C:14" 2>&1 | tee tcpdump.overcloud.122.log
    }
    [ "$1" == "125" ] && {
        set -x; tcpdump -v -i eth0 -e "ether host 00:17:A4:77:3C:3E" 2>&1 | tee tcpdump.overcloud.125.log
    }
    [ "$1" == "126" ] && {
        set -x; tcpdump -v -i eth0 -e "ether host 00:17:A4:77:3C:42" 2>&1 | tee tcpdump.overcloud.126.log
    }
#119: 00:17:A4:77:3C:1C
#120: 00:17:A4:77:3C:0C
#121: 00:17:A4:77:3C:10
#122: 00:17:A4:77:3C:14
#125: 00:17:A4:77:3C:3E
#126: 00:17:A4:77:3C:42

    die "Untreated ACTION_ARGS: '$ACTION_ARGS'"
}

tcpdumpUndercloudTraffic() {
    assertRootUser
    #UNDERCLOUD: 00:17:A4:77:3C:18
    set -x; tcpdump -v -i eth0 -e "ether host 00:17:A4:77:3C:18" 2>&1 | tee tcpdump.undercloud.log
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

undercloudSSH() {
    getUndercloudIP;
    ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} $*";
}

getUC_OC_LOGSandCONFIG() {
    die "TODO"
}

overcloudSCPfrom() {
    echo "overcloudSCPfrom $*" >&2
    FROM=$1; shift;
    TO=$1; shift;


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

unescapeILO() {
  stdbuf -oL \
    perl -ne '
    s/\x1b\x5b[0-9]m//g;
    s/\x1b\x5b[0-9]J//g;
    s/\x1b\x5bH//g;
    s/\x1b\x5b1;1H//g;

    s/\x1b\x5b14[23];[0-9]*H//g;
    s/\x1b\x5b[0-9]*;[0-9]*H//g;

    s/\x1b\x5b[0-9]*;1H//g;
    s/\x1b\x5b0;25;37;40m/\n/g;
    s/\x1b\x5b0;25;3[0-9];40m/\n/g;

    s/\x1b\x5b +\x1b\x5b/\x1b\x5b/g;

    s/\x1b\x5b/\nUNCAUGHT_ESC:/g;

    if (!/^\s*$/) {
        print "$_";
        #next; # Skip blank lines
    }
  '
}

UNUSED_openAlliLoTextCons() {
    LOCK=/tmp/.allILO

    [ -f $LOCK ] && die "alLILO seems to be running already"

    touch $LOCK

    DTIME=$(date +%Y-%m-%d-%Hh%Mm%S)
    for i in 118 119 120 121 122 125 126;do
        echo "iLoTextCons -il$i"
    done

    rm $LOCK
}

OLD_tailIloConsole() {
    stdbuf -oL ssh $HOST textcons |
        stdbuf -oL tee -a $RAW_LOGFILE |
        unescapeILO |
        stdbuf -oL tee -a ${LOGFILE}
}

tailIloConsole() {
    stdbuf -oL ssh $HOST textcons |
        stdbuf -oL tee -a $RAW_LOGFILE
}

iLoTextCons() {
    ARG=$1; shift
    NUM=${ARG#-il}
    echo $NUM

#tail -100f i118.textcons.log | strings | grep -v "^\[[0-9]*;1H"

    HOST=i$NUM

    [ -z "$DTIME" ] && DTIME=$(date +%Y-%m-%d-%Hh%Mm%S)
    RUNDIR="RUN-${DTIME}"
    [ ! -z "$NAME" ] && RUNDIR=${NAME}-${RUNDIR}

    mkdir -p $RUNDIR
    RAW_LOGFILE=${RUNDIR}/${HOST}.textcons.raw.log
    LOGFILE=${RUNDIR}/${HOST}.textcons.log

    echo "WHILE: ssh $HOST textcons | unescapeILO | tee ${LOGFILE}"
    while true;do
             #stdbuf -oL strings |
             #stdbuf -oL grep -vE "^[ ]*$" |
        tailIloConsole

        sleep 1; echo "-- SSH connection lost: reconnecting"
    #stdbuf -oL grep -v "^\[[0-9]*;1H" |
    done
}

looptests() {
    PROMPTS=0

    let LOOP=1
    while true; do
        echo $LOOP > CURRENT.LOOP
        ERC=${envrc}.${LOOP}
        CSV=baremetal.csv.${LOOP}

        while [ ! -f ${ERC} ];do
             press "No such file as ${ERC} for loop $LOOP"
        done
        while [ ! -f ${CSV} ];do
             press "No such file as ${CSV} for loop $LOOP"
        done

        cp ${ERC} ${envrc}
        cp $CSV baremetal.csv

        STEP1_CreateSeedVM;
        ./ipmitool.sh +v; ./ipmitool.sh +v off
        ./ipmitool.sh +v; ./ipmitool.sh +v off
        #ssh $HOME_LOGIN "cd ~/ILO; ./ILO.sh -name LOOP1"
        #ssh $HOME_LOGIN "cd ~/ILO; ./ILO.sh "
        STEP2_Install;
        let LOOP=LOOP+1
    done
}

REBOOT_ALL() {
    checkRunningOnSeedHost
    getUndercloudIP
    getOvercloudIPs
    echo "UCIP=$UCIP"
    echo "OCIPS=$OCIPS"

    DOIT="echo"

    for IP in $UCIP $OCIPS;do
        echo ssh -qt $VM_LOGIN "ssh -qt heat-admin@${IP} 'sudo su - -c \"$DOIT reboot -f\"'"
        ssh -qt $VM_LOGIN "ssh -qt heat-admin@${IP} 'sudo su - -c \"$DOIT reboot -f\"'"
    done

    #echo "REBOOT seedhost ..."
    echo "reboot -f"
    echo "$DOIT reboot -f"
}


########################################
#

[ -z "$1" ] && set -- -np -12
#[ -z "$1" ] && die "Missing argument"

env | grep -E "BM_|FLOATING|OVERCLOUD|UNDERCLOUD|SEED" &&
    die "Careful - Helion variables seem to already be set"

ACTION=""
ACTION_ARGS=""
#FOLLOW=""
#LINES=100

while [ ! -z "$1" ] ;do
    case $1 in
        -np) PROMPTS=0;;
        -name)  shift; NAME=$1;;

        -loop) ACTION="looptests";;
        -12) ACTION="1+2";;
        -1) ACTION=1;;
        -2) ACTION=2;;
        -prog)
            echo "Checking for wrapped_wait in install log on VM:";
            ssh -t $VM_LOGIN tail -1000f cloud_install.log | grep wrapped_wait;
            exit 0;;

        -ILO) XXX_openAlliLoTextCons; exit 0;;
        -il*) iLoTextCons $1; exit 0;;
        -i[0-9]*)
            NUM=${1#-i};
            ssh i$NUM; exit 0;;

        -dumpuc) ACTION="dumpUC";;
        -dumpoc) ACTION="dumpOC";;
        -dump119) ACTION="dumpOC"; ACTION_ARGS=119;;
        -dump120) ACTION="dumpOC"; ACTION_ARGS=120;;
        -dump121) ACTION="dumpOC"; ACTION_ARGS=121;;
        -dump122) ACTION="dumpOC"; ACTION_ARGS=122;;
        -dump125) ACTION="dumpOC"; ACTION_ARGS=125;;
        -dump126) ACTION="dumpOC"; ACTION_ARGS=126;;

        #-f) FOLLOW="f";;
        #-lines) shift; LINES="$1";;

        #-LOGS) shift; getUC_OC_LOGSandCONFIG $*; exit 0;;

        #-uc) undercloudCredentials; exit 0;;
        #-ucls) undercloudNovaList; exit 0;;
        #-ucip) getUndercloudIP; exit 0;;
        #-ucssh) shift; undercloudSSH $*; exit 0;;

        #-uclogs) shift; undercloudLsLogs; exit 0;;
        #-uclog) shift; undercloudLog; exit 0;;
        #-ucllog) shift; undercloudLastLog; exit 0;;

        #-ocip) shift; getOvercloudIP $1; exit 0;;
        #-ocssh) shift; overcloudSSH $*; exit 0;;
        #-oc) overcloudCredentials; exit 0;;
        #-oclist) overcloudNovaList; exit 0;;
        #-ocboot)
            #shift;
            #[ -z "$1" ] && set -- 1;
            #overcloudNovaBoot $1; exit 0;; # Boot first glance image
        #-ocglist) overcloudGlanceList; exit 0;;

        -REBOOT) REBOOT_ALL; exit 0;;

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

[ -z "$ACTION" ] && die "No action specified"

[ $ACTION == "1" ] && STEP1_CreateSeedVM
[ $ACTION == "2" ] && STEP2_Install

[ $ACTION == "looptests" ] &&  {
    looptests
}

[ $ACTION == "1+2" ] &&  {
    STEP1_CreateSeedVM;
    ./ipmitool.sh +v; ./ipmitool.sh +v off
    ./ipmitool.sh +v; ./ipmitool.sh +v off
    ssh $HOME_LOGIN    "cd ~/ILO; export DISPLAY=:0; ./ILO.sh"
    STEP2_Install;
}

[ $ACTION == "dumpUC" ] && tcpdumpUndercloudTraffic
[ $ACTION == "dumpOC" ] && tcpdumpOvercloudTraffic $ACTION_ARGS



