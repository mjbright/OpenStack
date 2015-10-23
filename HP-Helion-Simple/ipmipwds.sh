
SUBNET=192.168.50

die() {
    echo "$0: die - $*" >&2
    exit 1
}

#ENC1_IP=$(seq 20 35)
#ENC2_IP=$(seq 50 65)
ENC1_IP=$(seq 20 35)
ENC2_IP="$(seq 50 55) $(seq 57 60)"

VERBOSE=0
TEST_IP=""

groupStatus() {
    GROUP_NAME=$1; shift
    USER=$1; shift
    PASS=$1; shift
    SUBNET=$1; shift
    RANGE=$*

    echo "$GROUP_NAME: $SUBNET.<<$RANGE>>"
    for IP in $RANGE;do
      ip=${SUBNET}.${IP} 

      testIPMI $ip $USER $PASS
      #IPMI_CMD="ipmitool -I lanplus -H $ip -U $USER -P $PASS power status"
      #IPMI_OP=$($IPMI_CMD 2>/dev/null)
      #[ $? -eq 0 ] && echo "[$IP]: $IPMI_OP" \
      #             || echo "[$IP]: Failed to connect to IPMI" 
    done
   
}

testIPMI() {
    ip=$1; shift
    USER=$1; shift
    PASS=$1; shift

    IPMI_CMD="ipmitool -I lanplus -H $ip -U $USER -P $PASS power status"
    [ $VERBOSE -gt 0 ] && echo $IPMI_CMD
    $IPMI_CMD
    RET=$?
    [ $VERBOSE -gt 0 ] && echo $RET

    IPMI_OP=$($IPMI_CMD 2>/dev/null)
    RET=$?
    [ $RET -eq 0 ] && echo "[$ip]: $IPMI_OP" \
                   || echo "[$ip]: Failed to connect to IPMI" 
    return $RET
}

test_ALL() {
    USER=Administrator
    PASS=GHYF92CV
    groupStatus "Enclosure1" $USER $PASS $SUBNET $ENC1_IP 
    groupStatus "Enclosure2" $USER $PASS $SUBNET $ENC2_IP
}


testPASS() {
    TEST_IP=$1; shift

    LOGINS="
        Administrator/GHYF92CV
        root/kpnpockpn
        hpinvent/HPpoc2015
        hp/hp1vent
        hp/hp1nvent
        hp/hpinvent
        Administrator/FHSXE32U
        Administrator/92D4CP0Q
        Administrator/92D4CPOQ
        Administrator/K5JXJDY7
        Administrator/2K4CUHDM
        Administrator/9A2T5T32
        Administrator/FRJS62D2
        Administrator/F3T3JM7S
    "

    for LOGIN in $LOGINS;do
        USER=${LOGIN%%/*}
        PASS=${LOGIN##*/}

        #echo "$USER-$PASS"
        IP=23
        [ ! -z "$TEST_IP" ] && IP=$TEST_IP
        #IP=24
        ip=${SUBNET}.${IP} 
    
        #IPMI_CMD="ipmitool -I lanplus -H $ip -U $USER -P $PASS power status"
        echo testIPMI $ip $USER $PASS
        testIPMI $ip $USER $PASS
        RET=$?
        #[ $RET -eq 0 ] && break
        [ $RET -eq 0 ] && {
            echo "-- $RET ---- PASSWORD[$PASS] --";
            break;
        }

        sleep 1
    done
}

################################################################################
# Args:

while [ ! -z "$1" ];do
    case $1 in
        -v)     VERBOSE=1;;
        [0-9]*) TEST_IP=$1;;
        *)      die "Unknown option <<$1>>";;
    esac
    shift
done

################################################################################
# Main:

testPASS $TEST_IP

exit 0

echo $ENC1_IP
echo $ENC2_IP


for IP in $ENC1_IP;do
  ip=${SUBNET}.${IP} 
  ipmitool -I lanplus -H $ip -U $USER -P $PASS power status 2>/dev/null ||
     echo "Failed $ip"
done

for IP in $ENC2_IP;do
  ip=${SUBNET}.${IP} 
  ipmitool -I lanplus -H $ip -U $USER -P $PASS power status 2>/dev/null ||
     echo "Failed $ip"
done

exit

#IP=60; ipmitool -I lanplus -H 192.168.50.$IP -U Administrator -P GHYF92CV power status


