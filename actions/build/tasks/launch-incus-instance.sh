#!/bin/bash

#########################################################
# Initialization #
#########################################################
set -euo pipefail
source ./common/log_functions.sh

IMAGE=
INSTANCE_HOSTNAME=
PROFILE=
CPUS=2
MEMORY="2000MiB"

#########################################################
# Parse command options #
#########################################################

OPTS=$( getopt -ao '' --long image:,hostname:,profile:,cpus:,memory: -- "$@" )
eval set -- ${OPTS}
while true;
do
  case $1 in
    --image)        IMAGE=$2                ; shift 2   ;;
    --hostname)     INSTANCE_HOSTNAME=$2    ; shift 2   ;;
    --profile)      PROFILE=$2              ; shift 2   ;;
    --cpus)         CPUS=$2                 ; shift 2   ;;
    --memory)       MEMORY=$2               ; shift 2   ;;
    --) shift; break ;;
    *) >&2 echo Unsupported option: $1 ;;
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

  if incus info ${INSTANCE_HOSTNAME} &> /dev/null ; then
    log_error "Can't launch instance '${INSTANCE_HOSTNAME}' since another with the same name is currently running."
    exit 1
  fi
}

#########################################################
# Main Script #
#########################################################

log_message "Attempting to launch Incus instance '${INSTANCE_HOSTNAME}'..."
check_prerequisits

incus launch ${IMAGE} ${INSTANCE_HOSTNAME} \
  --profile ${PROFILE} \
  --vm \
  --config limits.cpu=${CPUS} \
  --config limits.memory=${MEMORY} \
  --config migration.stateful="true"

if [[ $? -gt 0 ]] ; then
  log_error "Could not launch Incus instance '${INSTANCE_HOSTNAME}'."
  exit 1
fi

log_message "Incus instance '${INSTANCE_HOSTNAME}' launched successfully."

#########################################################
# Finalization #
#########################################################

exit 0
