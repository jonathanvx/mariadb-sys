
create or replace view top_five_size as
SELECT table_name
FROM   information_schema.TABLES
WHERE TABLE_SCHEMA NOT IN ('performance_schema','information_schema','mysql','sys')
ORDER  BY data_length + index_length DESC limit 5;

create or replace view recommend_compression as
select t.table_name as 'Recommended Tables for Innodb Compresssion'
from top_five_size t
INNER JOIN information_schema.COLUMNS c ON t.table_name = c.table_name
where c.DATA_TYPE like '%text%' or c.DATA_TYPE = 'text'
group by t.table_name limit 2;

