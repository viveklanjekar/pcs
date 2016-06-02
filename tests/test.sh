#!/bin/bash
docker network create --subnet=192.168.1.0/24 net1
docker run --net=net1 --ip=192.168.1.10  --name etcd quay.io/coreos/etcd:v2.3.6
docker run -d --name=pcs1 --security-opt seccomp:unconfined -e ETCD="192.168.1.10:2379" -e "MY_IP=192.168.1.20" --net=net1 --ip 192.168.1.20 --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro -e "BOOTSTRAP=True" pcs
docker run -d --name=pcs2 --security-opt seccomp:unconfined -e ETCD="192.168.1.10:2379" -e "MY_IP=192.168.1.21" --net=net1 --ip 192.168.1.21 --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro pcs
docker run -d --name=pcs3 --security-opt seccomp:unconfined -e ETCD="192.168.1.10:2379" -e "MY_IP=192.168.1.22" --net=net1 --ip 192.168.1.22 --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro pcs
sleep 30s && docker exec -it pcs3 pcs status
