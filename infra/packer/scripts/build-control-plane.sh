#!/bin/bash
#
# Script: build-control-plane.sh
# Author: Esteban Cruz
# Date: June 27, 2024
# Description: 
#   Description goes here.
# Usage:
#   - Instructions go here.
#

#########################################################
# Initialization #
#########################################################
set -euo pipefail

LOG_FILE="/tmp/log/build-control-plane.log"
WRITE_LOGS=false
CONTROL_PLANE_CIDR="10.125.165.10/24"
DEFAULT_GATEWAY="10.125.165.1"

#########################################################
# Bash functions definition #
#########################################################

log_message() {
    local datetime
    datetime=$(date +"%Y-%m-%d %H:%M:%S")
    if $WRITE_LOGS
    then
        echo "${datetime} - $1" | tee -a ${LOG_FILE}
    else
        echo "${datetime} - $1"
    fi  
}

log_error() {
    local datetime
    datetime=$(date +"%Y-%m-%d %H:%M:%S")
    if $WRITE_LOGS
    then
        echo "${datetime} - ERROR - $1" | tee -a ${LOG_FILE} >&2
    else
        echo "${datetime} - ERROR - $1"
    fi
}

root_required() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root." | tee -a ${LOG_FILE} >&2
        exit 1
    fi
}

check_prerequisites() {
    log_message "No checks to run."
}

#########################################################
# Main Script #
#########################################################
check_prerequisites
log_message "Starting build-control-plane.sh script."



if [[ -n $(incus profile show control-plane) ]];
then
    echo "Profile exists"
else
    echo "profile does not exist"
fi


#########################################################
# Finalization #
#########################################################

log_message "Script build-control-plane.sh completed successfully."

incus config device add <instance_name> <device_name> disk pool=<pool_name> source=<volume_name> [path=<path_in_instance>]

# Problematic command
incus snapshot create control-plane k8s-master --stateful -v --version
Error: Stateful stop and snapshots require that the instance limits.memory is less than size.state on the root disk device

profile: control-plane


# Get devices in the profile
incus profile device show control-plane
# eth0:
#   name: eth0
#   network: incusbr0
#   type: nic
# root:
#   path: /
#   pool: default
#   type: disk

# We probably need to add a device
 incus profile device add

pool = storage name


incus storage volume info default virtual-machine/control-plane


# Set root size.state
incus profile device set control-plane root size.state=3000MiB