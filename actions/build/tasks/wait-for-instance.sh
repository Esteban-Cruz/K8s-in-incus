#!/bin/bash
set -euo pipefail

#########################################################
# Initialization #
#########################################################

declare INSTANCE_NAME
declare MAX_RETRIES=10

#########################################################
# Parse command options #
#########################################################

OPTS=$( getopt -ao '' --long instance-name:,max-retries: -- "$@" )
eval set -- ${OPTS}
while true;
do
  case $1 in
    --instance-name)             INSTANCE_NAME=$2          ; shift 2       ;;
    --max-retries)                    MAX_RETRIES=$2            ; shift 2       ;;
    --)                                                           shift; break  ;;
    *) >&2 log_error Unsupported option: $1                     ; exit 1        ;;
  esac
done

#########################################################
# Bash functions definition #
#########################################################

source ./common/log_functions.sh

check_prerequisites() {
  if [[ $# -gt 0 ]]; then
      log_error "Arguments are not supported for this script."
      exit 1
  fi

  if [[ -z "$(incus --version)" ]]; then
    log_error "It appears that incus is not installed in the system, or could not be found." \
      "It is recommended to use incus version 6.0.0."
    exit 1
  fi

  local instance_status=$(incus list -f yaml | yq eval " .[] | select(.name==\"${INSTANCE_NAME}\") | .status " -)
  if [[ "$instance_status" != "Running" ]]; then
      log_error "No instance ${INSTANCE_NAME} was found."
      exit 1
  fi
}

#########################################################
# Main Script #
#########################################################

check_prerequisites
log_info "Waiting for instance '${INSTANCE_NAME}' to be ready."

retries_count=0
until [ $retries_count -ge $MAX_RETRIES ]
do
  # TODO(Esteban Cruz): Can we check the ipv4 interface status instead?
  if incus exec ${INSTANCE_NAME} -- ls &> /dev/null; then
    log_info "Instance is ready." ; break
  fi
  retries_count=$(( retries_count+1 )) ; sleep 5
  log_info "Instance is not ready, retrying in 5 seconds..."
done

if [[ $retries_count -ge $MAX_RETRIES ]] ; then
  log_error "Failed to reach instance ${INSTANCE_NAME} after $MAX_RETRIES retries."
  exit 1
fi

#########################################################
# Finalization #
#########################################################

exit 0
