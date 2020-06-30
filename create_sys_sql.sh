
ECHO > maria_sys.sql

CAT ./before_setup.sql >> maria_sys.sql

CAT ./views/x_ps_digest_avg_latency_distribution.sql >> maria_sys.sql
CAT ./views/x_ps_digest_95th_percentile_by_avg_us.sql >> maria_sys.sql
CAT ./views/x_ps_schema_table_statistics_io.sql >> maria_sys.sql
CAT ./views/x_schema_flattened_keys.sql >> maria_sys.sql

CAT ./views/innodb_buffer_stats_by_schema.sql >> maria_sys.sql
CAT ./views/innodb_buffer_stats_by_table.sql >> maria_sys.sql
CAT ./views/innodb_lock_waits.sql >> maria_sys.sql
CAT ./views/schema_object_overview.sql >> maria_sys.sql
CAT ./views/schema_auto_increment_columns.sql >> maria_sys.sql
CAT ./views/schema_redundant_indexes.sql >> maria_sys.sql

CAT ./views/ps_check_lost_instrumentation.sql >> maria_sys.sql

CAT ./views/processlist.sql >> maria_sys.sql
CAT ./views/sessions.sql >> maria_sys.sql

CAT ./views/latest_file_io.sql >> maria_sys.sql
CAT ./views/io_by_thread_by_latency.sql >> maria_sys.sql
CAT ./views/io_global_by_file_by_bytes.sql >> maria_sys.sql
CAT ./views/io_global_by_file_by_latency.sql >> maria_sys.sql
CAT ./views/io_global_by_wait_by_bytes.sql >> maria_sys.sql
CAT ./views/io_global_by_wait_by_latency.sql >> maria_sys.sql

CAT ./views/schema_index_statistics.sql >> maria_sys.sql
CAT ./views/schema_table_statistics.sql >> maria_sys.sql
CAT ./views/schema_table_statistics_with_buffer.sql >> maria_sys.sql
CAT ./views/schema_tables_with_full_table_scans.sql >> maria_sys.sql
CAT ./views/schema_unused_indexes.sql >> maria_sys.sql

CAT ./views/statement_analysis.sql >> maria_sys.sql
CAT ./views/statements_with_errors_or_warnings.sql >> maria_sys.sql
CAT ./views/statements_with_full_table_scans.sql >> maria_sys.sql
CAT ./views/statements_with_runtimes_in_95th_percentile.sql >> maria_sys.sql
CAT ./views/statements_with_sorting.sql >> maria_sys.sql
CAT ./views/statements_with_temp_tables.sql >> maria_sys.sql

CAT ./views/user_summary_by_file_io_type.sql >> maria_sys.sql
CAT ./views/user_summary_by_file_io.sql >> maria_sys.sql
CAT ./views/user_summary_by_statement_type.sql >> maria_sys.sql
CAT ./views/user_summary_by_statement_latency.sql >> maria_sys.sql
CAT ./views/user_summary_by_stages.sql >> maria_sys.sql

CAT ./views/user_summary.sql  >> maria_sys.sql

CAT ./views/host_summary_by_file_io_type.sql >> maria_sys.sql
CAT ./views/host_summary_by_file_io.sql >> maria_sys.sql
CAT ./views/host_summary_by_statement_type.sql >> maria_sys.sql
CAT ./views/host_summary_by_statement_latency.sql >> maria_sys.sql
CAT ./views/host_summary_by_stages.sql >> maria_sys.sql

CAT ./views/host_summary.sql >> maria_sys.sql

CAT ./views/wait_classes_global_by_avg_latency.sql >> maria_sys.sql
CAT ./views/wait_classes_global_by_latency.sql >> maria_sys.sql
CAT ./views/waits_by_user_by_latency.sql >> maria_sys.sql
CAT ./views/waits_by_host_by_latency.sql >> maria_sys.sql
CAT ./views/waits_global_by_latency.sql >> maria_sys.sql

CAT ./views/metrics_56.sql >> maria_sys.sql
CAT ./views/largest_tables.sql >> maria_sys.sql
