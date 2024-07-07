#!/bin/bash


log_info() {
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
}

log_warning() {
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
}

log_error() {    
    local level="ERROR"
    local message="$1"
    local details="$2"

    local log_details=""
    if [ -n "$details" ]; then
        log_details="Details: $details"
    fi

    local timestamp
    timestamp=$(date +"%Y-%m-%dT%H:%M:%SZ")

    local caller_func="${FUNCNAME[1]}"
    local caller_lineno="${BASH_LINENO}"
    local caller_file="${BASH_SOURCE[1]}"

    local log_entry="[${timestamp}] ${level} - $message ($caller_file: line: $caller_lineno)"

    if [ -n "$log_details" ]; then
        log_entry+=" - ${log_details}"
    fi

    if [ "$WRITE_TO_LOGFILE" = true ]; then
        local log_json="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\",\"details\":\"$details\",\"function\":\"$caller_func\",\"line\":\"$caller_lineno\",\"file\":\"$caller_file\"}"
        echo "$log_json" >> "$LOG_FILE"
    fi

    echo "$log_entry" >&2
}

log_debug() {
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
}
