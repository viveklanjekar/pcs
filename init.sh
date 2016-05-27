#!/usr/bin/env bash


if [[ "$MY_IP" == ""  ]]
  then
    echo "-e 'MY_IP' has to be set"
    exit 1
fi
export NODES=`echo "$ETCD_ENDPOINTS"| tr ',' ' '`
etcdctl --endpoint "$ETCD_ENDPOINTS" set /etcd/nodes "$ETCD_ENDPOINTS"
etcdctl --endpoint "$ETCD_ENDPOINTS" set /hacluster/newnode ""
etcdctl --endpoint "$ETCD_ENDPOINTS" set /hacluster/pass "$HACLUSTER_PASS"
confd -onetime -node http://192.168.2.253:2379 # TODO: replace with list of nodes or srv discovery
echo "hacluster:$HACLUSTER_PASS"|chpasswd
echo "MY_IP=$MY_IP" > /etc/sysconfig/my_ip
echo "BOOTSTRAP=$BOOTSTRAP" > /etc/sysconfig/bootstrap
if [ -f "/tmp/cib.txt" ]
  then
     systemctl enable pcsd_config
     etcdctl --endpoint "$ETCD_ENDPOINTS" set /hacluster/nodelist "$HACLUSTER_NODELIST"
fi
exec /usr/lib/systemd/systemd
