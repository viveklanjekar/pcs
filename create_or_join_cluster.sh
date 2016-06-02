#!/bin/bash

source /etc/sysconfig/my_ip
source /etc/sysconfig/etcd
source /etc/sysconfig/bootstrap

if [ "$BOOTSTRAP" == "True" ]
  then
    pcs-etcd create --etcd_nodes "$ETCD" --my_ip "$MY_IP"
  else
    pcs-etcd join --etcd_nodes "$ETCD" --my_ip "$MY_IP"
fi
systemd-notify READY=1
