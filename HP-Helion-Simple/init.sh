#!/bin/bash

set -o nounset # Force error on unset variables

[ -f ./env_vars ] && {
    echo ". ./env_vars"
    . ./env_vars
}

[ -f $JSON ] && {
    echo "source $LOAD_CONFIG_SH $JSON"
    set +o nounset # Force error on unset variables
    source $LOAD_CONFIG_SH $JSON
    set -o nounset # Force error on unset variables
}

env | grep -q BM_NETWORK_SEED_IP || die "Missing variable definitions"

cd /root;

bash -x /root/tripleo/tripleo-incubator/scripts/hp_ced_installer.sh |& tee cloud_install.log 


