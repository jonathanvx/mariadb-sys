SELECT schemaname, 
       relname as table_name, 
       seq_scan AS table_scans,
       idx_scan AS index_scans,
       n_tup_ins AS inserts,
       n_tup_upd AS updates,
       n_tup_del AS deletes
FROM pg_stat_user_tables 
WHERE schemaname NOT IN ('pg_catalog','information_schema', '_timescaledb_internal', '_timescaledb_catalog', '_timescaledb_cache','_timescaledb_config');
