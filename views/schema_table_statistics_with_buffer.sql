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
