#!/bin/bash
set -euo pipefail

#########################################################
# Initialization #
#########################################################

declare PROFILE_NAME
declare STATIC_ADDRESS
declare GATEWAY

#########################################################
# Parse command options #
#########################################################

OPTS=$( getopt -ao '' --long profile-name:,network-name:,static-address:,gateway: -- "$@" )
eval set -- ${OPTS}
while true;
do
  case $1 in
    --profile-name)             PROFILE_NAME="$2"                 ; shift 2       ;;
    --network-name)             NETWORK_NAME="$2"                 ; shift 2       ;;
    --static-address)           STATIC_ADDRESS="$2"               ; shift 2       ;;
    --gateway)                  GATEWAY="$2"                      ; shift 2       ;;
    --)                                                             shift; break  ;;
    *) >&2 log_error Unsupported option: $1                       ; exit 1        ;;
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

}

#########################################################
# Main Script #
#########################################################

check_prerequisites
log_info "Creating and configuring Incus profile '${PROFILE_NAME}'."

if incus profile show ${PROFILE_NAME} &> /dev/null
then
    log_info "Incus profile '${PROFILE_NAME}' already exists, skipping profile creation."
else
    log_info "Incus profile '${PROFILE_NAME}' does not exist, creating it."
    if ! command_output=$(incus profile create ${PROFILE_NAME} 2>&1 >/dev/null ); then
      log_error "Failed to create incus profile ${PROFILE_NAME}." \
        "$command_output"
      exit 1
    fi
fi

log_debug "Adding static address '${STATIC_ADDRESS}' and default gateway '${GATEWAY}' to profile '${PROFILE_NAME}' "
if ! command_output=$(incus profile edit "${PROFILE_NAME}" <<EOF 2>&1 >/dev/null
config:
  cloud-init.user-data: |
    runcmd:
    - source /root/.profile
  cloud-init.network-config: |
    version: 2
    ethernets: 
      enp5s0: 
        dhcp4: no
        addresses:
          - ${STATIC_ADDRESS}
        routes:
          - to: default
            via: ${GATEWAY}
        nameservers:
            addresses: 
              - 8.8.8.8
              - 8.8.4.4
description: ${PROFILE_NAME} profile
devices:
  eth0:
    name: eth0
    network: ${NETWORK_NAME}
    type: nic
  root:
    path: /
    pool: default
    type: disk
    size.state: 2500MiB
name: ${PROFILE_NAME}
EOF
); then
  log_error "Failed to edit incus profile '${PROFILE_NAME}'" \
    "$command_output"
  exit 1
fi

log_info "Incus profile '${PROFILE_NAME}' configured successfully."

#########################################################
# Finalization #
#########################################################

exit 0
