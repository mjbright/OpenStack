#!/bin/bash

set -o nounset # Force error on unset variables
#source env_vars
. ./env_vars
. ./VARS


./ipmitool.sh off

cd /root

#ip addr del $BM_SEEDHOST/24 dev brbm
#ovs-vsctl del-port $BRIDGE_INTERFACE
#ovs-vsctl del-br brbm
#ip addr add $BM_SEEDHOST/24 dev $BRIDGE_INTERFACE scope global
#route add default gw $BM_GATEWAY dev $BRIDGE_INTERFACE

virsh destroy seed
virsh undefine seed

/root/tripleo/tripleo-incubator/scripts/hp_ced_host_manager.sh --create-seed
