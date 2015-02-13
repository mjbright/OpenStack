#!/bin/bash

INSTALLER_OPTS=""
INSTALLER_OPTS="--skip-demo"

set -o nounset # Force error on unset variables

die() {
    echo "die: $0 - $*" >&2
    exit 1
}

[ -f ./env_vars ] && {
    echo ". ./env_vars"
    . ./env_vars
}

[ ! -f $JSON ] && die "No such json file <$JSON>"

echo "source $LOAD_CONFIG_SH $JSON"
set +o nounset # Force error on unset variables
source $LOAD_CONFIG_SH $JSON
set -o nounset # Force error on unset variables

env | grep -q BM_NETWORK_SEED_IP || die "Missing variable definitions"
env | grep 192.0 && {
    env | grep 192.0
    die "Looks like there are undefined variable (192.0.*)"
}

cd /root;

bash -x /root/tripleo/tripleo-incubator/scripts/hp_ced_installer.sh $INSTALLER_OPTS |& tee cloud_install.log 


