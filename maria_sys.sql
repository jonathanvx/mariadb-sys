
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

SET NAMES utf8;

CREATE DATABASE IF NOT EXISTS sys DEFAULT CHARACTER SET utf8;

USE sys;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$ps_digest_avg_latency_distribution
--
-- Helper view for x$ps_digest_95th_percentile_by_avg_us
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$ps_digest_avg_latency_distribution (
  cnt,
  avg_us
) AS
SELECT COUNT(*) cnt, 
       ROUND(avg_timer_wait/1000000) AS avg_us
  FROM performance_schema.events_statements_summary_by_digest
 GROUP BY avg_us;-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$ps_digest_95th_percentile_by_avg_us
--
-- Helper view for statements_with_runtimes_in_95th_percentile.
-- Lists the 95th percentile runtime, for all statements
--
-- mysql> select * from x$ps_digest_95th_percentile_by_avg_us;
-- +--------+------------+
-- | avg_us | percentile |
-- +--------+------------+
-- |    964 |     0.9525 |
-- +--------+------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$ps_digest_95th_percentile_by_avg_us (
  avg_us,
  percentile
) AS
SELECT s2.avg_us avg_us,
       IFNULL(SUM(s1.cnt)/NULLIF((SELECT COUNT(*) FROM performance_schema.events_statements_summary_by_digest), 0), 0) percentile
  FROM sys.x$ps_digest_avg_latency_distribution AS s1
  JOIN sys.x$ps_digest_avg_latency_distribution AS s2
    ON s1.avg_us <= s2.avg_us
 GROUP BY s2.avg_us
HAVING IFNULL(SUM(s1.cnt)/NULLIF((SELECT COUNT(*) FROM performance_schema.events_statements_summary_by_digest), 0), 0) > 0.95
 ORDER BY percentile
 LIMIT 1;-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: x$ps_schema_table_statistics_io
--
-- Helper view for schema_table_statistics
-- Having this view with ALGORITHM = TEMPTABLE means MySQL can use the optimizations for
-- materialized views to improve the overall performance.
--
-- mysql> SELECT * FROM x$ps_schema_table_statistics_io LIMIT 1\G
-- *************************** 1. row ***************************
--              table_schema: charsets
--                table_name: Index
--                count_read: 1
--  sum_number_of_bytes_read: 18710
--            sum_timer_read: 20229409070
--               count_write: 0
-- sum_number_of_bytes_write: 0
--           sum_timer_write: 0
--                count_misc: 2
--            sum_timer_misc: 80768480
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$ps_schema_table_statistics_io (
  table_schema,
  table_name,
  count_read,
  sum_number_of_bytes_read,
  sum_timer_read,
  count_write,
  sum_number_of_bytes_write,
  sum_timer_write,
  count_misc,
  sum_timer_misc
) AS
SELECT LEFT(SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(file_name, '\\', '/'), '/', -2), '/', 1), 64) AS table_schema,
       LEFT(SUBSTRING_INDEX(REPLACE(SUBSTRING_INDEX(REPLACE(file_name, '\\', '/'), '/', -1), '@0024', '$'), '.', 1), 64) AS table_name,
       SUM(count_read) AS count_read,
       SUM(sum_number_of_bytes_read) AS sum_number_of_bytes_read,
       SUM(sum_timer_read) AS sum_timer_read,
       SUM(count_write) AS count_write,
       SUM(sum_number_of_bytes_write) AS sum_number_of_bytes_write,
       SUM(sum_timer_write) AS sum_timer_write,
       SUM(count_misc) AS count_misc,
       SUM(sum_timer_misc) AS sum_timer_misc
  FROM performance_schema.file_summary_by_instance
 GROUP BY table_schema, table_name;--
-- View: x$schema_flattened_keys
--
-- Helper view for the schema_redundant_keys view.
--
-- mysql> select * from sys.x$schema_flattened_keys;
-- +---------------+---------------------+------------------------------+------------+----------------+-----------------+
-- | table_schema  | table_name          | index_name                   | non_unique | subpart_exists | index_columns   |
-- +---------------+---------------------+------------------------------+------------+----------------+-----------------+
-- | mem__advisors | advisor_initialized | PRIMARY                      |          0 |              0 | advisorClassId  |
-- | mem__advisors | advisor_schedules   | advisorClassIdIdx            |          1 |              0 | advisorClassId  |
-- | mem__advisors | advisor_schedules   | PRIMARY                      |          0 |              0 | schedule_id     |
-- | mem__advisors | app_identity_path   | FK_7xbq2i81hgo0xlvnb6rr77s21 |          1 |              0 | for_schedule_id |
-- | mem__advisors | app_identity_path   | PRIMARY                      |          0 |              0 | hib_id          |
-- ...
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER
VIEW x$schema_flattened_keys (
  table_schema,
  table_name,
  index_name,
  non_unique,
  subpart_exists,
  index_columns
) AS
  SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    INDEX_NAME,
    MAX(NON_UNIQUE) AS non_unique,
    MAX(IF(SUB_PART IS NULL, 0, 1)) AS subpart_exists,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS index_columns
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE
    INDEX_TYPE='BTREE'
    AND TABLE_SCHEMA NOT IN ('mysql', 'sys', 'INFORMATION_SCHEMA', 'PERFORMANCE_SCHEMA')
  GROUP BY
    TABLE_SCHEMA, TABLE_NAME, INDEX_NAME;-- Copyright (c) 2014, 2016, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: innodb_buffer_stats_by_schema
-- 
-- Summarizes the output of the INFORMATION_SCHEMA.INNODB_BUFFER_PAGE 
-- table, aggregating by schema
--
-- 
-- mysql> select * from innodb_buffer_stats_by_schema;
-- +--------------------------+------------+------------+-------+--------------+-----------+-------------+
-- | object_schema            | allocated  | data       | pages | pages_hashed | pages_old | rows_cached |
-- +--------------------------+------------+------------+-------+--------------+-----------+-------------+
-- | mem30_trunk__instruments | 1.69 MiB   | 510.03 KiB |   108 |          108 |       108 |        3885 |
-- | InnoDB System            | 688.00 KiB | 351.62 KiB |    43 |           43 |        43 |         862 |
-- | mem30_trunk__events      | 80.00 KiB  | 21.61 KiB  |     5 |            5 |         5 |         229 |
-- +--------------------------+------------+------------+-------+--------------+-----------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW innodb_buffer_stats_by_schema AS
SELECT IF(LOCATE('.', ibp.table_name) = 0, 'InnoDB System', REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', 1), '`', '')) AS object_schema,
       round(SUM(IF(ibp.compressed_size = 0, 16384, compressed_size))/ 1073741824, 4) AS allocated_Gb,
       round(SUM(ibp.data_size)/ 1073741824, 4) AS data_Gb,
       COUNT(ibp.page_number) AS pages,
       COUNT(IF(ibp.is_hashed = 'YES', 1, NULL)) AS pages_hashed,
       COUNT(IF(ibp.is_old = 'YES', 1, NULL)) AS pages_old,
       ROUND(SUM(ibp.number_records)/COUNT(DISTINCT ibp.index_name)) AS rows_cached 
  FROM information_schema.innodb_buffer_page ibp 
 WHERE table_name IS NOT NULL
 GROUP BY object_schema
 ORDER BY SUM(IF(ibp.compressed_size = 0, 16384, compressed_size)) DESC;
-- Copyright (c) 2014, 2016, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: innodb_buffer_stats_by_table
-- 
-- Summarizes the output of the INFORMATION_SCHEMA.INNODB_BUFFER_PAGE 
-- table, aggregating by schema and table name
--
-- mysql> select * from innodb_buffer_stats_by_table;
-- +--------------------------+------------------------------------+------------+-----------+-------+--------------+-----------+-------------+
-- | object_schema            | object_name                        | allocated  | data      | pages | pages_hashed | pages_old | rows_cached |
-- +--------------------------+------------------------------------+------------+-----------+-------+--------------+-----------+-------------+
-- | InnoDB System            | SYS_COLUMNS                        | 128.00 KiB | 98.97 KiB |     8 |            8 |         8 |        1532 |
-- | InnoDB System            | SYS_FOREIGN                        | 128.00 KiB | 55.48 KiB |     8 |            8 |         8 |         172 |
-- | InnoDB System            | SYS_TABLES                         | 128.00 KiB | 56.18 KiB |     8 |            8 |         8 |         365 |
-- | InnoDB System            | SYS_INDEXES                        | 112.00 KiB | 76.16 KiB |     7 |            7 |         7 |        1046 |
-- | mem30_trunk__instruments | agentlatencytime                   | 96.00 KiB  | 28.83 KiB |     6 |            6 |         6 |         252 |
-- | mem30_trunk__instruments | binlogspaceusagedata               | 96.00 KiB  | 22.54 KiB |     6 |            6 |         6 |         196 |
-- | mem30_trunk__instruments | connectionsdata                    | 96.00 KiB  | 36.68 KiB |     6 |            6 |         6 |         276 |
-- ...
-- +--------------------------+------------------------------------+------------+-----------+-------+--------------+-----------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW innodb_buffer_stats_by_table AS
SELECT IF(LOCATE('.', ibp.table_name) = 0, 'InnoDB System', REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', 1), '`', '')) AS object_schema,
       REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', -1), '`', '') AS object_name,
       round(SUM(IF(ibp.compressed_size = 0, 16384, compressed_size))/ 1073741824, 4) AS allocated_Gb,
       round(SUM(ibp.data_size)/ 1073741824, 4) AS data_Gb,
       COUNT(ibp.page_number) AS pages,
       COUNT(IF(ibp.is_hashed = 'YES', 1, NULL)) AS pages_hashed,
       COUNT(IF(ibp.is_old = 'YES', 1, NULL)) AS pages_old,
       ROUND(SUM(ibp.number_records)/COUNT(DISTINCT ibp.index_name)) AS rows_cached 
  FROM information_schema.innodb_buffer_page ibp 
 WHERE table_name IS NOT NULL
 GROUP BY object_schema, object_name
 ORDER BY SUM(IF(ibp.compressed_size = 0, 16384, compressed_size)) DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: innodb_lock_waits
--
-- Give a snapshot of which InnoDB locks transactions are waiting for.
-- The lock waits are ordered by the age of the lock descending.
--
-- Versions: 5.1+ (5.1 requires InnoDB Plugin with I_S tables)
--
-- mysql> SELECT * FROM x$innodb_lock_waits\G
-- *************************** 1. row ***************************
--                 wait_started: 2014-11-11 13:39:20
--                     wait_age: 00:00:07
--                wait_age_secs: 7
--                 locked_table: `db1`.`t1`
--                 locked_index: PRIMARY
--                  locked_type: RECORD
--               waiting_trx_id: 867158
--          waiting_trx_started: 2014-11-11 13:39:15
--              waiting_trx_age: 00:00:12
--      waiting_trx_rows_locked: 0
--    waiting_trx_rows_modified: 0
--                  waiting_pid: 3
--                waiting_query: UPDATE t1 SET val = val + 1 WHERE id = 2
--              waiting_lock_id: 867158:2363:3:3
--            waiting_lock_mode: X
--              blocking_trx_id: 867157
--                 blocking_pid: 4
--               blocking_query: UPDATE t1 SET val = val + 1 + SLEEP(10) WHERE id = 2
--             blocking_lock_id: 867157:2363:3:3
--           blocking_lock_mode: X
--         blocking_trx_started: 2014-11-11 13:39:11
--             blocking_trx_age: 00:00:16
--     blocking_trx_rows_locked: 1
--   blocking_trx_rows_modified: 1
--      sql_kill_blocking_query: KILL QUERY 4
-- sql_kill_blocking_connection: KILL 4
-- 1 row in set (0.01 sec)
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW innodb_lock_waits (
  wait_started,
  wait_age,
  wait_age_secs,
  locked_table,
  locked_index,
  locked_type,
  waiting_trx_id,
  waiting_trx_started,
  waiting_trx_age,
  waiting_trx_rows_locked,
  waiting_trx_rows_modified,
  waiting_pid,
  waiting_query,
  waiting_lock_id,
  waiting_lock_mode,
  blocking_trx_id,
  blocking_pid,
  blocking_query,
  blocking_lock_id,
  blocking_lock_mode,
  blocking_trx_started,
  blocking_trx_age,
  blocking_trx_rows_locked,
  blocking_trx_rows_modified,
  sql_kill_blocking_query,
  sql_kill_blocking_connection
) AS
SELECT r.trx_wait_started AS wait_started,
       TIMEDIFF(NOW(), r.trx_wait_started) AS wait_age,
       TIMESTAMPDIFF(SECOND, r.trx_wait_started, NOW()) AS wait_age_secs,
       rl.lock_table AS locked_table,
       rl.lock_index AS locked_index,
       rl.lock_type AS locked_type,
       r.trx_id AS waiting_trx_id,
       r.trx_started as waiting_trx_started,
       TIMEDIFF(NOW(), r.trx_started) AS waiting_trx_age,
       r.trx_rows_locked AS waiting_trx_rows_locked,
       r.trx_rows_modified AS waiting_trx_rows_modified,
       r.trx_mysql_thread_id AS waiting_pid,
       r.trx_query AS waiting_query,
       rl.lock_id AS waiting_lock_id,
       rl.lock_mode AS waiting_lock_mode,
       b.trx_id AS blocking_trx_id,
       b.trx_mysql_thread_id AS blocking_pid,
       b.trx_query AS blocking_query,
       bl.lock_id AS blocking_lock_id,
       bl.lock_mode AS blocking_lock_mode,
       b.trx_started AS blocking_trx_started,
       TIMEDIFF(NOW(), b.trx_started) AS blocking_trx_age,
       b.trx_rows_locked AS blocking_trx_rows_locked,
       b.trx_rows_modified AS blocking_trx_rows_modified,
       CONCAT('KILL QUERY ', b.trx_mysql_thread_id) AS sql_kill_blocking_query,
       CONCAT('KILL ', b.trx_mysql_thread_id) AS sql_kill_blocking_connection
  FROM information_schema.innodb_lock_waits w
       INNER JOIN information_schema.innodb_trx b    ON b.trx_id = w.blocking_trx_id
       INNER JOIN information_schema.innodb_trx r    ON r.trx_id = w.requesting_trx_id
       INNER JOIN information_schema.innodb_locks bl ON bl.lock_id = w.blocking_lock_id
       INNER JOIN information_schema.innodb_locks rl ON rl.lock_id = w.requested_lock_id
 ORDER BY r.trx_wait_started;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: schema_object_overview
-- 
-- Shows an overview of the types of objects within each schema
--
-- Note: On instances with a large number of objects, this could take
--       some time to execute, and is not recommended.
--
-- mysql> select * from schema_object_overview;
-- +---------------------------------+---------------+-------+
-- | db                              | object_type   | count |
-- +---------------------------------+---------------+-------+
-- | information_schema              | SYSTEM VIEW   |    59 |
-- | mem30_test__instruments         | BASE TABLE    |     1 |
-- | mem30_test__instruments         | INDEX (BTREE) |     2 |
-- | mem30_test__test                | BASE TABLE    |     9 |
-- | mem30_test__test                | INDEX (BTREE) |    19 |
-- ...
-- | sys                             | FUNCTION      |     8 |
-- | sys                             | PROCEDURE     |    16 |
-- | sys                             | VIEW          |    59 |
-- +---------------------------------+---------------+-------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_object_overview (
  db,
  object_type,
  count
) AS
SELECT ROUTINE_SCHEMA AS db, ROUTINE_TYPE AS object_type, COUNT(*) AS count FROM information_schema.routines GROUP BY ROUTINE_SCHEMA, ROUTINE_TYPE
 UNION 
SELECT TABLE_SCHEMA, TABLE_TYPE, COUNT(*) FROM information_schema.tables GROUP BY TABLE_SCHEMA, TABLE_TYPE
 UNION
SELECT TABLE_SCHEMA, CONCAT('INDEX (', INDEX_TYPE, ')'), COUNT(*) FROM information_schema.statistics GROUP BY TABLE_SCHEMA, INDEX_TYPE
 UNION
SELECT TRIGGER_SCHEMA, 'TRIGGER', COUNT(*) FROM information_schema.triggers GROUP BY TRIGGER_SCHEMA
 UNION
SELECT EVENT_SCHEMA, 'EVENT', COUNT(*) FROM information_schema.events GROUP BY EVENT_SCHEMA
ORDER BY DB, OBJECT_TYPE;

--
-- View: schema_auto_increment_columns
--
-- Present current auto_increment usage/capacity in all tables.
--
-- mysql> select * from schema_auto_increment_columns limit 5;
-- +-------------------+-------------------+-------------+-----------+-------------+-----------+-------------+---------------------+----------------+----------------------+
-- | table_schema      | table_name        | column_name | data_type | column_type | is_signed | is_unsigned | max_value           | auto_increment | auto_increment_ratio |
-- +-------------------+-------------------+-------------+-----------+-------------+-----------+-------------+---------------------+----------------+----------------------+
-- | test              | t1                | i           | tinyint   | tinyint(4)  |         1 |           0 |                 127 |             34 |               0.2677 |
-- | mem__advisor_text | template_meta     | hib_id      | int       | int(11)     |         1 |           0 |          2147483647 |            516 |               0.0000 |
-- | mem__advisors     | advisor_schedules | schedule_id | int       | int(11)     |         1 |           0 |          2147483647 |            249 |               0.0000 |
-- | mem__advisors     | app_identity_path | hib_id      | int       | int(11)     |         1 |           0 |          2147483647 |            251 |               0.0000 |
-- | mem__bean_config  | plists            | id          | bigint    | bigint(20)  |         1 |           0 | 9223372036854775807 |              1 |               0.0000 |
-- +-------------------+-------------------+-------------+-----------+-------------+-----------+-------------+---------------------+----------------+----------------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER
VIEW schema_auto_increment_columns (
  table_schema,
  table_name,
  column_name,
  data_type,
  column_type,
  is_signed,
  is_unsigned,
  max_value,
  auto_increment,
  auto_increment_ratio
) AS
SELECT TABLE_SCHEMA,
       TABLE_NAME,
       COLUMN_NAME,
       DATA_TYPE,
       COLUMN_TYPE,
       (LOCATE('unsigned', COLUMN_TYPE) = 0) AS is_signed,
       (LOCATE('unsigned', COLUMN_TYPE) > 0) AS is_unsigned,
       (
          CASE DATA_TYPE
            WHEN 'tinyint' THEN 255
            WHEN 'smallint' THEN 65535
            WHEN 'mediumint' THEN 16777215
            WHEN 'int' THEN 4294967295
            WHEN 'bigint' THEN 18446744073709551615
          END >> IF(LOCATE('unsigned', COLUMN_TYPE) > 0, 0, 1)
       ) AS max_value,
       AUTO_INCREMENT,
       AUTO_INCREMENT / (
         CASE DATA_TYPE
           WHEN 'tinyint' THEN 255
           WHEN 'smallint' THEN 65535
           WHEN 'mediumint' THEN 16777215
           WHEN 'int' THEN 4294967295
           WHEN 'bigint' THEN 18446744073709551615
         END >> IF(LOCATE('unsigned', COLUMN_TYPE) > 0, 0, 1)
       ) AS auto_increment_ratio
  FROM INFORMATION_SCHEMA.COLUMNS
 INNER JOIN INFORMATION_SCHEMA.TABLES USING (TABLE_SCHEMA, TABLE_NAME)
 WHERE TABLE_SCHEMA NOT IN ('mysql', 'sys', 'INFORMATION_SCHEMA', 'performance_schema')
   AND TABLE_TYPE='BASE TABLE'
   AND EXTRA='auto_increment'
 ORDER BY auto_increment_ratio DESC, max_value;
--
-- View: schema_redundant_keys
--
-- Shows indexes which are made redundant (or duplicate) by other (dominant) keys.
--
-- mysql> select * from sys.schema_redundant_indexes\G
-- *************************** 1. row ***************************
--               table_schema: test
--                 table_name: rkey
--       redundant_index_name: j
--    redundant_index_columns: j
-- redundant_index_non_unique: 1
--        dominant_index_name: j_2
--     dominant_index_columns: j,k
--  dominant_index_non_unique: 1
--             subpart_exists: 0
--             sql_drop_index: ALTER TABLE `test`.`rkey` DROP INDEX `j`
-- 1 row in set (0.20 sec)
-- 
-- mysql> SHOW CREATE TABLE test.rkey\G
-- *************************** 1. row ***************************
--        Table: rkey
-- Create Table: CREATE TABLE `rkey` (
--   `i` int(11) NOT NULL,
--   `j` int(11) DEFAULT NULL,
--   `k` int(11) DEFAULT NULL,
--   PRIMARY KEY (`i`),
--   KEY `j` (`j`),
--   KEY `j_2` (`j`,`k`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=latin1
-- 1 row in set (0.06 sec)
-- 

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER
VIEW schema_redundant_indexes (
  table_schema,
  table_name,
  redundant_index_name,
  redundant_index_columns,
  redundant_index_non_unique,
  dominant_index_name,
  dominant_index_columns,
  dominant_index_non_unique,
  subpart_exists,
  sql_drop_index
) AS
  SELECT
    redundant_keys.table_schema,
    redundant_keys.table_name,
    redundant_keys.index_name AS redundant_index_name,
    redundant_keys.index_columns AS redundant_index_columns,
    redundant_keys.non_unique AS redundant_index_non_unique,
    dominant_keys.index_name AS dominant_index_name,
    dominant_keys.index_columns AS dominant_index_columns,
    dominant_keys.non_unique AS dominant_index_non_unique,
    IF(redundant_keys.subpart_exists OR dominant_keys.subpart_exists, 1 ,0) AS subpart_exists,
    CONCAT(
      'ALTER TABLE `', redundant_keys.table_schema, '`.`', redundant_keys.table_name, '` DROP INDEX `', redundant_keys.index_name, '`'
      ) AS sql_drop_index
  FROM
    x$schema_flattened_keys AS redundant_keys
    INNER JOIN x$schema_flattened_keys AS dominant_keys
    USING (TABLE_SCHEMA, TABLE_NAME)
  WHERE
    redundant_keys.index_name != dominant_keys.index_name
    AND (
      ( 
        /* Identical columns */
        (redundant_keys.index_columns = dominant_keys.index_columns)
        AND (
          (redundant_keys.non_unique > dominant_keys.non_unique)
          OR (redundant_keys.non_unique = dominant_keys.non_unique 
          	AND IF(redundant_keys.index_name='PRIMARY', '', redundant_keys.index_name) > IF(dominant_keys.index_name='PRIMARY', '', dominant_keys.index_name)
          )
        )
      )
      OR
      ( 
        /* Non-unique prefix columns */
        LOCATE(CONCAT(redundant_keys.index_columns, ','), dominant_keys.index_columns) = 1
        AND redundant_keys.non_unique = 1
      )
      OR
      ( 
        /* Unique prefix columns */
        LOCATE(CONCAT(dominant_keys.index_columns, ','), redundant_keys.index_columns) = 1
        AND dominant_keys.non_unique = 0
      )
    );
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: ps_check_lost_instrumentation
-- 
-- Used to check whether Performance Schema is not able to monitor
-- all runtime data - only returns variables that have lost instruments
--
-- mysql> select * from ps_check_lost_instrumentation;
-- +----------------------------------------+----------------+
-- | variable_name                          | variable_value |
-- +----------------------------------------+----------------+
-- | Performance_schema_file_handles_lost   | 101223         |
-- | Performance_schema_file_instances_lost | 1231           |
-- +----------------------------------------+----------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW ps_check_lost_instrumentation (
  variable_name,
  variable_value
)
AS
SELECT variable_name, variable_value
  FROM information_schema.global_status
 WHERE variable_name LIKE 'perf%lost'
   AND variable_value > 0;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: processlist
--
-- A detailed non-blocking processlist view to replace 
-- [INFORMATION_SCHEMA. | SHOW FULL] PROCESSLIST
--
-- mysql> select * from processlist where conn_id is not null\G
-- *************************** 1. row ***************************
--                 thd_id: 23
--                conn_id: 4
--                   user: msandbox@localhost
--                     db: test
--                command: Query
--                  state: Sending data
--                   time: 4
--      current_statement: select count(*) from t1
--      statement_latency: 4.56 s
--           lock_latency: 108.00 us
--          rows_examined: 0
--              rows_sent: 0
--          rows_affected: 0
--             tmp_tables: 0
--        tmp_disk_tables: 0
--              full_scan: YES
--         last_statement: NULL
-- last_statement_latency: NULL
--              last_wait: wait/io/table/sql/handler
--      last_wait_latency: Still Waiting
--                 source: handler.cc:2688
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER
VIEW processlist AS
SELECT pps.thread_id AS thd_id,
       pps.processlist_id AS conn_id,
       IF(pps.name = 'thread/sql/one_connection',
          CONCAT(pps.processlist_user, '@', pps.processlist_host),
          REPLACE(pps.name, 'thread/', '')) user,
       pps.processlist_db AS db,
       pps.processlist_command AS command,
       pps.processlist_state AS state,
       pps.processlist_time AS 'time',
       LEFT(REPLACE(pps.processlist_info, '\n', ' '), 100) AS current_statement,
       IF(esc.end_event_id IS NULL,
          round(esc.timer_wait / 1000000000000, 2),
          NULL) AS statement_latency_sec,
       round(esc.lock_time / 1000000000000, 2) AS lock_latency_sec,
       esc.rows_examined AS rows_examined,
       esc.rows_sent AS rows_sent,
       esc.rows_affected AS rows_affected,
       esc.created_tmp_tables AS tmp_tables,
       esc.created_tmp_disk_tables AS tmp_disk_tables,
       IF(esc.no_good_index_used > 0 OR esc.no_index_used > 0, 'YES', 'NO') AS full_scan,
       IF(esc.end_event_id IS NOT NULL,
          LEFT(REPLACE(esc.sql_text, '\n', ' '), 100),
          NULL) AS last_statement,
       IF(esc.end_event_id IS NOT NULL,
          round(esc.timer_wait / 1000000000000, 2),
          NULL) AS last_statement_latency_sec,
       ewc.event_name AS last_wait,
       IF(ewc.end_event_id IS NULL AND ewc.event_name IS NOT NULL,
          'Still Waiting',
          round(ewc.timer_wait  / 1000000000000, 2)) last_wait_latency_sec,
       ewc.source
  FROM performance_schema.threads AS pps
  LEFT JOIN performance_schema.events_waits_current AS ewc USING (thread_id)
  LEFT JOIN performance_schema.events_statements_current as esc USING (thread_id)
 ORDER BY pps.processlist_time DESC, last_wait_latency_sec DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: session
--
-- Filter sys.processlist to only show user sessions and not background threads.
-- This is a non-blocking closer replacement to
-- [INFORMATION_SCHEMA. | SHOW FULL] PROCESSLIST
-- 
-- Performs less locking than the legacy sources, whilst giving extra information.
--
-- mysql> select * from sys.sessions\G
-- *************************** 1. row ***************************
--                 thd_id: 24
--                conn_id: 2
--                   user: root@localhost
--                     db: sys
--                command: Query
--                  state: Sending data
--                   time: 0
--      current_statement: select * from sys.session
--      statement_latency: 137.22 ms
--               progress: NULL
--           lock_latency: 33.75 ms
--          rows_examined: 0
--              rows_sent: 0
--          rows_affected: 0
--             tmp_tables: 4
--        tmp_disk_tables: 1
--              full_scan: YES
--         last_statement: NULL
-- last_statement_latency: NULL
--         current_memory: 3.26 MiB
--              last_wait: wait/synch/mutex/innodb/file_format_max_mutex
--      last_wait_latency: 64.09 ns
--                 source: trx0sys.cc:778
--            trx_latency: 7.88 s
--              trx_state: ACTIVE
--         trx_autocommit: NO
--                    pid: 4212
--           program_name: mysql
--

CREATE OR REPLACE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW sessions
 AS
SELECT * FROM sys.processlist
WHERE conn_id IS NOT NULL AND command != 'Daemon';

-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: latest_file_io
--
-- Shows the latest file IO, by file / thread.
--
-- mysql> select * from latest_file_io limit 5;
-- +----------------------+----------------------------------------+------------+-----------+-----------+
-- | thread               | file                                   | latency    | operation | requested |
-- +----------------------+----------------------------------------+------------+-----------+-----------+
-- | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 9.26 us    | write     | 124 bytes |
-- | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 4.00 us    | write     | 2 bytes   |
-- | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 56.34 us   | close     | NULL      |
-- | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYD             | 53.93 us   | close     | NULL      |
-- | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 104.05 ms  | delete    | NULL      |
-- +----------------------+----------------------------------------+------------+-----------+-----------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW latest_file_io AS
SELECT IF(id IS NULL, 
             CONCAT(SUBSTRING_INDEX(name, '/', -1), ':', thread_id), 
             CONCAT(user, '@', host, ':', id)
          ) thread, 
       object_name file, 
       round(timer_wait / 1000000000000, 4) AS latency_sec, 
       operation, 
       round(number_of_bytes / 1073741824, 4) AS requested_Gb
  FROM performance_schema.events_waits_history_long 
  JOIN performance_schema.threads USING (thread_id)
  LEFT JOIN information_schema.processlist ON processlist_id = id
 WHERE object_name IS NOT NULL
   AND event_name LIKE 'wait/io/file/%'
 ORDER BY timer_start;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: io_by_thread_by_latency
--
-- Show the top IO consumers by thread, ordered by total latency
--
-- mysql> select * from io_by_thread_by_latency;
-- +---------------------+-------+---------------+-------------+-------------+-------------+-----------+----------------+
-- | user                | total | total_latency | min_latency | avg_latency | max_latency | thread_id | processlist_id |
-- +---------------------+-------+---------------+-------------+-------------+-------------+-----------+----------------+
-- | root@localhost      | 11580 | 18.01 s       | 429.78 ns   | 1.12 ms     | 181.07 ms   |        25 |              6 |
-- | main                |  1358 | 1.31 s        | 475.02 ns   | 2.27 ms     | 350.70 ms   |         1 |           NULL |
-- | page_cleaner_thread |   654 | 147.44 ms     | 588.12 ns   | 225.44 us   | 46.41 ms    |        18 |           NULL |
-- | io_write_thread     |   131 | 107.75 ms     | 8.60 us     | 822.55 us   | 27.69 ms    |         8 |           NULL |
-- | io_write_thread     |    46 | 47.07 ms      | 10.64 us    | 1.02 ms     | 16.90 ms    |         9 |           NULL |
-- | io_write_thread     |    71 | 46.99 ms      | 9.11 us     | 661.81 us   | 17.04 ms    |        11 |           NULL |
-- | io_log_thread       |    20 | 21.01 ms      | 14.25 us    | 1.05 ms     | 7.08 ms     |         3 |           NULL |
-- | srv_master_thread   |    13 | 17.60 ms      | 8.49 us     | 1.35 ms     | 9.99 ms     |        16 |           NULL |
-- | srv_purge_thread    |     4 | 1.81 ms       | 34.31 us    | 452.45 us   | 1.02 ms     |        17 |           NULL |
-- | io_write_thread     |    19 | 951.39 us     | 9.75 us     | 50.07 us    | 297.47 us   |        10 |           NULL |
-- | signal_handler      |     3 | 218.03 us     | 21.64 us    | 72.68 us    | 154.84 us   |        19 |           NULL |
-- +---------------------+-------+---------------+-------------+-------------+-------------+-----------+----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW io_by_thread_by_latency AS
SELECT IF(processlist_id IS NULL, 
             SUBSTRING_INDEX(name, '/', -1), 
             CONCAT(processlist_user, '@', processlist_host)
          ) user, 
       SUM(count_star) total,
       round(SUM(sum_timer_wait) / 1000000000000, 4) total_latency_sec,
       round(MIN(min_timer_wait) / 1000000000000, 4) min_latency_sec,
       round(AVG(avg_timer_wait) / 1000000000000, 4) avg_latency_sec,
       round(MAX(max_timer_wait) / 1000000000000, 4) max_latency_sec,
       thread_id,
       processlist_id
  FROM performance_schema.events_waits_summary_by_thread_by_event_name 
  LEFT JOIN performance_schema.threads USING (thread_id)
 WHERE event_name LIKE 'wait/io/file/%'
   AND sum_timer_wait > 0
 GROUP BY thread_id, processlist_id, user
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: io_global_by_file_by_bytes
--
-- Shows the top global IO consumers by bytes usage by file.
--
-- mysql> SELECT * FROM io_global_by_file_by_bytes LIMIT 5;
-- +--------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
-- | file                                       | count_read | total_read | avg_read  | count_write | total_written | avg_write | total      | write_pct |
-- +--------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
-- | @@datadir/ibdata1                          |        147 | 4.27 MiB   | 29.71 KiB |           3 | 48.00 KiB     | 16.00 KiB | 4.31 MiB   |      1.09 |
-- | @@datadir/mysql/proc.MYD                   |        347 | 85.35 KiB  | 252 bytes |         111 | 19.08 KiB     | 176 bytes | 104.43 KiB |     18.27 |
-- | @@datadir/ib_logfile0                      |          6 | 68.00 KiB  | 11.33 KiB |           8 | 4.00 KiB      | 512 bytes | 72.00 KiB  |      5.56 |
-- | /opt/mysql/5.5.33/share/english/errmsg.sys |          3 | 43.68 KiB  | 14.56 KiB |           0 | 0 bytes       | 0 bytes   | 43.68 KiB  |      0.00 |
-- | /opt/mysql/5.5.33/share/charsets/Index.xml |          1 | 17.89 KiB  | 17.89 KiB |           0 | 0 bytes       | 0 bytes   | 17.89 KiB  |      0.00 |
-- +--------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW io_global_by_file_by_bytes AS
SELECT file_name AS file, 
       count_read, 
       round(sum_number_of_bytes_read / 1073741824, 4) AS total_read_Gb,
       round(IFNULL(sum_number_of_bytes_read / NULLIF(count_read, 0), 0) / 1073741824, 4) AS avg_read_Gb,
       count_write, 
       round(sum_number_of_bytes_write / 1073741824, 4) AS total_written_Gb,
       round(IFNULL(sum_number_of_bytes_write / NULLIF(count_write, 0), 0.00) / 1073741824, 4) AS avg_write_Gb,
       round((sum_number_of_bytes_read + sum_number_of_bytes_write) / 1073741824, 4) AS total_Gb, 
       IFNULL(ROUND(100-((sum_number_of_bytes_read/ NULLIF((sum_number_of_bytes_read+sum_number_of_bytes_write), 0))*100), 2), 0.00) AS write_pct 
  FROM performance_schema.file_summary_by_instance
 ORDER BY sum_number_of_bytes_read + sum_number_of_bytes_write DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: io_global_by_file_by_latency
--
-- Shows the top global IO consumers by latency by file.
--
-- mysql> select * from io_global_by_file_by_latency limit 5;
-- +-----------------------------------------------------------+-------+---------------+------------+--------------+-------------+---------------+------------+--------------+
-- | file                                                      | total | total_latency | count_read | read_latency | count_write | write_latency | count_misc | misc_latency |
-- +-----------------------------------------------------------+-------+---------------+------------+--------------+-------------+---------------+------------+--------------+
-- | @@datadir/sys/wait_classes_global_by_avg_latency_raw.frm~ |    24 | 451.99 ms     |          0 | 0 ps         |           4 | 108.07 us     |         20 | 451.88 ms    |
-- | @@datadir/sys/innodb_buffer_stats_by_schema_raw.frm~      |    24 | 379.84 ms     |          0 | 0 ps         |           4 | 108.88 us     |         20 | 379.73 ms    |
-- | @@datadir/sys/io_by_thread_by_latency_raw.frm~            |    24 | 379.46 ms     |          0 | 0 ps         |           4 | 101.37 us     |         20 | 379.36 ms    |
-- | @@datadir/ibtmp1                                          |    53 | 373.45 ms     |          0 | 0 ps         |          48 | 246.08 ms     |          5 | 127.37 ms    |
-- | @@datadir/sys/statement_analysis_raw.frm~                 |    24 | 353.14 ms     |          0 | 0 ps         |           4 | 94.96 us      |         20 | 353.04 ms    |
-- +-----------------------------------------------------------+-------+---------------+------------+--------------+-------------+---------------+------------+--------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW io_global_by_file_by_latency AS
SELECT file_name AS file, 
       count_star AS total, 
       round(sum_timer_wait / 1000000000000, 4) AS total_latency_sec,
       count_read,
       round(sum_timer_read / 1000000000000, 4) AS read_latency_sec,
       count_write,
       round(sum_timer_write / 1000000000000, 4) AS write_latency_sec,
       count_misc,
       round(sum_timer_misc / 1000000000000, 4) AS misc_latency_sec
  FROM performance_schema.file_summary_by_instance
 ORDER BY sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: io_global_by_wait_by_bytes
--
-- Shows the top global IO consumer classes by bytes usage.
--
-- mysql> select * from io_global_by_wait_by_bytes;
-- +--------------------+--------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
-- | event_name         | total  | total_latency | min_latency | avg_latency | max_latency | count_read | total_read | avg_read  | count_write | total_written | avg_written | total_requested |
-- +--------------------+--------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
-- | myisam/dfile       | 163681 | 983.13 ms     | 379.08 ns   | 6.01 us     | 22.06 ms    |      68737 | 127.31 MiB | 1.90 KiB  |     1012221 | 121.52 MiB    | 126 bytes   | 248.83 MiB      |
-- | myisam/kfile       |   1775 | 375.13 ms     | 1.02 us     | 211.34 us   | 35.15 ms    |      54066 | 9.97 MiB   | 193 bytes |      428257 | 12.40 MiB     | 30 bytes    | 22.37 MiB       |
-- | sql/FRM            |  57889 | 8.40 s        | 19.44 ns    | 145.05 us   | 336.71 ms   |       8009 | 2.60 MiB   | 341 bytes |       14675 | 2.91 MiB      | 208 bytes   | 5.51 MiB        |
-- | sql/global_ddl_log |    164 | 75.96 ms      | 5.72 us     | 463.19 us   | 7.43 ms     |         20 | 80.00 KiB  | 4.00 KiB  |          76 | 304.00 KiB    | 4.00 KiB    | 384.00 KiB      |
-- | sql/file_parser    |    419 | 601.37 ms     | 1.96 us     | 1.44 ms     | 37.14 ms    |         66 | 42.01 KiB  | 652 bytes |          64 | 226.98 KiB    | 3.55 KiB    | 268.99 KiB      |
-- | sql/binlog         |    190 | 6.79 s        | 1.56 us     | 35.76 ms    | 4.21 s      |         52 | 60.54 KiB  | 1.16 KiB  |           0 | 0 bytes       | 0 bytes     | 60.54 KiB       |
-- | sql/ERRMSG         |      5 | 2.03 s        | 8.61 us     | 405.40 ms   | 2.03 s      |          3 | 51.82 KiB  | 17.27 KiB |           0 | 0 bytes       | 0 bytes     | 51.82 KiB       |
-- | mysys/charset      |      3 | 196.52 us     | 17.61 us    | 65.51 us    | 137.33 us   |          1 | 17.83 KiB  | 17.83 KiB |           0 | 0 bytes       | 0 bytes     | 17.83 KiB       |
-- | sql/partition      |     81 | 18.87 ms      | 888.08 ns   | 232.92 us   | 4.67 ms     |         66 | 2.75 KiB   | 43 bytes  |           8 | 288 bytes     | 36 bytes    | 3.04 KiB        |
-- | sql/dbopt          | 329166 | 26.95 s       | 2.06 us     | 81.89 us    | 178.71 ms   |          0 | 0 bytes    | 0 bytes   |           9 | 585 bytes     | 65 bytes    | 585 bytes       |
-- | sql/relaylog       |      7 | 1.18 ms       | 838.84 ns   | 168.30 us   | 892.70 us   |          0 | 0 bytes    | 0 bytes   |           1 | 120 bytes     | 120 bytes   | 120 bytes       |
-- | mysys/cnf          |      5 | 171.61 us     | 303.26 ns   | 34.32 us    | 115.21 us   |          3 | 56 bytes   | 19 bytes  |           0 | 0 bytes       | 0 bytes     | 56 bytes        |
-- | sql/pid            |      3 | 220.55 us     | 29.29 us    | 73.52 us    | 143.11 us   |          0 | 0 bytes    | 0 bytes   |           1 | 5 bytes       | 5 bytes     | 5 bytes         |
-- | sql/casetest       |      1 | 121.19 us     | 121.19 us   | 121.19 us   | 121.19 us   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
-- | sql/binlog_index   |      5 | 593.47 us     | 1.07 us     | 118.69 us   | 535.90 us   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
-- | sql/misc           |     23 | 2.73 ms       | 65.14 us    | 118.50 us   | 255.31 us   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
-- +--------------------+--------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW io_global_by_wait_by_bytes AS
SELECT SUBSTRING_INDEX(event_name, '/', -2) event_name,
       count_star AS total,
       round(sum_timer_wait / 1000000000000, 4) AS total_latency_sec,
       round(min_timer_wait / 1000000000000, 4) AS min_latency_sec,
       round(avg_timer_wait / 1000000000000, 4) AS avg_latency_sec,
       round(max_timer_wait / 1000000000000, 4) AS max_latency_sec,
       count_read,
       round(sum_number_of_bytes_read / 1073741824, 4) AS total_read_Gb,
       round(IFNULL(sum_number_of_bytes_read / NULLIF(count_read, 0), 0) / 1073741824, 4) AS avg_read_Gb,
       count_write,
       round(sum_number_of_bytes_write / 1073741824, 4) AS total_written,
       round(IFNULL(sum_number_of_bytes_write / NULLIF(count_write, 0), 0) / 1073741824, 4) AS avg_written_Gb,
       round((sum_number_of_bytes_write + sum_number_of_bytes_read) / 1073741824, 4) AS total_requested_Gb
  FROM performance_schema.file_summary_by_event_name
 WHERE event_name LIKE 'wait/io/file/%' 
   AND count_star > 0
 ORDER BY sum_number_of_bytes_write + sum_number_of_bytes_read DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: io_global_by_wait_by_latency
--
-- Shows the top global IO consumers by latency.
--
-- mysql> SELECT * FROM io_global_by_wait_by_latency;
-- +-------------------------+-------+---------------+-------------+-------------+--------------+---------------+--------------+------------+------------+-----------+-------------+---------------+-------------+
-- | event_name              | total | total_latency | avg_latency | max_latency | read_latency | write_latency | misc_latency | count_read | total_read | avg_read  | count_write | total_written | avg_written |
-- +-------------------------+-------+---------------+-------------+-------------+--------------+---------------+--------------+------------+------------+-----------+-------------+---------------+-------------+
-- | sql/file_parser         |  5433 | 30.20 s       | 5.56 ms     | 203.65 ms   | 22.08 ms     | 24.89 ms      | 30.16 s      |         24 | 6.18 KiB   | 264 bytes |         737 | 2.15 MiB      | 2.99 KiB    |
-- | innodb/innodb_data_file |  1344 | 1.52 s        | 1.13 ms     | 350.70 ms   | 203.82 ms    | 450.96 ms     | 868.21 ms    |        147 | 2.30 MiB   | 16.00 KiB |        1001 | 53.61 MiB     | 54.84 KiB   |
-- | innodb/innodb_log_file  |   828 | 893.48 ms     | 1.08 ms     | 30.11 ms    | 16.32 ms     | 705.89 ms     | 171.27 ms    |          6 | 68.00 KiB  | 11.33 KiB |         413 | 2.19 MiB      | 5.42 KiB    |
-- | myisam/kfile            |  7642 | 242.34 ms     | 31.71 us    | 19.27 ms    | 73.60 ms     | 23.48 ms      | 145.26 ms    |        758 | 135.63 KiB | 183 bytes |        4386 | 232.52 KiB    | 54 bytes    |
-- | myisam/dfile            | 12540 | 223.47 ms     | 17.82 us    | 32.50 ms    | 87.76 ms     | 16.97 ms      | 118.74 ms    |       5390 | 4.49 MiB   | 873 bytes |        1448 | 2.65 MiB      | 1.88 KiB    |
-- | csv/metadata            |     8 | 28.98 ms      | 3.62 ms     | 20.15 ms    | 399.27 us    | 0 ps          | 28.58 ms     |          2 | 70 bytes   | 35 bytes  |           0 | 0 bytes       | 0 bytes     |
-- | mysys/charset           |     3 | 24.24 ms      | 8.08 ms     | 24.15 ms    | 24.15 ms     | 0 ps          | 93.18 us     |          1 | 17.31 KiB  | 17.31 KiB |           0 | 0 bytes       | 0 bytes     |
-- | sql/ERRMSG              |     5 | 20.43 ms      | 4.09 ms     | 19.31 ms    | 20.32 ms     | 0 ps          | 103.20 us    |          3 | 58.97 KiB  | 19.66 KiB |           0 | 0 bytes       | 0 bytes     |
-- | mysys/cnf               |     5 | 11.37 ms      | 2.27 ms     | 11.28 ms    | 11.29 ms     | 0 ps          | 78.22 us     |          3 | 56 bytes   | 19 bytes  |           0 | 0 bytes       | 0 bytes     |
-- | sql/dbopt               |    57 | 4.04 ms       | 70.92 us    | 843.70 us   | 0 ps         | 186.43 us     | 3.86 ms      |          0 | 0 bytes    | 0 bytes   |           7 | 431 bytes     | 62 bytes    |
-- | csv/data                |     4 | 411.55 us     | 102.89 us   | 234.89 us   | 0 ps         | 0 ps          | 411.55 us    |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
-- | sql/misc                |    22 | 340.38 us     | 15.47 us    | 33.77 us    | 0 ps         | 0 ps          | 340.38 us    |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
-- | archive/data            |    39 | 277.86 us     | 7.12 us     | 16.18 us    | 0 ps         | 0 ps          | 277.86 us    |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
-- | sql/pid                 |     3 | 218.03 us     | 72.68 us    | 154.84 us   | 0 ps         | 21.64 us      | 196.39 us    |          0 | 0 bytes    | 0 bytes   |           1 | 6 bytes       | 6 bytes     |
-- | sql/casetest            |     5 | 197.15 us     | 39.43 us    | 126.31 us   | 0 ps         | 0 ps          | 197.15 us    |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
-- | sql/global_ddl_log      |     2 | 14.60 us      | 7.30 us     | 12.12 us    | 0 ps         | 0 ps          | 14.60 us     |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
-- +-------------------------+-------+---------------+-------------+-------------+--------------+---------------+--------------+------------+------------+-----------+-------------+---------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW io_global_by_wait_by_latency AS
SELECT SUBSTRING_INDEX(event_name, '/', -2) AS event_name,
       count_star AS total,
       round(sum_timer_wait / 1000000000000, 4) AS total_latency_sec,
       round(avg_timer_wait / 1000000000000, 4) AS avg_latency_sec,
       round(max_timer_wait / 1000000000000, 4) AS max_latency_sec,
       round(sum_timer_read / 1000000000000, 4) AS read_latency_sec,
       round(sum_timer_write / 1000000000000, 4) AS write_latency_sec,
       round(sum_timer_misc / 1000000000000, 4) AS misc_latency_sec,
       count_read,
       round(sum_number_of_bytes_read / 1073741824, 4) AS total_read_Gb,
       round(IFNULL(sum_number_of_bytes_read / NULLIF(count_read, 0), 0) / 1073741824, 4) AS avg_read_Gb,
       count_write,
       round(sum_number_of_bytes_write / 1073741824, 4) AS total_written_Gb,
       round(IFNULL(sum_number_of_bytes_write / NULLIF(count_write, 0), 0) / 1073741824, 4) AS avg_written_Gb
  FROM performance_schema.file_summary_by_event_name 
 WHERE event_name LIKE 'wait/io/file/%'
   AND count_star > 0
 ORDER BY sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: schema_index_statistics
--
-- Statistics around indexes.
--
-- Ordered by the total wait time descending - top indexes are most contended.
--
-- mysql> select * from schema_index_statistics limit 5;
-- +------------------+-------------+------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
-- | table_schema     | table_name  | index_name | rows_selected | select_latency | rows_inserted | insert_latency | rows_updated | update_latency | rows_deleted | delete_latency |
-- +------------------+-------------+------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
-- | mem              | mysqlserver | PRIMARY    |          6208 | 108.27 ms      |             0 | 0 ps           |         5470 | 1.47 s         |            0 | 0 ps           |
-- | mem              | innodb      | PRIMARY    |          4666 | 76.27 ms       |             0 | 0 ps           |         4454 | 571.47 ms      |            0 | 0 ps           |
-- | mem              | connection  | PRIMARY    |          1064 | 20.98 ms       |             0 | 0 ps           |         1064 | 457.30 ms      |            0 | 0 ps           |
-- | mem              | environment | PRIMARY    |          5566 | 151.17 ms      |             0 | 0 ps           |          694 | 252.57 ms      |            0 | 0 ps           |
-- | mem              | querycache  | PRIMARY    |          1698 | 27.99 ms       |             0 | 0 ps           |         1698 | 371.72 ms      |            0 | 0 ps           |
-- +------------------+-------------+------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_index_statistics AS
SELECT OBJECT_SCHEMA AS table_schema,
       OBJECT_NAME AS table_name,
       INDEX_NAME as index_name,
       COUNT_FETCH AS rows_selected,
       round(SUM_TIMER_FETCH / 1000000000000, 4) AS select_latency_sec,
       COUNT_INSERT AS rows_inserted,
       round(SUM_TIMER_INSERT / 1000000000000, 4) AS insert_latency_sec,
       COUNT_UPDATE AS rows_updated,
       round(SUM_TIMER_UPDATE / 1000000000000, 4) AS update_latency_sec,
       COUNT_DELETE AS rows_deleted,
       round(SUM_TIMER_INSERT / 1000000000000, 4) AS delete_latency_sec
  FROM performance_schema.table_io_waits_summary_by_index_usage
 WHERE index_name IS NOT NULL
 ORDER BY sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: schema_table_statistics
--
-- Statistics around tables.
--
-- Ordered by the total wait time descending - top tables are most contended.
-- 
-- mysql> SELECT * FROM schema_table_statistics\G
-- *************************** 1. row ***************************
--      table_schema: sys
--        table_name: sys_config
--     total_latency: 0 ps
--      rows_fetched: 0
--     fetch_latency: 0 ps
--     rows_inserted: 0
--    insert_latency: 0 ps
--      rows_updated: 0
--    update_latency: 0 ps
--      rows_deleted: 0
--    delete_latency: 0 ps
--  io_read_requests: 8
--           io_read: 2.28 KiB
--   io_read_latency: 727.32 us
-- io_write_requests: 0
--          io_write: 0 bytes
--  io_write_latency: 0 ps
--  io_misc_requests: 10
--   io_misc_latency: 126.88 us
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_table_statistics AS
SELECT pst.object_schema AS table_schema,
       pst.object_name AS table_name,
       round(pst.sum_timer_wait / 1000000000000, 4) AS total_latency_sec,
       pst.count_fetch AS rows_fetched,
       round(pst.sum_timer_fetch / 1000000000000, 4) AS fetch_latency_sec,
       pst.count_insert AS rows_inserted,
       round(pst.sum_timer_insert / 1000000000000, 4) AS insert_latency_sec,
       pst.count_update AS rows_updated,
       round(pst.sum_timer_update / 1000000000000, 4) AS update_latency_sec,
       pst.count_delete AS rows_deleted,
       round(pst.sum_timer_delete / 1000000000000, 4) AS delete_latency_sec,
       fsbi.count_read AS io_read_requests,
       round(fsbi.sum_number_of_bytes_read / 1073741824, 4) AS io_read_Gb,
       round(fsbi.sum_timer_read / 1000000000000, 4) AS io_read_latency_sec,
       fsbi.count_write AS io_write_requests,
       round(fsbi.sum_number_of_bytes_write / 1073741824, 4) AS io_write_Gb,
       round(fsbi.sum_timer_write / 1000000000000, 4) AS io_write_latency_sec,
       fsbi.count_misc AS io_misc_requests,
       round(fsbi.sum_timer_misc / 1000000000000, 4) AS io_misc_latency_sec
  FROM performance_schema.table_io_waits_summary_by_table AS pst
  LEFT JOIN x$ps_schema_table_statistics_io AS fsbi
    ON pst.object_schema = fsbi.table_schema
   AND pst.object_name = fsbi.table_name
 ORDER BY pst.sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: schema_table_statistics_with_buffer
--
-- Statistics around tables.
--
-- Ordered by the total wait time descending - top tables are most contended.
--
-- More statistics such as caching stats for the InnoDB buffer pool with InnoDB tables
--
-- mysql> select * from schema_table_statistics_with_buffer limit 1\G
-- *************************** 1. row ***************************
--                  table_schema: mem
--                    table_name: mysqlserver
--                  rows_fetched: 27087
--                 fetch_latency: 442.72 ms
--                 rows_inserted: 2
--                insert_latency: 185.04 us 
--                  rows_updated: 5096
--                update_latency: 1.39 s
--                  rows_deleted: 0
--                delete_latency: 0 ps
--              io_read_requests: 2565
--                 io_read_bytes: 1121627
--               io_read_latency: 10.07 ms
--             io_write_requests: 1691
--                io_write_bytes: 128383
--              io_write_latency: 14.17 ms
--              io_misc_requests: 2698
--               io_misc_latency: 433.66 ms
--           innodb_buffer_pages: 19
--    innodb_buffer_pages_hashed: 19
--       innodb_buffer_pages_old: 19
-- innodb_buffer_bytes_allocated: 311296
--      innodb_buffer_bytes_data: 1924
--     innodb_buffer_rows_cached: 2
--
 
CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_table_statistics_with_buffer AS
SELECT pst.object_schema AS table_schema,
       pst.object_name AS table_name,
       pst.count_fetch AS rows_fetched,
       round(pst.sum_timer_fetch / 1000000000000, 4) AS fetch_latency_sec,
       pst.count_insert AS rows_inserted,
       round(pst.sum_timer_insert / 1000000000000, 4) AS insert_latency_sec,
       pst.count_update AS rows_updated,
       round(pst.sum_timer_update / 1000000000000, 4) AS update_latency_sec,
       pst.count_delete AS rows_deleted,
       round(pst.sum_timer_delete / 1000000000000, 4) AS delete_latency_sec,
       fsbi.count_read AS io_read_requests,
       round(fsbi.sum_number_of_bytes_read / 1073741824, 4) AS io_read_Gb,
       round(fsbi.sum_timer_read / 1000000000000, 4) AS io_read_latency_sec,
       fsbi.count_write AS io_write_requests,
       round(fsbi.sum_number_of_bytes_write / 1073741824, 4) AS io_write_Gb,
       round(fsbi.sum_timer_write / 1000000000000, 4) AS io_write_latency_sec,
       fsbi.count_misc AS io_misc_requests,
       round(fsbi.sum_timer_misc / 1000000000000, 4) AS io_misc_latency_sec,
       round(ibp.allocated_Gb / 1073741824, 4) AS innodb_buffer_allocated_Gb,
       round(ibp.data_Gb / 1073741824, 4) AS innodb_buffer_data_Gb,
       round((ibp.allocated_Gb - ibp.data_Gb) / 1073741824, 4) AS innodb_buffer_free_Gb,
       ibp.pages AS innodb_buffer_pages,
       ibp.pages_hashed AS innodb_buffer_pages_hashed,
       ibp.pages_old AS innodb_buffer_pages_old,
       ibp.rows_cached AS innodb_buffer_rows_cached
  FROM performance_schema.table_io_waits_summary_by_table AS pst
  LEFT JOIN x$ps_schema_table_statistics_io AS fsbi
    ON pst.object_schema = fsbi.table_schema
   AND pst.object_name = fsbi.table_name
  LEFT JOIN sys.innodb_buffer_stats_by_table AS ibp
    ON pst.object_schema = ibp.object_schema
   AND pst.object_name = ibp.object_name
 ORDER BY pst.sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: schema_tables_with_full_table_scans
--
-- Find tables that are being accessed by full table scans
-- ordering by the number of rows scanned descending.
--
-- mysql> select * from schema_tables_with_full_table_scans limit 5;
-- +--------------------+--------------------------------+-------------------+-----------+
-- | object_schema      | object_name                    | rows_full_scanned | latency   |
-- +--------------------+--------------------------------+-------------------+-----------+
-- | mem30__instruments | fsstatistics                   |          10207042 | 13.10 s   |
-- | mem30__instruments | preparedstatementapidata       |            436428 | 973.27 ms |
-- | mem30__instruments | mysqlprocessactivity           |            411702 | 282.07 ms |
-- | mem30__instruments | querycachequeriesincachedata   |            374011 | 767.15 ms |
-- | mem30__instruments | rowaccessesdata                |            322321 | 1.55 s    |
-- +--------------------+--------------------------------+-------------------+-----------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_tables_with_full_table_scans AS
SELECT object_schema, 
       object_name,
       count_read AS rows_full_scanned,
       round(sum_timer_wait / 1000000000000, 4) AS latency_sec
  FROM performance_schema.table_io_waits_summary_by_index_usage 
 WHERE index_name IS NULL
   AND count_read > 0
 ORDER BY count_read DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: schema_unused_indexes
-- 
-- Finds indexes that have had no events against them (and hence, no usage).
--
-- To trust whether the data from this view is representative of your workload,
-- you should ensure that the server has been up for a representative amount of
-- time before using it.
--
-- PRIMARY (key) indexes are ignored.
--
-- mysql> select * from schema_unused_indexes limit 5;
-- +--------------------+---------------------+--------------------+
-- | object_schema      | object_name         | index_name         |
-- +--------------------+---------------------+--------------------+
-- | mem30__bean_config | plists              | path               |
-- | mem30__config      | group_selections    | name               |
-- | mem30__config      | notification_groups | name               |
-- | mem30__config      | user_form_defaults  | FKC1AEF1F9E7EE2CFB |
-- | mem30__enterprise  | whats_new_entries   | entryId            |
-- +--------------------+---------------------+--------------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_unused_indexes (
  object_schema,
  object_name,
  index_name
) AS
SELECT object_schema,
       object_name,
       index_name
  FROM performance_schema.table_io_waits_summary_by_index_usage 
 WHERE index_name IS NOT NULL
   AND count_star = 0
   AND object_schema != 'mysql'
   AND index_name != 'PRIMARY'
 ORDER BY object_schema, object_name;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: statement_analysis
--
-- Lists a normalized statement view with aggregated statistics,
-- mimics the MySQL Enterprise Monitor Query Analysis view,
-- ordered by the total execution time per normalized statement
-- 
-- mysql> select- * from statement_analysis limit 1\G
-- *************************** 1. row--**************************
--             query: SELECT * FROM `schema_object_o ... MA` , `information_schema` ...
--                db: sys
--         full_scan: *
--        exec_count: 2
--         err_count: 0
--        warn_count: 0
--     total_latency: 16.75 s
--       max_latency: 16.57 s
--       avg_latency: 8.38 s
--      lock_latency: 16.69 s
--         rows_sent: 84
--     rows_sent_avg: 42
--     rows_examined: 20012
--     rows_affected: 0
-- rows_affected_avg: 0
-- rows_examined_avg: 10006
--        tmp_tables: 378
--   tmp_disk_tables: 66
--       rows_sorted: 168
-- sort_merge_passes: 0
--            digest: 54f9bd520f0bbf15db0c2ed93386bec9
--        first_seen: 2014-03-07 13:13:41
--         last_seen: 2014-03-07 13:13:48
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW statement_analysis AS
SELECT DIGEST_TEXT AS query,
       SCHEMA_NAME AS db,
       IF(SUM_NO_GOOD_INDEX_USED > 0 OR SUM_NO_INDEX_USED > 0, '*', '') AS full_scan,
       COUNT_STAR AS exec_count,
       SUM_ERRORS AS err_count,
       SUM_WARNINGS AS warn_count,
       round(SUM_TIMER_WAIT / 1000000000000, 4) AS total_latency_sec,
       round(MAX_TIMER_WAIT / 1000000000000, 4) AS max_latency_sec,
       round(AVG_TIMER_WAIT / 1000000000000, 4) AS avg_latency_sec,
       round(SUM_LOCK_TIME / 1000000000000, 4) AS lock_latency_sec,
       SUM_ROWS_SENT AS rows_sent,
       ROUND(IFNULL(SUM_ROWS_SENT / NULLIF(COUNT_STAR, 0), 0)) AS rows_sent_avg,
       SUM_ROWS_EXAMINED AS rows_examined,
       ROUND(IFNULL(SUM_ROWS_EXAMINED / NULLIF(COUNT_STAR, 0), 0))  AS rows_examined_avg,
       SUM_ROWS_AFFECTED AS rows_affected,
       ROUND(IFNULL(SUM_ROWS_AFFECTED / NULLIF(COUNT_STAR, 0), 0))  AS rows_affected_avg,
       SUM_CREATED_TMP_TABLES AS tmp_tables,
       SUM_CREATED_TMP_DISK_TABLES AS tmp_disk_tables,
       SUM_SORT_ROWS AS rows_sorted,
       SUM_SORT_MERGE_PASSES AS sort_merge_passes,
       DIGEST AS digest,
       FIRST_SEEN AS first_seen,
       LAST_SEEN as last_seen
  FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: statement_analysis
--
-- Lists a normalized statement view with aggregated statistics,
-- mimics the MySQL Enterprise Monitor Query Analysis view,
-- ordered by the total execution time per normalized statement
-- 
-- mysql> select- * from statement_analysis limit 1\G
-- *************************** 1. row--**************************
--             query: SELECT * FROM `schema_object_o ... MA` , `information_schema` ...
--                db: sys
--         full_scan: *
--        exec_count: 2
--         err_count: 0
--        warn_count: 0
--     total_latency: 16.75 s
--       max_latency: 16.57 s
--       avg_latency: 8.38 s
--      lock_latency: 16.69 s
--         rows_sent: 84
--     rows_sent_avg: 42
--     rows_examined: 20012
--     rows_affected: 0
-- rows_affected_avg: 0
-- rows_examined_avg: 10006
--        tmp_tables: 378
--   tmp_disk_tables: 66
--       rows_sorted: 168
-- sort_merge_passes: 0
--            digest: 54f9bd520f0bbf15db0c2ed93386bec9
--        first_seen: 2014-03-07 13:13:41
--         last_seen: 2014-03-07 13:13:48
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW statement_analysis_basic AS
SELECT LEFT(REPLACE(DIGEST_TEXT, '\n', ' '), 100) AS query,
       COUNT_STAR AS exec_count,
       round(SUM_TIMER_WAIT / 1000000000000, 0) AS total_sec,
       round(SUM_LOCK_TIME / 1000000000000, 0) AS lock_sec,
       SUM_ROWS_SENT AS rows_sent,
       SUM_ROWS_EXAMINED AS rows_examined,
       SUM_ROWS_AFFECTED AS rows_affected
  FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: statements_with_errors_or_warnings
--
-- Lists all normalized statements that have raised errors or warnings.
--
-- mysql> select * from statements_with_errors_or_warnings LIMIT 1\G
-- *************************** 1. row ***************************
--       query: CREATE OR REPLACE ALGORITHM =  ... _delete` AS `rows_deleted` ...
--          db: sys
--  exec_count: 2
--      errors: 1
--   error_pct: 50.0000
--    warnings: 0
-- warning_pct: 0.0000
--  first_seen: 2014-03-07 12:56:54
--   last_seen: 2014-03-07 13:01:01
--      digest: 943a788859e623d5f7798ba0ae0fd8a9
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW statements_with_errors_or_warnings AS
SELECT DIGEST_TEXT AS query,
       SCHEMA_NAME as db,
       COUNT_STAR AS exec_count,
       SUM_ERRORS AS errors,
       IFNULL(SUM_ERRORS / NULLIF(COUNT_STAR, 0), 0) * 100 as error_pct,
       SUM_WARNINGS AS warnings,
       IFNULL(SUM_WARNINGS / NULLIF(COUNT_STAR, 0), 0) * 100 as warning_pct,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_ERRORS > 0
    OR SUM_WARNINGS > 0
ORDER BY SUM_ERRORS DESC, SUM_WARNINGS DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: statements_with_full_table_scans
--
-- Lists all normalized statements that use have done a full table scan
-- ordered by number the percentage of times a full scan was done,
-- then by the statement latency.
--
-- This view ignores SHOW statements, as these always cause a full table scan,
-- and there is nothing that can be done about this.
--
-- mysql> select * from statements_with_full_table_scans limit 1\G
-- *************************** 1. row ***************************
--                    query: SELECT * FROM `schema_tables_w ... ex_usage` . `COUNT_READ` DESC
--                       db: sys
--               exec_count: 1
--            total_latency: 88.20 ms
--      no_index_used_count: 1
-- no_good_index_used_count: 0
--        no_index_used_pct: 100
--                rows_sent: 0
--            rows_examined: 1501
--            rows_sent_avg: 0
--        rows_examined_avg: 1501
--               first_seen: 2014-03-07 13:58:20
--                last_seen: 2014-03-07 13:58:20
--                   digest: 64baecd5c1e1e1651a6b92e55442a288
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW statements_with_full_table_scans AS
SELECT DIGEST_TEXT AS query,
       SCHEMA_NAME as db,
       COUNT_STAR AS exec_count,
       round(SUM_TIMER_WAIT / 1000000000000, 4) AS total_latency_sec,
       SUM_NO_INDEX_USED AS no_index_used_count,
       SUM_NO_GOOD_INDEX_USED AS no_good_index_used_count,
       ROUND(IFNULL(SUM_NO_INDEX_USED / NULLIF(COUNT_STAR, 0), 0) * 100) AS no_index_used_pct,
       SUM_ROWS_SENT AS rows_sent,
       SUM_ROWS_EXAMINED AS rows_examined,
       ROUND(SUM_ROWS_SENT/COUNT_STAR) AS rows_sent_avg,
       ROUND(SUM_ROWS_EXAMINED/COUNT_STAR) AS rows_examined_avg,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE (SUM_NO_INDEX_USED > 0
    OR SUM_NO_GOOD_INDEX_USED > 0)
   AND DIGEST_TEXT NOT LIKE 'SHOW%'
 ORDER BY no_index_used_pct DESC, total_latency_sec DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: statements_with_runtimes_in_95th_percentile
--
-- List all statements whose average runtime, in microseconds, is in the top 95th percentile.
-- 
-- mysql> select * from statements_with_runtimes_in_95th_percentile limit 5;
-- +-------------------------------------------------------------------+------+-----------+------------+-----------+------------+---------------+-------------+-------------+-----------+---------------+---------------+-------------------+---------------------+---------------------+----------------------------------+
-- | query                                                             | db   | full_scan | exec_count | err_count | warn_count | total_latency | max_latency | avg_latency | rows_sent | rows_sent_avg | rows_examined | rows_examined_avg | FIRST_SEEN          | LAST_SEEN           | digest                           |
-- +-------------------------------------------------------------------+------+-----------+------------+-----------+------------+---------------+-------------+-------------+-----------+---------------+---------------+-------------------+---------------------+---------------------+----------------------------------+
-- | SELECT `e` . `round_robin_bin` ...  `timestamp` = `maxes` . `ts`  | mem  | *         |         14 |         0 |          0 | 43.96 s       | 6.69 s      | 3.14 s      |        11 |             1 |        253170 |             18084 | 2013-12-04 20:05:01 | 2013-12-04 20:06:34 | 29ba002bf039bb6439357a10134407de |
-- | SELECT `e` . `round_robin_bin` ...  `timestamp` = `maxes` . `ts`  | mem  | *         |          8 |         0 |          0 | 17.89 s       | 4.12 s      | 2.24 s      |         7 |             1 |        169534 |             21192 | 2013-12-04 20:04:54 | 2013-12-04 20:05:05 | 0b1c1f91e7e9e0ff91aa49d15f540793 |
-- | SELECT `e` . `round_robin_bin` ...  `timestamp` = `maxes` . `ts`  | mem  | *         |          1 |         0 |          0 | 2.22 s        | 2.22 s      | 2.22 s      |         1 |             1 |         40322 |             40322 | 2013-12-04 20:05:39 | 2013-12-04 20:05:39 | 07b27145c8f8a3779737df5032374833 |
-- | SELECT `e` . `round_robin_bin` ...  `timestamp` = `maxes` . `ts`  | mem  | *         |          1 |         0 |          0 | 1.97 s        | 1.97 s      | 1.97 s      |         1 |             1 |         40322 |             40322 | 2013-12-04 20:05:39 | 2013-12-04 20:05:39 | a07488137ea5c1bccf3e291c50bfd21f |
-- | SELECT `e` . `round_robin_bin` ...  `timestamp` = `maxes` . `ts`  | mem  | *         |          2 |         0 |          0 | 3.91 s        | 3.91 s      | 1.96 s      |         1 |             1 |         13126 |              6563 | 2013-12-04 20:05:04 | 2013-12-04 20:06:34 | b8bddc6566366dafc7e474f67096a93b |
-- +-------------------------------------------------------------------+------+-----------+------------+-----------+------------+---------------+-------------+-------------+-----------+---------------+---------------+-------------------+---------------------+---------------------+----------------------------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW statements_with_runtimes_in_95th_percentile AS
SELECT DIGEST_TEXT AS query,
       SCHEMA_NAME as db,
       IF(SUM_NO_GOOD_INDEX_USED > 0 OR SUM_NO_INDEX_USED > 0, '*', '') AS full_scan,
       COUNT_STAR AS exec_count,
       SUM_ERRORS AS err_count,
       SUM_WARNINGS AS warn_count,
       round(SUM_TIMER_WAIT / 1000000000000, 4) AS total_latency_sec,
       round(MAX_TIMER_WAIT / 1000000000000, 4) AS max_latency_sec,
       round(AVG_TIMER_WAIT / 1000000000000, 4) AS avg_latency_sec,
       SUM_ROWS_SENT AS rows_sent,
       ROUND(IFNULL(SUM_ROWS_SENT / NULLIF(COUNT_STAR, 0), 0)) AS rows_sent_avg,
       SUM_ROWS_EXAMINED AS rows_examined,
       ROUND(IFNULL(SUM_ROWS_EXAMINED / NULLIF(COUNT_STAR, 0), 0)) AS rows_examined_avg,
       FIRST_SEEN AS first_seen,
       LAST_SEEN AS last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest stmts
  JOIN sys.x$ps_digest_95th_percentile_by_avg_us AS top_percentile
    ON ROUND(stmts.avg_timer_wait/1000000) >= top_percentile.avg_us
 ORDER BY AVG_TIMER_WAIT DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: statements_with_sorting
--
-- Lists all normalized statements that have done sorts,
-- ordered by total_latency descending.
--
-- mysql> select * from statements_with_sorting limit 1\G
-- *************************** 1. row ***************************
--             query: SELECT * FROM `schema_object_o ... MA` , `information_schema` ...
--                db: sys
--        exec_count: 2
--     total_latency: 16.75 s
-- sort_merge_passes: 0
--   avg_sort_merges: 0
-- sorts_using_scans: 12
--  sort_using_range: 0
--       rows_sorted: 168
--   avg_rows_sorted: 84
--        first_seen: 2014-03-07 13:13:41
--         last_seen: 2014-03-07 13:13:48
--            digest: 54f9bd520f0bbf15db0c2ed93386bec9
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW statements_with_sorting AS
SELECT DIGEST_TEXT AS query,
       SCHEMA_NAME db,
       COUNT_STAR AS exec_count,
       round(SUM_TIMER_WAIT / 1000000000000, 4) AS total_latency_sec,
       SUM_SORT_MERGE_PASSES AS sort_merge_passes,
       ROUND(IFNULL(SUM_SORT_MERGE_PASSES / NULLIF(COUNT_STAR, 0), 0)) AS avg_sort_merges,
       SUM_SORT_SCAN AS sorts_using_scans,
       SUM_SORT_RANGE AS sort_using_range,
       SUM_SORT_ROWS AS rows_sorted,
       ROUND(IFNULL(SUM_SORT_ROWS / NULLIF(COUNT_STAR, 0), 0)) AS avg_rows_sorted,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_SORT_ROWS > 0
 ORDER BY SUM_TIMER_WAIT DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: statements_with_temp_tables
--
-- Lists all normalized statements that use temporary tables
-- ordered by number of on disk temporary tables descending first, 
-- then by the number of memory tables.
--
-- mysql> select * from statements_with_temp_tables limit 1\G
-- *************************** 1. row ***************************
--                    query: SELECT * FROM `schema_object_o ... MA` , `information_schema` ...
--                       db: sys
--               exec_count: 2
--            total_latency: 16.75 s
--        memory_tmp_tables: 378
--          disk_tmp_tables: 66
-- avg_tmp_tables_per_query: 189
--   tmp_tables_to_disk_pct: 17
--               first_seen: 2014-03-07 13:13:41
--                last_seen: 2014-03-07 13:13:48
--                   digest: 54f9bd520f0bbf15db0c2ed93386bec9
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW statements_with_temp_tables AS
SELECT DIGEST_TEXT AS query,
       SCHEMA_NAME as db,
       COUNT_STAR AS exec_count,
       round(SUM_TIMER_WAIT / 1000000000000, 4) as total_latency_sec,
       SUM_CREATED_TMP_TABLES AS memory_tmp_tables,
       SUM_CREATED_TMP_DISK_TABLES AS disk_tmp_tables,
       ROUND(IFNULL(SUM_CREATED_TMP_TABLES / NULLIF(COUNT_STAR, 0), 0)) AS avg_tmp_tables_per_query,
       ROUND(IFNULL(SUM_CREATED_TMP_DISK_TABLES / NULLIF(SUM_CREATED_TMP_TABLES, 0), 0) * 100) AS tmp_tables_to_disk_pct,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_CREATED_TMP_TABLES > 0
ORDER BY SUM_CREATED_TMP_DISK_TABLES DESC, SUM_CREATED_TMP_TABLES DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: user_summary_by_file_io_type
--
-- Summarizes file IO by event type per user.
--
-- When the user found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from user_summary_by_file_io_type;
-- +------------+--------------------------------------+-------+-----------+-------------+
-- | user       | event_name                           | total | latency   | max_latency |
-- +------------+--------------------------------------+-------+-----------+-------------+
-- | background | wait/io/file/sql/FRM                 |   871 | 168.15 ms | 18.48 ms    |
-- | background | wait/io/file/innodb/innodb_data_file |   173 | 129.56 ms | 34.09 ms    |
-- | background | wait/io/file/innodb/innodb_log_file  |    20 | 77.53 ms  | 60.66 ms    |
-- | background | wait/io/file/myisam/dfile            |    40 | 6.54 ms   | 4.58 ms     |
-- | background | wait/io/file/mysys/charset           |     3 | 4.79 ms   | 4.71 ms     |
-- | background | wait/io/file/myisam/kfile            |    67 | 4.38 ms   | 300.04 us   |
-- | background | wait/io/file/sql/ERRMSG              |     5 | 2.72 ms   | 1.69 ms     |
-- | background | wait/io/file/sql/pid                 |     3 | 266.30 us | 185.47 us   |
-- | background | wait/io/file/sql/casetest            |     5 | 246.81 us | 150.19 us   |
-- | background | wait/io/file/sql/global_ddl_log      |     2 | 21.24 us  | 18.59 us    |
-- | root       | wait/io/file/sql/file_parser         |  1422 | 4.80 s    | 135.14 ms   |
-- | root       | wait/io/file/sql/FRM                 |   865 | 85.82 ms  | 9.81 ms     |
-- | root       | wait/io/file/myisam/kfile            |  1073 | 37.14 ms  | 15.79 ms    |
-- | root       | wait/io/file/myisam/dfile            |  2991 | 25.53 ms  | 5.25 ms     |
-- | root       | wait/io/file/sql/dbopt               |    20 | 1.07 ms   | 153.07 us   |
-- | root       | wait/io/file/sql/misc                |     4 | 59.71 us  | 33.75 us    |
-- | root       | wait/io/file/archive/data            |     1 | 13.91 us  | 13.91 us    |
-- +------------+--------------------------------------+-------+-----------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW user_summary_by_file_io_type AS
SELECT IF(user IS NULL, 'background', user) AS user,
       event_name,
       count_star AS total,
       round(sum_timer_wait / 1000000000000, 4) AS latency_sec,
       round(max_timer_wait / 1000000000000, 4) AS max_latency_sec
  FROM performance_schema.events_waits_summary_by_user_by_event_name
 WHERE event_name LIKE 'wait/io/file%'
   AND count_star > 0
 ORDER BY user, sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: user_summary_by_file_io
--
-- Summarizes file IO totals per user.
--
-- When the user found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from user_summary_by_file_io;
-- +------------+-------+------------+
-- | user       | ios   | io_latency |
-- +------------+-------+------------+
-- | root       | 26457 | 21.58 s    |
-- | background |  1189 | 394.21 ms  |
-- +------------+-------+------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW user_summary_by_file_io AS
SELECT IF(user IS NULL, 'background', user) AS user,
       SUM(count_star) AS ios,
       round(SUM(sum_timer_wait) / 1000000000000, 4) AS io_latency_sec 
  FROM performance_schema.events_waits_summary_by_user_by_event_name
 WHERE event_name LIKE 'wait/io/file/%'
 GROUP BY IF(user IS NULL, 'background', user)
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: user_summary_by_statement_type
--
-- Summarizes the types of statements executed by each user.
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from user_summary_by_statement_type;
-- +------+----------------------+--------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | user | statement            | total  | total_latency | max_latency | lock_latency | rows_sent | rows_examined | rows_affected | full_scans |
-- +------+----------------------+--------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | root | create_view          |   2063 | 00:05:04.20   | 463.58 ms   | 1.42 s       |         0 |             0 |             0 |          0 |
-- | root | select               |    174 | 40.87 s       | 28.83 s     | 858.13 ms    |      5212 |        157022 |             0 |         82 |
-- | root | stmt                 |   6645 | 15.31 s       | 491.78 ms   | 0 ps         |         0 |             0 |          7951 |          0 |
-- | root | call_procedure       |     17 | 4.78 s        | 1.02 s      | 37.94 ms     |         0 |             0 |            19 |          0 |
-- | root | create_table         |     19 | 3.04 s        | 431.71 ms   | 0 ps         |         0 |             0 |             0 |          0 |
-- ...
-- +------+----------------------+--------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW user_summary_by_statement_type AS
SELECT IF(user IS NULL, 'background', user) AS user,
       SUBSTRING_INDEX(event_name, '/', -1) AS statement,
       count_star AS total,
       round(sum_timer_wait / 1000000000000, 4) AS total_latency_sec,
       round(max_timer_wait / 1000000000000, 4) AS max_latency_sec,
       round(sum_lock_time / 1000000000000, 4) AS lock_latency_sec,
       sum_rows_sent AS rows_sent,
       sum_rows_examined AS rows_examined,
       sum_rows_affected AS rows_affected,
       sum_no_index_used + sum_no_good_index_used AS full_scans
  FROM performance_schema.events_statements_summary_by_user_by_event_name
 WHERE sum_timer_wait != 0
 ORDER BY user, sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: user_summary_by_statement_latency
--
-- Summarizes overall statement statistics by user.
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from user_summary_by_statement_latency;
-- +------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | user | total | total_latency | max_latency | lock_latency | rows_sent | rows_examined | rows_affected | full_scans |
-- +------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | root |  3381 | 00:02:09.13   | 1.48 s      | 1.07 s       |      1151 |         93947 |           150 |         91 |
-- +------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW user_summary_by_statement_latency AS
SELECT IF(user IS NULL, 'background', user) AS user,
       SUM(count_star) AS total,
       round(SUM(sum_timer_wait) / 1000000000000, 4) AS total_latency_sec,
       round(SUM(max_timer_wait) / 1000000000000, 4) AS max_latency_sec,
       round(SUM(sum_lock_time) / 1000000000000, 4) AS lock_latency_sec,
       SUM(sum_rows_sent) AS rows_sent,
       SUM(sum_rows_examined) AS rows_examined,
       SUM(sum_rows_affected) AS rows_affected,
       SUM(sum_no_index_used) + SUM(sum_no_good_index_used) AS full_scans
  FROM performance_schema.events_statements_summary_by_user_by_event_name
 GROUP BY IF(user IS NULL, 'background', user)
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: user_summary_by_stages
--
-- Summarizes stages by user, ordered by user and total latency per stage.
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.  
-- 
-- mysql> select * from user_summary_by_stages;
-- +------+--------------------------------+-------+---------------+-------------+
-- | user | event_name                     | total | total_latency | avg_latency |
-- +------+--------------------------------+-------+---------------+-------------+
-- | root | stage/sql/Opening tables       |   889 | 1.97 ms       | 2.22 us     |
-- | root | stage/sql/Creating sort index  |     4 | 1.79 ms       | 446.30 us   |
-- | root | stage/sql/init                 |    10 | 312.27 us     | 31.23 us    |
-- | root | stage/sql/checking permissions |    10 | 300.62 us     | 30.06 us    |
-- | root | stage/sql/freeing items        |     5 | 85.89 us      | 17.18 us    |
-- | root | stage/sql/statistics           |     5 | 79.15 us      | 15.83 us    |
-- | root | stage/sql/preparing            |     5 | 69.12 us      | 13.82 us    |
-- | root | stage/sql/optimizing           |     5 | 53.11 us      | 10.62 us    |
-- | root | stage/sql/Sending data         |     5 | 44.66 us      | 8.93 us     |
-- | root | stage/sql/closing tables       |     5 | 37.54 us      | 7.51 us     |
-- | root | stage/sql/System lock          |     5 | 34.28 us      | 6.86 us     |
-- | root | stage/sql/query end            |     5 | 24.37 us      | 4.87 us     |
-- | root | stage/sql/end                  |     5 | 8.60 us       | 1.72 us     |
-- | root | stage/sql/Sorting result       |     5 | 8.33 us       | 1.67 us     |
-- | root | stage/sql/executing            |     5 | 5.37 us       | 1.07 us     |
-- | root | stage/sql/cleaning up          |     5 | 4.60 us       | 919.00 ns   |
-- +------+--------------------------------+-------+---------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW user_summary_by_stages AS
SELECT IF(user IS NULL, 'background', user) AS user,
       event_name,
       count_star AS total,
       round(sum_timer_wait / 1000000000000, 4) AS total_latency_sec, 
       round(avg_timer_wait / 1000000000000, 4) AS avg_latency_sec 
  FROM performance_schema.events_stages_summary_by_user_by_event_name
 WHERE sum_timer_wait != 0 
 ORDER BY user, sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: user_summary
--
-- Summarizes statement activity, file IO and connections by user.
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.  
--
-- mysql> select * from user_summary;
-- +------+------------+-------------------+-----------------------+-------------+----------+-----------------+---------------------+-------------------+--------------+
-- | user | statements | statement_latency | statement_avg_latency | table_scans | file_ios | file_io_latency | current_connections | total_connections | unique_hosts |
-- +------+------------+-------------------+-----------------------+-------------+----------+-----------------+---------------------+-------------------+--------------+
-- | root |       2924 | 00:03:59.53       | 81.92 ms              |          82 |    54702 | 55.61 s         |                   1 |                 1 |            1 |
-- +------+------------+-------------------+-----------------------+-------------+----------+-----------------+---------------------+-------------------+--------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW user_summary AS
SELECT IF(accounts.user IS NULL, 'background', accounts.user) AS user,
       SUM(stmt.total) AS statements,
       round(SUM(stmt.total_latency_sec), 4) AS statement_latency_sec,
       round((IFNULL(SUM(stmt.total_latency_sec) / NULLIF(SUM(stmt.total), 0), 0)), 4) AS statement_avg_latency_sec,
       SUM(stmt.full_scans) AS table_scans,
       SUM(io.ios) AS file_ios,
       round(SUM(io.io_latency_sec), 4) AS file_io_latency_sec,
       SUM(accounts.current_connections) AS current_connections,
       SUM(accounts.total_connections) AS total_connections,
       COUNT(DISTINCT host) AS unique_hosts
  FROM performance_schema.accounts
  LEFT JOIN sys.user_summary_by_statement_latency AS stmt ON IF(accounts.user IS NULL, 'background', accounts.user) = stmt.user
  LEFT JOIN sys.user_summary_by_file_io AS io ON IF(accounts.user IS NULL, 'background', accounts.user) = io.user
 GROUP BY IF(accounts.user IS NULL, 'background', accounts.user);
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: host_summary_by_file_io_type
--
-- Summarizes file IO by event type per host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from host_summary_by_file_io_type;
-- +------------+--------------------------------------+-------+---------------+-------------+
-- | host       | event_name                           | total | total_latency | max_latency |
-- +------------+--------------------------------------+-------+---------------+-------------+
-- | hal1       | wait/io/file/sql/FRM                 |   871 | 168.15 ms     | 18.48 ms    |
-- | hal1       | wait/io/file/innodb/innodb_data_file |   173 | 129.56 ms     | 34.09 ms    |
-- | hal1       | wait/io/file/innodb/innodb_log_file  |    20 | 77.53 ms      | 60.66 ms    |
-- | hal1       | wait/io/file/myisam/dfile            |    40 | 6.54 ms       | 4.58 ms     |
-- | hal1       | wait/io/file/mysys/charset           |     3 | 4.79 ms       | 4.71 ms     |
-- | hal1       | wait/io/file/myisam/kfile            |    67 | 4.38 ms       | 300.04 us   |
-- | hal1       | wait/io/file/sql/ERRMSG              |     5 | 2.72 ms       | 1.69 ms     |
-- | hal1       | wait/io/file/sql/pid                 |     3 | 266.30 us     | 185.47 us   |
-- | hal1       | wait/io/file/sql/casetest            |     5 | 246.81 us     | 150.19 us   |
-- | hal1       | wait/io/file/sql/global_ddl_log      |     2 | 21.24 us      | 18.59 us    |
-- | hal2       | wait/io/file/sql/file_parser         |  1422 | 4.80 s        | 135.14 ms   |
-- | hal2       | wait/io/file/sql/FRM                 |   865 | 85.82 ms      | 9.81 ms     |
-- | hal2       | wait/io/file/myisam/kfile            |  1073 | 37.14 ms      | 15.79 ms    |
-- | hal2       | wait/io/file/myisam/dfile            |  2991 | 25.53 ms      | 5.25 ms     |
-- | hal2       | wait/io/file/sql/dbopt               |    20 | 1.07 ms       | 153.07 us   |
-- | hal2       | wait/io/file/sql/misc                |     4 | 59.71 us      | 33.75 us    |
-- | hal2       | wait/io/file/archive/data            |     1 | 13.91 us      | 13.91 us    |
-- +------------+--------------------------------------+-------+---------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
 -- DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW host_summary_by_file_io_type  AS
SELECT IF(host IS NULL, 'background', host) AS host,
       event_name,
       count_star AS total,
       round(sum_timer_wait / 1000000000000, 4) AS total_latency_sec,
       round(max_timer_wait / 1000000000000, 4) AS max_latency_sec
  FROM performance_schema.events_waits_summary_by_host_by_event_name
 WHERE event_name LIKE 'wait/io/file%'
   AND count_star > 0
 ORDER BY IF(host IS NULL, 'background', host), sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: host_summary_by_file_io
--
-- Summarizes file IO totals per host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from host_summary_by_file_io;
-- +------------+-------+------------+
-- | host       | ios   | io_latency |
-- +------------+-------+------------+
-- | hal1       | 26457 | 21.58 s    |
-- | hal2       |  1189 | 394.21 ms  |
-- +------------+-------+------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW host_summary_by_file_io AS
SELECT IF(host IS NULL, 'background', host) AS host,
       SUM(count_star) AS ios,
       round(SUM(sum_timer_wait) / 1000000000000, 4) AS io_latency_sec 
  FROM performance_schema.events_waits_summary_by_host_by_event_name
 WHERE event_name LIKE 'wait/io/file/%'
 GROUP BY IF(host IS NULL, 'background', host)
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: host_summary_by_statement_type
--
-- Summarizes the types of statements executed by each host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from host_summary_by_statement_type;
-- +------+----------------------+--------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | host | statement            | total  | total_latency | max_latency | lock_latency | rows_sent | rows_examined | rows_affected | full_scans |
-- +------+----------------------+--------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | hal  | create_view          |   2063 | 00:05:04.20   | 463.58 ms   | 1.42 s       |         0 |             0 |             0 |          0 |
-- | hal  | select               |    174 | 40.87 s       | 28.83 s     | 858.13 ms    |      5212 |        157022 |             0 |         82 |
-- | hal  | stmt                 |   6645 | 15.31 s       | 491.78 ms   | 0 ps         |         0 |             0 |          7951 |          0 |
-- | hal  | call_procedure       |     17 | 4.78 s        | 1.02 s      | 37.94 ms     |         0 |             0 |            19 |          0 |
-- | hal  | create_table         |     19 | 3.04 s        | 431.71 ms   | 0 ps         |         0 |             0 |             0 |          0 |
-- ...
-- +------+----------------------+--------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW host_summary_by_statement_type AS
SELECT IF(host IS NULL, 'background', host) AS host,
       SUBSTRING_INDEX(event_name, '/', -1) AS statement,
       count_star AS total,
       round(sum_timer_wait / 1000000000000, 4) AS total_latency_sec,
       round(max_timer_wait / 1000000000000, 4) AS max_latency_sec,
       round(sum_lock_time / 1000000000000, 4) AS lock_latency_sec,
       sum_rows_sent AS rows_sent,
       sum_rows_examined AS rows_examined,
       sum_rows_affected AS rows_affected,
       sum_no_index_used + sum_no_good_index_used AS full_scans
  FROM performance_schema.events_statements_summary_by_host_by_event_name
 WHERE sum_timer_wait != 0
 ORDER BY IF(host IS NULL, 'background', host), sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: host_summary_by_statement_latency
--
-- Summarizes overall statement statistics by host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select-- from host_summary_by_statement_latency;
-- +------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | host | total | total_latency | max_latency | lock_latency | rows_sent | rows_examined | rows_affected | full_scans |
-- +------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | hal  |  3381 | 00:02:09.13   | 1.48 s      | 1.07 s       |      1151 |         93947 |           150 |         91 |
-- +------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW host_summary_by_statement_latency AS
SELECT IF(host IS NULL, 'background', host) AS host,
       SUM(count_star) AS total,
       round(SUM(sum_timer_wait) / 1000000000000, 4) AS total_latency_sec,
       round(MAX(max_timer_wait) / 1000000000000, 4) AS max_latency_sec,
       round(SUM(sum_lock_time) / 1000000000000, 4) AS lock_latency_sec,
       SUM(sum_rows_sent) AS rows_sent,
       SUM(sum_rows_examined) AS rows_examined,
       SUM(sum_rows_affected) AS rows_affected,
       SUM(sum_no_index_used) + SUM(sum_no_good_index_used) AS full_scans
  FROM performance_schema.events_statements_summary_by_host_by_event_name
 GROUP BY IF(host IS NULL, 'background', host)
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: host_summary_by_stages
--
-- Summarizes stages by host, ordered by host and total latency per stage.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from host_summary_by_stages;
-- +------+--------------------------------+-------+---------------+-------------+
-- | host | event_name                     | total | total_latency | avg_latency |
-- +------+--------------------------------+-------+---------------+-------------+
-- | hal  | stage/sql/Opening tables       |   889 | 1.97 ms       | 2.22 us     |
-- | hal  | stage/sql/Creating sort index  |     4 | 1.79 ms       | 446.30 us   |
-- | hal  | stage/sql/init                 |    10 | 312.27 us     | 31.23 us    |
-- | hal  | stage/sql/checking permissions |    10 | 300.62 us     | 30.06 us    |
-- | hal  | stage/sql/freeing items        |     5 | 85.89 us      | 17.18 us    |
-- | hal  | stage/sql/statistics           |     5 | 79.15 us      | 15.83 us    |
-- | hal  | stage/sql/preparing            |     5 | 69.12 us      | 13.82 us    |
-- | hal  | stage/sql/optimizing           |     5 | 53.11 us      | 10.62 us    |
-- | hal  | stage/sql/Sending data         |     5 | 44.66 us      | 8.93 us     |
-- | hal  | stage/sql/closing tables       |     5 | 37.54 us      | 7.51 us     |
-- | hal  | stage/sql/System lock          |     5 | 34.28 us      | 6.86 us     |
-- | hal  | stage/sql/query end            |     5 | 24.37 us      | 4.87 us     |
-- | hal  | stage/sql/end                  |     5 | 8.60 us       | 1.72 us     |
-- | hal  | stage/sql/Sorting result       |     5 | 8.33 us       | 1.67 us     |
-- | hal  | stage/sql/executing            |     5 | 5.37 us       | 1.07 us     |
-- | hal  | stage/sql/cleaning up          |     5 | 4.60 us       | 919.00 ns   |
-- +------+--------------------------------+-------+---------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW host_summary_by_stages AS
SELECT IF(host IS NULL, 'background', host) AS host,
       event_name,
       count_star AS total,
       round(sum_timer_wait / 1000000000000, 4) AS total_latency_sec, 
       round(avg_timer_wait / 1000000000000, 4) AS avg_latency_sec 
  FROM performance_schema.events_stages_summary_by_host_by_event_name
 WHERE sum_timer_wait != 0
 ORDER BY IF(host IS NULL, 'background', host), sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: host_summary
--
-- Summarizes statement activity, file IO and connections by host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from host_summary;
-- +------+------------+-------------------+-----------------------+-------------+----------+-----------------+---------------------+-------------------+--------------+
-- | host | statements | statement_latency | statement_avg_latency | table_scans | file_ios | file_io_latency | current_connections | total_connections | unique_users |
-- +------+------------+-------------------+-----------------------+-------------+----------+-----------------+---------------------+-------------------+--------------+
-- | hal1 |       2924 | 00:03:59.53       | 81.92 ms              |          82 |    54702 | 55.61 s         |                   1 |                 1 |            1 |
-- +------+------------+-------------------+-----------------------+-------------+----------+-----------------+---------------------+-------------------+--------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW host_summary AS
SELECT IF(accounts.host IS NULL, 'background', accounts.host) AS host,
       SUM(stmt.total) AS statements,
       round(SUM(stmt.total_latency), 4) AS statement_latency_sec,
       round(IFNULL(SUM(stmt.total_latency) / NULLIF(SUM(stmt.total), 0), 0), 4) AS statement_avg_latency_sec,
       SUM(stmt.full_scans) AS table_scans,
       SUM(io.ios) AS file_ios,
       round(SUM(io.io_latency), 4) AS file_io_latency_sec,
       SUM(accounts.current_connections) AS current_connections,
       SUM(accounts.total_connections) AS total_connections,
       COUNT(DISTINCT accounts.user) AS unique_users
  FROM performance_schema.accounts
  LEFT JOIN sys.host_summary_by_statement_latency AS stmt ON accounts.host = stmt.host
  LEFT JOIN sys.host_summary_by_file_io AS io ON accounts.host = io.host
 GROUP BY IF(accounts.host IS NULL, 'background', accounts.host);
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: wait_classes_global_by_avg_latency
-- 
-- Lists the top wait classes by average latency, ignoring idle (this may be very large).
--
-- mysql> select * from wait_classes_global_by_avg_latency where event_class != 'idle';
-- +-------------------+--------+---------------+-------------+-------------+-------------+
-- | event_class       | total  | total_latency | min_latency | avg_latency | max_latency |
-- +-------------------+--------+---------------+-------------+-------------+-------------+
-- | wait/io/file      | 543123 | 44.60 s       | 19.44 ns    | 82.11 us    | 4.21 s      |
-- | wait/io/table     |  22002 | 766.60 ms     | 148.72 ns   | 34.84 us    | 44.97 ms    |
-- | wait/io/socket    |  79613 | 967.17 ms     | 0 ps        | 12.15 us    | 27.10 ms    |
-- | wait/lock/table   |  35409 | 18.68 ms      | 65.45 ns    | 527.51 ns   | 969.88 us   |
-- | wait/synch/rwlock |  37935 | 4.61 ms       | 21.38 ns    | 121.61 ns   | 34.65 us    |
-- | wait/synch/mutex  | 390622 | 18.60 ms      | 19.44 ns    | 47.61 ns    | 10.32 us    |
-- +-------------------+--------+---------------+-------------+-------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW wait_classes_global_by_avg_latency AS
SELECT SUBSTRING_INDEX(event_name,'/', 3) AS event_class,
       SUM(COUNT_STAR) AS total,
       round(CAST(SUM(sum_timer_wait) AS UNSIGNED) / 1000000000000, 4) AS total_latency_sec,
       round(MIN(min_timer_wait) / 1000000000000, 4) AS min_latency_sec,
       round(IFNULL(SUM(sum_timer_wait) / NULLIF(SUM(COUNT_STAR), 0), 0) / 1000000000000, 4) AS avg_latency_sec,
       round(CAST(MAX(max_timer_wait) AS UNSIGNED) / 1000000000000, 4) AS max_latency_sec
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE sum_timer_wait > 0
   AND event_name != 'idle'
 GROUP BY event_class
 ORDER BY IFNULL(SUM(sum_timer_wait) / NULLIF(SUM(COUNT_STAR), 0), 0) DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: wait_classes_global_by_latency
-- 
-- Lists the top wait classes by total latency, ignoring idle (this may be very large).
--
-- mysql> select * from wait_classes_global_by_latency;
-- +-------------------+--------+---------------+-------------+-------------+-------------+
-- | event_class       | total  | total_latency | min_latency | avg_latency | max_latency |
-- +-------------------+--------+---------------+-------------+-------------+-------------+
-- | wait/io/file      | 550470 | 46.01 s       | 19.44 ns    | 83.58 us    | 4.21 s      |
-- | wait/io/socket    | 228833 | 2.71 s        | 0 ps        | 11.86 us    | 29.93 ms    |
-- | wait/io/table     |  64063 | 1.89 s        | 99.79 ns    | 29.43 us    | 68.07 ms    |
-- | wait/lock/table   |  76029 | 47.19 ms      | 65.45 ns    | 620.74 ns   | 969.88 us   |
-- | wait/synch/mutex  | 635925 | 34.93 ms      | 19.44 ns    | 54.93 ns    | 107.70 us   |
-- | wait/synch/rwlock |  61287 | 7.62 ms       | 21.38 ns    | 124.37 ns   | 34.65 us    |
-- +-------------------+--------+---------------+-------------+-------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW wait_classes_global_by_latency AS
SELECT SUBSTRING_INDEX(event_name,'/', 3) AS event_class, 
       SUM(COUNT_STAR) AS total,
       round(SUM(sum_timer_wait) / 1000000000000, 4) AS total_latency_sec,
       round(MIN(min_timer_wait) / 1000000000000, 4) min_latency_sec,
       round(IFNULL(SUM(sum_timer_wait) / NULLIF(SUM(COUNT_STAR), 0), 0) / 1000000000000, 4) AS avg_latency_sec,
       round(MAX(max_timer_wait) / 1000000000000, 4) AS max_latency_sec
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE sum_timer_wait > 0
   AND event_name != 'idle'
 GROUP BY SUBSTRING_INDEX(event_name,'/', 3) 
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: waits_by_user_by_latency
--
-- Lists the top wait events per user by their total latency, ignoring idle (this may be very large).
--
-- mysql> select * from waits_by_user_by_latency;
-- +------+-----------------------------------------------------+--------+---------------+-------------+-------------+
-- | user | event                                               | total  | total_latency | avg_latency | max_latency |
-- +------+-----------------------------------------------------+--------+---------------+-------------+-------------+
-- | root | wait/io/file/sql/file_parser                        |  13743 | 00:01:00.46   | 4.40 ms     | 231.88 ms   |
-- | root | wait/io/file/innodb/innodb_data_file                |   4699 | 3.02 s        | 643.38 us   | 46.93 ms    |
-- | root | wait/io/file/sql/FRM                                |  11462 | 2.60 s        | 226.83 us   | 61.72 ms    |
-- | root | wait/io/file/myisam/dfile                           |  26776 | 746.70 ms     | 27.89 us    | 308.79 ms   |
-- | root | wait/io/file/myisam/kfile                           |   7126 | 462.66 ms     | 64.93 us    | 88.76 ms    |
-- | root | wait/io/file/sql/dbopt                              |    179 | 137.58 ms     | 768.59 us   | 15.46 ms    |
-- | root | wait/io/file/csv/metadata                           |      8 | 86.60 ms      | 10.82 ms    | 50.32 ms    |
-- | root | wait/synch/mutex/mysys/IO_CACHE::append_buffer_lock | 798080 | 66.46 ms      | 82.94 ns    | 161.03 us   |
-- | root | wait/io/file/sql/binlog                             |     19 | 49.11 ms      | 2.58 ms     | 9.40 ms     |
-- | root | wait/io/file/sql/misc                               |     26 | 22.38 ms      | 860.80 us   | 15.30 ms    |
-- | root | wait/io/file/csv/data                               |      4 | 297.46 us     | 74.37 us    | 111.93 us   |
-- | root | wait/synch/rwlock/sql/MDL_lock::rwlock              |    944 | 287.86 us     | 304.62 ns   | 874.64 ns   |
-- | root | wait/io/file/archive/data                           |      4 | 82.71 us      | 20.68 us    | 40.74 us    |
-- | root | wait/synch/mutex/myisam/MYISAM_SHARE::intern_lock   |     60 | 12.21 us      | 203.20 ns   | 512.72 ns   |
-- | root | wait/synch/mutex/innodb/trx_mutex                   |     81 | 5.93 us       | 73.14 ns    | 252.59 ns   |
-- +------+-----------------------------------------------------+--------+---------------+-------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW waits_by_user_by_latency AS
SELECT IF(user IS NULL, 'background', user) AS user,
       event_name AS event,
       count_star AS total,
       round(sum_timer_wait / 1000000000000, 4) AS total_latency_sec,
       round(avg_timer_wait / 1000000000000, 4) AS avg_latency_sec,
       round(max_timer_wait / 1000000000000, 4) AS max_latency_sec
  FROM performance_schema.events_waits_summary_by_user_by_event_name
 WHERE event_name != 'idle'
   AND user IS NOT NULL
   AND sum_timer_wait > 0
 ORDER BY user, sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: waits_by_host_by_latency
--
-- Lists the top wait events per host by their total latency, ignoring idle (this may be very large).
--
-- mysql> select * from sys.waits_by_host_by_latency where host != 'background' limit 5;
-- +-----------+------------------------------+-------+---------------+-------------+-------------+
-- | host      | event                        | total | total_latency | avg_latency | max_latency |
-- +-----------+------------------------------+-------+---------------+-------------+-------------+
-- | localhost | wait/io/file/sql/file_parser |  1386 | 14.50 s       | 10.46 ms    | 357.36 ms   |
-- | localhost | wait/io/file/sql/FRM         |   162 | 356.08 ms     | 2.20 ms     | 75.33 ms    |
-- | localhost | wait/io/file/myisam/kfile    |   410 | 322.29 ms     | 786.08 us   | 65.98 ms    |
-- | localhost | wait/io/file/myisam/dfile    |  1327 | 307.44 ms     | 231.68 us   | 37.16 ms    |
-- | localhost | wait/io/file/sql/dbopt       |    89 | 180.34 ms     | 2.03 ms     | 63.41 ms    |
-- +-----------+------------------------------+-------+---------------+-------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW waits_by_host_by_latency AS
SELECT IF(host IS NULL, 'background', host) AS host,
       event_name AS event,
       count_star AS total,
       round(sum_timer_wait / 1000000000000, 4) AS total_latency_sec,
       round(avg_timer_wait / 1000000000000, 4) AS avg_latency_sec,
       round(max_timer_wait / 1000000000000, 4) AS max_latency_sec
  FROM performance_schema.events_waits_summary_by_host_by_event_name
 WHERE event_name != 'idle'
   AND sum_timer_wait > 0
 ORDER BY host, sum_timer_wait DESC;
-- Copyright (c) 2014, 2015, Oracle and/or its affiliates. All rights reserved.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: waits_global_by_latency
--
-- Lists the top wait events by their total latency, ignoring idle (this may be very large).
--
-- mysql> select * from waits_global_by_latency limit 5;
-- +--------------------------------------+------------+---------------+-------------+-------------+
-- | event                                | total      | total_latency | avg_latency | max_latency |
-- +--------------------------------------+------------+---------------+-------------+-------------+
-- | wait/io/file/myisam/dfile            | 3623719744 | 00:47:49.09   | 791.70 ns   | 312.96 ms   |
-- | wait/io/table/sql/handler            |   69114944 | 00:44:30.74   | 38.64 us    | 879.49 ms   |
-- | wait/io/file/innodb/innodb_log_file  |   28100261 | 00:37:42.12   | 80.50 us    | 476.00 ms   |
-- | wait/io/socket/sql/client_connection |  200704863 | 00:18:37.81   | 5.57 us     | 1.27 s      |
-- | wait/io/file/innodb/innodb_data_file |    2829403 | 00:08:12.89   | 174.20 us   | 455.22 ms   |
-- +--------------------------------------+------------+---------------+-------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW waits_global_by_latency AS
SELECT event_name AS event,
       count_star AS total,
       round(sum_timer_wait / 1000000000000, 4) AS total_latency_sec,
       round(avg_timer_wait / 1000000000000, 4) AS avg_latency_sec,
       round(max_timer_wait / 1000000000000, 4) AS max_latency_sec
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE event_name != 'idle'
   AND sum_timer_wait > 0
 ORDER BY sum_timer_wait DESC;
-- Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
--
--   This program is free software; you can redistribute it and/or modify
--   it under the terms of the GNU General Public License as published by
--   the Free Software Foundation; version 2 of the License.
--
--   This program is distributed in the hope that it will be useful,
--   but WITHOUT ANY WARRANTY; without even the implied warranty of
--   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--   GNU General Public License for more details.
--
--   You should have received a copy of the GNU General Public License
--   along with this program; if not, write to the Free Software
--   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA 


-- View: metrics
-- 
-- Creates a union of the following information:
--
--    *  information_schema.GLOBAL_STATUS
--    *  information_schema.INNODB_METRICS
--    *  Performance Schema global memory usage information
--    *  Current time
--
-- This is the same as the metrics view with the exception that the global status is taken from information_schema.GLOBAL_STATUS instead of
-- from the Peformance Schema. Use this view if one of the following conditions are fulfilled:
--
--    * The MySQL version is 5.6 or 5.7.0-5.7.5
--    * In 5.7.6 and later if show_compatibility_56 is ON. See also https://dev.mysql.com/doc/refman/5.7/en/server-system-variables.html#sysvar_show_compatibility_56
--
-- In MySQL 5.7.6 and later the view will generate one warning:
-- mysql> SHOW WARNINGS;
-- +---------+------+-----------------------------------------------------------------------------------------------------------------------------------------------+
-- | Level   | Code | Message                                                                                                                                       |
-- +---------+------+-----------------------------------------------------------------------------------------------------------------------------------------------+
-- | Warning | 1287 | 'INFORMATION_SCHEMA.GLOBAL_STATUS' is deprecated and will be removed in a future release. Please use performance_schema.global_status instead |
-- +---------+------+-----------------------------------------------------------------------------------------------------------------------------------------------+
-- 1 row in set (0.00 sec)
--
-- For view has the following columns:
-- 
--    * Variable_name: The name of the variable
--    * Variable_value: The value of the variable
--    * Type: The type of the variable. This will depend on the source, e.g. Global Status, InnoDB Metrics - ..., etc.
--    * Enabled: Whether the variable is enabled or not. Possible values are 'YES', 'NO', 'PARTIAL'.
--      PARTIAL is currently only supported for the memory usage variables and means some but not all of the memory/% instruments
--      are enabled.
--
-- mysql> SELECT * FROM metrics;
-- +-----------------------------------------------+-------------------------...+--------------------------------------+---------+
-- | Variable_name                                 | Variable_value          ...| Type                                 | Enabled |
-- +-----------------------------------------------+-------------------------...+--------------------------------------+---------+
-- | aborted_clients                               | 0                       ...| Global Status                        | YES     |
-- | aborted_connects                              | 0                       ...| Global Status                        | YES     |
-- | binlog_cache_disk_use                         | 0                       ...| Global Status                        | YES     |
-- | binlog_cache_use                              | 0                       ...| Global Status                        | YES     |
-- | binlog_stmt_cache_disk_use                    | 0                       ...| Global Status                        | YES     |
-- | binlog_stmt_cache_use                         | 0                       ...| Global Status                        | YES     |
-- | bytes_received                                | 217081                  ...| Global Status                        | YES     |
-- | bytes_sent                                    | 27257                   ...| Global Status                        | YES     |
-- ...
-- | innodb_rwlock_x_os_waits                      | 0                       ...| InnoDB Metrics - server              | YES     |
-- | innodb_rwlock_x_spin_rounds                   | 2723                    ...| InnoDB Metrics - server              | YES     |
-- | innodb_rwlock_x_spin_waits                    | 1                       ...| InnoDB Metrics - server              | YES     |
-- | trx_active_transactions                       | 0                       ...| InnoDB Metrics - transaction         | NO      |
-- ...
-- | trx_rseg_current_size                         | 0                       ...| InnoDB Metrics - transaction         | NO      |
-- | trx_rseg_history_len                          | 4                       ...| InnoDB Metrics - transaction         | YES     |
-- | trx_rw_commits                                | 0                       ...| InnoDB Metrics - transaction         | NO      |
-- | trx_undo_slots_cached                         | 0                       ...| InnoDB Metrics - transaction         | NO      |
-- | trx_undo_slots_used                           | 0                       ...| InnoDB Metrics - transaction         | NO      |
-- | NOW()                                         | 2015-05-31 13:27:50.382 ...| System Time                          | YES     |
-- | UNIX_TIMESTAMP()                              | 1433042870.382          ...| System Time                          | YES     |
-- +-----------------------------------------------+-------------------------...+--------------------------------------+---------+
-- 565 rows in set, 1 warning (0.02 sec)

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW metrics (
  Variable_name,
  Variable_value,
  Type,
  Enabled
) AS
(
SELECT LOWER(VARIABLE_NAME) AS Variable_name, VARIABLE_VALUE AS Variable_value, 'Global Status' AS Type, 'YES' AS Enabled
  FROM information_schema.GLOBAL_STATUS
) UNION ALL (
SELECT NAME AS Variable_name, COUNT AS Variable_value,
       CONCAT('InnoDB Metrics - ', SUBSYSTEM) AS Type,
       IF(STATUS = 'enabled', 'YES', 'NO') AS Enabled
  FROM information_schema.INNODB_METRICS
  -- Deduplication - some variables exists both in GLOBAL_STATUS and INNODB_METRICS
  -- Keep the one from GLOBAL_STATUS as it is always enabled and it's more likely to be used for existing tools.
 WHERE NAME NOT IN (
     'lock_row_lock_time', 'lock_row_lock_time_avg', 'lock_row_lock_time_max', 'lock_row_lock_waits',
     'buffer_pool_reads', 'buffer_pool_read_requests', 'buffer_pool_write_requests', 'buffer_pool_wait_free',
     'buffer_pool_read_ahead', 'buffer_pool_read_ahead_evicted', 'buffer_pool_pages_total', 'buffer_pool_pages_misc',
     'buffer_pool_pages_data', 'buffer_pool_bytes_data', 'buffer_pool_pages_dirty', 'buffer_pool_bytes_dirty',
     'buffer_pool_pages_free', 'buffer_pages_created', 'buffer_pages_written', 'buffer_pages_read',
     'buffer_data_reads', 'buffer_data_written', 'file_num_open_files',
     'os_log_bytes_written', 'os_log_fsyncs', 'os_log_pending_fsyncs', 'os_log_pending_writes',
     'log_waits', 'log_write_requests', 'log_writes', 'innodb_dblwr_writes', 'innodb_dblwr_pages_written', 'innodb_page_size')
) UNION ALL (
SELECT 'NOW()' AS Variable_name, NOW(3) AS Variable_value, 'System Time' AS Type, 'YES' AS Enabled
) UNION ALL (
SELECT 'UNIX_TIMESTAMP()' AS Variable_name, ROUND(UNIX_TIMESTAMP(NOW(3)), 3) AS Variable_value, 'System Time' AS Type, 'YES' AS Enabled
)
 ORDER BY Type, Variable_name;

CREATE OR REPLACE
  ALGORITHM = MERGE
--  DEFINER = 'root'@'localhost'
  SQL SECURITY INVOKER 
VIEW largest_tables AS
SELECT CONCAT(table_schema, '.', table_name) as schema_table,
       table_rows as 'rows',
       ROUND(data_length / ( 1024 * 1024 * 1024 ), 2) as data_Gb,
       ROUND(index_length / ( 1024 * 1024 * 1024 ), 2) as index_Gb,
       ROUND((data_length + index_length ) / ( 1024 * 1024 * 1024 ), 2) as total_size_Gb,
       ROUND(data_free / ( 1024 * 1024 * 1024 ), 2) as data_frag,
       ROUND(index_length / data_length, 2) as index_frac
FROM   information_schema.TABLES
ORDER  BY data_length + index_length DESC;
