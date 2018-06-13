#!/bin/bash
set -o errexit
docker network create --subnet=192.168.10.0/24 net1 || true
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
docker exec etcd /etcdctl mkdir /hacluster/nodes
echo "Testing start of 5 node cluster"
docker run -d --stop-signal=RTMIN+3 --name=pcs1 -h pcs1 --security-opt seccomp:unconfined -e ETCD="192.168.10.10:2379" -e "MY_IP=pcs1" --net=net1 --ip 192.168.10.20 --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro pcs
docker run -d --stop-signal=RTMIN+3 --name=pcs2 -h pcs2 --security-opt seccomp:unconfined -e ETCD="192.168.10.10:2379" -e "MY_IP=pcs2" --net=net1 --ip 192.168.10.21 --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro pcs
docker run -d --stop-signal=RTMIN+3 --name=pcs3 -h pcs3 --security-opt seccomp:unconfined -e ETCD="192.168.10.10:2379" -e "MY_IP=pcs3" --net=net1 --ip 192.168.10.22 --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro pcs
docker run -d --stop-signal=RTMIN+3 --name=pcs4 -h pcs4 --security-opt seccomp:unconfined -e ETCD="192.168.10.10:2379" -e "MY_IP=pcs4" --net=net1 --ip 192.168.10.23 --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro pcs
docker run -d --stop-signal=RTMIN+3 --name=pcs5 -h pcs5 --security-opt seccomp:unconfined -e ETCD="192.168.10.10:2379" -e "MY_IP=pcs5" --net=net1 --ip 192.168.10.24 --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro pcs
sleep 80s && docker exec pcs2 journalctl && docker exec pcs2 pcs status
[ `docker exec -it pcs3 pcs status | grep Online |wc -l` == 6 ] && echo "Cluster started sucessfully"
echo "Test removing node"
docker stop pcs3 && docker rm pcs3
sleep 5s && [ `docker exec -it pcs2 pcs status | grep Online |wc -l` == 5 ] && echo "Node removed successfully"
docker run -d --stop-signal=RTMIN+3 --name=pcs3 -h pcs3 --security-opt seccomp:unconfined -e ETCD="192.168.10.10:2379" -e "MY_IP=pcs3" --net=net1 --ip 192.168.10.22 --cap-add=NET_ADMIN  -v /sys/fs/cgroup:/sys/fs/cgroup:ro pcs
sleep 30s && docker exec pcs2 journalctl && docker exec pcs2 pcs status
[ `docker exec -it pcs3 pcs status | grep Online |wc -l` == 6 ] && echo "Node joined back sucesfully"
