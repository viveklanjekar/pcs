#!/bin/bash

source /etc/sysconfig/my_ip
source /etc/sysconfig/etcd
source /etc/sysconfig/bootstrap

if [ $BOOTSTRAP == "True" ]
  then
    pcs-etcd create
fi
