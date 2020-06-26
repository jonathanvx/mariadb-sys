
ECHO > tmp_maria_sys.sql

CAT ./before_setup.sql >> tmp_maria_sys.sql

CAT ./views/version.sql >> tmp_maria_sys.sql

CAT ./tables/sys_config.sql >> tmp_maria_sys.sql

CAT ./tables/sys_config_data_10.sql >> tmp_maria_sys.sql


CAT ./functions/extract_schema_from_file_name.sql >> tmp_maria_sys.sql
CAT ./functions/extract_table_from_file_name.sql >> tmp_maria_sys.sql
CAT ./functions/format_bytes.sql >> tmp_maria_sys.sql

CAT ./functions/format_path.sql >> tmp_maria_sys.sql
CAT ./functions/format_statement.sql >> tmp_maria_sys.sql
CAT ./functions/format_time.sql >> tmp_maria_sys.sql
CAT ./functions/list_add.sql >> tmp_maria_sys.sql
CAT ./functions/list_drop.sql >> tmp_maria_sys.sql

CAT ./functions/ps_is_account_enabled.sql >> tmp_maria_sys.sql
CAT ./functions/ps_is_consumer_enabled.sql >> tmp_maria_sys.sql
CAT ./functions/ps_is_instrument_default_enabled.sql >> tmp_maria_sys.sql
CAT ./functions/ps_is_instrument_default_timed.sql >> tmp_maria_sys.sql
CAT ./functions/ps_is_thread_instrumented.sql >> tmp_maria_sys.sql
CAT ./functions/ps_thread_id.sql >> tmp_maria_sys.sql
CAT ./functions/ps_thread_account.sql >> tmp_maria_sys.sql
CAT ./functions/ps_thread_stack.sql >> tmp_maria_sys.sql

CAT ./functions/quote_identifier.sql >> tmp_maria_sys.sql
CAT ./functions/sys_get_config.sql >> tmp_maria_sys.sql
CAT ./functions/version_major.sql >> tmp_maria_sys.sql
CAT ./functions/version_minor.sql >> tmp_maria_sys.sql
CAT ./functions/version_patch.sql >> tmp_maria_sys.sql

CAT ./views/i_s/innodb_buffer_stats_by_schema.sql >> tmp_maria_sys.sql
CAT ./views/i_s/x_innodb_buffer_stats_by_schema.sql >> tmp_maria_sys.sql
CAT ./views/i_s/innodb_buffer_stats_by_table.sql >> tmp_maria_sys.sql
CAT ./views/i_s/x_innodb_buffer_stats_by_table.sql >> tmp_maria_sys.sql
CAT ./views/i_s/innodb_lock_waits.sql >> tmp_maria_sys.sql
CAT ./views/i_s/x_innodb_lock_waits.sql >> tmp_maria_sys.sql
CAT ./views/i_s/schema_object_overview.sql >> tmp_maria_sys.sql
CAT ./views/i_s/schema_auto_increment_columns.sql >> tmp_maria_sys.sql
CAT ./views/i_s/x_schema_flattened_keys.sql >> tmp_maria_sys.sql
CAT ./views/i_s/schema_redundant_indexes.sql >> tmp_maria_sys.sql

CAT ./views/p_s/ps_check_lost_instrumentation.sql >> tmp_maria_sys.sql

CAT ./views/p_s/processlist.sql >> tmp_maria_sys.sql

CAT ./views/p_s/x_processlist.sql >> tmp_maria_sys.sql


CAT ./views/p_s/sessions.sql >> tmp_maria_sys.sql

CAT ./views/p_s/x_sessions.sql >> tmp_maria_sys.sql

CAT ./views/p_s/latest_file_io.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_latest_file_io.sql >> tmp_maria_sys.sql
CAT ./views/p_s/io_by_thread_by_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_io_by_thread_by_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/io_global_by_file_by_bytes.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_io_global_by_file_by_bytes.sql >> tmp_maria_sys.sql
CAT ./views/p_s/io_global_by_file_by_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_io_global_by_file_by_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/io_global_by_wait_by_bytes.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_io_global_by_wait_by_bytes.sql >> tmp_maria_sys.sql
CAT ./views/p_s/io_global_by_wait_by_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_io_global_by_wait_by_latency.sql >> tmp_maria_sys.sql

CAT ./views/p_s/schema_index_statistics.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_schema_index_statistics.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_ps_schema_table_statistics_io.sql >> tmp_maria_sys.sql
CAT ./views/p_s/schema_table_statistics.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_schema_table_statistics.sql >> tmp_maria_sys.sql
CAT ./views/p_s/schema_table_statistics_with_buffer.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_schema_table_statistics_with_buffer.sql >> tmp_maria_sys.sql
CAT ./views/p_s/schema_tables_with_full_table_scans.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_schema_tables_with_full_table_scans.sql >> tmp_maria_sys.sql
CAT ./views/p_s/schema_unused_indexes.sql >> tmp_maria_sys.sql

CAT ./views/p_s/statement_analysis.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_statement_analysis.sql >> tmp_maria_sys.sql
CAT ./views/p_s/statements_with_errors_or_warnings.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_statements_with_errors_or_warnings.sql >> tmp_maria_sys.sql
CAT ./views/p_s/statements_with_full_table_scans.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_statements_with_full_table_scans.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_ps_digest_avg_latency_distribution.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_ps_digest_95th_percentile_by_avg_us.sql >> tmp_maria_sys.sql
CAT ./views/p_s/statements_with_runtimes_in_95th_percentile.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_statements_with_runtimes_in_95th_percentile.sql >> tmp_maria_sys.sql
CAT ./views/p_s/statements_with_sorting.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_statements_with_sorting.sql >> tmp_maria_sys.sql
CAT ./views/p_s/statements_with_temp_tables.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_statements_with_temp_tables.sql >> tmp_maria_sys.sql

CAT ./views/p_s/user_summary_by_file_io_type.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_user_summary_by_file_io_type.sql >> tmp_maria_sys.sql
CAT ./views/p_s/user_summary_by_file_io.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_user_summary_by_file_io.sql >> tmp_maria_sys.sql
CAT ./views/p_s/user_summary_by_statement_type.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_user_summary_by_statement_type.sql >> tmp_maria_sys.sql
CAT ./views/p_s/user_summary_by_statement_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_user_summary_by_statement_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/user_summary_by_stages.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_user_summary_by_stages.sql >> tmp_maria_sys.sql

CAT ./views/p_s/user_summary.sql  >> tmp_maria_sys.sql

CAT ./views/p_s/x_user_summary.sql >> tmp_maria_sys.sql

CAT ./views/p_s/host_summary_by_file_io_type.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_host_summary_by_file_io_type.sql >> tmp_maria_sys.sql
CAT ./views/p_s/host_summary_by_file_io.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_host_summary_by_file_io.sql >> tmp_maria_sys.sql
CAT ./views/p_s/host_summary_by_statement_type.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_host_summary_by_statement_type.sql >> tmp_maria_sys.sql
CAT ./views/p_s/host_summary_by_statement_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_host_summary_by_statement_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/host_summary_by_stages.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_host_summary_by_stages.sql >> tmp_maria_sys.sql

CAT ./views/p_s/host_summary.sql >> tmp_maria_sys.sql

CAT ./views/p_s/x_host_summary.sql >> tmp_maria_sys.sql

CAT ./views/p_s/wait_classes_global_by_avg_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_wait_classes_global_by_avg_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/wait_classes_global_by_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_wait_classes_global_by_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/waits_by_user_by_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_waits_by_user_by_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/waits_by_host_by_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_waits_by_host_by_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/waits_global_by_latency.sql >> tmp_maria_sys.sql
CAT ./views/p_s/x_waits_global_by_latency.sql >> tmp_maria_sys.sql

CAT ./views/p_s/metrics_56.sql >> tmp_maria_sys.sql

CAT ./procedures/diagnostics.sql  >> tmp_maria_sys.sql
ECHO ' ' >> tmp_maria_sys.sql
CAT ./procedures/ps_statement_avg_latency_histogram.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_trace_statement_digest.sql >> tmp_maria_sys.sql

CAT ./procedures/ps_trace_thread.sql >> tmp_maria_sys.sql

CAT ./procedures/ps_setup_disable_background_threads.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_disable_consumer.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_disable_instrument.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_disable_thread.sql >> tmp_maria_sys.sql

CAT ./procedures/ps_setup_enable_background_threads.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_enable_consumer.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_enable_instrument.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_enable_thread.sql >> tmp_maria_sys.sql

CAT ./procedures/ps_setup_reload_saved.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_reset_to_default_57_before.sql >> tmp_maria_sys.sql

CAT ./procedures/ps_setup_reset_to_default.sql  >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_reset_to_default_57_after.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_save.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_show_disabled.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_show_disabled_consumers.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_show_disabled_instruments.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_show_enabled.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_show_enabled_consumers.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_setup_show_enabled_instruments.sql >> tmp_maria_sys.sql
CAT ./procedures/ps_truncate_all_tables.sql >> tmp_maria_sys.sql

CAT ./procedures/statement_performance_analyzer.sql >> tmp_maria_sys.sql
ECHO ' ' >> tmp_maria_sys.sql
CAT ./procedures/table_exists.sql >> tmp_maria_sys.sql
CAT ./procedures/get_optimizer_switches.sql >> tmp_maria_sys.sql

CAT ./after_setup.sql >> tmp_maria_sys.sql

CAT tmp_maria_sys.sql | SED "s/DEFINER=\'root\'@\'localhost\'//g" | SED "s/DEFINER = \'root\'@\'localhost\'//g" > maria_sys.sql

rm -f tmp_maria_sys.sql
