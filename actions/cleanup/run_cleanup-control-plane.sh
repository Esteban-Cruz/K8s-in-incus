#!/bin/bash
#
# Script: run_cleanup-control-plane.sh
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

INSTANCE_NAME="control-plane"
BASE_IMAGE="control-plane"
CONTROL_PLANE_PROFILE="control-plane"

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
elif ! command_output=$(incus delete $INSTANCE_NAME -f 2>&1 >/dev/null); then
    log_error "Failed to delete instance $INSTANCE_NAME" $command_output
fi

log_info "Deleting profile $CONTROL_PLANE_PROFILE"
if ! incus profile show $CONTROL_PLANE_PROFILE &> /dev/null; then
    log_info "No profile $CONTROL_PLANE_PROFILE was found"
elif ! command_output=$(incus profile delete $CONTROL_PLANE_PROFILE 2>&1 >/dev/null); then
    log_error "Failed to delete profile $CONTROL_PLANE_PROFILE" "$command_output"
fi

log_info "Deleting image $BASE_IMAGE"
if ! incus image info $BASE_IMAGE &> /dev/null; then
    log_info "No image $BASE_IMAGE was found"
elif command_output=$(incus image info ${BASE_IMAGE} 2>&1 >/dev/null); then
    log_error "Failed to delete image $BASE_IMAGE" "$command_output"
fi

#########################################################
# Finalization #
#########################################################

log_info "Clean up completed successfully"

