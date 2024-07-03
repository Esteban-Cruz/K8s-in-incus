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
declare -a CONTAINERD_VERSION

#########################################################
# Bash functions definition #
#########################################################

log_info() {
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
# Parse command options #
#########################################################

OPTS=$( getopt -ao 'v:' --long containerd-version: -- "$@" )
eval set -- ${OPTS}
while true;
do
  case $1 in
    -v | --containerd-version)            CONTAINERD_VERSION="$2" ; shift 2       ;;
    --)                                                             shift; break  ;;
    *) >&2 log_error Unsupported option: $1                       ; exit 1        ;;
  esac
done

#########################################################
# Main Script #
#########################################################

check_prerequisites
log_info "Starting Containerd installation and configuration."

# --------------------------------------------------------
log_info "Setting up Docker's apt repository."
# 
# Instructions from:
# - https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
# 

# Update package list
apt update || log_error "Failed to update package list."

# Install necessary packages
apt install -y ca-certificates curl || log_error "Failed to install required packages."

# Create directory for apt keyrings if it doesn't exist
mkdir -m 0755 -p /etc/apt/keyrings || log_error "Failed to create directory /etc/apt/keyrings."

# Download Docker's GPG key and place it in apt keyring directory
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || \
    log_error "Failed to download Docker's GPG key."
chmod 644 /etc/apt/keyrings/docker.asc || log_error "Failed to set permissions for /etc/apt/keyrings/docker.asc."

# Add Docker repository to sources list
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    || log_error "Failed to add Docker repository to sources list."

# Update package list again to include Docker's repository
apt update || log_error "Failed to update package list after adding Docker repository."

# Install desired version of containerd if provided, install latest version available otherwise
if [ -n "$CONTAINERD_VERSION" ]; then
    # Run apt-cache madison to get available versions and capture output
    madison_output=$(apt-cache madison containerd)

    # Check if the desired version is available
    version_found=$(echo "$madison_output" | awk '{ print $3 }' | grep -E "${CONTAINERD_VERSION}") # Bug when the version does not exist, or pattern matches all available versions.

    if [ -n "$version_found" ]; then
        # If version is found, store it in a variable
        selected_version="$version_found"
        log_info "Found Containerd version ${selected_version}. Proceeding with installation."
        apt install -y containerd=${selected_version}
    else
        log_error "Containerd version ${CONTAINERD_VERSION} could not be found."
    fi
else
    # Install containerd latest version available
    apt install -y containerd
fi

log_info "Containerd setup completed successfully."

# --------------------------------------------------------
log_info "Configuring the systemd cgroup driver."
# 
# Instructions from:
# - https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd

# Directory for containerd config
config_dir="/etc/containerd"

# Create directory if it doesn't exist
mkdir -p "$config_dir" || \
    log_error "Failed to create directory '$config_dir'."

# Generate default configuration and save to config.toml
containerd config default > "$config_dir/config.toml" || \
    log_error "Failed to generate default config for containerd."

# Modify the configuration to enable systemd cgroup driver
sed -i.bak -r "s/SystemdCgroup = false/SystemdCgroup = true/" "$config_dir/config.toml" || \
    log_error "Failed to modify config.toml"

# Restart containerd service.
systemctl restart containerd || \
    log_error "Failed to restart containerd service."

log_info "Systemd cgroup driver configured successfully."

#########################################################
# Finalization #
#########################################################

log_info "Successful Containerd installation and configuration."
exit 0