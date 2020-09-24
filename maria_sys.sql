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



CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
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


CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
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


CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
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


CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
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



CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
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
 AND pps.processlist_id <> CONNECTION_ID()
 ORDER BY pps.processlist_time DESC, last_wait_latency_sec DESC;


DROP PROCEDURE IF EXISTS ps_reset_tables;

DELIMITER $$

CREATE PROCEDURE ps_reset_tables ()
    COMMENT '
             Description

             Truncates all summary tables within Performance Schema, 
             resetting all aggregated instrumentation as a snapshot.

             Example

             mysql> CALL sys.ps_truncate_all_tables();
             | summary             |
             | Truncated 44 tables |
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

        PREPARE truncate_stmt FROM @truncate_stmt;
        EXECUTE truncate_stmt;
        DEALLOCATE PREPARE truncate_stmt;

        SET v_total_tables = v_total_tables + 1;
    END LOOP;

    CLOSE ps_tables;

    SELECT CONCAT('Truncated ', v_total_tables, ' tables') AS summary;

END$$

DELIMITER ;


CREATE OR REPLACE
  ALGORITHM = MERGE
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
 ORDER BY auto_increment DESC;


CREATE OR REPLACE
  ALGORITHM = MERGE
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

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
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


CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
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


CREATE OR REPLACE
  ALGORITHM = MERGE
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


CREATE OR REPLACE
  ALGORITHM = MERGE
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


CREATE OR REPLACE
  ALGORITHM = MERGE
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


CREATE OR REPLACE
  ALGORITHM = MERGE
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
   AND SCHEMA_NAME NOT IN ('performance_schema','information_schema','mysql')
 ORDER BY no_index_used_pct DESC, total_latency_sec DESC;



CREATE OR REPLACE
  ALGORITHM = MERGE
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
