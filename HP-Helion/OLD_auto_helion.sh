

IP=10.3.3.117
IP=10.3.160.10
SEEDHOST=seedhost

export NODE_MIN_DISK=512

export FLOATING_PREFIX=10.3.160
export FLOATING_PREFIX=192.0.2

#IP=10.3.160.199
USER=user
LOGIN=${USER}@${IP}

BACKUP_ETC=0

PROMPTS=1

VM_SEED="192.0.2.1"
VM_LOGIN="root@$VM_SEED"
DEBUG_VM=1

THIS_OS=UNKNOWN
uname -a | grep -i ^Linux && {
    THIS_OS=LINUX;
    PING_COUNT_ARG="-c 1";
    PING_RECEIVED_REGEX="bytes from";
}
uname -a | grep -i ^CYGWIN && {
    THIS_OS=CYGWIN;
    PING_COUNT_ARG="-n 1";
    PING_RECEIVED_REGEX="Reply from";
}

################################################################################
# Functions:

die() {
    echo "$0: die - $*" >&2
    exit 1
}

pause() {
    echo; echo "--"
    echo $*
    [ $PROMPTS -eq 0 ] && return

    echo "Press <return> to continue"
    read _DUMMY
    [ "$_DUMMY" = "q" ] && exit 0
    [ "$_DUMMY" = "Q" ] && exit 0
}

yesno() {
    resp=""
    default=""
    [ ! -z "$2" ] && default="$2"
    [ $PROMPTS -eq 0 ] && [ -z "$default" ] &&
        die "No prompts: No default on 'yesno $1'"
    [ $PROMPTS -eq 0 ] && {
        resp=$default
        echo "Choosing default response '$resp'"
        [ \( "$resp" = "y" \) -o \( "$resp" = "Y" \) ] && return 1;
        [ \( "$resp" = "n" \) -o \( "$resp" = "N" \) ] && return 0;
        die "No match on default '$default'";
    }

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
        [ \( "$resp" = "y" \) -o \( "$resp" = "Y" \) ] && return 1
        [ \( "$resp" = "n" \) -o \( "$resp" = "N" \) ] && return 0
    done
}

create_seedvm_ssh_config() {
    die "DISABLED"
    #cat >seedvm_ssh.config <<EOF
#
#Host seedvm
#    HostName 192.0.2.1
#    User root
#    StrictHostKeyChecking no
#    UserKnownHostsFile /dev/null
#Host under
#    HostName 192.0.2.2
#    User root
## #    StrictHostKeyChecking no
## #    UserKnownHostsFile /dev/null
#
#EOF
}

create_seedvm_env_sh() {

    echo "CREATE undercloud.sh"
    cat >undercloud.sh <<EOF

echo "\$0: \$*"

if [ "\$1" = "--novalist" ];then
    exec ssh -t heat-admin@192.0.2.2 "sudo su - -c '. /root/stackrc; nova list'"
fi

if [ "\$1" = "--over-nova-ip" ];then
    ID=\$(ssh -t heat-admin@192.0.2.2 "sudo su - -c '. /root/stackrc; nova list'" | grep NovaCompute0 | awk '{print \$2;}')
    echo ID=\$ID
    exec ssh -t heat-admin@192.0.2.2 "sudo su - -c '. /root/stackrc; nova show \$ID'"
fi

echo "[\$(hostname) \$(id)] executing command '\$@'"
#OK: ssh -t heat-admin@192.0.2.2 "sudo su - -c 'hostname'"
ssh -t heat-admin@192.0.2.2 "sudo -- sh -c '\$@'"

EOF

    echo "CREATE seedvm_env.sh"
    cat >seedvm_env.sh <<EOF

export OVERCLOUD_NTP_SERVER=10.3.252.26
export UNDERCLOUD_NTP_SERVER=10.3.252.26

export OVERCLOUD_NeutronPublicInterface=eth0
export UNDERCLOUD_NeutronPublicInterface=eth0

#export FLOATING_START=10.3.160.45
#export FLOATING_END=10.3.160.254
#export FLOATING_CIDR=10.3.160.0/24
export FLOATING_START=${FLOATING_PREFIX}.45
export FLOATING_END=${FLOATING_PREFIX}.254
export FLOATING_CIDR=${FLOATING_PREFIX}.0/24

export OVERCLOUD_COMPUTESCALE=1

# Default: 50GBy:
export OVERCLOUD_CINDER_LVMLOOPDEVSIZE=50000

#echo "===================="
#echo "== OC vars: ========"
#env | grep OVERCLOUD_
#echo "===================="

# Seen in ask.openstack helion forum:
export LANG=C
export OVERCLOUD_STACK_TIMEOUT=240 # instead of default 60
export UNDERCLOUD_STACK_TIMEOUT=240 # instead of default 60
#export OVERCLOUD_STACK_TIMEOUT=120 # instead of default 60
#export UNDERCLOUD_STACK_TIMEOUT=120 # instead of default 60
#export OVERCLOUD_STACK_TIMEOUT=60
#export UNDERCLOUD_STACK_TIMEOUT=60
#\${OVERCLOUD_STACK_TIMEOUT:-60}
#wait_for_stack_ready \$((\$OVERCLOUD_STACK_TIMEOUT * 60 / 10)) 10 \$STACKNAME
#UNDERCLOUD_STACK_TIMEOUT=\${UNDERCLOUD_STACK_TIMEOUT:-60}
#wait_for_stack_ready \$((\$UNDERCLOUD_STACK_TIMEOUT * 60 / 10)) 10 undercloud

bash -x /root/tripleo/tripleo-incubator/scripts/hp_ced_installer.sh \$*

EOF
    #chmod a+x seedvm_env.sh
    echo DONE
}

testPing() {
    ping -w 1000 $PING_COUNT_ARG $IP | grep -q "$PING_RECEIVED_REGEX"
    RET=$?
    #echo "RET=$RET"
    return $RET
    # && echo "PING OK"
}

waitOnNode() {
    while [ true ];do
        echo "Pinging machine[$IP] ..."
        testPing && break
        sleep 1
    done
    echo "Machine is up"
}

setupSSH() {
    ssh-copy-id $LOGIN
    #ssh -t $LOGIN uptime | grep -q
    ssh -t $LOGIN uptime
}

checkNetworkOnNode() {
    echo;echo "ovs-vsctl show:"
    ssh -t $LOGIN ovs-vsctl show

    echo;echo "brctl show:"
    ssh -t $LOGIN brctl show

    echo
}

vmCommand() {
    [ $DEBUG_VM -ne 0 ] && echo "ssh -t $LOGIN sudo ssh $VM_LOGIN \
        $*"
    ssh -t $LOGIN sudo ssh -t $VM_LOGIN "\"$*\""
    #ssh -t $LOGIN sudo ssh $VM_LOGIN $*
    #ssh -t $LOGIN sudo ssh $VM_LOGIN bash -c "$*"
}

undercloudCommand() {
    #vmCommand bash -x /home/heat-admin/undercloud.sh "$@"
    #vmCommand bash -x ./undercloud.sh "$@"
    #vmCommand "./undercloud.sh $@"
    vmCommand ./undercloud.sh "$@"
}

A_undercloudCommand() {
    vmCommand ssh -t heat-admin@192.0.2.2 "$@"
}

STEP0() {
    pause "Setting up ssh keys"
    setupSSH

    pause "Enable passwd-less sudo"
    ssh -t $LOGIN sudo sed -i.bak 's/^\(%sudo *ALL=(ALL:ALL) \)/\1 NOPASSWD: /' /etc/sudoers

    #pause "Re-Enable passwd sudo"
    #ssh -t $LOGIN sudo sed -i.bak 's/NOPASSWD://' /etc/sudoers

    [ $BACKUP_ETC -ne 0 ] && {
        pause "Copying /etc to /etc.base0";
        ssh -t $LOGIN sudo cp -a /etc/ /etc.base0;
    }

    pause "Pinging gateway"
    ssh -t $LOGIN ping -c 1 10.3.160.1

    pause "Checking connectivity to google.com (via ip/via hostname)"
    GIP=173.194.40.166
    ssh -t $LOGIN wget $GIP || echo "Failed to wget 'google.com' based on IP '$GIP'"

    ssh -t $LOGIN wget google.com || echo "Failed to wget 'google.com'"

    pause "Checking network state"
    checkNetworkOnNode
}

STEP1() {
    pause "Copy Helion archive file to seedhost '$SEEDHOST'"
    rsync -av --progress /e/z/Downloads/hp_helion_openstack_community_baremetal.tgz $SEEDHOST:
}

STEP2() {
    pause "Perform apt-get install -y libvirt-bin openvswitch-switch python-libvirt qemu-system-x86 qemu-kvm"
    ssh -t $LOGIN sudo apt-get install -y libvirt-bin openvswitch-switch python-libvirt qemu-system-x86 qemu-kvm
    pause "Pinging gateway"
    ssh -t $LOGIN ping -c 1 10.3.160.1

    pause "Restart libvirt-bin restart"
    ssh -t $LOGIN sudo /etc/init.d/libvirt-bin restart

    pause "Checking with virt-host-validate"
    ssh -t $LOGIN sudo virt-host-validate

    pause "Pinging gateway"
    ssh -t $LOGIN ping -c 1 10.3.160.1

    [ $BACKUP_ETC -ne 0 ] && {
        pause "Copying /etc to /etc.base1-post-apt-get";
        ssh -t $LOGIN sudo cp -a /etc/ /etc.base1-post-apt-get;
    }
}

showSeedTime() {
    echo "Time on seedhost: " $(ssh -t $LOGIN sudo su - -c "date")
    echo "Time on seedhost VM: " $(ssh -t $LOGIN sudo su - -c "ssh root@192.0.2.1 date")
    echo `date` $*
}

STEP3() {
    #[ -f /tmp/hp_ced_start_seed.sh.log ] &&
        #mv /tmp/hp_ced_start_seed.sh.log /tmp/hp_ced_start_seed.sh.log.1

    ssh -t $LOGIN virsh list --all | grep " seed " && {
        echo "Seed VM is already present";
        yesno "Continue to recreate VM?" "y" && exit 0
    }

    START_SEED_SH="/root/work/tripleo/tripleo-incubator/scripts/hp_ced_start_seed.sh"
    #SEED_LOG="/tmp/hp_ced_start_seed.sh.log"
    SEED_LOG="./hp_ced_start_seed.sh.log"

    pause "About to run $START_SEED_SH"
    time ssh -t $LOGIN sudo su - -c "bash -c 'id; echo HELLO; id; cd /root/work; bash -x $START_SEED_SH 2>&1'" | tee $SEED_LOG

    showSeedTime "Log saved locally at $SEED_LOG"

    [ $BACKUP_ETC -ne 0 ] && {
        pause "Copying /etc to /etc.postStep3-start-seed.sh";
        ssh -t $LOGIN sudo cp -a /etc/ /etc.postStep3-start-seed.sh;
    }
}

checkMachinesAreOff() {
    ./ipmitool.sh | grep "is on" && {
        echo; echo "Error: Some machines are still running";
        yesno "Stop machines" "y"
        if [ $? -ne 0 ];then
            ./ipmitool.sh -off;
        else
            echo; echo "Not stopping machines"; echo;
            sleep 5
            ./ipmitool.sh | grep "is on" || {
                die "Machines still running";
            }
        fi
    }

    # Redo the test as user may have stopped machines manually:
    ./ipmitool.sh | grep "is on"
    while [ $? -eq 0 ];do
        echo "Looping until all machines are off"
        sleep 5
        ./ipmitool.sh | grep "is on"
    done

    echo; echo "All machines are off"
    #exit 0
}

setBootToPXE() {
    echo; echo "Selecting PXE boot"
    ./ipmitool.sh -a chassis bootdev pxe
    echo
}

BAD_turnOffStrictHostKeyCheckingForSeedHost() {
    #Host seedvm
    #HostName 192.0.2.1
    #User root
    #StrictHostKeyChecking no
    #UserKnownHostsFile /dev/null

    ssh -t $LOGIN "sudo su - -c 'grep -q $VM_LOGIN /root/.ssh/config || { echo \"Adding <$VM_LOGIN> entry to seed:/root/.ssh/config\"; { echo; echo "Host seedvm"; echo "    HostName 192.0.2.1"; echo "    User root"; echo "    StrictHostKeyChecking no"; echo "    UserKnownHostsFile /dev/null"; echo; } >> /root/.ssh/config; cat /root/.ssh/config; }'";
    #exit 0
}

STEP4u() {
    export BM_NETWORK_SEED_IP=192.0.2.1
    export OVERCLOUD_NeutronPublicInterface="eth0"
    OPTS="--skip-seed"

    time vmCommand "bash -x ./seedvm_env.sh $OPTS 2>&1" | tee ./hp_ced_installer.sh.log
    showSeedTime "Finished[STEP4u] - exit code=$?"
}

STEP4o() {
    export BM_NETWORK_SEED_IP=192.0.2.1
    export OVERCLOUD_NeutronPublicInterface="eth0"
    OPTS="--skip-seed --skip-undercloud"

    time vmCommand "bash -x ./seedvm_env.sh $OPTS 2>&1" | tee ./hp_ced_installer.sh.log
    showSeedTime "Finished[STEP4o] - exit code=$?"
}

transferFiles() {
    echo "Creating files ..."
    create_seedvm_env_sh
    ls -altr seedvm_env.sh
    #ssh-keygen -R root@192.0.2.1 

    echo "Copying baremetal.csv to seedhost '$SEEDHOST':"
    rsync -av --progress baremetal.csv $SEEDHOST:
    #pause "Copy baremetal.csv to seedhost '$SEEDHOST'"

    echo "Transferring files ... to seedvm:"

    #ssh $LOGIN "sudo ssh $VM_LOGIN 'mkdir /root/.ssh; cat > /root/.ssh/config'" < seedvm_ssh.config
    ssh $LOGIN "sudo ssh $VM_LOGIN 'cat > seedvm_env.sh'" < seedvm_env.sh
    ssh $LOGIN "sudo ssh $VM_LOGIN 'cat > baremetal.csv'" < baremetal.csv
    ssh $LOGIN "sudo ssh $VM_LOGIN 'cat > undercloud.sh'" < undercloud.sh
    ssh $LOGIN "sudo ssh $VM_LOGIN 'chmod +x undercloud.sh'"
}

STEP4() {
    ## turnOffStrictHostKeyCheckingForSeedHost
    checkMachinesAreOff
    setBootToPXE

    transferFiles

    #vmCommand "source  seedvm_env.sh; env; env | grep OVER"
    time vmCommand "bash -x /root/seedvm_env.sh 2>&1" | tee ./hp_ced_installer.sh.log
    showSeedTime "Finished[STEP4] - exit code=$?"
}

waitForSeedVMToShutOff() {
    while [ true ];do
        echo "Checking SeedVM status ..."
        ssh -t $LOGIN virsh list --all | grep seed | grep "shut off" && break
        sleep 1
    done
    echo "SeedVM is shut off"
}

STEP_BAD() {
    pause "Shutdown VM and snapshot it"
    vmCommand shutdown -h 0

    waitForSeedVMToShutOff

    pause "Creating initial backup of SeedVM"
    echo "DISABLED: time cp -a /var/lib/libvirt/images/ var.lib.libvirt.images.2014-07-09-13h-SeedVM.initial"
    #time cp -a /var/lib/libvirt/images/ var.lib.libvirt.images.2014-07-09-13h-SeedVM.initial

    pause "Restarting seed VM"
    virsh start seed
}

################################################################################
# Testing routines:

TEST() {
    echo "vmCommand uptime"
    vmCommand uptime
}

TEST_REMOTE_COMMANDS() {
    # WORKS: both commands execute on seedvm: (\; necessary for 2nd):
    # vmCommand "ls -altr /var/log/upstart/os-collect-config.log\; hostname";

    # FAILS: hostname OK, following commands after logout:
    # vmCommand "hostname;cd;ls -altr /var/log/upstart/os-collect-config.log; hostname";

    # WORKS: all commands execute on seedvm: (\; necessary for 2nd ...):
    vmCommand "hostname\;cd\;ls -altr /var/log/upstart/os-collect-config.log\; hostname";

    # WORKS: all commands execute on seedvm: (\; necessary for 2nd ...):
    vmCommand "hostname\;cd\; ls -altr /var/log/upstart/os-collect-config.log\; hostname";

    # FAILS: hostname OK, following commands after logout:
    # vmCommand "hostname\;cd; ls -altr /var/log/upstart/os-collect-config.log; hostname";
}

################################################################################
# Main/Args:

[ $THIS_OS = "UNKNOWN" ] && die "Failed to determine OS of this machine"

waitOnNode

while [ ! -z "$1" ];do
    case $1 in
        -np) PROMPTS=0;;
        -p) PROMPTS=1;;

        # Run both steps 3 and step 4 in succession
        -34) STEP3; STEP4;;

        -0) STEP0;;
        -1) STEP1;;
        -2) STEP2;;
        -3) STEP3;;
        -4) STEP4;;
        -4u) STEP4u;;
        -4o) STEP4o;;
        -5) STEP5;;

        # tail log on seedvm:
        #NOTE: ; closes connection!
        --vmlog) vmCommand "tail -200f /var/log/upstart/os-collect-config.log";;
        # backslashing ; is ok:
        #-vmlog) vmCommand "cd\;tail -200f /var/log/upstart/os-collect-config.log";;

        # login to seedhost:
        #--seed) shift; ssh -t $LOGIN sudo "\"$*\""
        --seed) shift; [ -z "$1" ] && set -- bash; ssh -t $LOGIN "\"$*\"";;
        --seedroot) shift; [ -z "$1" ] && set -- bash; ssh -t $LOGIN "sudo '$*'";;
        #--seedroot) shift; [ -z "$1" ] && set -- bash; ssh -t $LOGIN "sudo sh -- '$*'";;
        #--seedroot) shift; ssh -t $LOGIN "sudo sh -- '$*'";;

        # login to seedvm:
        --vm) shift; vmCommand $*;;

        # login to undercloud:
        --under) shift; undercloudCommand "$*";;
        --underroot) undercloudCommand "sudo sh -";;
        #-under) shift; vmCommand ssh -t heat-admin@192.0.2.2 "$*";;
        #-underroot) vmCommand ssh -t heat-admin@192.0.2.2 "sudo sh -";;

        # do nova list from seedvm of undercloud:
        --underlist) vmCommand sudo su - -c "bash -c 'id; hostname; id; cd /root/; . stackrc; nova list'";;

        # do nova list from undercloud of overcloud:
        --tfr) transferFiles;;
        --over-nova-ip)
            transferFiles;
            undercloudCommand --over-nova-ip;
            ;;
        --overlist)
            transferFiles;
            #undercloudCommand --novalist;
            undercloudCommand ". /root/stackrc\; nova list";
            ;;

        #--over) undercloudCommand  ssh overcloud ????;;

        #--overlist) vmCommand ssh -t heat-admin@192.0.2.2 sudo su - -c "bash -c 'hostname; hostname; id; hostname; id; ip a; ls -altr /root; source /root/stackrc && nova list'";;

        #--overlist) vmCommand ssh -t heat-admin@192.0.2.2 sudo su - -c "bash -c 'hostname; id; hostname; id; ip a; ls -altr /root; source /root/stackrc && nova list'";;


        #--overlist) vmCommand ssh -t heat-admin@192.0.2.2 "sudo sh - -c 'bash -c \"source /root/stackrc && nova list\"'";;
        #--overlist) vmCommand ssh -t heat-admin@192.0.2.2 "sudo sh - -c 'source /root/stackrc && nova list'";;
        -underck) vmCommand ssh -t heat-admin@192.0.2.2 "sudo bash -c 'hostname; ip a; ls -altr /root; cksum /root/stackrc'";;
        -underrc) vmCommand ssh -t heat-admin@192.0.2.2 "sudo bash -c 'hostname; ip a; ls -altr /root; source /root/stackrc && env | grep OS_'";;

        #--overcloud) vmCommand ssh -t heat-admin@192.0.2.2 "source stackrc && nova list";;
        --overcloud) vmCommand ssh -t heat-admin@192.0.2.2 ". stackrc && nova list";;

        -t1) TEST_REMOTE_COMMANDS;;
        -t) TEST;;
        *) die "Unknown option '$1'";;
    esac
    shift
done

exit 0


