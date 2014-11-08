#!/bin/bash
#
# Copyright 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

cloud_status_once() {
    # Ensure the output occurs inside the echo so all the output is given at once.
    HEAT_RESOURCE_LIST="$(heat resource-list "${1}")"
    NOVA_LIST="$(nova list)"
    echo -e "$(date): current status is:\n${HEAT_RESOURCE_LIST}\n${NOVA_LIST}"

    # Identify any instances in ERROR state and get detailed status
    NOVA_ERROR_INSTANCES=$(printf %s "$NOVA_LIST" | while IFS= read -r line
    do
        echo "$line" | awk -F\| '{ gsub(/^[ \t]+|[ \t]+$/, "", $4); if ($4 == "ERROR") {print $2}}'
    done)
    if [ -n "${NOVA_ERROR_INSTANCES}" ] ; then
        echo "$(date): Showing status for instances in ERROR state"
        for instance in $NOVA_ERROR_INSTANCES ; do
            nova show $instance || true
        done
    fi
}
export -f cloud_status_once

cloud_status() {
    while : ; do
        cloud_status_once "${1}"
        sleep 120
    done
}
export -f cloud_status

validate_mac() {
    MAC=$1
    NF=`echo ${MAC} | awk -F: '{print NF}'`
    if [ $NF -ne 6 ]
    then
        return 1
    fi
    return 0
}

validate_power() {
    POWER_MANAGER=${1}
    IPMI_USER=${2}
    IPMI_PASSWORD=${3}
    IPMI_IP=${4}
    if [ $POWER_MANAGER = 'nova.virt.baremetal.ipmi.IPMI' ] ; then
        if ! ipmitool -I lanplus -H $IPMI_IP -U $IPMI_USER -P "$IPMI_PASSWORD" power status 2>/dev/null ; then
            return 1
        fi
    else
        # Only support real h/w
        :
    fi
    return 0
}

power_off() {
    # TODO - check power again and verify its actually off
    POWER_MANAGER=${1}
    IPMI_USER=${2}
    IPMI_PASSWORD=${3}
    IPMI_IP=${4}
    if [ $POWER_MANAGER = 'nova.virt.baremetal.ipmi.IPMI' ] ; then
        ipmitool -I lanplus -H $IPMI_IP -U $IPMI_USER -P "$IPMI_PASSWORD" power off 2>/dev/null || true
    fi
}

function isnumber {
    re='^[0-9]+$'
    if [[ $1 =~ $re ]] ; then
        echo $1
        return 0
    fi
    return 1
}

export -f isnumber

# Add h/w real system limits with overrides possible
NODE_MIN_CPU=${NODE_MIN_CPU:-1}
NODE_MIN_MEMORY=${NODE_MIN_MEMORY:-32768}
#NODE_MIN_DISK=${NODE_MIN_DISK:-512}
NODE_MIN_DISK=${NODE_MIN_DISK:-200}
# ironic has a 2TB maximum limit
# TODO: remove this limit when ironic is fixed.
NODE_MAX_DISK=${NODE_MAX_DISK:-2048}

validate_node() {
    # Validate CPU, Memory and Disk
    CPU=${1}
    MEMORY=${2}
    DISK=${3}
    if [[ -z "$CPU" || -z "$MEMORY" || -z "$DISK" ]] ; then
        return 1
    fi
    if [[ !($(isnumber $CPU) && \
            $(isnumber $MEMORY) && \
            $(isnumber $DISK)) ]] ; then
        return 1
    fi
    if [[ $CPU -lt ${NODE_MIN_CPU} || \
          $MEMORY -lt ${NODE_MIN_MEMORY} || \
          $DISK -lt ${NODE_MIN_DISK} ]] ; then
        return 1
    fi
    if [[ -n "${NODE_MAX_DISK:-}" && $DISK -gt  ${NODE_MAX_DISK} ]] ; then
        echo "Disk size(${DISK}) exceeds maximum allowable disk size(${NODE_MAX_DISK}GB)." >&2
        return 1
    fi
    return 0
}
