
create or replace view top_five_read as
SELECT pst.object_name AS table_name
  FROM performance_schema.table_io_waits_summary_by_table AS pst
  LEFT JOIN
      (SELECT LEFT(SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(file_name, '\\', '/'), '/', -2), '/', 1), 64) AS table_schema,
       LEFT(SUBSTRING_INDEX(REPLACE(SUBSTRING_INDEX(REPLACE(file_name, '\\', '/'), '/', -1), '@0024', '$'), '.', 1), 64) AS table_name
       FROM performance_schema.file_summary_by_instance
       GROUP BY table_schema, table_name) AS fsbi
    ON pst.object_schema = fsbi.table_schema
   AND pst.object_name = fsbi.table_name
   WHERE table_schema NOT IN ('performance_schema','mysql','information_schema', 'sys')
 ORDER BY pst.sum_timer_fetch DESC limit 5;

create or replace view recommend_fix_unoptimised_queries as
SELECT DIGEST_TEXT AS 'query',
       COUNT_STAR AS exec_count,
       round(SUM_TIMER_WAIT / 1000000000000, 0) AS total_latency_sec,
       SUM_NO_INDEX_USED AS no_index_used_count,
       ROUND(SUM_ROWS_SENT/COUNT_STAR) AS rows_sent_avg,
       ROUND(SUM_ROWS_EXAMINED/COUNT_STAR) AS rows_examined_avg,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen
  FROM performance_schema.events_statements_summary_by_digest
 WHERE (SUM_NO_INDEX_USED > 0
    OR SUM_NO_GOOD_INDEX_USED > 0)
   AND DIGEST_TEXT NOT LIKE 'SHOW%'
   AND SCHEMA_NAME NOT IN ('performance_schema','information_schema','mysql','sys')
   AND (SUM_ROWS_EXAMINED/SUM_ROWS_SENT) >1
   AND (SCHEMA_NAME IS NOT NULL or SCHEMA_NAME <> 'NULL')
   AND LAST_SEEN >= NOW() - INTERVAL 7 DAY
   AND DIGEST_TEXT LIKE '%WHERE%'
   AND (
   	DIGEST_TEXT LIKE CONCAT('%',(SELECT table_name FROM top_five_read limit 0,1) ,'%')
   	OR DIGEST_TEXT LIKE CONCAT('%',(SELECT table_name FROM top_five_read limit 1,1) ,'%')
   	OR DIGEST_TEXT LIKE CONCAT('%',(SELECT table_name FROM top_five_read limit 2,1) ,'%')
   	OR DIGEST_TEXT LIKE CONCAT('%',(SELECT table_name FROM top_five_read limit 3,1) ,'%')
   	OR DIGEST_TEXT LIKE CONCAT('%',(SELECT table_name FROM top_five_read limit 4,1) ,'%')
   	)
 ORDER BY total_latency_sec DESC LIMIT 5;

