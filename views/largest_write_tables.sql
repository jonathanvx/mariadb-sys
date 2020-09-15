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
 ORDER BY (pst.sum_timer_wait - pst.sum_timer_fetch) DESC limit 15;
