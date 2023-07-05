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
}

function pmm_admin_add_mysql() {
  while true; do
    consul_pmm_service=`curl -s http://${CONSUL_HTTP_ADDR}/v1/agent/service/pmm.${ENV_CLUSTER_NAMESPACE}.svc.cluster.local`
    pmm_service=`echo $consul_pmm_service | jq '.Service' | awk -F '"' '{print $2}'`
    pmm_service_port=`echo $consul_pmm_service | jq '.Port'`
    if [ "x$pmm_service_port" == "x443" ]; then
        echo "### pmm-agent setup --config-file=/usr/local/percona/pmm2/config/pmm-agent.yaml --server-insecure-tls --server-address=$pmm_service:$pmm_service_port --server-username=admin --server-password=$ENV_PMM_ADMIN_PASSWORD --force" >> /var/log/pmm-agent.log 2>&1
        pmm-agent setup --config-file=/usr/local/percona/pmm2/config/pmm-agent.yaml --server-insecure-tls --server-address=$pmm_service:$pmm_service_port --server-username=admin --server-password=$ENV_PMM_ADMIN_PASSWORD --force >> /var/log/pmm-agent.log 2>&1
        echo "### pmm-agent run --config-file=/usr/local/percona/pmm2/config/pmm-agent.yaml --server-insecure-tls --server-address=$pmm_service:$pmm_service_port --server-username=admin --server-password=$ENV_PMM_ADMIN_PASSWORD" >> /var/log/pmm-agent.log 2>&1
        pmm-agent run --config-file=/usr/local/percona/pmm2/config/pmm-agent.yaml --server-insecure-tls --server-address=$pmm_service:$pmm_service_port --server-username=admin --server-password=$ENV_PMM_ADMIN_PASSWORD >> /var/log/pmm-agent.log 2>&1 &
    else
      echo "Pmm service unregistered"
      sleep 10
      continue
    fi
    break
  done

  pmm-admin status
  if [ $? -eq 0 ]; then
    while true; do
      netstat -lntup | grep 3306
      if [ $? -eq 0 ]; then
	    echo "Run pmm admin add mysql"
        pmm-admin add mysql --query-source=slowlog --username=root --password=$MYSQL_ROOT_PASSWORD sl-$my_hostname
        pmm-admin add mysql --query-source=perfschema --username=root --password=$MYSQL_ROOT_PASSWORD ps-$my_hostname
      else
	    echo "Mysql not running"
        sleep 10
        continue
      fi
      break
    done
  else
    echo "Pmm admin not running"
  fi
}

function set_sql_mode() {
  while true; do
    netstat -lntup | grep 3306
    if [ $? -eq 0 ]; then
      MYSQL_PWD=$MYSQL_ROOT_PASSWORD mysql -uroot -e "SET global sql_mode=(SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', ''))"
    else
      echo "Mysql not running"
      sleep 10
      continue
    fi
    break
  done
}

if [ "x$CONSUL_REGISTER_ENABLE" == "xfalse" ]; then
else
register_service
fi

if [ "x$PMM_ADMIN_ENABLE" == "xfalse" ]; then
else
pmm_admin_add_mysql
fi

set_sql_mode &
/usr/local/bin/docker-entrypoint-inner.sh $@
