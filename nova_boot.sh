#!/usr/bin/bash

VERBOSE=1
PROMPTS=0

LOGFILE=/tmp/LAUNCHER.sh.log

exec &> >(tee "$LOGFILE")
echo "Running nova version: " $(nova --version 2>&1)

# USER: Used to identify network names ... (TODO: and instances ...)
USER="MIKE"

# ext-net:
# NETWORKS_ARG="--nic net-id=f7fdbec6-6c18-48ab-af8a-4ec32e61a2d5"

# default-net:
NETWORKS_ARG="--nic net-id=dcf015a6-001d-4c7a-a07b-a4ab792a44ba"

NUM_NETWORKS=2

NUM_INSTANCES=1
NUM_INSTANCES_ARG=""
[ $NUM_INSTANCES -gt 1 ] && NUM_INSTANCES_ARG="--num-instances $NUM_INSTANCES"

################################################################################
# Functions:

function die {
    echo "die: $0 - $*" >&2
    myexit 1
}

function myexit {
    SAVED_LOGFILE=${LOGFILE}_$(date +%Y%m%d_%H%M%S)
    echo "Logged output to '$SAVED_LOGFILE'" >&2
    exit $1
}

function yesno {
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

function prompt {
    echo $*
    [ $PROMPTS -eq 0 ] && return 1
    echo "Press <return> to continue"
    read resp
    [ \( "$resp" = "q" \) -o \( "$resp" = "Q" \) ] && exit 0
}

function perlMATCHic {
    __TEST="$1" __REGEX="$2" perl -e '
        if ($ENV{__TEST} =~ /$ENV{__REGEX}/i) { exit(0); } else { exit(1); }
           #{ exit(0); } else { exit(1); }
           #{ print "$ENV{__TEST} =~ /$ENV{__REGEX}/i\n"; exit(0); } else {
           #{ print "$ENV{__TEST} !~ /$ENV{__REGEX}/i\n"; exit(1); }
    '
    return $?
}

function perlMATCH {
    __TEST="$1" __REGEX="$2" perl -e '
        if ($ENV{__TEST} =~ /$ENV{__REGEX}/) { exit(0); } else { exit(1); }
           #{ exit(0); } else { exit(1); }
           #{ print "$ENV{__TEST} =~ /$ENV{__REGEX}/i\n"; exit(0); } else {
           #{ print "$ENV{__TEST} !~ /$ENV{__REGEX}/i\n"; exit(1); }
    '
    return $?
}

function OP {
    [ $VERBOSE -ne 0 ] && echo "DEBUG: $*"
    prompt
    $*
    RET=$?
    #[ $VERBOSE -ne 0 ] && echo "VERBOSE=$VERBOSE"
    #[ $RET -ne 0 ] && echo "RET=$RET"
    [ $VERBOSE -ne 0 ] && [ $RET -ne 0 ] && echo "Returned $RET"
    [ $RET -ne 0 ] && die "Returned $RET: $*"
}

function DELETE_ALL_MATCHING {
    MATCH=$1; shift;

    OP nova delete $(nova list | grep $MATCH | awk -F'|' '{print $2;}')
}

function getTableRow {
    ROW=$1; shift # Counting 1 as 1st table entry
    #let ROW=ROW+1

    ROW=$ROW perl -ne '
        if (!/^\|/) { #print "IGNORE[$row]=$_";
            next;
        };
        $row++;

        if ($row == $ENV{ROW}) {
            #print "$row: $_";
            print $_;
        }'
    #grep "^|" | head -$ROW | tail -1
}

function getTableField {
    ROW=$1;   shift # Counting 1 as 1st table entry
    FIELD=$1; shift # Counting 1 as 1st field
    #let ROW=ROW+1
    #let FIELD=FIELD-1

    FIELD=$FIELD ROW=$ROW perl -ne '
        if (!/^\|/) { #print "IGNORE[$row]=$_";
            next;
        };
        $row++;

        if ($row == $ENV{ROW}) {
            @FIELDS = split(/\s*\|\s*/, $_);
            $field=$ENV{FIELD};
            #print "$row,$field : $FIELDS[$field]";
            print $FIELDS[$field];
        }'
}

################################################################################
# Other functions:

function downloadAlphaCoreOS {
    wget http://alpha.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2
    bunzip2 coreos_production_openstack_image.img.bz2
}

function glanceCreate {
    [ $IMAGE != "coreos" ] && die "Not implemented yet for image '$IMAGE'"

    glanceCoreOSCreate
}

function glanceCoreOSCreate {
    OP glance image-create --name coreos \
      --container-format bare \
      --disk-format qcow2 \
      --file coreos_production_openstack_image.img \
      --is-public True

    OP glance image-list
}

function imageBoot {
    IMAGE=$1; shift;

    IMAGE_ID=$(glance image-list | grep $IMAGE | getTableField 1 1)
    echo "COREOS uuid=$IMAGE_ID"

    OP nova keypair-list # >/dev/null 2>&1

    OP nova keypair-list | grep $KEYPAIR_NAME && {
        echo "$KEYPAIR_NAME keypair already installed";
    } || {
        pushd ~/.ssh/
            KEYPAIR_PUB_FILENAME=${KEYPAIR_PUB##*/}
            OP nova keypair-add --pub_key $KEYPAIR_PUB_FILENAME $KEYPAIR_NAME
        popd
    }

    BOOT_INFO_FILE=/tmp/imageBoot.$$

    OP nova list | grep $DEFAULT_INSTANCE_NAME && {
	INSTANCE_NAME=${DEFAULT_INSTANCE_NAME}_$(date +%Y%m%d_%H%M%S)
    }
    echo INSTANCE_NAME=$INSTANCE_NAME
    [ -z "$INSTANCE_NAME" ] && die "Failed to retrieve \$INSTANCE_NAME"

    USER_DATA=""
    [ $IMAGE = "coreos" ] && {
        USER_DATA="--user-data ./coreos-config.yaml";
    }

    OP nova boot \
        --image $IMAGE_ID \
        --key-name $KEYPAIR_NAME \
        --flavor $FLAVOR \
        $USER_DATA \
        $NUM_INSTANCES_ARG \
        $NETWORKS_ARG \
        --security-groups default $INSTANCE_NAME | tee $BOOT_INFO_FILE

   IMAGE_ID=$(grep -i "^| id " $BOOT_INFO_FILE | awk -F'|' '{ print $3; }')
   IMAGE_ID=${IMAGE_ID# *}
   echo "IMAGE_ID=$IMAGE_ID"
   [ -z "$IMAGE_ID" ] && die "Failed to retrieve \$IMAGE_ID"
   
   set +x
}

function getDiscoveryToken {
    #curl -w n https://discovery.etcd.io/new
    TOKEN=$(curl -w "\n" https://discovery.etcd.io/new  2>/dev/null | sed 's/.*\///')
    cp coreos-config.yaml.template c.yaml
    grep token c.yaml 
    sed -ibak "s/<token>/$TOKEN/" c.yaml
    grep token c.yaml
}

function waitOnPort {
    HOST=$1; shift;
    PORT=$1; shift;

    SLEEP=5
    WAIT=5

    while ! nc -v -w $WAIT $HOST $PORT </dev/null >/dev/null 2>&1; do
        set -x; nc -v -w $WAIT $HOST $PORT </dev/null ; set +x
        echo "Retrying ... $HOST:$PORT"; sleep $SLEEP;
    done
}

function whichFloatingIPFieldForIP {
    HEADER="$1"; shift
    FIELD=0

    #echo "Nova version: " $(nova --version)

    EXP_HEADER=".*Id.*IP.*Server Id.*Fixed IP.*Pool.*"
    if perlMATCHic "$HEADER" "$EXP_HEADER";then
       #echo BINGO on Windows-2.2
       FIELD=4
    else
        #  | Ip | Server Id | Fixed Ip | Pool |
        EXP_HEADER=".*Ip.*Server Id.*Fixed Ip.*Pool.*"
        if perlMATCHic "$HEADER" "$EXP_HEADER";then
           #echo BINGO on Linux-version2.1.7
           FIELD=2
        else
           die "UNKNOWN Header version: '$HEADER'"
        fi
    fi
}

function getFloatingIP {
    #FREE_IP=$(nova floating-ip-list | grep ext-net | grep " - " | head -1 | awk '{ print $2;}');
    #FREE_IP=$(nova floating-ip-list | grep ext-net | grep " - " | head -1 | awk '{ print $4;}');

    FIELD=0
    saveIFS=$IFS
    IFS=$'\n'
    LINES=( $(nova floating-ip-list | grep '^|') )
    IFS=$saveIFS
    #let N=${#LINES[@]}-1
    #for i in $(seq 0 $N); do echo $i. ${LINES[$i]}; done

    HEADER=${LINES[0]}
    whichFloatingIPFieldForIP "$HEADER"
    ## nova floating-ip-list | head
    ## echo "USE field $FIELD"

    FREE_IP=$(nova floating-ip-list | grep ext-net | grep " - " | head -1 | awk "{ print \$$FIELD;}");
    echo "IMAGE_ID=$IMAGE_ID"
    echo "FREE_IP=$FREE_IP"
    #die "TO FIX - same on Windows and Linux????"
    OP nova list
    OP nova floating-ip-associate $IMAGE_ID $FREE_IP
    OP nova keypair-list
    OP nova list | grep $IMAGE_ID
}

function testSSH {
    waitOnPort $FREE_IP 22
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R ${FREE_IP}

    KEYPAIR_FILE=${KEYPAIR_PUB%.pub}
    SCP="scp -oStrictHostKeyChecking=no -i $KEYPAIR_FILE"
    SSH="ssh -oStrictHostKeyChecking=no -i $KEYPAIR_FILE ${USER_LOGIN}@${FREE_IP}"

    #echo "echo yes | $SSH uptime"
    # set -x
    echo yes | $SSH uptime

    if [ $IMAGE = "coreos" ];then
        $SCP local.etc.resolv.conf ${USER_LOGIN}@${FREE_IP}:/tmp/resolv.conf.local
        $SSH "cd /etc; [ ! -f resolve.conf.bak ] && { sudo cp resolv.conf resolv.conf.bak; sudo cp /tmp/resolv.conf.local resolv.conf; }"
        $SSH "cd /etc; cat resolv.conf; ls -altr /etc/resolv.conf"
        $SSH "ping -w 1 -c 1 www.google.com; docker search hadoop"
        $SSH "docker ps -a; docker run -it base bash; bash"
    fi
}

function TEST0 {
    imageBoot $IMAGE
    getFloatingIP
    testSSH
    exit 0
}

function TEST1_cirros {
    chooseCirros
    imageBoot $IMAGE
    getFloatingIP
    testSSH
    exit 0
}

function TEST2_multiplenetworks {
    CREATE_TEST_NETWORKS
    imageBoot $IMAGE
    getFloatingIP
    testSSH
    exit 0
}

function TEST3_JPC {

    chooseCirros

    NUM_INSTANCES=4; NUM_INSTANCES_ARG="--num-instances $NUM_INSTANCES"
    NUM_NETWORKS=4
    CREATE_TEST_NETWORKS

    imageBoot $IMAGE
    getFloatingIP
    testSSH
    exit 0
}

function chooseCoreos {
    IMAGE="coreos"
    FLAVOR=m1.small;
    DEFAULT_INSTANCE_NAME=coreos;
    INSTANCE_NAME=$DEFAULT_INSTANCE_NAME;

    KEYPAIR_PUB=$HOME/.ssh/coreos_rsa.pub
    KEYPAIR_NAME=coreos
    #USER_LOGIN=coreos # ??
    USER_LOGIN=core # ??
}

function chooseCirros {
    IMAGE="cirros";
    FLAVOR=m1.tiny;
    DEFAULT_INSTANCE_NAME=cirros;
    INSTANCE_NAME=$DEFAULT_INSTANCE_NAME;

    KEYPAIR_PUB=$HOME/.ssh/myos_rsa.pub
    KEYPAIR_NAME=mjb
    USER_LOGIN=cirros
}

function CREATE_TEST_NETWORKS {
  OP neutron ext-list

  TEST_NETWORK_BASENAME="${USER}TESTNET"
  TEST_SUBNETWORK_BASENAME="${USER}TESTSUBNET"

  NETWORK_NAMES=$(neutron net-list | awk '/^\|/ && (NR > 2) {print $4;}')
  SUBNETWORK_NAMES=$(neutron subnet-list | awk '/^\|/ && (NR > 2) {print $4;}' | grep -v '^|')
  echo "Found " $(echo $NETWORK_NAMES    | wc -w) "               networks"
  echo "Found " $(echo $SUBNETWORK_NAMES | wc -w) "            subnetworks"
  #echo "Found " $(echo $NETWORK_NAMES    | grep $TEST_NETWORK_BASENAME    | wc -w) "       test    networks matching '$TEST_NETWORK_BASENAME'"
  #echo "Found " $(echo $SUBNETWORK_NAMES | grep $TEST_SUBNETWORK_BASENAME | wc -w) "       test subnetworks matching '$TEST_SUBNETWORK_BASENAME'"

  NETWORK_NAMES=$(neutron net-list       | awk '/^\|/ && (NR > 2) {print $4;}' | grep $TEST_NETWORK_BASENAME )
  SUBNETWORK_NAMES=$(neutron subnet-list | awk '/^\|/ && (NR > 2) {print $4;}' | grep -v '^|' | grep $TEST_SUBNETWORK_BASENAME )

  #echo "\$NETWORK_NAMES=$NETWORK_NAMES"
  #echo "\$SUBNETWORK_NAMES=$SUBNETWORK_NAMES"
  echo "Found " $(echo $NETWORK_NAMES    | wc -w) "       test    networks matching '$TEST_NETWORK_BASENAME'"
  echo "Found " $(echo $SUBNETWORK_NAMES | wc -w) "       test subnetworks matching '$TEST_SUBNETWORK_BASENAME'"

  for NET in $(seq 1 $NUM_NETWORKS); do
      NETWORK_NAME=${TEST_NETWORK_BASENAME}${NET}

      #OP neutron net-list | grep $NETWORK_NAME || {}
      echo $NETWORK_NAMES | grep -q $NETWORK_NAME  || {
          OP neutron net-create --tenant-id admin $NETWORK_NAME
      }

      SUBNET=192.168.1${NET}.0/24
      SUBNETWORK_NAME=${TEST_SUBNETWORK_BASENAME}${NET}
      #OP neutron subnet-list | grep $SUBNETWORK_NAME || {}
      echo $SUBNETWORK_NAMES | grep -q $SUBNETWORK_NAME  || {
          #echo "echo $SUBNETWORK_NAMES | grep -q $SUBNETWORK_NAME ==> " $(echo $SUBNETWORK_NAMES | grep -q $SUBNETWORK_NAME | wc -l)
          OP neutron subnet-create ${NETWORK_NAME} $SUBNET --name $SUBNETWORK_NAME
      }

      NETWORK_ID=$(neutron net-show $NETWORK_NAME | grep " id " | awk '{print $4;}')
      [ -z "$NETWORK_ID" ] && die "Failed to created network <$NETWORK_ID>"

      NETWORKS_ARG+=" --nic net-id=$NETWORK_ID"
  done

  #NETWORKS_ARG="--nic net-id=TESTNET1 --nic net-id=TESTNET2 --nic net-id=TESTNET3 --nic net-id=TESTNET4"
}

################################################################################
# Args:
#set -x

env | grep OS_USERNAME || die "OS_USERNAME is not set"

DOWNLOAD=0
UPLOAD=0
DELETE_ALL=0
BOOT=0

ACTIONS=""

# DEFAULTS:
FLOATING=0
TEST_SSH=0
[ -z "$1" ] && set -- -v -image coreos -boot -fip -ssh

chooseCoreos

while [ ! -z "$1" ];do
    case $1 in
        -v*) let VERBOSE=VERBOSE+${#1}-1;;

        -TEST0) ACTIONS="TEST0" ;;
        -TEST1) ACTIONS="TEST1_cirros" ;;
        -TEST2) ACTIONS="TEST2_multiplenetworks" ;;
        -TEST3) ACTIONS="TEST3_JPC" ;;

        -down) DOWNLOAD=1;;
        -up) UPLOAD=1;;

        -demo) PROMPTS=1;;

        -I|--instances)  shift; NUM_INSTANCES=$1; NUM_INSTANCES_ARG="--num-instances $NUM_INSTANCES";;
        -N|--networks)   shift; NUM_NETWORKS=$1;;

        -delete) DELETE_ALL=1;;

        -cirros)  chooseCirros;;

        -image)  shift; IMAGE=$1;;
        -boot)   ACTIONS="BOOT"; BOOT=1;;
        -fip)   FLOATING=1;;
        -ssh)   [ ! -z "$1" ] && { FREE_IP=$1; shift; }
                TEST_SSH=1;;

        *) die "Unknown option '$1'";;
    esac
    shift
done

################################################################################
# Main:

[ -z "$ACTIONS" ] && {
    imageBoot $IMAGE;
    getFloatingIP;
    testSSH;
}

for ACTION in $ACTIONS;do
    case $ACTIONS in
        TEST0) TEST0;;
        TEST1_cirros) TEST1_cirros;;
        TEST2_multiplenetworks) TEST2_multiplenetworks;;
        TEST3_JPC) TEST3_JPC;;
        BOOT) echo BOOT;;
        *) die "Unknown ACTION: $ACTION";;
    esac
done

[ $DOWNLOAD -ne 0 ] && downloadAlphaCoreOS
[ $UPLOAD -ne 0 ]   && { OP glance image-list; glanceCreate; }

[ $DELETE_ALL -ne 0 ] && DELETE_ALL_MATCHING $IMAGE

[ $BOOT -ne 0 ] && imageBoot $IMAGE

[ $FLOATING -ne 0 ] && getFloatingIP
[ $TEST_SSH -ne 0 ] && testSSH

myexit 0

