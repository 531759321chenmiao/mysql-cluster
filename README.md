# MySQL

## TODO

+ memory pool
+ transaction mod
+ 设置明确需要主从同步的表
+ 周期性全量备份到对象存储
+ 配置文件/数据/安装路径配置

## 只有查询权限的账户

```sql
  CREATE
    USER IF NOT EXISTS 'query'@'127.0.0.1'
    IDENTIFIED BY '12345679' WITH MAX_USER_CONNECTIONS 10;
  GRANT
    SELECT ON *.* TO 'query'@'127.0.0.1';
```

## [配置优化可动态加载](./dynamic.md)

```ini
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-configmap
  namespace: kube-system
  labels:
    app: mysql
data:
  my.cnf: |
    [client]
    default-character-set=utf8mb4
    [mysql]
    default-character-set=utf8mb4
  master.cnf: |
    [mysqld]
    # charset
    character-set-server = utf8mb4
    collation-server = utf8mb4_unicode_ci
    init_connect='SET NAMES utf8mb4'
    skip-character-set-client-handshake = true

    # bin log
    ## master only
    log-bin
    sync_binlog = 1
    binlog_format = ROW
    binlog_cache_size = 4M
    max_binlog_cache_size = 2G
    max_binlog_size = 1G
    expire_logs_days = 7

    # performance setttings
    max_connections = 2000
    open_files_limit    = 65535
    table_open_cache = 1024
    table_definition_cache = 1024
    thread_stack = 512K
    sort_buffer_size = 4M
    join_buffer_size = 4M
    read_buffer_size = 8M
    read_rnd_buffer_size = 4M
    bulk_insert_buffer_size = 64M
    thread_cache_size = 768
    interactive_timeout = 600
    wait_timeout = 600
    tmp_table_size = 32M
    max_heap_table_size = 32M
  slave.cnf: |
    [mysqld]
    # charset
    character-set-server = utf8mb4
    collation-server = utf8mb4_unicode_ci
    init_connect='SET NAMES utf8mb4'
    skip-character-set-client-handshake = true

    # bin log
    sync_binlog = 1
    binlog_format = ROW
    binlog_cache_size = 4M
    max_binlog_cache_size = 2G
    max_binlog_size = 1G
    expire_logs_days = 7

    # performance setttings
    max_connections = 2000
    open_files_limit    = 65535
    table_open_cache = 1024
    table_definition_cache = 1024
    thread_stack = 512K
    sort_buffer_size = 4M
    join_buffer_size = 4M
    read_buffer_size = 8M
    read_rnd_buffer_size = 4M
    bulk_insert_buffer_size = 64M
    thread_cache_size = 768
    interactive_timeout = 600
    wait_timeout = 600
    tmp_table_size = 32M
    max_heap_table_size = 32M

    # slave only
    super-read-only = ON
```

## 配置优化不可动态加载

```ini
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-configmap
  namespace: kube-system
  labels:
    app: mysql
data:
  my.cnf: |
    [client]
    default-character-set=utf8mb4
    [mysql]
    default-character-set=utf8mb4
  master.cnf: |
    [mysqld]
    # charset
    character-set-server = utf8mb4
    collation-server = utf8mb4_unicode_ci
    init_connect='SET NAMES utf8mb4'
    skip-character-set-client-handshake = true

    # bin log
    ## master only
    log-bin
    sync_binlog = 1
    binlog_format = ROW
    binlog_cache_size = 4M
    max_binlog_cache_size = 2G
    max_binlog_size = 1G
    expire_logs_days = 7

    # performance setttings
    max_connections = 2000
    open_files_limit    = 65535
    table_open_cache = 1024
    table_definition_cache = 1024
    thread_stack = 512K
    sort_buffer_size = 4M
    join_buffer_size = 4M
    read_buffer_size = 8M
    read_rnd_buffer_size = 4M
    bulk_insert_buffer_size = 64M
    thread_cache_size = 768
    interactive_timeout = 600
    wait_timeout = 600
    tmp_table_size = 32M
    max_heap_table_size = 32M

    # innodb settings
    innodb_buffer_pool_size = 1600M
    innodb_buffer_pool_instances = 4
    innodb_data_file_path = ibdata1:12M:autoextend
    innodb_log_buffer_size = 32M
    innodb_open_files = 65535
    innodb_flush_method = O_DIRECT
  slave.cnf: |
    [mysqld]
    # charset
    character-set-server = utf8mb4
    collation-server = utf8mb4_unicode_ci
    init_connect='SET NAMES utf8mb4'
    skip-character-set-client-handshake = true

    # bin log
    sync_binlog = 1
    binlog_format = ROW
    binlog_cache_size = 4M
    max_binlog_cache_size = 2G
    max_binlog_size = 1G
    expire_logs_days = 7

    # performance setttings
    max_connections = 2000
    open_files_limit    = 65535
    table_open_cache = 1024
    table_definition_cache = 1024
    thread_stack = 512K
    sort_buffer_size = 4M
    join_buffer_size = 4M
    read_buffer_size = 8M
    read_rnd_buffer_size = 4M
    bulk_insert_buffer_size = 64M
    thread_cache_size = 768
    interactive_timeout = 600
    wait_timeout = 600
    tmp_table_size = 32M
    max_heap_table_size = 32M

    # innodb settings
    innodb_buffer_pool_size = 1600M
    innodb_buffer_pool_instances = 4
    innodb_data_file_path = ibdata1:12M:autoextend
    innodb_log_buffer_size = 32M
    innodb_open_files = 65535
    innodb_flush_method = O_DIRECT

    # slave only
    super-read-only = ON
```

## 备份优化

+ TODO

## [generate config](https://imysql.com/my-cnf-wizard.html)
