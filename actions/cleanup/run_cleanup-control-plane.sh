#!/bin/bash
#
# Author: Esteban Cruz
# Date: June 28, 2024
# Description: 
#   Description goes here.
# Usage:
#   - Instructions go here.
#

#########################################################
# Initialization #
#########################################################

set -euo pipefail

export LOG_DIR="./logs/"
export LOG_FILE="${LOG_DIR}/kubernetes-in-incus-$(date +"%Y%m%d").log"
export WRITE_TO_LOGFILE=false
export DEBUG=false

INSTANCE_NAME="control-plane"
BASE_IMAGE="control-plane"
CONTROL_PLANE_PROFILE="control-plane"
NETWORK_NAME="kubernetes"
NO_WORKER_NODES=1

#########################################################
# Bash functions definition #
#########################################################

source ./common/log_functions.sh

check_prerequisites() {
  if [[ -z "$(incus --version)" ]]; then
    log_error "It appears that incus is not installed in the system, or could not be found." \
      "It is recommended to use incus version 6.0.0."
    exit 1
  fi
}

#########################################################
# Main Script #
#########################################################

check_prerequisites
log_info "Starting clean up script"

log_info "Deleting $INSTANCE_NAME instance"
if ! incus info $INSTANCE_NAME &> /dev/null; then
    log_info "No instance $INSTANCE_NAME is running"
elif ! command_output=$(incus delete $INSTANCE_NAME -f 2>&1); then
    log_error "Failed to delete instance $INSTANCE_NAME" $command_output
fi

for (( i=1; i<= $NO_WORKER_NODES; i++ ))
do
    worker_instance="worker-${i}"
    log_info "Deleting $worker_instance instance"
    if ! incus info $worker_instance &> /dev/null; then
        log_info "No instance $worker_instance is running"
    elif ! command_output=$(incus delete $worker_instance -f 2>&1); then
        log_error "Failed to delete instance $worker_instance" $command_output
    fi
done

log_info "Deleting profile $CONTROL_PLANE_PROFILE"
if ! incus profile show $CONTROL_PLANE_PROFILE &> /dev/null; then
    log_info "No profile $CONTROL_PLANE_PROFILE was found"
elif ! command_output=$(incus profile delete $CONTROL_PLANE_PROFILE 2>&1); then
    log_error "Failed to delete profile $CONTROL_PLANE_PROFILE" "$command_output"
fi


for (( i=0; i <= $NO_WORKER_NODES; i++ ))
do
    worker_profile="worker-${i}"
    log_info "Deleting profile $worker_profile"
    if ! incus profile show $worker_profile &> /dev/null; then
        log_info "No profile $worker_profile was found"
    elif ! command_output=$(incus profile delete $worker_profile 2>&1); then
        log_error "Failed to delete profile $worker_profile" "$command_output"
    fi
done


log_info "Deleting image $BASE_IMAGE"
if ! incus image info $BASE_IMAGE &> /dev/null; then
    log_info "No image $BASE_IMAGE was found"
elif ! command_output=$(incus image delete ${BASE_IMAGE} 2>&1); then
    log_error "Failed to delete image $BASE_IMAGE" "$command_output"
fi

log_info "Deleting incus network $NETWORK_NAME"
if ! incus network info $NETWORK_NAME &> /dev/null; then
    log_info "No network $NETWORK_NAME was found"
elif ! command_output=$(incus network delete ${NETWORK_NAME} 2>&1); then
    log_error "Failed to delete network $NETWORK_NAME" "$command_output"
fi

#########################################################
# Finalization #
#########################################################

log_info "Clean up completed successfully"

