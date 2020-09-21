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

