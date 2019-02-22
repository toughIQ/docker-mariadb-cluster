[![Docker Pulls](https://img.shields.io/docker/pulls/toughiq/mariadb-cluster.svg)](https://hub.docker.com/r/toughiq/mariadb-cluster/)
[![](https://images.microbadger.com/badges/image/toughiq/mariadb-cluster.svg)](https://microbadger.com/images/toughiq/mariadb-cluster "Get your own image badge on microbadger.com")

# docker-mariadb-cluster
__Version 2__
Dockerized Automated MariaDB Galera Cluster

Version 2 is the advanced branch and is featured on DockerHub as `latest` from now on.
Old version 1.0 can be found here: https://github.com/toughIQ/docker-mariadb-cluster/tree/v1.
To get V1.0 Docker images, just `docker pull toughiq/mariadb-cluster:1.0`

The idea of this project is to create an automated and fully ephemeral MariaDB Galera cluster.
No static bindings, no persistent volumes. Like a disk RAID the data gets replicated across the cluster. 
If one node fails, another node will be brought up and the data will be initialized.

__Consider this a POC and not a production ready system!__ 

Built for use with Docker __1.12.1__+ in __Swarm Mode__

# WORK in Progress!

See [Issues](https://github.com/toughIQ/docker-mariadb-cluster/issues) for known problems and [Wiki](https://github.com/toughIQ/docker-mariadb-cluster/wiki) for notes and ideas.

## Setup
### Init Swarm Nodes/Cluster

Swarm Master:
		
	docker swarm init
		
Additional Swarm Node(s):

	docker swarm join <MasterNodeIP>:2377 + join-tokens shown at swarm init

To get the tokens at a later time, run `docker swarm join-token (manager|worker)`

### Create DB network

	docker network create -d overlay mydbnet

### Init/Bootstrap DB Cluster 

At first we start with a new service, which is set to `--replicas=1` to turn this instance into a bootstrapping node.
If there is just one service task running within the cluster, this instance automatically starts with `bootstrapping` enabled. 

	docker service create --name dbcluster \
	--network mydbnet \
	--replicas=1 \
	--env DB_SERVICE_NAME=dbcluster \
	toughiq/mariadb-cluster

Note: the service name provided by `--name` has to match the environment variable __DB_SERVICE_NAME__ set with `--env DB_SERVICE_NAME`.
	
Of course there are the default MariaDB options to define a root password, create a database, create a user and set a password for this user.
Example:

	docker service create --name dbcluster \
	--network mydbnet \
	--replicas=1 \
	--env DB_SERVICE_NAME=dbcluster \
	--env MYSQL_ROOT_PASSWORD=rootpass \
	--env MYSQL_DATABASE=mydb \
	--env MYSQL_USER=mydbuser \
	--env MYSQL_PASSWORD=mydbpass \
	toughiq/mariadb-cluster

### Scale out additional cluster members
Just after the first service instance/task is running with we are good to scale out.
Check service with `docker service ps dbcluster`. The result should look like this, with __CURRENT STATE__ telling something like __Running__.

	ID                         NAME         IMAGE                    NODE    DESIRED STATE  CURRENT STATE           ERROR
	7c81muy053eoc28p5wrap2uzn  dbcluster.1  toughiq/mariadb-cluster  node01  Running        Running 41 seconds ago  

Lets scale out now:

	docker service scale dbcluster=3

This additional 2 nodes start will come up in "cluster join"-mode. Lets check again: `docker service ps dbcluster`

	ID                         NAME         IMAGE                    NODE    DESIRED STATE  CURRENT STATE               ERROR
	7c81muy053eoc28p5wrap2uzn  dbcluster.1  toughiq/mariadb-cluster  node01  Running        Running 6 minutes ago       
	8ht037ka0j4g6lnhc194pxqfn  dbcluster.2  toughiq/mariadb-cluster  node02  Running        Running about a minute ago  
	bgk07betq9pwgkgpd3eoozu6u  dbcluster.3  toughiq/mariadb-cluster  node03  Running        Running about a minute ago 

### Create MaxScale Proxy Service and connect to DBCluster

There is no absolute need for a MaxScale Proxy service with this Docker Swarm enabled DB cluster, since Swarm provides a loadbalancer. So it would be possible to connect to the cluster by using the loadbalancer DNS name, which is in our case __dbcluster__. Its the same name, which is provided at startup by `--name`.

But MaxScale provides some additional features regarding loadbalancing database traffic. And its an easy way to get information on the status of the cluster.

Details on this MaxScale image can be found here: https://github.com/toughIQ/docker-maxscale

	docker service create --name maxscale \
	--network mydbnet \
	--env DB_SERVICE_NAME=dbcluster \
	--env ENABLE_ROOT_USER=1 \
	--publish 3306:3306 \
	toughiq/maxscale
	
To disable root access to the database via MaxScale just set `--env ENABLE_ROOT_USER=0` or remove this line at all.
Root access is disabled by default.

### Check successful startup of Cluster & MaxScale
Execute the following command. Just use autocompletion to get the `SLOT` and `ID`.

	docker exec -it maxscale.<SLOT>.<ID> maxadmin -pmariadb list servers

The result should report the cluster up and running:

	-------------------+-----------------+-------+-------------+--------------------
	Server             | Address         | Port  | Connections | Status              
	-------------------+-----------------+-------+-------------+--------------------
	10.0.0.3           | 10.0.0.3        |  3306 |           0 | Slave, Synced, Running
	10.0.0.4           | 10.0.0.4        |  3306 |           0 | Slave, Synced, Running
	10.0.0.5           | 10.0.0.5        |  3306 |           0 | Master, Synced, Running
	-------------------+-----------------+-------+-------------+--------------------

### Data persistance
If you need data persistance; Mount a volume to /data in the container (using --mount).  A subfolder of /data will be created for each container (by ip) and the mysql datadir will be redirected here. Ensure /data is owned by 999:999.