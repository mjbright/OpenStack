#!/bin/bash

set -o nounset # Force error on unset variables
#source env_vars;
. ./env_vars

cd /root;

bash -x /root/tripleo/tripleo-incubator/scripts/hp_ced_installer.sh |& tee cloud_install.log 

