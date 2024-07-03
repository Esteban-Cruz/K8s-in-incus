#!/bin/bash

CONTROL_PLANE_CIDR="10.125.165.10/24"
DEFAULT_GATEWAY="10.125.165.1"

tee <<EOF
config:
  cloud-init.network-config: |
    version: 2
    ethernets: 
      enp5s0: 
        dhcp4: no
        addresses:
          - ${CONTROL_PLANE_CIDR}
        routes:
          - to: default
            via: ${DEFAULT_GATEWAY}
        nameservers:
            addresses: 
              - 8.8.8.8
              - 8.8.4.4
description: Control plane profile
devices:
  eth0:
    name: eth0
    network: incusbr0
    type: nic
  root:
    path: /
    pool: default
    size.state: 3000MiB
    type: disk
name: Control plane
EOF