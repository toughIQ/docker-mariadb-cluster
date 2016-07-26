# docker-mariadb-cluster
Dockerized MariaDB Galera Cluster

# WORK in Progress!!

docker network create -d overlay mynet

docker service create --name master --network mynet --replicas=1 -e MYSQL_ALLOW_EMPTY_PASSWORD=0 -e MYSQL_ROOT_PASSWORD=rootpass -e DB_BOOTSTRAP_NAME=bootstrap maria --wsrep-new-cluster

docker service create --name maria --network mynet --replicas=3 -e DB_SERVICE_NAME=maria -e DB_BOOTSTRAP_NAME=bootstrap maria
