FROM mariadb:10.1
MAINTAINER toughiq@gmail.com

RUN apt-get update && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*
    
COPY scripts/ /docker-entrypoint-initdb.d/.

COPY docker-entrypoint.sh /usr/local/bin/
RUN rm -rf docker-entrypoint.sh
RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat

# we have to change the default docker-entrypoint.sh script
# to make sure galera.cnf gets written EVERY time to update cluster config
# even if DB already exists and/or config is persisted on volume
# We insert a seperate call at the end of the default file to run cluster init
RUN sed -i -e 's/exec gosu.*$/exec \/docker-entrypoint-initdb.d\/init_cluster_conf.sh\n\texec gosu mysql \"\$BASH_SOURCE\" \"\$\@\"/g' docker-entrypoint.sh 


# we need to touch and chown config files, since we cant write as mysql user
RUN touch /etc/mysql/conf.d/galera.cnf \
    && chown mysql.mysql /etc/mysql/conf.d/galera.cnf \
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

