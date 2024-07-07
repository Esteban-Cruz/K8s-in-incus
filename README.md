# K8s-in-incus

This project is meant to host a Kubernetes home lab for learning purposes, the project is currently being developed, for now it is only possible to spin up a Kubernetes cluster to play around, I will add more features soon such as worker nodes, a web interface, scripts to replicate real life problems, solutions, test cases, and more.
The project has only been tested on Ubuntu 24.04 LTS.

### Prerequisites:
- [incus](https://linuxcontainers.org/incus/docs/main/installing/) (tested with version 6.0.0, minor updates should work fine)
- [yq](https://mikefarah.gitbook.io/yq) (tested with version 4.2.0, minor updates should work fine)
- Enable nested virtualization, more information on how to check if nested virtualization is enabled can be found [here](https://ubuntu.com/server/docs/how-to-enable-nested-virtualization#:~:text=If%20the%20module%20is%20loaded&text=If%20the%20output%20is%20either,the%20case%20for%20Ubuntu%20users%29.), you can also check it by running the following command too on Ubuntu:
	```
	kvm-ok
	```
	This will show you if  the `kvm` module is enabled.

  
##  Instructions
Clone the repository and cd into the project's root directory.


### Build the Kubernetes infrastructure
```
./actions/build/run_create-kubernetes-cluster.sh
```

  

### Remove and clean up all incus resources previously created.
```
./actions/cleanup/run_cleanup-control-plane.sh
```


  

## License
MIT
**Free Software, Hell Yeah!**