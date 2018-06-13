#!/bin/bash

source /etc/sysconfig/my_ip
source /etc/sysconfig/etcd

pcs-etcd join_or_create --etcd_nodes "$ETCD" --my_ip "$MY_IP"
systemd-notify READY=1
