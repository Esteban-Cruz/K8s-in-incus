#!/bin/bash

#######################
# Logging Functions   #
#######################

# Define log file (can be overridden by individual scripts)
LOG_FILE="/var/log/common_script.log"


log_message() {
    local datetime=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${datetime} - $1" | tee -a ${LOG_FILE}
}

debug_message() {
    if [[ "${DEBUG:-}" == "true" ]]; then
        local datetime=$(date +"%Y-%m-%d %H:%M:%S")
        echo "${datetime} - DEBUG - $1" | tee -a ${LOG_FILE}
    fi
}

log_error() {
    local datetime=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${datetime} - ERROR - $1" | tee -a ${LOG_FILE} >&2
}