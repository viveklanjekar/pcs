#!/bin/bash
docker network create --subnet=192.168.10.0/24 net1
export HostIP=192.168.10.10
docker run -d --net net1 --ip 192.168.10.10 \
 --name etcd quay.io/coreos/etcd \
 -name etcd0 \
 -advertise-client-urls http://${HostIP}:2379,http://${HostIP}:4001 \
 -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
 -initial-advertise-peer-urls http://${HostIP}:2380 \
 -listen-peer-urls http://0.0.0.0:2380 \
 -initial-cluster-token etcd-cluster-1 \
 -initial-cluster etcd0=http://${HostIP}:2380 \
 -initial-cluster-state new
sleep 2s
docker exec etcd /etcdctl set /hacluster/user hacluster
docker exec etcd /etcdctl set /hacluster/password pass
docker run -d --name=pcs1 --security-opt seccomp:unconfined -e ETCD="192.168.10.10:2379" -e "MY_IP=192.168.10.20" --net=net1 --ip 192.168.10.20 --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro -e "BOOTSTRAP=True" pcs
sleep 90s
docker run -d --name=pcs2 --security-opt seccomp:unconfined -e ETCD="192.168.10.10:2379" -e "MY_IP=192.168.10.21" --net=net1 --ip 192.168.10.21 --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro pcs
#sleep 90s
#docker run -d --name=pcs3 --security-opt seccomp:unconfined -e ETCD="192.168.10.10:2379" -e "MY_IP=192.168.10.22" --net=net1 --ip 192.168.10.22 --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro pcs
sleep 90s && docker exec pcs2 journalctl && docker exec pcs2 pcs status

