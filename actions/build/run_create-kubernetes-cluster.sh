#!/bin/bash
#
# Author: Esteban Cruz
# Date: July 5, 2024
# Description: 
#   TODO(Esteban Cruz):...
# Usage:
#   - TODO(Esteban Cruz):...
#

#########################################################
# Initialization #
#########################################################

set -eo pipefail

export LOG_DIR="./logs/"
export LOG_FILE="${LOG_DIR}/kubernetes-in-incus-$(date +"%Y%m%d").log"
export WRITE_TO_LOGFILE=false
export DEBUG=false

#########################################################
# Bash functions definition #
#########################################################

source ./common/log_functions.sh
source ./actions/incus/helpers/functions.sh

#########################################################
# DEFAULTS #
#########################################################
# -------------------------------------------------------
# Control Plane settings #
# -------------------------------------------------------

# Incus
DESIRED_INCUS_VERSION="6.0.0"
CONTROL_PLANE_BASE_IMAGE="images:ubuntu/22.04/cloud"
CONTROL_PLANE_CPUS="2"
CONTROL_PLANE_MEMORY="2GiB"
CONTROL_PLANE_HOSTNAME="control-plane"
NETWORK_NAME="kubernetes"
# Kubernetes #
CONTROL_PLANE_CONTAINERD_VERSION="1.7.12"
CONTROL_PLANE_KUBERNETES_REPOSITORY_VERSION="v1.30"
CONTROL_PLANE_KUBEADM_VERSION="1.30.0-1.1"
CONTROL_PLANE_KUBELET_VERSION="1.30.0-1.1"
CONTROL_PLANE_KUBECTL_VERSION="1.30.0-1.1"
POD_NETWORK_ADDON="https://reweave.azurewebsites.net/k8s/v1.30/net.yaml"
NO_WORKER_NODES=1

#########################################################
# Main Script #
#########################################################

# -------------------------------------------------------
# Global configuration #
# -------------------------------------------------------

log_info "Veryfying incus installation"
if ! command_output=$(is_incus_installed 2>&1); then
    log_error "$command_output"
    exit 1
fi
log_info "Incus is installed on the system"

log_info "Veryfying desired incus version"
if ! command_output=$(is_incus_version "$DESIRED_INCUS_VERSION" 2>&1 ); then
    log_error "$command_output"
    exit 1
fi
log_info "Incus version '${DESIRED_INCUS_VERSION}' is installed on the system"

log_info "Attempting to create incus network '$NETWORK_NAME'"
if ! command_output=$(create_incus_network "$NETWORK_NAME" 2>&1); then
    log_error "$command_output"
    exit 1
fi
log_info "Successfully created incus network '$NETWORK_NAME'"

log_info "Retrieving default gateway for network ${NETWORK_NAME}"
declare default_gateway_cidr
if ! command_output=$(get_network_default_gateway_cidr "$NETWORK_NAME" 2>&1); then
    log_error "$command_output"
    exit 1
fi

declare default_gateway_cidr=$command_output
declare default_gateway_address=${default_gateway_cidr%/*}
declare network_submask=${default_gateway_cidr#*/}

log_info "Successfully retrieved default gateway '$default_gateway_cidr' from network ${NETWORK_NAME}"

# -------------------------------------------------------
# Control Plane Section #
# -------------------------------------------------------

log_info "Getting ip address for the control plane node"
if ! command_output=$(get_next_ipv4 "$default_gateway_address"); then
    log_error "$command_output"
    exit 1
fi

control_plane_address="$command_output"
control_plane_cidr_adress="${control_plane_address}/${network_submask}"
log_info "IP address $control_plane_cidr_adress will be assigned to the control-plane node"

# Create incus profile for the Control Plane
if ! ./actions/incus/create-profile.sh \
  --profile-name="${CONTROL_PLANE_HOSTNAME}" \
  --network-name="${NETWORK_NAME}" \
  --static-address="${control_plane_cidr_adress}" \
  --gateway="${default_gateway_address}"; 
then
  log_error "Failed to run script to create incus profile for control plane"
  exit 1
fi

# Launching Incus Control Plane instance
if ! ./actions/incus/launch-instance.sh \
  --image="${CONTROL_PLANE_BASE_IMAGE}" \
  --hostname="${CONTROL_PLANE_HOSTNAME}" \
  --profile="${CONTROL_PLANE_HOSTNAME}" \
  --cpus="${CONTROL_PLANE_CPUS}" \
  --memory="${CONTROL_PLANE_MEMORY}";
then
  log_error "Failed to run script to launch incus instance for control-plane"
  exit 1
fi

# Waiting for Control Plane instance to be ready to exec scripts
./actions/incus/wait-for-instance.sh \
  --instance-name="${CONTROL_PLANE_HOSTNAME}" \
  --max-retries=10

# ------------------------------------
# Control Plane Provisioning Section #
# ------------------------------------

# Install and configure Containerd
./actions/incus/exec-script.sh \
  --incus-cwd "/tmp/kubeadm/provisioning" \
  --instance-name "${CONTROL_PLANE_HOSTNAME}" \
  --script "./actions/build/provision-scripts/containerd.sh" \
  --containerd-version "${CONTROL_PLANE_CONTAINERD_VERSION}"

# Apply Network settings
./actions/incus/exec-script.sh \
  --incus-cwd "/tmp/kubeadm/provisioning" \
  --instance-name "${CONTROL_PLANE_HOSTNAME}" \
  --script "./actions/build/provision-scripts/network-configurations.sh"

# Installing kubernetes components
./actions/incus/exec-script.sh \
  --incus-cwd "/tmp/kubeadm/provisioning" \
  --instance-name "${CONTROL_PLANE_HOSTNAME}" \
  --script "./actions/build/provision-scripts/kubernetes-components.sh" \
  --repository-version "${CONTROL_PLANE_KUBERNETES_REPOSITORY_VERSION}" \
  --kubeadm "${CONTROL_PLANE_KUBEADM_VERSION}" \
  --kubelet "${CONTROL_PLANE_KUBELET_VERSION}" \
  --kubectl "${CONTROL_PLANE_KUBECTL_VERSION}" \
  --pull-images "true"

# Initializing Kubernetes cluster with Kubeadm
./actions/incus/exec-script.sh \
  --incus-cwd "/tmp/kubeadm/provisioning" \
  --instance-name "${CONTROL_PLANE_HOSTNAME}" \
  --script "./actions/build/provision-scripts/init-kubeadm-cluster.sh" \
  --node-name "${CONTROL_PLANE_HOSTNAME}" \
  --apiserver-advertise-address "${control_plane_address}" \
  --network-addon "${POD_NETWORK_ADDON}"

log_info "Applying customizations"
./actions/incus/exec-script.sh \
  --incus-cwd "/tmp/kubeadm/provisioning" \
  --instance-name "${CONTROL_PLANE_HOSTNAME}" \
  --script "./actions/build/provision-scripts/customizations.sh"

# -------------------------------------------------------
# Worker Nodes Section #
# -------------------------------------------------------

for (( i = 1; i <= $NO_WORKER_NODES; i++ ))
do
    worker_hostname="worker-$i"

    log_info "Getting ip address for worker '$worker_hostname'"
    if ! command_output=$(get_next_ipv4 "$control_plane_address" $(($i+1))); then
        log_error "$command_output"
        exit 1
    fi

    worker_address="$command_output"
    worker_cidr_address="${worker_address}/${network_submask}"
    log_info "IP address $worker_cidr_address will be assigned to the worker node '${worker_hostname}'"

    # Create incus profile for worker node
    if ! ./actions/incus/create-profile.sh \
      --profile-name="${worker_hostname}" \
      --network-name="${NETWORK_NAME}" \
      --static-address="${worker_cidr_address}" \
      --gateway="${default_gateway_address}"; 
    then
      log_error "Failed to run script to create incus profile for worker 'worker_hostname'"
      exit 1
    fi

    # Launching Incus worker node instance
    if ! ./actions/incus/launch-instance.sh \
      --image="${CONTROL_PLANE_BASE_IMAGE}" \
      --hostname="${worker_hostname}" \
      --profile="${worker_hostname}" \
      --cpus="${CONTROL_PLANE_CPUS}" \
      --memory="${CONTROL_PLANE_MEMORY}";
    then
      log_error "Failed to run script to launch incus instance for worker node"
      exit 1
    fi

    # Waiting for worker instance to be ready to exec scripts
    ./actions/incus/wait-for-instance.sh \
      --instance-name="${worker_hostname}" \
      --max-retries=10

    # ------------------------------------
    # Worker Provisioning Section #
    # ------------------------------------

    # Install and configure Containerd
    ./actions/incus/exec-script.sh \
      --incus-cwd "/tmp/kubeadm/provisioning" \
      --instance-name "${worker_hostname}" \
      --script "./actions/build/provision-scripts/containerd.sh" \
      --containerd-version "${CONTROL_PLANE_CONTAINERD_VERSION}"

    # Apply Network settings
    ./actions/incus/exec-script.sh \
      --incus-cwd "/tmp/kubeadm/provisioning" \
      --instance-name "${worker_hostname}" \
      --script "./actions/build/provision-scripts/network-configurations.sh"

    # Installing kubernetes components
    ./actions/incus/exec-script.sh \
      --incus-cwd "/tmp/kubeadm/provisioning" \
      --instance-name "${worker_hostname}" \
      --script "./actions/build/provision-scripts/kubernetes-components.sh" \
      --repository-version "${CONTROL_PLANE_KUBERNETES_REPOSITORY_VERSION}" \
      --kubeadm "${CONTROL_PLANE_KUBEADM_VERSION}" \
      --kubelet "${CONTROL_PLANE_KUBELET_VERSION}"

    
    if ! command_output=$(incus exec ${CONTROL_PLANE_HOSTNAME} -- /bin/bash -c "kubeadm token create --print-join-command" 2>&1); then
      log_error "Failed to create kubeadm token for worker $worker_hostname"
      exit 1
    else
      join_command=$command_output
      if ! command_output=$(incus exec ${worker_hostname} -- /bin/bash -c "${join_command}"); then
        log_error "Worker node $worker_hostname failed to join the cluster" "$command_output"
        exit 1
      fi
    fi

    log_info "Worker node ${worker_hostname} joined the cluster successfully"
done

#########################################################
# Finalization #
#########################################################

log_info "Successfully created the kubernetes cluster"
