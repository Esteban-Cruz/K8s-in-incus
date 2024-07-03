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
set -eo pipefail

declare -a KUBERNETES_REPOSITORY_VERSION
declare -a KUBEADM_VERSION
declare -a KUBELET_VERSION
declare -a KUBECTL_VERSION
declare -a PULL_IMAGES="false"
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
    echo "${datetime} - ERROR - $1" >&2
    exit 1
}

root_required() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root."
        exit 1
    fi
}

check_prerequisits() {
    root_required
    if [ -z "$KUBERNETES_REPOSITORY_VERSION" ]; then
        log_error "Missing required argument: --repository-version"
    fi

    if [ -z "$KUBEADM_VERSION" ]; then
        log_error "Missing required argument: --kubeadm"
    fi

    if [ -z "$KUBELET_VERSION" ]; then
        log_error "Missing required argument: --kubelet"
    fi
}

#########################################################
# Parse command options #
#########################################################

OPTS=$( getopt -ao '' --long repository-version:,kubeadm:,kubelet:,kubectl:,pull-images: -- "$@" )
eval set -- ${OPTS}
while true;
do
  case $1 in
    --repository-version)            KUBERNETES_REPOSITORY_VERSION="$2" ; shift 2       ;;  
    --kubeadm)            KUBEADM_VERSION="$2"               ; shift 2       ;;
    --kubelet)            KUBELET_VERSION="$2"               ; shift 2       ;;
    --kubectl)            KUBECTL_VERSION="$2"               ; shift 2       ;;
    --pull-images)        PULL_IMAGES="$2"                   ; shift 2       ;;
    --)                                                        shift; break  ;;
    *) >&2 log_error Unsupported option: $1                  ; exit 1        ;;
  esac
done
#########################################################
# Main Script #
#########################################################

log_message "Installing Kubernetes components"

# --------------------------------------------------------
log_message "Update apt packages and install Kubernetes components"
# 
# Instructions from:
# - https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl

log_message "Updating apt package index and installing packages needed to use the Kubernetes apt repository"
apt update -y \
    || log_error "Failed to update apt package index."
apt install -y apt-transport-https ca-certificates curl gnupg \
    || log_error "Failed to install prerequisite packages."

# Download public signing key for the Kubernetes package repositories
log_message "Downloading public signing key for the Kubernetes package repositories."
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_REPOSITORY_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
    || log_error "Failed to download and install Kubernetes signing key."

# Add Kubernetes apt repository
log_message "Adding appropriate Kubernetes apt repository."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_REPOSITORY_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list \
    || log_error "Failed to add Kubernetes apt repository."

# Update apt package index again after adding the repository
apt update -y \
    || log_error "Failed to update apt package index after adding Kubernetes repository."

# Install Kubernetes Components
if [ -n "$KUBEADM_VERSION" ]; then
    log_message "Installing kubeadm='${KUBEADM_VERSION}'"
    apt install -y kubeadm="${KUBEADM_VERSION}" \
        || log_error "Failed to install 'kubeadm=${KUBEADM_VERSION}'"
    apt-mark hold kubeadm \
        || log_error "Failed to mark kubeadm on hold"
fi

if [ -n "$KUBELET_VERSION" ]; then
    log_message "Installing kubelet='${KUBELET_VERSION}'"
    apt install -y kubelet="${KUBELET_VERSION}" \
        || log_error "Failed to install 'kubelet=${KUBELET_VERSION}'"
    apt-mark hold kubelet \
        || log_error "Failed to mark kubelet on hold"
    systemctl enable --now kubelet \
        || log_error "Failed to enable and start kubelet service."
fi

if [ -n "${KUBECTL_VERSION}" ]; then
    apt install -y kubectl="${KUBECTL_VERSION}" \
        || log_error "Failed to install 'kubectl=${KUBECTL_VERSION}'"
    apt-mark hold kubectl \
        || log_error "Failed to mark kubectl on hold"
fi

if [ "${PULL_IMAGES}" = "true" ]; then
    log_message "Pulling control plane images."
    kubeadm config images pull || log_error "Failed to pull Kubernetes images."
fi

#########################################################
# Finalization #
#########################################################

log_message "Successfully installed Kubernetes components"

