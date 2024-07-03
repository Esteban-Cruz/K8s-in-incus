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
    echo "${datetime} - ERROR - $1" >&2
    exit 1
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

check_prerequisites
log_message "Installing and configuring prerequisites."

# --------------------------------------------------------
log_message "Adding necessary Kernel modules."
# 
# Instructions from:
# - https://kubernetes.io/docs/setup/production-environment/container-runtimes/#install-and-configure-prerequisites
# 

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Load kernel modules
modprobe overlay || log_error "Failed to add kernel module 'overlay'"
modprobe br_netfilter || log_error "Failed to add kernel module 'br_netfilter'"

# --------------------------------------------------------
log_message "Enable IPv4 packet forwarding."
# 
# Instructions from:
# - https://kubernetes.io/docs/setup/production-environment/container-runtimes/#prerequisite-ipv4-forwarding-optional
# 

# Sysctl params required by setup, params persist across reboots
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
log_message "Applying sysctl params."
sysctl --system || log_error "Failed applying sysctl params."

#########################################################
# Finalization #
#########################################################

log_message "Successfully installed and configured prerequisites."

exit 0