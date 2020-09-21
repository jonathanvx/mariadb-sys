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
       pps.processlist_info AS current_statement,
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
 WHERE pps.processlist_command NOT IN ('Sleep', 'Binlog Dump')
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
       round(SUM(sum_timer_wait) / 1000000000000, 0) total_latency_sec,
       round(MIN(min_timer_wait) / 1000000000000, 0) min_latency_sec,
       round(AVG(avg_timer_wait) / 1000000000000, 0) avg_latency_sec,
       round(MAX(max_timer_wait) / 1000000000000, 0) max_latency_sec,
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
VIEW largest_read_tables AS
SELECT pst.object_schema AS table_schema,
       pst.object_name AS table_name,
       fsbi.count_read,
       round(pst.sum_timer_wait / 1000000000000, 0) AS total_latency_sec,
       pst.count_fetch AS rows_fetched,
       round(pst.sum_timer_fetch / 1000000000000, 0) AS fetch_latency_sec,
       pst.count_insert AS rows_inserted,
       round(pst.sum_timer_insert / 1000000000000, 0) AS insert_latency_sec,
       pst.count_update AS rows_updated,
       round(pst.sum_timer_update / 1000000000000, 0) AS update_latency_sec,
       pst.count_delete AS rows_deleted,
       round(pst.sum_timer_delete / 1000000000000, 0) AS delete_latency_sec,
       fsbi.count_read AS io_read_requests,
       round(fsbi.sum_number_of_bytes_read / 1073741824, 4) AS io_read_Gb,
       round(fsbi.sum_timer_read / 1000000000000, 0) AS io_read_latency_sec,
       fsbi.count_write AS io_write_requests,
       round(fsbi.sum_number_of_bytes_write / 1073741824, 4) AS io_write_Gb,
       round(fsbi.sum_timer_write / 1000000000000, 0) AS io_write_latency_sec,
       fsbi.count_misc AS io_misc_requests,
       round(fsbi.sum_timer_misc / 1000000000000, 0) AS io_misc_latency_sec
  FROM performance_schema.table_io_waits_summary_by_table AS pst
  LEFT JOIN 
      (SELECT LEFT(SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(file_name, '\\', '/'), '/', -2), '/', 1), 64) AS table_schema,
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
       GROUP BY table_schema, table_name) AS fsbi
    ON pst.object_schema = fsbi.table_schema
   AND pst.object_name = fsbi.table_name
 ORDER BY pst.sum_timer_fetch DESC limit 15;


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
ORDER  BY data_length + index_length DESC limit 15;
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
VIEW largest_write_tables AS
SELECT pst.object_schema AS table_schema,
       pst.object_name AS table_name,
       fsbi.count_write,
       round(pst.sum_timer_wait / 1000000000000, 0) AS total_latency_sec,
       pst.count_fetch AS rows_fetched,
       round(pst.sum_timer_fetch / 1000000000000, 0) AS fetch_latency_sec,
       pst.count_insert AS rows_inserted,
       round(pst.sum_timer_insert / 1000000000000, 0) AS insert_latency_sec,
       pst.count_update AS rows_updated,
       round(pst.sum_timer_update / 1000000000000, 0) AS update_latency_sec,
       pst.count_delete AS rows_deleted,
       round(pst.sum_timer_delete / 1000000000000, 0) AS delete_latency_sec,
       fsbi.count_read AS io_read_requests,
       round(fsbi.sum_number_of_bytes_read / 1073741824, 4) AS io_read_Gb,
       round(fsbi.sum_timer_read / 1000000000000, 0) AS io_read_latency_sec,
       fsbi.count_write AS io_write_requests,
       round(fsbi.sum_number_of_bytes_write / 1073741824, 4) AS io_write_Gb,
       round(fsbi.sum_timer_write / 1000000000000, 0) AS io_write_latency_sec,
       fsbi.count_misc AS io_misc_requests,
       round(fsbi.sum_timer_misc / 1000000000000, 0) AS io_misc_latency_sec
  FROM performance_schema.table_io_waits_summary_by_table AS pst
  LEFT JOIN 
      (SELECT LEFT(SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(file_name, '\\', '/'), '/', -2), '/', 1), 64) AS table_schema,
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
       GROUP BY table_schema, table_name) AS fsbi
    ON pst.object_schema = fsbi.table_schema
   AND pst.object_name = fsbi.table_name
 ORDER BY (pst.sum_timer_wait - pst.sum_timer_fetch) DESC limit 15;

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
 WHERE pps.processlist_command NOT IN ('Sleep', 'Binlog Dump')
 ORDER BY pps.processlist_time DESC, last_wait_latency_sec DESC;

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
       round(SUM_TIMER_FETCH / 1000000000000, 0) AS select_latency_sec,
       COUNT_INSERT AS rows_inserted,
       round(SUM_TIMER_INSERT / 1000000000000, 0) AS insert_latency_sec,
       COUNT_UPDATE AS rows_updated,
       round(SUM_TIMER_UPDATE / 1000000000000, 0) AS update_latency_sec,
       COUNT_DELETE AS rows_deleted,
       round(SUM_TIMER_INSERT / 1000000000000, 0) AS delete_latency_sec
  FROM performance_schema.table_io_waits_summary_by_index_usage
 WHERE index_name IS NOT NULL
 ORDER BY sum_timer_wait DESC;
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
    (SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    INDEX_NAME,
    MAX(NON_UNIQUE) AS non_unique,
    MAX(IF(SUB_PART IS NULL, 0, 1)) AS subpart_exists,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS index_columns
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE INDEX_TYPE='BTREE'
  AND TABLE_SCHEMA NOT IN ('mysql', 'sys', 'INFORMATION_SCHEMA', 'PERFORMANCE_SCHEMA')
  GROUP BY TABLE_SCHEMA, TABLE_NAME, INDEX_NAME) AS redundant_keys
    INNER JOIN (SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    INDEX_NAME,
    MAX(NON_UNIQUE) AS non_unique,
    MAX(IF(SUB_PART IS NULL, 0, 1)) AS subpart_exists,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS index_columns
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE INDEX_TYPE='BTREE'
  AND TABLE_SCHEMA NOT IN ('mysql', 'sys', 'INFORMATION_SCHEMA', 'PERFORMANCE_SCHEMA')
  GROUP BY TABLE_SCHEMA, TABLE_NAME, INDEX_NAME) AS dominant_keys
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
       round(pst.sum_timer_wait / 1000000000000, 0) AS total_latency_sec,
       pst.count_fetch AS rows_fetched,
       round(pst.sum_timer_fetch / 1000000000000, 0) AS fetch_latency_sec,
       pst.count_insert AS rows_inserted,
       round(pst.sum_timer_insert / 1000000000000, 0) AS insert_latency_sec,
       pst.count_update AS rows_updated,
       round(pst.sum_timer_update / 1000000000000, 0) AS update_latency_sec,
       pst.count_delete AS rows_deleted,
       round(pst.sum_timer_delete / 1000000000000, 0) AS delete_latency_sec,
       fsbi.count_read AS io_read_requests,
       round(fsbi.sum_number_of_bytes_read / 1073741824, 4) AS io_read_Gb,
       round(fsbi.sum_timer_read / 1000000000000, 0) AS io_read_latency_sec,
       fsbi.count_write AS io_write_requests,
       round(fsbi.sum_number_of_bytes_write / 1073741824, 4) AS io_write_Gb,
       round(fsbi.sum_timer_write / 1000000000000, 0) AS io_write_latency_sec,
       fsbi.count_misc AS io_misc_requests,
       round(fsbi.sum_timer_misc / 1000000000000, 0) AS io_misc_latency_sec
  FROM performance_schema.table_io_waits_summary_by_table AS pst
  LEFT JOIN 
      (SELECT LEFT(SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(file_name, '\\', '/'), '/', -2), '/', 1), 64) AS table_schema,
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
       GROUP BY table_schema, table_name) AS fsbi
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
       round(sum_timer_wait / 1000000000000, 0) AS latency_sec
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
       round(SUM_TIMER_WAIT / 1000000000000, 0) AS total_latency_sec,
       round(MAX_TIMER_WAIT / 1000000000000, 0) AS max_latency_sec,
       round(AVG_TIMER_WAIT / 1000000000000, 0) AS avg_latency_sec,
       round(SUM_LOCK_TIME / 1000000000000, 0) AS lock_latency_sec,
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
       round(SUM_TIMER_WAIT / 1000000000000, 0) AS total_latency_sec,
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
       round(SUM_TIMER_WAIT / 1000000000000, 0) AS total_latency_sec,
       round(MAX_TIMER_WAIT / 1000000000000, 0) AS max_latency_sec,
       round(AVG_TIMER_WAIT / 1000000000000, 0) AS avg_latency_sec,
       SUM_ROWS_SENT AS rows_sent,
       ROUND(IFNULL(SUM_ROWS_SENT / NULLIF(COUNT_STAR, 0), 0)) AS rows_sent_avg,
       SUM_ROWS_EXAMINED AS rows_examined,
       ROUND(IFNULL(SUM_ROWS_EXAMINED / NULLIF(COUNT_STAR, 0), 0)) AS rows_examined_avg,
       FIRST_SEEN AS first_seen,
       LAST_SEEN AS last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest stmts
  JOIN (SELECT s2.avg_us avg_us,
       IFNULL(SUM(s1.cnt)/NULLIF((SELECT COUNT(*) FROM performance_schema.events_statements_summary_by_digest), 0), 0) percentile
       FROM (SELECT COUNT(*) cnt, 
        ROUND(avg_timer_wait/1000000) AS avg_us
        FROM performance_schema.events_statements_summary_by_digest
        GROUP BY avg_us) AS s1
        JOIN (SELECT COUNT(*) cnt, 
        ROUND(avg_timer_wait/1000000) AS avg_us
        FROM performance_schema.events_statements_summary_by_digest
        GROUP BY avg_us) AS s2
        ON s1.avg_us <= s2.avg_us
        GROUP BY s2.avg_us
        HAVING IFNULL(SUM(s1.cnt)/NULLIF((SELECT COUNT(*) FROM performance_schema.events_statements_summary_by_digest), 0), 0) > 0.95
        ORDER BY percentile
        LIMIT 1) AS top_percentile
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
       round(SUM_TIMER_WAIT / 1000000000000, 0) as total_latency_sec,
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
       round(sum_timer_wait / 1000000000000, 0) AS total_latency_sec, 
       round(avg_timer_wait / 1000000000000, 0) AS avg_latency_sec 
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
       round(SUM(sum_timer_wait) / 1000000000000, 0) AS total_latency_sec,
       round(SUM(max_timer_wait) / 1000000000000, 0) AS max_latency_sec,
       round(SUM(sum_lock_time) / 1000000000000, 0) AS lock_latency_sec,
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
       round(sum_timer_wait / 1000000000000, 0) AS total_latency_sec,
       round(max_timer_wait / 1000000000000, 0) AS max_latency_sec,
       round(sum_lock_time / 1000000000000, 0) AS lock_latency_sec,
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
       round(sum_timer_wait / 1000000000000, 0) AS total_latency_sec,
       round(avg_timer_wait / 1000000000000, 0) AS avg_latency_sec,
       round(max_timer_wait / 1000000000000, 0) AS max_latency_sec
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
       round(sum_timer_wait / 1000000000000, 0) AS total_latency_sec,
       round(avg_timer_wait / 1000000000000, 0) AS avg_latency_sec,
       round(max_timer_wait / 1000000000000, 0) AS max_latency_sec
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE event_name != 'idle'
   AND sum_timer_wait > 0
 ORDER BY sum_timer_wait DESC;
-- This stored procedure allows you to create a view for the statements associated with a particular table on a particular schema. 
-- It is similar to statament_analysis view with an additional WHERE clause to filter results on the table provided into the stored procedure.

DROP PROCEDURE IF EXISTS create_table_statement_view;
DELIMITER $$

CREATE PROCEDURE create_table_statement_view(IN i_db varchar(255), IN i_table varchar(255))
BEGIN
    DECLARE validate_table BOOLEAN;
	SELECT count(1) INTO validate_table FROM information_schema.tables WHERE table_name = i_table and table_schema = i_db;

	IF validate_table THEN
	  set @statement_view := 
      CONCAT("CREATE OR REPLACE ALGORITHM = MERGE SQL SECURITY INVOKER 
      VIEW statement_analysis_for_",i_table ," AS
      SELECT DIGEST_TEXT AS query,
      SCHEMA_NAME AS db,
      IF(SUM_NO_GOOD_INDEX_USED > 0 OR SUM_NO_INDEX_USED > 0, '*', '') AS full_scan,
      COUNT_STAR AS exec_count,
      SUM_ERRORS AS err_count,
      SUM_WARNINGS AS warn_count,
      round(SUM_TIMER_WAIT / 1000000000000, 0) AS total_latency_sec,
      round(MAX_TIMER_WAIT / 1000000000000, 0) AS max_latency_sec,
      round(AVG_TIMER_WAIT / 1000000000000, 0) AS avg_latency_sec,
      round(SUM_LOCK_TIME / 1000000000000, 0) AS lock_latency_sec,
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
      WHERE DIGEST_TEXT like '%",i_table,"%' AND SCHEMA_NAME = '",i_db,"'
      ORDER BY SUM_TIMER_WAIT DESC LIMIT 15");
      PREPARE stmt1 FROM @statement_view;
      EXECUTE stmt1;
      DEALLOCATE PREPARE stmt1;

      SELECT "View Created" as Message;
    ELSE
      SELECT "Table not found" as Message;
	END IF;

END $$

DELIMITER ;

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

-- This stored procedure resets all the performance_schema information by truncating the tables inside of the schema.

DROP PROCEDURE IF EXISTS ps_reset_tables;

DELIMITER $$

CREATE PROCEDURE ps_reset_tables (
        IN in_verbose BOOLEAN
    )
    COMMENT '
             Description
             -----------

             Truncates all summary tables within Performance Schema, 
             resetting all aggregated instrumentation as a snapshot.

             Parameters
             -----------

             in_verbose (BOOLEAN):
               Whether to print each TRUNCATE statement before running

             Example
             -----------

             mysql> CALL sys.ps_truncate_all_tables(false);
             +---------------------+
             | summary             |
             +---------------------+
             | Truncated 44 tables |
             +---------------------+
             1 row in set (0.10 sec)

             Query OK, 0 rows affected (0.10 sec)
            '
    SQL SECURITY INVOKER
    DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_total_tables INT DEFAULT 0;
    DECLARE v_ps_table VARCHAR(64);
    DECLARE ps_tables CURSOR FOR
        SELECT table_name 
          FROM INFORMATION_SCHEMA.TABLES 
         WHERE table_schema = 'performance_schema' 
           AND (table_name LIKE '%summary%' 
            OR table_name LIKE '%history%');
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN ps_tables;

    ps_tables_loop: LOOP
        FETCH ps_tables INTO v_ps_table;
        IF v_done THEN
          LEAVE ps_tables_loop;
        END IF;

        SET @truncate_stmt := CONCAT('TRUNCATE TABLE performance_schema.', v_ps_table);
        IF in_verbose THEN
            SELECT CONCAT('Running: ', @truncate_stmt) AS status;
        END IF;

        PREPARE truncate_stmt FROM @truncate_stmt;
        EXECUTE truncate_stmt;
        DEALLOCATE PREPARE truncate_stmt;

        SET v_total_tables = v_total_tables + 1;
    END LOOP;

    CLOSE ps_tables;

    SELECT CONCAT('Truncated ', v_total_tables, ' tables') AS summary;

END$$

DELIMITER ;
