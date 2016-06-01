#!/bin/bash

source /etc/sysconfig/my_ip
source /etc/sysconfig/etcd
source /etc/sysconfig/bootstrap

if [ $BOOTSTRAP == "True" ]
  then
    pcs-etcd create --etcd_nodes "$ETCD" --my_ip "$MY_IP"
    /usr/bin/crm configure load update /tmp/cib.txt
  else
    /usr/bin/pcs-etcd join --etcd_nodes "$ETCD" --my_ip "$MY_IP"
fi
systemd-notify READY=1
