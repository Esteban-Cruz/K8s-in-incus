#!/bin/bash
#
# Script: init-kubeadm-cluster.sh
# Author: Esteban Cruz
# Date: June 26, 2024
# Description: 
#   Description goes here.
# Usage:
#   - Instructions go here.
#

#########################################################
# Initialization #
#########################################################
set -euo pipefail

POD_NETWORK_ADDON="https://reweave.azurewebsites.net/k8s/v1.30/net.yaml"
CONTROL_PLANE_STATIC_IP="10.125.165.111"
CONTROL_PLANE_HOSTNAME="control-plane"
LOG_FILE="/tmp/log/init-kubeadm-cluster.log"

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

log_message "Starting init-kubeadm-cluster.sh script."
check_prerequisits

log_message "Initializing control-plane node."

# TODO(Esteban Cruz): Can we assign the hostname in the preProvisioning instead?
hostname $CONTROL_PLANE_HOSTNAME # Needed to overwrite packer hostname
kubeadm init \
    --apiserver-advertise-address="$CONTROL_PLANE_STATIC_IP" \
    --node-name="${CONTROL_PLANE_HOSTNAME}"

log_message "Setting up kube config file."
mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown $(id -u):$(id -g) /root/.kube/config

log_message "Installing a Pod network add-on."
kubectl apply -f $POD_NETWORK_ADDON  || {
    log_error "Unable to install Pod network add-on $POD_NETWORK_ADDON"
    exit 1
}

# TODO(Esteban Cruz): Does this have to be here?
log_message "Configuring containerd runtime and image endpoints."
crictl config \
    --set runtime-endpoint=unix:///run/containerd/containerd.sock \
    --set image-endpoint=unix:///run/containerd/containerd.sock

#########################################################
# Finalization #
#########################################################

log_message "Script init-kubeadm-cluster.sh completed successfully."

