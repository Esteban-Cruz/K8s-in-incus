#!/bin/bash

set -o pipefail

source ./common/log_functions.sh


# Check if incus command is installed and accessible.
# Usage: is_incus_installed
# Returns: 0 if incus is installed and accessible, non-zero otherwise.
is_incus_installed() {
    if ! command_output=$(incus --version &> /dev/null); then
        return 1
    fi
}

# Check if installed incus version matches the desired version.
# Usage: is_incus_version <desired_version>
# Returns: Return 0 if the desired version of incus is installed, return 1 otherwise
is_incus_version() {
    local desired_version="$1"
    if [ -z "$desired_version" ]; then
        log_error "No desired incus version was provided"
        exit 1
    fi

    local current_version
    if ! command_output=$(incus --version 2>&1 >/dev/null); then
        log_error "$command_output"
        exit 1
    fi

    current_version=$command_output
    if [ "$current_version" != "$desired_version" ]; then
        return 1
    fi
}

# Attempts to create an incus network with the name provided.
# Usage: create_incus_network <network_name>
# Returns: None
create_incus_network() {
    local network_name="$1"
    local type="${2:-bridge}"

    if [ -z "$network_name" ]; then
        log_error "Can't create incus network if no name is provided"
        exit 1
    fi

    if command_output=$( incus network show "$network_name" &> /dev/null ); then
        log_error "Couldn't create incus network '$network_name' because it already exists"
        exit 1
    fi

    if ! command_output=$(incus network create "$network_name" --type "$type" 2>&1 ); then
        log_error "Failed to create incus network $network_name" "$command_output"
        exit 1
    fi
}


# Attempts to delete an incus network with the specified name.
# Usage: delete_incus_network <network_name>
# Returns: None
delete_incus_network() {
    local network_name="$1"
    if [ -z "$network_name" ]; then
        log_error "Can't delete an incus network if no name is provided"
        exit 1
    fi

    if ! incus network show "$network_name" &> /dev/null; then
        log_error "No incus network $network_name was found for deleting"
        exit 1
    fi

    if ! command_output=$(incus network delete "${network_name}" 2>&1 >/dev/null); then
        log_error "$command_output"
        exit 1
    fi
}


# Retrieves the default gateway in CIDR format for a specified network.
# Usage: get_network_default_gateway_cidr <network_name>
# Returns: The default gateway in CIDR format, or an error on failure.
get_network_default_gateway_cidr() {
    local network_name="$1"

    if [ -z "$network_name" ]; then
        log_error "Missing network name argument"
        exit 1
    fi

    if ! command_output=$(incus network list --format yaml | \
      yq eval ".[] | select(.name==\"${network_name}\") | .config[\"ipv4.address\"]" - );
    then
        log_error "$command_output"2
        exit 1
    fi

    if [ -z "$command_output" ]; then
        log_error "No default gateway was found for network '$network_name'"
        exit 1
    fi
    echo "$command_output"
}


# Calculates the next ip address to the one provided.
# Usage: get_next_ipv4 <IP address>
# Returns: The next IP address.
get_next_ipv4(){
    if [ -z "$1" ]; then
        log_error "IP address is missing for calculating the next one."
        exit 1
    fi

    if ! [[ "$1" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
        log_error "The provided ip address '$1' is not valid"
        exit 1
    fi

    local ip=$1
    local increment=${2:-1}
    local ip_hex=$(printf '%.2X%.2X%.2X%.2X\n' `echo $ip | sed -e 's/\./ /g'`)
    local next_ip_hex=$(printf %.8X `echo $(( 0x$ip_hex + $increment ))`)
    local next_ip=$(printf '%d.%d.%d.%d\n' `echo $next_ip_hex | sed -r 's/(..)/0x\1 /g'`)
    echo "$next_ip"
}