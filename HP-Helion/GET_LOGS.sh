#1/bin/bash

HOST=$(hostname)

NAME=${HOST}

SCRIPT=/tmp/GET_LOGS.sh

SEEDHOST=10.3.160.10
SEEDNAME=helionseed
SEED_USER=user

SEEDVM=10.3.160.6
VM_LOGIN=root@$SEEDVM

LOG_DIRS="/var/log/upstart"
CFG_DIRS="/etc"
TMP=/tmp

TAR_LOGS=0
TAR_CFG=0
INSTALL=0

################################################################################
# Fns:

die() {
    echo "FAIL[$HOST]: $0 - $*" >&2
    exit 1
}

info() {
    echo "INFO[$HOST]: $0 - $*" >&2
}

getTableRow() {
    let _IDX=1+$1
    grep "^|"  | head -$_IDX | tail -1
}

getUndercloudIP() {
    UCIP=$(ssh $VM_LOGIN ". stackrc; nova list | grep undercloud-undercloud | sed -e 's/.*ctlplane=//' -e 's/ .*//'")
    #echo "Undercloud IP=$UCIP" >&2
}

showOvercloudNodes() {
    ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} 'sudo su - -c \". stackrc; nova list\"'" 2>/dev/null
}

getOvercloudIPs() {
    OCIPS=()
    OCNAMES=()
    #declare -A OCNAMES
    #ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} 'sudo su - -c \". stackrc; nova list\"'" 2>/dev/null |
        while read -r LINE; do
            [ "$LINE" != "${LINE##*ctlplane=}" ] && {
                _OCIP=$( echo $LINE | sed -e 's/.*ctlplane=//' -e 's/ .*//' )
                _OCNAME=$( echo $LINE | awk '{ print $4; }')
                OCIPS+=( $_OCIP )
                OCNAMES+=( $_OCNAME )
                #echo LINE=$LINE;
                #echo "OCIP=$_OCIP"
                #echo "${OCIPS[@]}"
                #echo "${#OCIPS[@]}"
            }
        done < <(ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} 'sudo su - -c \". stackrc; nova list\"'" 2>/dev/null)

   #echo $OCIPS
   #echo "\$OCIPS[${#OCIPS[@]}]=( ${OCIPS[@]} )" >&2
   echo "\$OCIPS[${#OCIPS[@]}]= ${OCIPS[@]} " >&2
}

installScript() {
   #FROM seedhost to seedvm to HOST

   scp $0 $VM_LOGIN:$SCRIPT
   getUndercloudIP

   #echo "=======DISABLED:========"
   echo ssh $VM_LOGIN "sudo su - -c 'scp $SCRIPT heat-admin@$UCIP:$SCRIPT'"
   ssh -t $VM_LOGIN "sudo su - -c 'scp $SCRIPT heat-admin@$UCIP:$SCRIPT'"

   getOvercloudIPs

   for OCIP in ${OCIPS[@]};do
       echo ssh $VM_LOGIN "sudo su - -c 'scp $SCRIPT heat-admin@$OCIP:$SCRIPT'"
       ssh -t $VM_LOGIN "sudo su - -c 'scp $SCRIPT heat-admin@$OCIP:$SCRIPT'"
       #ssh -t $VM_LOGIN "sudo su - -c 'ssh heat-admin@$OCIP ls -altr $SCRIPT'"
   done
}

getLogsFromSeedVM() {
    BASH_X="bash -x"
    BASH_X="bash"

    echo;echo "-- creating logs.tbz2 on seedvm"
    ssh -t $VM_LOGIN "$BASH_X $SCRIPT -tarlogs"
    echo;echo "-- recuperating logs.tbz2 from seedvm"
    scp $VM_LOGIN:/tmp/logs.tbz2 $TMP/seedvm.logs.tbz2
}

getConfigFromSeedVM() {
    BASH_X="bash -x"
    BASH_X="bash"

    echo;echo "-- creating cfg.tbz2 on seedvm"
    ssh -t $VM_LOGIN "$BASH_X $SCRIPT -tarcfg"
    echo;echo "-- recuperating cfg.tbz2 from seedvm"
    scp $VM_LOGIN:/tmp/cfg.tbz2 $TMP/seedvm.cfg.tbz2
}

getLogsFromUndercloudNode() {
    BASH_X="bash -x"
    BASH_X="bash"

    getUndercloudIP
    echo;echo "-- creating logs.tbz2 on undercloud[$UCIP]"
    #ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} $BASH_X '$SCRIPT -tarlogs'"
    ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} $BASH_X '$SCRIPT -tarlogs'"
    #ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} 'echo HERE on $UCIP'"
    #ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} '$SCRIPT'"
    #ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} '$SCRIPT -tarlogs'"
    echo;echo "-- recuperating logs.tbz2 from undercloud"
    set -x
    ssh -t $VM_LOGIN "sudo su - -c 'scp -3 heat-admin@${UCIP}:/tmp/logs.tbz2 ${SEED_USER}@${SEEDHOST}:$TMP/undercloud.logs.tbz2'"
#exit 0
    #ssh -t $VM_LOGIN "sudo su - -c 'scp heat-admin@${UCIP}:/tmp/logs.tbz2 root@${SEEDHOST}:$TMP/undercloud.logs.tbz2'"
}

getConfigFromUndercloudNode() {
    BASH_X="bash -x"
    BASH_X="bash"

    getUndercloudIP
    echo;echo "-- creating cfg.tbz2 on undercloud[$UCIP]"
    #ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} $BASH_X '$SCRIPT -tarcfg'"
    ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} $BASH_X '$SCRIPT -tarcfg'"
    #ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} 'echo HERE on $UCIP'"
    #ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} '$SCRIPT'"
    #ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} '$SCRIPT -tarcfg'"
    echo;echo "-- recuperating cfg.tbz2 from undercloud"
    ssh -t $VM_LOGIN "sudo su - -c 'scp -3 heat-admin@${UCIP}:/tmp/cfg.tbz2 ${SEED_USER}@${SEEDHOST}:$TMP/undercloud.cfg.tbz2'"
    #ssh -t $VM_LOGIN "sudo su - -c 'scp heat-admin@${UCIP}:/tmp/cfg.tbz2 root@${SEEDHOST}:$TMP/undercloud.cfg.tbz2'"
}

getLogsFromOvercloudNodes() {
    BASH_X="bash -x"
    BASH_X="bash"

    IDX=0
    for OCIP in ${OCIPS[@]};do
       OCNAME=${OCNAMES[$IDX]}
       let IDX=IDX+1

       echo;echo "-- creating logs.tbz2 on overcloud[$OCIP - $OCNAME]"
       ssh -t $VM_LOGIN "ssh heat-admin@${OCIP} $BASH_X '$SCRIPT -tarlogs'"

       echo;echo "-- recuperating logs.tbz2 from overcloud[$OCIP - $OCNAME]"
       ssh -t $VM_LOGIN "sudo su - -c 'scp -3 heat-admin@${OCIP}:/tmp/logs.tbz2 ${SEED_USER}@${SEEDHOST}:$TMP/${OCNAME}.logs.tbz2'"
       #ssh -t $VM_LOGIN "sudo su - -c 'ssh heat-admin@$OCIP ls -altr $SCRIPT'"
    done
    #ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} '$SCRIPT -tarlogs'"
    #ssh -t $VM_LOGIN "scp heat-admin@${UCIP}:/tmp/logs.tbz2 root@${SEEDHOST}:$TMP/undercloud.logs.tbz2"
}

getConfigFromOvercloudNodes() {
    BASH_X="bash -x"
    BASH_X="bash"

    IDX=0
    for OCIP in ${OCIPS[@]};do
       OCNAME=${OCNAMES[$IDX]}
       let IDX=IDX+1

       echo;echo "-- creating cfg.tbz2 on overcloud[$OCIP - $OCNAME]"
       ssh -t $VM_LOGIN "ssh heat-admin@${OCIP} $BASH_X '$SCRIPT -tarcfg'"

       echo;echo "-- recuperating cfg.tbz2 from overcloud[$OCIP - $OCNAME]"
       ssh -t $VM_LOGIN "sudo su - -c 'scp -3 heat-admin@${OCIP}:/tmp/cfg.tbz2 ${SEED_USER}@${SEEDHOST}:$TMP/${OCNAME}.cfg.tbz2'"
       #ssh -t $VM_LOGIN "sudo su - -c 'ssh heat-admin@$OCIP ls -altr $SCRIPT'"
    done
    #ssh -t $VM_LOGIN "ssh heat-admin@${UCIP} '$SCRIPT -tarcfg'"
    #ssh -t $VM_LOGIN "scp heat-admin@${UCIP}:/tmp/cfg.tbz2 root@${SEEDHOST}:$TMP/undercloud.cfg.tbz2"
}

getLogsFromRemoteNodes() {
        echo "getLogsFromRemoteNodes: RUNNING from SEEDHOST [$SEEDNAME]"
        getLogsFromSeedVM
        getLogsFromUndercloudNode
        showOvercloudNodes
        getOvercloudIPs
        getLogsFromOvercloudNodes
}

getConfigFromRemoteNodes() {
        echo "getConfigFromRemoteNodes: RUNNING from SEEDHOST [$SEEDNAME]"
        getConfigFromSeedVM
        getConfigFromUndercloudNode
        showOvercloudNodes
        getOvercloudIPs
        getConfigFromOvercloudNodes
}

getUOstackrc() {
   scp -3 $VM_LOGIN:stackrc           mjb@10.3.3.117:undercloud.stackrc
   scp -3 $VM_LOGIN:overcloud.stackrc mjb@10.3.3.117:overcloud.stackrc
}

################################################################################
# Args:

#[ -z "$1" ] && die "No arguments provided"
[ "$1" = "-name" ] && {
        shift; TMP=/tmp/$1; set -x; mkdir -p $TMP; chown $SEED_USER $TMP; set +x;
        echo "ARGS='$*'"
        shift;
        echo "ARGS='$*'"
}

#[ -z "$1" ] && set -- -install -tarlogs
[ -z "$1" ] && 
    set -- -seedkey -install -tarlogs -tarcfg

echo "WHILE ARGS='$*'"
while [ ! -z "$1" ];do
    case $1 in

        -stackrc) getUOstackrc;;

        -tarlogs) TAR_LOGS=1;;
        -tarcfg) TAR_CFG=1;;
        -install) INSTALL=1;;
        -seedkey)
             echo "Installing key from root@${SEEDVM} to ${SEED_USER}@${SEEDHOST}"
             grep -q "^${SEEDHOST} " /home/$SEED_USER/.ssh/known_hosts || {
                 echo "Removing existing key from known_hosts";
                 set -x; sed -i.bak "/^${SEEDHOST}/d" /home/$SEED_USER/.ssh/known_hosts set +x;
             }

             grep -q "root@hLinux$" /home/$SEED_USER/.ssh/authorized_keys || {
                 echo "Removing existing key from authorized_keys";
                 set -x; sed -i.bak "/root@hLinux$/d" /home/$SEED_USER/.ssh/authorized_keys; set +x
             }

               #ssh -t $VM_LOGIN "sudo su - -c 'ssh-copy-id ${SEED_USER}@${SEEDHOST}'"
             set -x; ssh -t $VM_LOGIN "ssh-copy-id ${SEED_USER}@${SEEDHOST}"; set +x;
             ;;

        *) die "Unknown option '$*'";;
    esac
    shift
done

################################################################################
# Main:

[ $INSTALL -eq 1 ] && {
    installScript;
    #exit 0;
}

[ $TAR_LOGS -eq 1 ] && {
    #echo "if [ '$HOST' = '$SEEDNAME' ];then"
    if [ "$HOST" = "$SEEDNAME" ];then
        getLogsFromRemoteNodes
        #exit 0
    else
        set -x
        info "Creating tar of $LOG_DIRS";
        sudo tar cf - $LOG_DIRS | bzip2 -9 > /tmp/logs.tbz2;
        ls -altr /tmp/logs.tbz2 >&2
        #tar cf - $LOG_DIRS | bzip2 -9 > /tmp/${NAME}.logs.tbz2;
    fi
}

[ $TAR_CFG -eq 1 ] && {
    if [ "$HOST" = "$SEEDNAME" ];then
        getConfigFromRemoteNodes
        #exit 0
    else
        info "Creating tar of $CFG_DIRS";
        sudo tar cf - $CFG_DIRS | bzip2 -9 > /tmp/cfg.tbz2;
        #tar cf - $CFG_DIRS | bzip2 -9 > /tmp/${NAME}.cfg;
    fi
}

