#!/bin/bash

set -e


# we use dns service discovery to find other members when in node mode
if [ -n "$DB_SERVICE_NAME" ]; then
  CLUSTER_MEMBERS=`getent hosts tasks.$DB_SERVICE_NAME|awk '{print $1}'|tr '\n' ','`
fi

if [ -n "$DB_MASTER_NAME" ]; then
  CLUSTER_MEMBERS=$CLUSTER_MEMBERS`getent hosts tasks.$DB_MASTER_NAME|awk '{print $1}'`
fi


# we create a galera config

config_file="/etc/mysql/conf.d/galera.cnf"

# We start config file creation

cat <<EOF > $config_file
# Node specifics 
[mysqld] 
wsrep-node-name = "$HOSTNAME" 
wsrep-sst-receive-address = $HOSTNAME
wsrep-node-incoming-address = $HOSTNAME

# Cluster settings
wsrep-on=ON
wsrep-cluster-name = "$CLUSTER_NAME" 
wsrep-cluster-address = gcomm://$CLUSTER_MEMBERS?pc.wait_prim=no
wsrep-provider = /usr/lib/galera/libgalera_smm.so 
wsrep-provider-options = "gcache.size=256M;gcache.page_size=128M" 
wsrep-sst-auth = "$GALERA_USER:$GALERA_PASS" 
binlog-format = row 
default-storage-engine = InnoDB 
innodb-doublewrite = 1 
innodb-autoinc-lock-mode = 2 
innodb-flush-log-at-trx-commit = 2 
innodb-locks-unsafe-for-binlog = 1 
EOF
