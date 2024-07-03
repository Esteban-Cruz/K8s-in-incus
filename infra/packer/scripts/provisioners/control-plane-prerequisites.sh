#!/bin/bash
#
# Script: control-plane-prerequisites.sh
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

KUBERNETES_REPOSITORY_VERSION="v1.30"
KUBELET_VERSION="1.30.0-1.1"
KUBEADM_VERSION="1.30.0-1.1"
KUBECTL_VERSION="1.30.0-1.1"

#########################################################
# Bash functions definition #
#########################################################

log_message() {
    local datetime
    datetime=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${datetime} - $1" | tee -a ${LOG_FILE}
}

log_error() {
    local datetime
    datetime=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${datetime} - ERROR - $1" | tee -a ${LOG_FILE} >&2
}

root_required() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root." | tee -a ${LOG_FILE} >&2
        exit 1
    fi
}

check_prerequisites() {
    root_required
}

#########################################################
# Main Script #
#########################################################

log_message "Starting control-plane-prerequisites.sh script."
check_prerequisites
log_message "Installing kubeadm, kubelet and kubectl."
log_message "Updating apt package index and install packages needed to use the Kubernetes apt repository"
DEBIAN_FRONTEND=noninteractive apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y apt-transport-https ca-certificates curl gpg

log_message "Downloading public signing key for the Kubernetes package repositories."
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_REPOSITORY_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

log_message "Adding appropriate Kubernetes apt repository."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_REPOSITORY_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt update
DEBIAN_FRONTEND=noninteractive apt install -y kubelet="${KUBELET_VERSION}" kubeadm="${KUBEADM_VERSION}" kubectl="${KUBECTL_VERSION}"
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet


log_message "Pulling images used by kubeadm"
kubeadm config images pull

#########################################################
# Finalization #
#########################################################

log_message "Script control-plane-prerequisites.sh completed successfully."

