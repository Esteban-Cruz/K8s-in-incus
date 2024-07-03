#!/bin/bash

#########################################################
# Initialization #
#########################################################

set -euo pipefail
source ./common/log_functions.sh

INSTANCE_NAME=

#########################################################
# Parse command options #
#########################################################

OPTS=$( getopt -ao 'i:' --long instance-name: -- "$@" )
eval set -- ${OPTS}
while true;
do
  case $1 in
    -i | --instance-name)             INSTANCE_NAME=$2          ; shift 2       ;;
    --)                                                           shift; break  ;;
    *) >&2 log_error Unsupported option: $1                     ; exit 1        ;;
  esac
done

#########################################################
# Bash functions definition #
#########################################################

check_prerequisits() {
    if [[ $# -gt 0 ]] ; then
        log_error "Arguments are not supported for this script."
        exit 1
    fi

    # Assert instance is in running state.
    INSTANCE_STATUS=$(incus list -f yaml | yq eval " .[] | select(.name==\"${INSTANCE_NAME}\") | .status " -)
    if [[ "$INSTANCE_STATUS" != "Running" ]] ; then
        log_error "The instance ${INSTANCE_NAME} is not running."
        exit 1
    fi
}

#########################################################
# Main Script #
#########################################################

check_prerequisits
log_message "Waiting for instance '${INSTANCE_NAME}' to be ready..."

MAX_RETRIES=10
RETRIES=0
until [ $RETRIES -ge $MAX_RETRIES ]
do
  # TODO(Esteban Cruz): Use Instance Interface status instead of this check.
  if $( incus exec ${INSTANCE_NAME} -- ls &> /dev/null ) ; then
    log_message "Instance is ready." ; break
  fi
  RETRIES=$(( RETRIES+1 )) ; sleep 5
  log_message "Instance is not ready, retrying in 5 seconds..."
done

if [[ $RETRIES -ge $MAX_RETRIES ]] ; then
  log_error "There must be something wrong with the instance ${INSTANCE_NAME}."
  exit 1
fi

#########################################################
# Finalization #
#########################################################

exit 0
