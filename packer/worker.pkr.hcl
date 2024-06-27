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
  output_image    = "k8s-node"
  profile         = "node01"
  launch_config = {
    "limits.cpu"    = "2"
    "limits.memory" = "2000MiB"
  }

  publish_properties = {
    description = "Ubuntu Kubernetes Worker"
  }
}

build {
  sources = ["incus.k8s-master"]
  provisioner "shell" {
    env = {
      "ROLE" = "worker",
    }
    scripts = [
      "./scripts/preProvision.sh",
      "./scripts/containerd.sh",
      "./scripts/network-configurations.sh",
      "./scripts/control-plane-prerequisites.sh",
      "./scripts/init-kubeadm-cluster.sh",
    ]
  }
}


