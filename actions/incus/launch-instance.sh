#!/bin/bash
set -euo pipefail

#########################################################
# Initialization #
#########################################################

declare IMAGE
declare INSTANCE_HOSTNAME
declare PROFILE
declare -i CPUS=2
declare MEMORY="2000MiB"

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

source ./common/log_functions.sh

check_prerequisites() {
  if [[ $# -gt 0 ]] ; then
      log_error "Arguments are not supported for this script."
      exit 1
  fi

  if [[ -z "$(incus --version)" ]]; then
    log_error "It appears that incus is not installed in the system, or could not be found." \
      "It is recommended to use incus version 6.0.0."
    exit 1
  fi

  if incus info ${INSTANCE_HOSTNAME} &> /dev/null ; then
    log_error "Failed to launch instance '${INSTANCE_HOSTNAME}' since another with the same name is currently running."
    exit 1
  fi
}

#########################################################
# Main Script #
#########################################################

check_prerequisites
log_info "Launching Incus instance '${INSTANCE_HOSTNAME}'."

log_debug "Instance details: image=${IMAGE}, hostname=${INSTANCE_HOSTNAME}, profile=${PROFILE}, cpus=${CPUS}, memory=${MEMORY}"
if ! command_output=$(incus launch ${IMAGE} ${INSTANCE_HOSTNAME} \
  --profile ${PROFILE} \
  --vm \
  --config limits.cpu=${CPUS} \
  --config limits.memory=${MEMORY} \
  --config migration.stateful="true" 2>&1 >/dev/null )
then
  log_error "Could not launch Incus instance '${INSTANCE_HOSTNAME}'." "$command_output"
  exit 1
fi

log_info "Incus instance '${INSTANCE_HOSTNAME}' launched successfully."

#########################################################
# Finalization #
#########################################################

exit 0
