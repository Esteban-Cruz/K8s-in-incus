#!/bin/bash
#
# Script: run_build-workers.sh
# Author: Esteban Cruz
# Date: June 29, 2024
# Description: 
#   Description goes here.
# Usage:
#   - Instructions go here.
#

#########################################################
# Initialization #
#########################################################
set -euo pipefail

NO_WORKERS=1
SUBNET="10.125.165.0/24"
DEFAULT_GATEWAY="10.125.165.1"
HOSTNAME_PREFIX="control-plane"
IMAGE="images:ubuntu/22.04/cloud"
INCUS_PROFILE_NAME="control-plane"
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
    echo "${datetime} - ERROR - $1"
}

root_required() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root."
        exit 1
    fi
}

check_prerequisites() {
    log_info "No checks to run."
}

#########################################################
# Main Script #
#########################################################
check_prerequisites
log_info "Starting run_build-workers.sh script."

for i in $(seq 1 $max_iteration)
do
    
done


#########################################################
# Finalization #
#########################################################

log_info "Script run_build-workers.sh completed successfully."

