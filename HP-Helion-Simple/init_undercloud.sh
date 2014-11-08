#!/bin/bash

set -o nounset # Force error on unset variables
. ./env_vars
. ./VARS


#SRCDIR=/root
SRCDIR=.

VM_LOGIN=root@${BM_NETWORK_SEED_IP}

scp -o StrictHostKeyChecking=no $SRCDIR/baremetal.csv ${VM_LOGIN}:/root/
scp -o StrictHostKeyChecking=no $SRCDIR/env_vars ${VM_LOGIN}:/root/
scp -o StrictHostKeyChecking=no $SRCDIR/init.sh ${VM_LOGIN}:/root/
scp -o StrictHostKeyChecking=no $SRCDIR/hp_ced_functions.sh ${VM_LOGIN}:/root/tripleo/tripleo-incubator/scripts/hp_ced_functions.sh
ssh -o StrictHostKeyChecking=no ${VM_LOGIN} "./init.sh"



