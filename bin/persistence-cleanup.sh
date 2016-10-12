#!/bin/bash

#Wait until the service is up and running on this host.
healthcheck(){
  /usr/local/bin/docker-healthcheck 2> /dev/null
}
count=0
healthcheck
while [ $? != 0 ]; do
  sleep 1
  ((count=count+1))
  if [ "$count" -ge 100 ]; then
    break
  fi
  healthcheck
done


/usr/local/bin/docker-healthcheck 2> /dev/null
if [ $? -eq 0 ]; then
  #If there is a /data/ip directory that doesn't match an active swarm cluster IP address, it should be cleaned up.
  #Will only clean up a single such directory on a run.

  #Get the ip address for this container. There may be multiple.  We'll cross reference it with the $DB_SERVICE_NAME.
  for dir in `find /data -type d| awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}'`; do
    ip_match=0
	for swarm_service in $(getent hosts tasks.$DB_SERVICE_NAME| awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}'); do
      if [ "$dir" == "$swarm_service" ]; then
        ip_match=1
      fi
    done
	
	#Delete this extra folder structure
	if [ $dir ] && [ "$ip_match" != 1 ]; then
	  echo "Removing stale persistence dir /data/$dir"
	  rm -rf "/data/$dir"
	  exit
	fi
  done
fi