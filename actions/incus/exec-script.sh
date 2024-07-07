#!/bin/bash
set -euo pipefail

#########################################################
# Initialization #
#########################################################

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
log_info "Executing script '${SCRIPT}' against incus instance"

remote_script="${INCUS_CWD}/$(basename "${SCRIPT}")"

log_debug "Pushing script '$SCRIPT' to $INSTANCE_NAME:$INCUS_CWD using uid $USER_ID."
log_debug "Full path to script inside the ${INSTANCE_NAME} instance: '${remote_script}'"
if ! command_output=$(incus file push "${SCRIPT}" "${INSTANCE_NAME}${remote_script}" --uid "${USER_ID}" --create-dirs 2>&1 >/dev/null);
then
  log_error "Failed to push script ${SCRIPT} to instance $INSTANCE_NAME." "$command_output"
  exit 1
fi

log_debug "Constructing the command to execute the script"
command="${remote_script}"
for flag in "${FLAGS[@]}"; do
  command+=" ${flag}"
done

log_debug "Running against instance $INSTANCE_NAME the following command: '/bin/bash -c ${command}'"
if ! command_output=$(incus exec "${INSTANCE_NAME}" -- /bin/bash -c "${command}" 2>&1 >/dev/null);
then
  log_error "Failed to run script ${remote_script}" "$command_output"
  exit 1
fi

log_debug "Removing script from $INSTANCE_NAME after its execution"
if ! command_output=$(incus exec "${INSTANCE_NAME}" -- /bin/bash -c "rm ${remote_script}" 2>&1 >/dev/null);
then
  log_warning "Failed to remove script $remote_script from $INSTANCE_NAME after its executing"
fi

#########################################################
# Finalization #
#########################################################

log_info "Successfully executed script '${SCRIPT}' against incus instance"
