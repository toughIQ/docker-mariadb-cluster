#!/bin/bash

set -e

# This version is especially designed for usage with RANCHER deployment
# we set gcomm string with cluster_members via ENV by default
CLUSTER_ADDRESS="gcomm://$CLUSTER_MEMBERS?pc.wait_prim=no"

# RANCHER_STACK variable is needed to get correct hostname settings for replication
RANCHER_STACK=`curl http://rancher-metadata/latest/self/service/stack_name`
MY_NAME=`curl http://rancher-metadata/latest/self/service/name`

# we create a galera config
config_file="/etc/mysql/conf.d/galera.cnf"

cat <<EOF > $config_file
# Node specifics 
[mysqld] 
# enabled for rancher testing
wsrep-node-name = $MY_NAME.$RANCHER_STACK 
wsrep-sst-receive-address = $MY_NAME.$RANCHER_STACK
wsrep-node-incoming-address = $MY_NAME.$RANCHER_STACK

# Cluster settings
wsrep-on=ON
wsrep-cluster-name = "$CLUSTER_NAME" 
wsrep-cluster-address = $CLUSTER_ADDRESS
wsrep-provider = /usr/lib/galera/libgalera_smm.so 
wsrep-provider-options = "gcache.size=256M;gcache.page_size=128M;debug=no" 
wsrep-sst-auth = "$GALERA_USER:$GALERA_PASS" 
wsrep_sst_method = rsync
binlog-format = row 
default-storage-engine = InnoDB 
innodb-doublewrite = 1 
innodb-autoinc-lock-mode = 2 
innodb-flush-log-at-trx-commit = 2 
EOF
