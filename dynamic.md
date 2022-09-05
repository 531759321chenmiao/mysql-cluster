# 相关配置如下

+ expire_logs_days
+ innodb_buffer_pool_size
+ sync_binlog
+ binlog_format
+ open_files_limit(no dynamic)
+ innodb_buffer_pool_instances(no dynamic)

```sql
SET GLOBAL expire_logs_days = 7;
SET GLOBAL innodb_buffer_pool_size = 1677721600;
SET GLOBAL sync_binlog = 1;
SET GLOBAL binlog_format = ROW;
```
