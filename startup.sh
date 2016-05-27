#!bin/bash
pcs cluster auth -u hacluster -p pass 192.168.2.250 192.168.2.251
pcs cluster setup --name master 192.168.2.250 192.168.2.251
pcs cluster start --all
pcs cluster enable --all
crm configure property stonith-enabled=false
crm configure property no-quorum-policy=ignore
crm configure primitive ClusterIP ocf:heartbeat:IPaddr2 params ip=192.168.2.123 nic=virtual2 cidr_netmask=24 op monitor interval=30s
crm configure primitive ClusterIPext ocf:heartbeat:IPaddr2 params ip=134.157.183.92 cidr_netmask=23 op monitor interval=30s
crm configure primitive srv_conntrackd ocf:heartbeat:conntrackd
crm configure ms conntrackd srv_conntrackd  meta master-max="1" master-node-max="1" clone-max="2" clone-node-max="1" notify="true" target-role="Started"
crm configure colocation website-with-ip INFINITY: conntrackd:Master ClusterIPext ClusterIP
crm resource cleanup conntrackd
