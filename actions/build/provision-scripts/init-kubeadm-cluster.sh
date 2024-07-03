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

# NODE_NAME="control-plane"
# APISERVER_ADVERTISE_ADDRESS="10.125.165.10"
# POD_NETWORK_ADDON="https://reweave.azurewebsites.net/k8s/v1.30/net.yaml"
declare -a NODE_NAME
declare -a APISERVER_ADVERTISE_ADDRESS
declare -a POD_NETWORK_ADDON

#########################################################
# Parse command options #
#########################################################

OPTS=$( getopt -ao '' --long node-name:,apiserver-advertise-address:,network-addon: -- "$@" )
eval set -- ${OPTS}
while true;
do
  case $1 in
    --node-name)                                NODE_NAME="$2"                      ; shift 2       ;;
    --apiserver-advertise-address)              APISERVER_ADVERTISE_ADDRESS="$2"    ; shift 2       ;;
    --network-addon)                            POD_NETWORK_ADDON="$2"              ; shift 2       ;;
    --)                                                                               shift ; break  ;;
    *) >&2 log_error Unsupported option: $1                                         ; exit 1        ;;
  esac
done

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


# --------------------------------------------------------
log_message "Initializing control-plane node with kubeadm."
# 
# Instructions from:
# - https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node
# 
# Details about kubeadm parameters
# - https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#without-internet-connection
# 

log_message "Setting hostname to $NODE_NAME"
hostname "$NODE_NAME" || log_error "Failed to set hostname."

# Initialize Kubernetes control-plane with kubeadm
log_message "Running 'kubeadm init'..."
kubeadm init \
    --apiserver-advertise-address="$APISERVER_ADVERTISE_ADDRESS" \
    --node-name="$NODE_NAME" \
    || log_error "Failed to initialize Kubernetes control-plane."

# Set up kube config file
log_message "Setting up kube config file."

# Create kube config directory if it doesn't exist
mkdir -p /root/.kube

# Copy admin.conf to kube config directory
cp -i /etc/kubernetes/admin.conf /root/.kube/config \
    || log_error "Failed to copy admin.conf to /root/.kube/config."

# Set ownership of kube config file
chown "$(id -u)":"$(id -g)" /root/.kube/config \
    || log_error "Failed to set ownership of /root/.kube/config."

# --------------------------------------------------------
log_message "Installing Pod network add-on from $POD_NETWORK_ADDON."
# 
# Instructions from:
# - https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network
# - https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy
# - https://github.com/rajch/weave?tab=readme-ov-file#using-weave-net-on-kubernetes
# 

# TODO(Esteban Cruz): This should be in its own script, shouldn't it?.
# Apply Pod network add-on configuration
kubectl apply -f "$POD_NETWORK_ADDON" \
    || log_error "Failed to install Pod network add-on $POD_NETWORK_ADDON."

#########################################################
# Finalization #
#########################################################

log_message "Kubernetes control-plane initialization completed successfully."
exit 0
