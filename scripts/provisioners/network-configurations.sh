#!/bin/bash
#
# Script: network-configurations.sh
# Author: Esteban Cruz
# Date: June 26, 2024
# Description: 
#   Install and configure network prerequisites for Kubernetes on Ubuntu.
# Usage:
#   - root privileges are required to run this script.
#

#########################################################
# Initialization #
#########################################################
set -euo pipefail

FILE_NAME="network-configurations.sh"
SCRIPT_NAME="network-configurations"
LOG_FILE="/tmp/log/${SCRIPT_NAME}.log"

#########################################################
# Bash functions definition #
#########################################################

log_message() {
    local datetime=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${datetime} - $1" | tee -a ${LOG_FILE}
}

log_error() {
    local datetime=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${datetime} - ERROR - $1" | tee -a ${LOG_FILE} >&2
}

root_required() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root." | tee -a ${LOG_FILE} >&2
        exit 1
    fi
}

check_prerequisits() {
    root_required
}

#########################################################
# Main Script #
#########################################################

log_message "Starting $FILE_NAME script installer."
check_prerequisits

log_message "Adding necessary Kernel modules."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay br_netfilter

log_message "Enable IPv4 packet forwarding."
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

log_message Apply sysctl params without
sysctl --system

#########################################################
# Finalization #
#########################################################

log_message "Script $FILE_NAME completed successfully."
