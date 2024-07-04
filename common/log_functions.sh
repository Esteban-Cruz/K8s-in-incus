#!/bin/bash


log_info() {
    set +u

    local level="INFO"
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%dT%H:%M:%SZ")
    local raw_log="[$timestamp] $level - $message"

    if [ "$WRITE_TO_LOGFILE" = true ]; then
        local log_json="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\"}"
        echo "$log_json" >> "$LOG_FILE"
    fi
    echo "$raw_log"

    set -u
}

log_warning() {
    set +u

    local level="WARNING"
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%dT%H:%M:%SZ")
    local log_entry="[$timestamp] $level - $message"

    if [ "$WRITE_TO_LOGFILE" = true ]; then
        local log_json="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\"}"
        echo "$log_json" >> "$LOG_FILE"
    fi
    echo "$log_entry" >&2

    set -u
}

log_error() {
    set +u
    
    local level="ERROR"
    local message="$1"
    local details="$2"

    local log_details=""
    if [ -n "$details" ]; then
        log_details=", details: $details"
    fi

    local timestamp
    timestamp=$(date +"%Y-%m-%dT%H:%M:%SZ")
    local log_raw="[$timestamp] $level - $message $log_details"

    if [ "$WRITE_TO_LOGFILE" = true ]; then
        local log_json="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\",\"details\":\"$details\"}"
        echo "$log_json" >> "$LOG_FILE"
    fi
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
        local log_raw="[$timestamp] $level - $message"

        if [ $WRITE_TO_LOGFILE = true ]; then
            local log_json="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\"}"
            echo "$log_json" >> "$LOG_FILE"
        fi
        echo "$log_raw"
    fi
    set -u
}
