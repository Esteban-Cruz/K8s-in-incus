#!/bin/bash
#
# Script: run_cleanup-control-plane.sh
# Author: Esteban Cruz
# Date: June 28, 2024
# Description: 
#   Description goes here.
# Usage:
#   - Instructions go here.
#

#########################################################
# Initialization #
#########################################################
set -euo pipefail

CONTROL_PLANE_CIDR="10.125.165.10/24"
DEFAULT_GATEWAY="10.125.165.1"
MASTER_HOSTNAME="control-plane"
MASTER_IMAGE=$MASTER_HOSTNAME
INCUS_PROFILE_NAME="control-plane"

#########################################################
# Bash functions definition #
#########################################################

log_message() {
    local datetime
    datetime=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${datetime} - $1"
}

log_error() {
    local datetime
    datetime=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${datetime} - ERROR - $1"
}

root_required() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root."
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
log_message "Starting run_cleanup-control-plane.sh script."

if $( incus info ${MASTER_HOSTNAME} &> /dev/null ) ; then
   incus delete ${MASTER_HOSTNAME} -f
fi

if $( incus profile show ${INCUS_PROFILE_NAME} &> /dev/null ) ; then
    incus profile delete ${INCUS_PROFILE_NAME}
fi

if $( incus image info ${MASTER_IMAGE} &> /dev/null ) ; then
    incus image delete ${MASTER_IMAGE}
fi

#########################################################
# Finalization #
#########################################################

log_message "Script run_cleanup-control-plane.sh completed successfully."

