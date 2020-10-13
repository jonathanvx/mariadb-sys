
create or replace view top_five_write as
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
 ORDER BY (pst.sum_timer_wait - pst.sum_timer_fetch) DESC limit 5;

create or replace view recommend_drop_indexes as
select concat(object_name,'.', index_name) as 'Recommended Indexes to Drop' 
from schema_unused_indexes where object_name IN (select table_name from top_five_write);

