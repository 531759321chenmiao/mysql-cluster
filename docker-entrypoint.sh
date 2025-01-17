#!/bin/bash

my_hostname=`hostname`
my_ip=`hostname -i`
export CONSUL_HTTP_ADDR=${ENV_CONSUL_HOST}:${ENV_CONSUL_PORT}

function register_service() {
  last_state=-1
  while true; do
    ro=$(MYSQL_PWD=$MYSQL_ROOT_PASSWORD mysql -e "SELECT @@read_only;" | tail -n1)
    if [ ! $? -eq 0 ]; then
      echo "Wait for mysql daemon ready"
      sleep 10
      continue
    fi

    if [ "x$last_state" == "x$ro" ]; then
      sleep 2
      continue
    fi

    if [ "x$last_state" == "x1" ]; then
      my_id=$my_hostname.mysql-ro.${ENV_CLUSTER_NAMESPACE}.svc.cluster.local
    else
      my_id=$my_hostname.mysql.${ENV_CLUSTER_NAMESPACE}.svc.cluster.local
    fi

    consul services deregister -id=$my_id
    if [ "x$ro" == "x1" ]; then
      my_id_name=mysql-ro.${ENV_CLUSTER_NAMESPACE}.svc.cluster.local
      my_name=mysql-ro.npool.top
    else
      my_id_name=mysql.${ENV_CLUSTER_NAMESPACE}.svc.cluster.local
      my_name=mysql.npool.top
    fi

    my_id=${my_hostname}.$my_id_name
    consul services register -address=$my_ip -port=3306 -name=$my_name -id=$my_id
    if [ ! $? -eq 0 ]; then
      echo "Fail to register $my_name with address $my_hostname"
      sleep 2
      continue
    fi

    last_state=$ro
    sleep 2

  done
}

register_service &
/usr/local/bin/docker-entrypoint-inner.sh $@
