FROM mysql:5.7.35

RUN mkdir -p /usr/local/bin
RUN mv /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint-inner.sh

# RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 467B942D3A79BD29
# RUN gpg --export --armor 467B942D3A79BD29 | apt-key add -
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 467B942D3A79BD29
RUN apt-get update -y
RUN apt-get install debian-archive-keyring -y
RUN apt-get update -y
RUN apt --fix-broken install -y
RUN apt-get update -y
RUN apt-get install curl -y
RUN apt-get install lsb-release -y
RUN apt-get install apt-utils -y

COPY percona-release_latest.generic_all.deb /usr/local/bin
COPY percona-release_latest.buster_all.deb /usr/local/bin
RUN dpkg -i /usr/local/bin/percona-release_latest.generic_all.deb
RUN apt-get update -y
RUN apt-get install -y pmm2-client
RUN dpkg -i /usr/local/bin/percona-release_latest.buster_all.deb
RUN percona-release enable-only tools release
RUN apt-get update -y
RUN apt install percona-xtrabackup-24 -y
RUN apt install qpress -y

# COPY .docker-tmp/consul /usr/bin/consul
COPY docker-entrypoint.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/docker-entrypoint.sh
