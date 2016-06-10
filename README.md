# pcs

[Docker](https://www.docker.com/) image with [Pacemaker](http://clusterlabs.org/) and [Corosync](https://corosync.github.io/corosync/) managed by [pcs](https://github.com/feist/pcs).
Nodes of a PCS cluster are registered in etcd.

To get this image, pull it from [docker hub](https://hub.docker.com/r/mvdbeek/pcs/):
```
docker pull mvdbeek/pcs
```

If you want to build this image yourself, clone the [github repo](https://github.com/mvdbeek/pcs) and in directory with Dockerfile run:
```
docker build -t <username>/pcs .
```

Before using the image, an etcd cluster needs to be available.  
You can start a simple local etcd cluster with

export HostIP=<your_ip>
docker run -d --net host \
 --name etcd quay.io/coreos/etcd \
 -name etcd0 \
 -advertise-client-urls http://${HostIP}:2379,http://${HostIP}:4001 \
 -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
 -initial-advertise-peer-urls http://${HostIP}:2380 \
 -listen-peer-urls http://0.0.0.0:2380 \
 -initial-cluster-token etcd-cluster-1 \
 -initial-cluster etcd0=http://${HostIP}:2380 \
 -initial-cluster-state new

We then need to create a few keys in etcd:
```
docker exec etcd /etcdctl set /hacluster/user hacluster
docker exec etcd /etcdctl set /hacluster/password pass
docker exec etcd /etcdctl mkdir /hacluster/nodes
```
The user and password keys wil be picked up by the docker image.
If you change the password in etcd, the password will automatically be updated in the
pacemaker image(s).

To launch a pacemaker image, run:
```
docker run -d --stop-signal=RTMIN+3 --name=pcs --security-opt seccomp:unconfined -e ETCD="127.0.0.1:2379" -e "MY_IP=<my_ip/hostname>" --net=host --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro pcs
```

To add aditional pacemaker nodes, launch more images from different machines:
```
docker run -d --stop-signal=RTMIN+3 --name=pcs2 --security-opt seccomp:unconfined -e ETCD="<etcd_ip>:2379" -e "MY_IP=<my_ip/hostname>" --net=host --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro pcs
```

Stopping the containers with docker stop will expire entries in /hacluster/nodes/<my_ip/hostname>, and deregister them in pacemaker.

Pacemaker in this image is able to manage docker containers on the host - you can expose the docker socket and binary to the image (don't expose if not needed). Cgroup fs is required by the systemd in the container and `--net=host` is required so the pacemaker is able to manage virtual IP.

Pcs web ui will be available on the [https://localhost:2224/](https://localhost:2224/). To log in, you need to set password for the `hacluster` linux user inside of the image:
```
docker exec -it pcs bash
passwd hacluster
```

Then you can use `hacluster` as the login name and your password in the web ui.

#### Example usage

You can create cluster in the web ui, or via cli. Every node in the cluster must be running pcs docker container and must have setup password for the `hacluster` user. Then, on one of the nodes in the cluster run (modify pieces in []):
```
docker exec -it pcs bash
pcs cluster auth -u hacluster -p [hapass] [master1 master2 master3]  # master[1-3] are hostnames of nodes in your cluster
pcs cluster setup --name [master] [master1 master2 master3]
pcs cluster start --all
pcs cluster enable --all
```

Create virtual ip:
```
pcs resource create virtual-ip IPaddr2 ip=[192.168.92.3] --group [master-group]
```

Define docker resource image:
```
pcs resource create [docker-master] ocf:heartbeat:docker image=[docker-master] reuse=1 run_opts='[-p 8080]' --group [master-group]
```

Disable stonith (this will start the cluster):
```
pcs property set stonith-enabled=false
```

You can view and modify your cluster in the web ui even when you created it in cli, but you need to add it there first (Add existing).

