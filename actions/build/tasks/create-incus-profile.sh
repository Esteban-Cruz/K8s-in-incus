#!/bin/bash


#########################################################
# Initialization #
#########################################################
set -euo pipefail
source ./common/log_functions.sh

declare -a PROFILE_NAME
declare -a IPV4
declare -a GATEWAY

#########################################################
# Parse command options #
#########################################################
OPTS=$( getopt -ao '' --long profile-name:,ipv4:,gateway: -- "$@" )
eval set -- ${OPTS}
while true;
do
  case $1 in
    --profile-name)             PROFILE_NAME="$2"                 ; shift 2       ;;
    --ipv4)                     IPV4="$2"                         ; shift 2       ;;
    --gateway)                  GATEWAY="$2"                      ; shift 2       ;;
    --)                                                             shift; break  ;;
    *) >&2 log_error Unsupported option: $1                       ; exit 1        ;;
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

  if [[ -z "$PROFILE_NAME" ]] ; then
    log_error "Could not create ip address for the incus profile ${PROFILE_NAME}."
    exit 1
  fi

  if [[ -z "$GATEWAY" ]] ; then
    log_error "Missing required gateway."
    exit 1
  fi

  if [[ -z "$IPV4" ]] ; then
    log_error "Missing ipv4."
    exit 1
  fi

}

#########################################################
# Main Script #
#########################################################

log_message "Attempting to create Incus profile '${PROFILE_NAME}'."
check_prerequisits

if incus profile show "$PROFILE_NAME" &> /dev/null
then
    log_message "Incus profile '${PROFILE_NAME}' already exists, skipping profile creation."
else
    log_message "Incus profile '${PROFILE_NAME}' does not exist, creating it."
    incus profile create ${PROFILE_NAME} &> /dev/null && \
    incus profile edit ${PROFILE_NAME} <<EOF
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
          - ${IPV4}
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
    network: incusbr0
    type: nic
  root:
    path: /
    pool: default
    type: disk
    size.state: 2500MiB
name: ${PROFILE_NAME}
EOF
fi

if [[ $? -gt 0 ]] ; then
  log_error "Could not create Incus profile '${PROFILE_NAME}'."
fi

log_message "Incus profile '${PROFILE_NAME}' created successfully."

#########################################################
# Finalization #
#########################################################

exit 0
