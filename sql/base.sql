# prometheus mysql exporter sql
CREATE USER IF NOT EXISTS 'mysql_exporter'@'%.mysql-exporter.monitor.svc.cluster.local' IDENTIFIED BY '$MYSQL_EXPORTER_PASSWORD';
ALTER USER 'mysql_exporter'@'%.mysql-exporter.monitor.svc.cluster.local' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'mysql_exporter'@'%.mysql-exporter.monitor.svc.cluster.local';