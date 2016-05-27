#!/bin/bash

source /etc/sysconfig/cluster_setup
source /etc/sysconfig/pass
source /etc/sysconfig/etcd
source /etc/sysconfig/my_ip
source /etc/sysconfig/newnode
source /etc/sysconfig/bootstrap

function wait_for_authorization {
   while true; do
       AUTH=$(etcdctl --endpoints "$ETCD_NODES" get /hacluster/authorized_ips/"$MY_IP")
       if [ "$AUTH" == "True" ]
           then
               break
       fi
       sleep 1s
   done
   # cleanup keys in etcd
   etcdctl -endpoints "$ETCD_NODES" rm /hacluster/authorized_ips/"$MY_IP"
   etcdctl -endpoints "$ETCD_NODES" set /hacluster/newnode ""
}

if [ "$FIRST_START" == "True" ]
  then
    # This is before calling setup_cluster.sh through systemd
    export FIRST_START=False
    echo "First start, exiting"
    exit 0
fi


if [ "$BOOTSTRAP" == "True" ]
  then
      pcs cluster auth -u hacluster -p $PASS "$NODELIST"
      pcs cluster setup --name master "$NODELIST"
      pcs cluster start --all
      pcs cluster enable --all
      echo "BOOTSTRAP=False" > /etc/sysconfig/bootstrap
      exit 0
else
    echo "Didn't enter bootstrap"
    echo "$BOOTSTRAP"
fi


if [ "$MY_IP" == "$NEWNODE"  ]
  then
    echo "I am the new node, exiting"
    exit 0
fi

if [[ ! "$NODELIST" == *"$MY_IP"* ]]
  then
    # We want to add MY_IP
    etcdctl --endpoints "$ETCD_NODES" set /hacluster/authorized_ips/"$MY_IP" False
    etcdctl --endpoints "$ETCD_NODES" set /hacluster/newnode "$MY_IP"
    # From here on other nodes will identify this node, so we wait until /hacluster/authorized_ips/"$MY_IP" is True
    wait_for_authorization
    pcs cluster auth -u hacluster -p $PASS
    pcs cluster start --all
    pcs cluster enable --all
    echo "$MY_IP has been successfully added to the cluster"
    exit 0
fi

if [[ "$NODELIST" == *"$MY_IP"* ]] && [ "$NEWNODE" != "" ]
  then
    # The current node is a valid cluster member
    # and can authenticate the new node
    pcs cluster auth -u hacluster -p $PASS "$NEWNODE"
    pcs cluster node add "$NEWNODE"
    etcdctl --endpoints "$ETCD_NODES" set /hacluster/authorized_ips/"$NEWNODE" True
    echo "Authorized $MY_IP "
    exit 0
fi
