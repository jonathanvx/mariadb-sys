
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
