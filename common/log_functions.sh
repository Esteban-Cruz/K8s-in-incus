#!/bin/bash

LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/kubernetes-in-incus-$(date +"%Y%m%d").log"

log_info() {
    set +u

    local level="INFO"
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%dT%H:%M:%SZ")
    local log_json="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\"}"
    local raw_log="[$timestamp] $level - $message"

    echo "$log_json" >> "$LOG_FILE"
    echo "$raw_log"

    set -u
}


log_error() {
    set +u
    
    local level="ERROR"
    local message="$1"
    local details="$2"

    # local log_details=""
    # if [ -n "$details" ]; then
    #     log_details=",\"details\":\"$details\""
    # fi

    local timestamp
    timestamp=$(date +"%Y-%m-%dT%H:%M:%SZ")
    local log_json="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\",\"details\":\"$details\"}"
    local log_raw="[$timestamp] $level - $message: $details"

    echo "$log_json" >> "$LOG_FILE"
    echo "$log_raw" >&2

    set -u
}


log_debug() {
    set +u
    if [ "$DEBUG" = true ]; then
        local level="DEBUG"
        local message="$1"
        local timestamp
        timestamp=$(date +"%Y-%m-%dT%H:%M:%SZ")
        local log_json="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\"}"
        local log_raw="[$timestamp] $level - $message"

        echo "$log_json" >> "$LOG_FILE"
        echo "$log_raw"
    fi
    set -u
}
