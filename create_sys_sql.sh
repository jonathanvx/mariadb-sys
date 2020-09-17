ECHO > maria_sys.sql

CAT ./views/full_processlist.sql >> maria_sys.sql
CAT ./views/innodb_lock_waits.sql >> maria_sys.sql
CAT ./views/io_by_thread_by_latency.sql >> maria_sys.sql
CAT ./views/largest_read_tables.sql >> maria_sys.sql
CAT ./views/largest_tables.sql >> maria_sys.sql
CAT ./views/largest_write_tables.sql >> maria_sys.sql
CAT ./views/processlist.sql >> maria_sys.sql
CAT ./views/schema_auto_increment_columns.sql >> maria_sys.sql
CAT ./views/schema_index_statistics.sql >> maria_sys.sql
CAT ./views/schema_redundant_indexes.sql >> maria_sys.sql
CAT ./views/schema_table_statistics.sql >> maria_sys.sql
CAT ./views/schema_tables_with_full_table_scans.sql >> maria_sys.sql
CAT ./views/schema_unused_indexes.sql >> maria_sys.sql
CAT ./views/statement_analysis.sql >> maria_sys.sql
CAT ./views/statements_with_full_table_scans.sql >> maria_sys.sql
CAT ./views/statements_with_runtimes_in_95th_percentile.sql >> maria_sys.sql
CAT ./views/statements_with_temp_tables.sql >> maria_sys.sql
CAT ./views/user_summary_by_stages.sql >> maria_sys.sql
CAT ./views/user_summary_by_statement_latency.sql >> maria_sys.sql
CAT ./views/user_summary_by_statement_type.sql >> maria_sys.sql
CAT ./views/waits_by_user_by_latency.sql >> maria_sys.sql
CAT ./views/waits_global_by_latency.sql >> maria_sys.sql

CAT ./views/create_table_statement_view.sql >> maria_sys.sql
CAT ./views/ps_reset_tables.sql >> maria_sys.sql
