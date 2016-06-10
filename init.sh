#!/usr/bin/env bash


if [[ "$MY_IP" == ""  ]]
  then
    echo "-e 'MY_IP' has to be set"
    exit 1
fi
echo "MY_IP=$MY_IP" > /etc/sysconfig/my_ip
echo "ETCD=$ETCD" > /etc/sysconfig/etcd
exec /usr/lib/systemd/systemd
