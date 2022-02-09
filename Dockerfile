FROM mysql:5.7.35

RUN mkdir -p /usr/local/bin
RUN mv /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint-inner.sh

RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 467B942D3A79BD29
RUN gpg --export --armor 467B942D3A79BD29 | apt-key add -
RUN apt-get update -y
RUN apt-get install curl -y

COPY .docker-tmp/consul /usr/bin/consul
COPY docker-entrypoint.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/docker-entrypoint.sh
