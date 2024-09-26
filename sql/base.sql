-- prometheus mysql exporter sql
CREATE
  USER IF NOT EXISTS 'mysql_exporter'@'%.mysql-exporter.monitor.svc.cluster.local'
  IDENTIFIED BY '$MYSQL_EXPORTER_PASSWORD' WITH MAX_USER_CONNECTIONS 3;
GRANT
  PROCESS, REPLICATION CLIENT,
  SELECT ON *.* TO 'mysql_exporter'@'%.mysql-exporter.monitor.svc.cluster.local';

-- query only user
CREATE
  USER IF NOT EXISTS 'query'@'127.0.0.1'
  IDENTIFIED BY '12345679' WITH MAX_USER_CONNECTIONS 10;
GRANT
  SELECT ON *.* TO 'query'@'127.0.0.1';
