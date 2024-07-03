#!/bin/bash
#
# Script: containerd.sh
# Author: Esteban Cruz
# Date: June 20, 2024
# Description: 
#   Script to install and configure containerd as a prerequisit for Kubernetes on Ubuntu.
# Usage:
#   - root privileges are required to run this script.
#

#########################################################
# Initialization #
#########################################################
set -euo pipefail

FILE_NAME="containerd.sh"
SCRIPT_NAME="containerd_installer"

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
    root_required
}

#########################################################
# Main Script #
#########################################################

log_message "Starting ${FILE_NAME} script installer."
check_prerequisites

log_message "Update package list and install containerd."
DEBIAN_FRONTEND=noninteractive apt update
apt install -y containerd || {
        log_error "Failed to install containerd. Exiting."
        exit 1
}

log_message "Configuring containerd."
mkdir -p /etc/containerd/
containerd config default > /etc/containerd/config.toml
sed -ir "s/SystemdCgroup = false/SystemdCgroup = true/" /etc/containerd/config.toml

log_message "Restarting containerd service."
systemctl restart containerd || {
    log_error "Failed to restart containerd service. Exiting."
    exit 1
}

#########################################################
# Finalization #
#########################################################

log_message "Script ${FILE_NAME} completed successfully."
