#!/bin/bash
#
# Script: 05-customizations.sh
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

export DEBIAN_FRONTEND=noninteractive
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

#########################################################
# Main Script #
#########################################################

# check_prerequisites
log_message "Applying customizations."

log_message "Removing taint from Control Plane node."
kubectl taint node control-plane node-role.kubernetes.io/control-plane:NoSchedule- &> /dev/null \
    || log_error "Could not remove taint from Control Plane node."

# TODO(Esteban Cruz): Does this have to be here?
log_message "Configuring containerd runtime and image endpoints."
crictl config \
    --set runtime-endpoint=unix:///run/containerd/containerd.sock \
    --set image-endpoint=unix:///run/containerd/containerd.sock

echo "alias k=\"kubectl\"" >> /root/.profile

log_message "Installing package: 'yq'."
add-apt-repository -y ppa:rmescandon/yq
apt update
apt install yq -y

#########################################################
# Finalization #
#########################################################

log_message "Script 05-customizations.sh completed successfully."

