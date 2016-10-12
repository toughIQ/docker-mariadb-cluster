#!/bin/bash
echo "[mysqld]" > /etc/mysql/conf.d/cust.cnf

#We check to see if /data folder exists.  Assume we need to change mariadb datadir if so (for data persistence).
if [ -d "/data" ]; then

  #Get the ip address for this container. There may be multiple.  We'll cross reference it with the $DB_SERVICE_NAME.
  for interface in $(ip add|grep global|awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}'); do
	for swarm_service in $(getent hosts tasks.$DB_SERVICE_NAME|awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}'); do
	  if [ "$interface" == "$swarm_service" ]; then
	    THIS_DB_SERVICE_IP=$interface
      fi
	done
  done
  
  #Set the data dir to /data + the IP of this container.
  mkdir -p /data/$THIS_DB_SERVICE_IP
  echo "datadir = /data/$THIS_DB_SERVICE_IP" >> /etc/mysql/conf.d/cust.cnf
  #echo "socket = /data/$THIS_DB_SERVICE_IP/mysql.sock" >> /etc/mysql/conf.d/cust.cnf
  
  #Cleanup - clean up data folders for nodes no longer in the cluster. Don't wait for this.
  /usr/local/bin/persistence-cleanup.sh &
fi