#!/bin/bash

log_message() {
    local datetime
    datetime=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${datetime} - $1"
}

log_error() {
    local datetime
    datetime=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${datetime} - ERROR - $1"  >&2
}

root_required() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root."
        exit 1
    fi
}
