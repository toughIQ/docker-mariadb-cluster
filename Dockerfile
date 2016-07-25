FROM mariadb:10.1
MAINTAINER toughiq@gmail.com

RUN apt-get update && apt-get upgrade -y \
	&& rm -rf /var/lib/apt/lists/*
	

COPY scripts/ /docker-entrypoint-initdb.d/.


ENV GALERA_USER="galera" \
	GALERA_PASS="galerapass" \
	MAXSCALE_USER="maxscale" \
	MAXSCALE_PASS="maxscalepass"

