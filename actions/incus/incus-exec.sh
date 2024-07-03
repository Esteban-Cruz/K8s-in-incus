#!/bin/bash

#########################################################
# Initialization #
#########################################################

set -euo pipefail
DEFAULT_UID=0
DEFAULT_INCUS_CWD="/"

#########################################################
# Usage #
#########################################################

usage() {
  cat << EOF
Usage: $0 [--uid <uid>] [--incus-cwd <directory>] [--instance-name <name>] --script <path_to_script> [--flag1 <value1>] [--flag2 <value2>] ...

Options:
  --uid <uid>                         UID for the user (default: ${DEFAULT_UID})
  --incus-cwd <directory>             Working directory inside incus instance (default: ${DEFAULT_INCUS_CWD})
  --instance-name <name>              Name of the incus instance (required)
  --script <path_to_script>           Path to the script in the host to execute inside the incus instance (required)
  [--<additional-flag> <value1>] ...  Optional flag with value (optional)
EOF
}

#########################################################
# Parse command options #
#########################################################

# Defaults
USER_ID="${DEFAULT_UID}"
INCUS_CWD="${DEFAULT_INCUS_CWD}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --uid)            USER_ID="$2"        ; shift 2 ;;
    --incus-cwd)      INCUS_CWD="$2"      ; shift 2 ;;
    --instance-name)  INSTANCE_NAME="$2"  ; shift 2 ;;
    --script)         SCRIPT="$2"         ; shift 2 ;;
    --*)              FLAGS+=("$1 $2")    ; shift 2 ;;
    *)                usage               ; exit 1  ;;
  esac
done

#########################################################
# Bash functions definition #
#########################################################

source ./common/log_functions.sh

check_prerequisites() {
    if [[ -z "${INSTANCE_NAME}" ]]; then
      log_error "Missing required argument '--instance-name'."
      usage ; exit 1
    fi
    if [[ -z "${SCRIPT}" ]]; then
      log_error "At least one script is required."
      usage ; exit 1
    fi
}

#########################################################
# Main Script #
#########################################################

check_prerequisites

log_message "Execute the script on incus instance"
remote_script="${INCUS_CWD}/$(basename "${SCRIPT}")"

# Push the script to the remote instance
# log_message "DEBUG: incus file push "${SCRIPT}" "${INSTANCE_NAME}${remote_script}" --uid "${USER_ID}" --create-dirs"
incus file push "${SCRIPT}" "${INSTANCE_NAME}${remote_script}" --uid "${USER_ID}" --create-dirs \
  || log_error "Failed to push file ${SCRIPT}"

# Construct the command to execute the script
command="${remote_script}"
for flag in "${FLAGS[@]}"; do
  command+=" ${flag}"
done

# Execute the script on the remote instance
incus exec "${INSTANCE_NAME}" -- /bin/bash -c "${command}" ||
  { 
    log_error "Failed to run script ${remote_script}"
  }

#########################################################
# Finalization #
#########################################################
