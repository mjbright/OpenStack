#!/bin/bash

set -o nounset # Force error on unset variables
. ./env_vars
. ./VARS

SCRIPTS_DIR=/root/tripleo/tripleo-incubator/scripts
JSON_DIR=/root/tripleo/config
JSON_FILE=kvm-custom-ips.json

#SRCDIR=/root
SRCDIR=.

VM_LOGIN=root@${BM_NETWORK_SEED_IP}

press() {
    echo $*
    echo "Press <return> to continue"
    read _DUMMY
    [ "$_DUMMY" = "q" ] && exit 0
    [ "$_DUMMY" = "Q" ] && exit 0
}

########################################
# Modify and transfer hp_ced_functions.sh script to seed VM:
HP_C_F=hp_ced_functions.sh
NODE_MIN_DISK=200
cp -a /root/tripleo/tripleo-incubator/scripts/$HP_C_F $SRCDIR/$HP_C_F
sed -ie 's/^NODE_MIN_DISK=.*$/NODE_MIN_DISK=$NODE_MIN_DISK/g' $SRCDIR/$HP_C_F
ls -altr $SRCDIR/$HP_C_F $SRCDIR/${HP_C_F}.bak
diff $SRCDIR/$HP_C_F $SRCDIR/${HP_C_F}.bak
scp -o StrictHostKeyChecking=no $SRCDIR/hp_ced_functions.sh ${VM_LOGIN}:$SCRIPTS_DIR/hp_ced_functions.sh

########################################
# Transfer files to seed VM:
scp -o StrictHostKeyChecking=no $SRCDIR/baremetal.csv ${VM_LOGIN}:/root/
scp -o StrictHostKeyChecking=no $JSON_DIR/$JSON_FILE ${VM_LOGIN}:$JSON_DIR/$JSON_FILE
scp -o StrictHostKeyChecking=no $SRCDIR/env_vars ${VM_LOGIN}:/root/
scp -o StrictHostKeyChecking=no $SRCDIR/init.sh ${VM_LOGIN}:/root/

press "Will now launch installer"

########################################
# Launch installer:
ssh -o StrictHostKeyChecking=no ${VM_LOGIN} "./init.sh"



