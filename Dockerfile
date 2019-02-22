FROM mariadb:10.1
MAINTAINER toughiq@gmail.com

RUN apt-get update && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

COPY ["scripts/", "/docker-entrypoint-initdb.d/"]
COPY ["bin/initialize.sh", "bin/preflight.sh", "bin/persistence-cleanup.sh", "/usr/local/bin/"]
RUN chmod 755 /usr/local/bin/persistence-cleanup.sh; \
    chmod 755 /usr/local/bin/initialize.sh; \
    chmod 755 /usr/local/bin/preflight.sh; \
    sed -i '/bin\/bash/a /usr/local/bin/initialize.sh' /usr/local/bin/docker-entrypoint.sh; \
    sed -i '/exec "$@"/i /usr/local/bin/preflight.sh' /usr/local/bin/docker-entrypoint.sh

# we need to touch and chown config files, since we cant write as mysql user
RUN touch /etc/mysql/conf.d/galera.cnf \
    touch /etc/mysql/conf.d/cust.cnf \
    && chown mysql.mysql /etc/mysql/conf.d/galera.cnf \
    && chown mysql.mysql /etc/mysql/conf.d/cust.cnf \
    && chown mysql.mysql /docker-entrypoint-initdb.d/*.sql

# we expose all Cluster related Ports
# 3306: default MySQL/MariaDB listening port
# 4444: for State Snapshot Transfers
# 4567: Galera Cluster Replication
# 4568: Incremental State Transfer
EXPOSE 3306 4444 4567 4568

# we set some defaults
ENV GALERA_USER=galera \
    GALERA_PASS=galerapass \
    MAXSCALE_USER=maxscale \
    MAXSCALE_PASS=maxscalepass \
    CLUSTER_NAME=docker_cluster \
    MYSQL_ALLOW_EMPTY_PASSWORD=1

CMD ["mysqld"]