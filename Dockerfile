# Pull base image
FROM resin/rpi-raspbian:latest
MAINTAINER Carsten Payenberg <carsten dot payenberg@googlemail dot com>

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

# FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
# File::Basename
# File::Copy
# Sys::Hostname
# Data::Dumper
RUN apt-get update && apt-get install -y perl --no-install-recommends && rm -rf /var/lib/apt/lists/*

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
RUN { \
		echo mysql-server mysql-server/data-dir select ''; \
		echo mysql-server mysql-server/root-pass password ''; \
		echo mysql-server mysql-server/re-root-pass password ''; \
		echo mysql-server mysql-server/remove-test-db select false; \
	} | debconf-set-selections \
	&& apt-get update && apt-get install -y mariadb-server && rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql

# comment out a few problematic configuration values
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf

# Create the /var/run/mysqld , which isn't created by mariadb itself and
# causes mariadb to fail starting / shuts down gracefully on each start
RUN mkdir /var/run/mysqld
RUN chown mysql:mysql /var/run/mysqld

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld"]
