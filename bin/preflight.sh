#!/bin/bash
# Check our configs
# If a new container was launched with an old data volume the full docker-entrypoint.sh doesn't run.
# The result is that galera.cnf is not created in the new container.

#Check for galera.cnf
if [ ! -s /etc/mysql/conf.d/galera.cnf ]; then
  /docker-entrypoint-initdb.d/init_cluster_conf.sh
fi