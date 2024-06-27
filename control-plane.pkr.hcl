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
  }

  publish_properties = {
    description = "Ubuntu Kubernetes Control Plane"
  }
}

build {
  sources = ["incus.k8s-master"]
  provisioner "shell" {
    env = {
      "FOO" = "bar",
    }
    scripts = [
      "./scriptsprovisioners/preProvision.sh",
      "./scriptsprovisioners/containerd.sh",
      "./scriptsprovisioners/network-configurations.sh",
      "./scriptsprovisioners/control-plane-prerequisites.sh",
      "./scriptsprovisioners/init-kubeadm-cluster.sh",
    ]
  }
}


