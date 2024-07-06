# #!/bin/bash
# #
# # Script: run_build-control-plane.sh
# # Author: Esteban Cruz
# # Date: June 27, 2024
# # Description: 
# #   Description goes here.
# # Usage:
# #   - Instructions go here.
# #

# #########################################################
# # Initialization #
# #########################################################
# set -eo pipefail

# declare HOSTNAME
# declare NETWORK
# declare IPV6_CIDR

# declare CPUS=2
# declare MEMORY="2GiB"
# declare BASE_IMAGE="images:ubuntu/22.04/cloud"

# declare CONTAINERD_VERSION="1.7.12"
# declare KUBERNETES_REPOSITORY_VERSION="v1.30"
# declare KUBEADM_VERSION="1.30.0-1.1"
# declare KUBELET_VERSION="1.30.0-1.1"
# declare KUBECTL_VERSION="1.30.0-1.1"
# declare POD_NETWORK_ADDON="https://reweave.azurewebsites.net/k8s/v1.30/net.yaml"

# #########################################################
# # Bash functions definition #
# #########################################################

# source ./common/log_functions.sh

# #########################################################
# # Parse command options #
# #########################################################

# OPTS=$( getopt -ao '' --long hostname:,network:,cpus:,memory:,base-image:,containerd-version:,kubeadm-version:,kubelet-version:,kubectl-version:,pod-network-addon: -- "$@" )
# eval set -- ${OPTS}
# while true;
# do
#   case $1 in
#     --hostname)               HOSTNAME="$2"                   ; shift 2   ;;
#     --network)                NETWORK="$2"                   ; shift 2   ;;
#     --cpus)                   CPUS="$2"                       ; shift 2   ;;
#     --memory)                 MEMORY="$2"                     ; shift 2   ;;
#     --base-image)             BASE_IMAGE="$2"                 ; shift 2   ;;
#     --containerd-version)     CONTAINERD_VERSION="$2"         ; shift 2   ;;
#     --kubeadm-version)        KUBEADM_VERSION="$2"            ; shift 2   ;;
#     --kubelet-version)        KUBELET_VERSION="$2"            ; shift 2   ;;
#     --kubectl-version)        KUBECTL_VERSION="$2"            ; shift 2   ;;
#     --pod-network-addon)      POD_NETWORK_ADDON="$2"          ; shift 2   ;;
#     --) shift; break ;;
#     *) >&2 echo Unsupported option: $1 ;;
#   esac
# done

# # #########################################################
# # # Defaults #
# # #########################################################

# #########################################################
# # Checks #
# #########################################################

# if [ -z "$HOSTNAME" ]; then
#   log_error "No hostname was provided"
#   exit 1
# fi

# if [ -z "$NETWORK" ]; then
#   log_error "No network was provided"
#   exit 1
# fi

# #########################################################
# # Main Script #
# #########################################################

# if ! ./actions/incus/create-profile.sh \
#   --profile-name="${HOSTNAME}" \
#   --network-name="${NETWORK}" \
#   --static-address="${CONTROL_PLANE_ADDRESS_CIDR}" \
#   --gateway="${DEFAULT_GATEWAY_ADDRESS}"; 
# then
#   log_error "Failed to run script to create incus profile"
#   exit 1
# fi

# #########################################################
# # Finalization #
# #########################################################

# exit 0

# # source ./common/log_functions.sh

# # get_valid_network_interface() {
# #   local interface_name=$( incus network list --format yaml | \
# #     yq eval ' .[] | select(.managed==true and .type=="bridge" and .config["ipv4.nat"]==true and .status=="Created") | .name ' - | head -n1 )
# #   echo "$interface_name"
# # }

# # get_default_gateway_cidr() {
# #   local network_name="$1"
# #   if [ -n "$network_name" ]; then
# #     local ipv4_default_gateway=$(incus network list --format yaml | \
# #       yq eval " .[] | select(.name==\"${network_name}\") | .config[\"ipv4.address\"]" -)
# #     echo "$ipv4_default_gateway"
# #   fi
# # }

# # get_nextip(){
# #     local increment=1
# #     if [ -n "$2" ]; then
# #         increment=$2
# #     fi
# #     local ip=$1
# #     local ip_hex=$(printf '%.2X%.2X%.2X%.2X\n' `echo $ip | sed -e 's/\./ /g'`)
# #     local next_ip_hex=$(printf %.8X `echo $(( 0x$ip_hex + $increment ))`)
# #     local next_ip=$(printf '%d.%d.%d.%d\n' `echo $next_ip_hex | sed -r 's/(..)/0x\1 /g'`)
# #     echo "$next_ip"
# # }

# # is_incus_installed() {
# #   if [[ -z "$(incus --version)" ]]; then
# #     log_error "It appears that incus is not installed in the system, or could not be found." \
# #       "It is recommended to use incus version 6.0.0."
# #     exit 1
# #   fi
# # }

# # check_prerequisites() {
# #   is_incus_installed
# # }

# # #########################################################
# # # Defaults #
# # #########################################################
# # # -------------------------------------------------------
# # # CLUSTER SETTINGS #
# # # -------------------------------------------------------
# # NETWORK_NAME=$(get_valid_network_interface)
# # DEFAULT_GATEWAY_CIDR=$(get_default_gateway_cidr "$NETWORK_NAME")
# # DEFAULT_GATEWAY_ADDRESS=${DEFAULT_GATEWAY_CIDR%/*}
# # NETWORK_SUBMASK=${DEFAULT_GATEWAY_CIDR#*/}
# # # -------------------------------------------------------
# # # CONTROL PLANE SETTINGS #
# # # -------------------------------------------------------
# # CONTROL_PLANE_HOSTNAME="control-plane"
# # CONTROL_PLANE_BASE_IMAGE="images:ubuntu/22.04/cloud"
# # CONTROL_PLANE_ADDRESS_CIDR=$(get_nextip ${DEFAULT_GATEWAY_CIDR%/*} 1)/${NETWORK_SUBMASK}
# # CONTROL_PLANE_ADDRESS=${CONTROL_PLANE_ADDRESS_CIDR%/*}
# # CONTROL_PLANE_CPUS="2"
# # CONTROL_PLANE_MEMORY="2GiB"
# # CONTROL_PLANE_CONTAINERD_VERSION="1.7.12"
# # CONTROL_PLANE_KUBERNETES_REPOSITORY_VERSION="v1.30"
# # CONTROL_PLANE_KUBEADM_VERSION="1.30.0-1.1"
# # CONTROL_PLANE_KUBELET_VERSION="1.30.0-1.1"
# # CONTROL_PLANE_KUBECTL_VERSION="1.30.0-1.1"
# # POD_NETWORK_ADDON="https://reweave.azurewebsites.net/k8s/v1.30/net.yaml"

# # #########################################################
# # # Main Script #
# # #########################################################

# # check_prerequisites
# # log_info "Starting Control plane build script."

# # if ! ./actions/incus/create-profile.sh \
# #   --profile-name="${CONTROL_PLANE_HOSTNAME}" \
# #   --network-name="${NETWORK_NAME}" \
# #   --static-address="${CONTROL_PLANE_ADDRESS_CIDR}" \
# #   --gateway="${DEFAULT_GATEWAY_ADDRESS}"; 
# # then
# #   log_error "Failed to run script to create incus profile"
# #   exit 1
# # fi


# # if ! ./actions/incus/launch-instance.sh \
# #   --image="${CONTROL_PLANE_BASE_IMAGE}" \
# #   --hostname="${CONTROL_PLANE_HOSTNAME}" \
# #   --profile="${CONTROL_PLANE_HOSTNAME}" \
# #   --cpus="${CONTROL_PLANE_CPUS}" \
# #   --memory="${CONTROL_PLANE_MEMORY}";
# # then
# #   log_error "Failed to run script to launch incus instance"
# #   exit 1
# # fi


# # ./actions/incus/wait-for-instance.sh \
# #   --instance-name="${CONTROL_PLANE_HOSTNAME}" \
# #   --max-retries=10


# # log_info "Install Containerd"
# # ./actions/incus/exec-script.sh \
# #   --incus-cwd "/tmp/kubeadm/provision" \
# #   --instance-name "${CONTROL_PLANE_HOSTNAME}" \
# #   --script "./actions/build/provision-scripts/containerd.sh" \
# #   --containerd-version "${CONTROL_PLANE_CONTAINERD_VERSION}"


# # log_info "Configure Incus network"
# # ./actions/incus/exec-script.sh \
# #   --incus-cwd "/tmp/kubeadm/provisioning" \
# #   --instance-name "${CONTROL_PLANE_HOSTNAME}" \
# #   --script "./actions/build/provision-scripts/network-configurations.sh"


# # log_info "Installing kubernetes components"
# # ./actions/incus/exec-script.sh \
# #   --incus-cwd "/tmp/kubeadm/provisioning" \
# #   --instance-name "${CONTROL_PLANE_HOSTNAME}" \
# #   --script "./actions/build/provision-scripts/kubernetes-components.sh" \
# #   --repository-version "${CONTROL_PLANE_KUBERNETES_REPOSITORY_VERSION}" \
# #   --kubeadm "${CONTROL_PLANE_KUBEADM_VERSION}" \
# #   --kubelet "${CONTROL_PLANE_KUBELET_VERSION}" \
# #   --kubectl "${CONTROL_PLANE_KUBECTL_VERSION}" \
# #   --pull-images "true"


# # log_info "Initializing Kubernetes cluster with Kubeadm"
# # ./actions/incus/exec-script.sh \
# #   --incus-cwd "/tmp/kubeadm/provisioning" \
# #   --instance-name "${CONTROL_PLANE_HOSTNAME}" \
# #   --script "./actions/build/provision-scripts/init-kubeadm-cluster.sh" \
# #   --node-name "${CONTROL_PLANE_HOSTNAME}" \
# #   --apiserver-advertise-address "${CONTROL_PLANE_ADDRESS}" \
# #   --network-addon "${POD_NETWORK_ADDON}"


# # log_info "Applying customizations"
# # ./actions/incus/exec-script.sh \
# #   --incus-cwd "/tmp/kubeadm/provisioning" \
# #   --instance-name "${CONTROL_PLANE_HOSTNAME}" \
# #   --script "./actions/build/provision-scripts/customizations.sh"

# # # log_info "Creating stateful snapshot."
# # # incus snapshot create ${MASTER_HOSTNAME} ${MASTER_HOSTNAME} --stateful

# # # log_info "Publishing ${MASTER_HOSTNAME} as image."
# # # incus stop ${MASTER_HOSTNAME} --stateful
# # # incus publish ${MASTER_HOSTNAME} --alias ${MASTER_HOSTNAME} --reuse --force-local

# # #########################################################
# # # Finalization #
# # #########################################################

# # log_info "Control Plane built successfully!!! :-)"
