#!/bin/bash

set -e

# we set gcomm string with cluster_members via ENV by default
CLUSTER_ADDRESS="gcomm://$CLUSTER_MEMBERS?pc.wait_prim=no"

# we use dns service discovery to find other members when in service mode
# and set/override cluster_members provided by ENV
if [ -n "$DB_SERVICE_NAME" ]; then
  
  # we check, if we have to enable bootstrapping, if we are the only/first node live
  if [ `getent hosts tasks.$DB_SERVICE_NAME|wc -l` = 1 ] ;then 
    # bootstrapping gets enabled by empty gcomm string
    CLUSTER_ADDRESS="gcomm://"
  else
    # we fetch IPs of service members
    CLUSTER_MEMBERS=`getent hosts tasks.$DB_SERVICE_NAME|awk '{print $1}'|tr '\n' ','`
    # we set gcomm string with found service members
    CLUSTER_ADDRESS="gcomm://$CLUSTER_MEMBERS?pc.wait_prim=no"
  fi
fi


# we create a galera config
config_file="/etc/mysql/conf.d/galera.cnf"

cat <<EOF > $config_file
# Node specifics 
[mysqld] 
wsrep-node-name = $HOSTNAME 
wsrep-sst-receive-address = $HOSTNAME
wsrep-node-incoming-address = $HOSTNAME

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
