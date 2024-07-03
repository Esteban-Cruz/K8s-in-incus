# K8s in incus.

Background:
This project is meant to host a k8s home lab for learning Kubernetes.
This project is in development, for now it is only possible to spin up a Kubernetes cluster to play around, I will add more features soon.

The project has only been tested on Ubuntu 24.04 LTS.
Prerequistes:
- [incus 6.0.0](https://linuxcontainers.org/incus/)
- [yq 4.2.0](https://mikefarah.gitbook.io/yq)
- Enable nested virtualization

Build the k8s infrastructure
```
./actions/build/run_build-control-plane.sh
````

Remove and clean up incus VM, and its profile.
```
./actions/cleanup/run_cleanup-control-plane.sh
```

## License

MIT

**Free Software, Hell Yeah!**