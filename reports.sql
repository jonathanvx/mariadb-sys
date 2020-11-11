select 'The following reports are to give a sense of the current state of the database server' as 'Database Server Overview';
select '' as 'Top 5 Largest Tables';
select * from sys.largest_tables Limit 5\G
select '';

select '' as 'Top 5 Worst Queries';
select * from sys.statement_analysis limit 5\G
select '';

select 'The following reports are recommendations on how to improve the database server or where there are inefficiencies' as 'Recommendations';
select * from sys.recommend_compression;
select '';
select * from sys.recommend_drop_indexes;
select '';

select '' as 'Recommended Unoptimised Queries to Fix';
select * from sys.recommend_fix_unoptimised_queries\G
select '';

