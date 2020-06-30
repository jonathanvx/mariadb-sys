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
