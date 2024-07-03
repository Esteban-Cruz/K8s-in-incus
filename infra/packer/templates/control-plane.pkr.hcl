packer {
  required_plugins {
    incus = {
      source  = "github.com/bketelsen/incus"
      version = "~> 1"
    }
  }
}

source "incus" "k8s-master" {
  image           = "images:ubuntu/22.04/cloud"
  reuse           = true
  virtual_machine = true
  output_image    = "k8s-control-plane"
  profile         = "control-plane"
  launch_config = {
    "limits.cpu"    = "2"
    "limits.memory" = "2000MiB"
    "migration.stateful" = "true"
  }

  publish_properties = {
    description = "Ubuntu Kubernetes Control Plane"
  }
}

build {
  sources = ["incus.k8s-master"]
  provisioner "shell" {
    env = {
      "CONTROL_PLANE_CIDR" = "10.125.165.111/24",
      "DEFAULT_GATEWAY" = "10.125.165.1",
    }
    scripts = [
      "../scripts/provisioners/preProvision.sh",
      # "../scripts/provisioners/containerd.sh",
      # "../scripts/provisioners/network-configurations.sh",
      # "../scripts/provisioners/control-plane-prerequisites.sh",
      # "../scripts/provisioners/init-kubeadm-cluster.sh",
    ]
  }
}


