# docker-mariadb-cluster
Dockerized MariaDB Galera Cluster

# WORK in Progress!!

docker network create -d overlay mynet
docker service create --name master --network mynet -e DB_MASTER_NAME=master maria --wsrep-new-cluster
docker service create --name maria --network mynet -e DB_SERVICE_NAME=maria -e DB_MASTER_NAME=master maria
