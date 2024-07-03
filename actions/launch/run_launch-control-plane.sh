#!/bin/bash
#
# Script: run_launch-control-plane.sh
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

check_prerequisits() {
    if ! $(incus profile show ${INCUS_PROFILE_NAME} &> /dev/null )
    then
        log_error "Incus profile ${INCUS_PROFILE_NAME} not found."
        exit 1
    fi
    if ! $( incus image info ${MASTER_IMAGE} &> /dev/null )
    then
        log_error "Incus image ${MASTER_IMAGE} not found."
        exit 1
    fi
}

#########################################################
# Main Script #
#########################################################
check_prerequisits
log_message "Starting run_launch-control-plane.sh script."

incus launch ${MASTER_IMAGE} ${MASTER_HOSTNAME} \
    --profile ${INCUS_PROFILE_NAME} \
    --vm \
    --config limits.cpu=2 \
    --config limits.memory=2000MiB

#########################################################
# Finalization #
#########################################################

log_message "Script run_launch-control-plane.sh completed successfully."

