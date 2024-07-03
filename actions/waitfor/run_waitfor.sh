#!/bin/bash
#
# Script: run_waitfor.sh
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
    echo "No checks to run."
}

control_plane_is_ready() {
    local result=$(incus exec control-plane -- /bin/bash -c "kubectl get node control-plane -o yaml | yq e '.status.conditions[] | select(.reason == \"KubeletReady\") | .status' -")
    if [[ "$result" == "True" ]]; then
        return 0
    else
        return 1
    fi
}

wait_for_control_plane() {
    while ! control_plane_is_ready; do
        log_message "Control Plane not ready yet, waiting 5 seconds..."
        sleep 1
    done
    log_message "Control plane is ready."
}

wait_for_weave_interface() {
    while ! incus exec control-plane -- /bin/bash -c "ip link show weave" &> /dev/null
    do
        log_message "Weave Interface not ready yet, waiting 5 seconds..."
        sleep 1
    done
    log_message "Ready Fredy!"
}

#########################################################
# Main Script #
#########################################################
check_prerequisites
log_message "Starting run_waitfor.sh script."

log_message "Waiting for Weave Interface to be ready."
wait_for_weave_interface

log_message "Waiting for Control Plane to be ready."
wait_for_control_plane

#########################################################
# Finalization #
#########################################################

log_message "Script run_waitfor.sh completed successfully."

