#!/bin/bash

my_hostname=`hostname`
my_ip=`hostname -i`
export CONSUL_HTTP_ADDR=${ENV_CONSUL_HOST}:${ENV_CONSUL_PORT}

function register_service() {
  last_state=-1
  while true; do
    ro=$(MYSQL_PWD=$MYSQL_ROOT_PASSWORD mysql -e "SELECT @@read_only;" | tail -n1)

    case $ro in
      0 | 1)
	;;
      *)
	echo "Invalid ro: ($ro)"
        sleep 10
        continue
	;;
    esac

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

pmm-agent setup --config-file=/usr/local/percona/pmm2/config/pmm-agent.yaml --server-insecure-tls --server-address=monitoring-service:443 --server-username=admin --server-password=12345679 --force >> /var/log/pmm-agent.log
pmm-agent run --config-file=/usr/local/percona/pmm2/config/pmm-agent.yaml --server-insecure-tls --server-address=monitoring-service:443 --server-username=admin --server-password=12345679 >> /var/log/pmm-agent.log 2>&1 &
sleep 10
pmm-admin status
if [ $? -eq 0 ]; then
  pmm-admin add mysql --query-source=slowlog --username=root --password=$MYSQL_ROOT_PASSWORD sl-$my_hostname
  pmm-admin add mysql --query-source=perfschema --username=root --password=$MYSQL_ROOT_PASSWORD ps-$my_hostname
fi

RUN apt-get update -y
RUN apt-get install debian-archive-keyring debian-keyring -y

}

register_service &
/usr/local/bin/docker-entrypoint-inner.sh $@
