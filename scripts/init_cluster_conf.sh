#!/bin/bash

set -e


# we use dns service discovery to find other members when in node mode
if [ -n "$DB_SERVICE_NAME" ]; then
  CLUSTER_MEMBERS=`getent hosts tasks.$DB_SERVICE_NAME|awk '{print $1}'|tr '\n' ','`
fi

if [ -n "$DB_BOOTSTRAP_NAME" ]; then
  CLUSTER_MEMBERS=$CLUSTER_MEMBERS`getent hosts tasks.$DB_BOOTSTRAP_NAME|awk '{print $1}'`
fi


# we create a galera config
config_file="/etc/mysql/conf.d/galera.cnf"

# we get the current container IP
# was added for testing. disabled at the moment
#MYIP=`ip add show eth0 | grep inet | head -1 | awk '{print $2}' | cut -d"/" -f1`
# We start config file creation

cat <<EOF > $config_file
# Node specifics 
[mysqld] 
wsrep-node-name = $HOSTNAME 
#wsrep-node-address = $MYIP
wsrep-sst-receive-address = $HOSTNAME
wsrep-node-incoming-address = $HOSTNAME

# Cluster settings
wsrep-on=ON
wsrep-cluster-name = "$CLUSTER_NAME" 
wsrep-cluster-address = gcomm://$CLUSTER_MEMBERS?pc.wait_prim=no
wsrep-provider = /usr/lib/galera/libgalera_smm.so 
wsrep-provider-options = "gcache.size=256M;gcache.page_size=128M" 
wsrep-sst-auth = "$GALERA_USER:$GALERA_PASS" 
wsrep_sst_method = rsync
binlog-format = row 
default-storage-engine = InnoDB 
innodb-doublewrite = 1 
innodb-autoinc-lock-mode = 2 
innodb-flush-log-at-trx-commit = 2 
innodb-locks-unsafe-for-binlog = 1 
EOF
