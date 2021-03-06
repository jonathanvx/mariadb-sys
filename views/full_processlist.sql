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
 AND pps.processlist_id <> CONNECTION_ID()
 ORDER BY pps.processlist_time DESC, last_wait_latency_sec DESC;
