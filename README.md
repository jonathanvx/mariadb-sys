# The MariaDB sys schema

A collection of views, functions and procedures to help MariaDB administrators get insight in to MariaDB Database usage.

There are install files available for 10.x respectively. To load these, you must position yourself within the directory that you downloaded to, as these top level files SOURCE individual files that are shared across versions in most cases (though not all).

## Installation

The objects should all be created as the root user (but run with the privileges of the invoker).

For instance if you download to /tmp/mariadb-sys/, and want to install the 10.x version you should:

    cd /tmp/mariadb-sys/
    mysql -u root -p < ./maria_sys.sql

Alternatively, you could just choose to load individual files based on your needs, but beware, certain objects have dependencies on other objects. You will need to ensure that these are also loaded.

### Generating a single SQL file

There is bash script within the root of the branch directory, called `create_sys_sql.sh`, that allows you to create a single SQL file from the branch.

This includes substitution parameters for the MySQL user to use, and whether to include or exclude `SET sql_log_bin` commands from the scripts. This is particularly useful for installations such as Amazon RDS, which do not have the root@localhost user, or disallow setting sql_log_bin.


## Overview of objects

### Views

Many of the views in the sys schema have both a command line user friendly format output.

The examples below show output for only the formatted views, and note where there is an x$ counterpart available.


#### innodb_lock_waits / x$innodb_lock_waits

##### Description

Gives a snapshot of which InnoDB locks transactions are waiting for.
The lock waits are ordered by the age of the lock descending.

##### Structures

```SQL
mysql> desc sys.innodb_lock_waits;
+------------------------------+---------------------+------+-----+---------------------+-------+
| Field                        | Type                | Null | Key | Default             | Extra |
+------------------------------+---------------------+------+-----+---------------------+-------+
| wait_started                 | datetime            | YES  |     | NULL                |       |
| wait_age                     | time                | YES  |     | NULL                |       |
| wait_age_secs                | bigint(21)          | YES  |     | NULL                |       |
| locked_table                 | varchar(1024)       | NO   |     |                     |       |
| locked_index                 | varchar(1024)       | YES  |     | NULL                |       |
| locked_type                  | varchar(32)         | NO   |     |                     |       |
| waiting_trx_id               | varchar(18)         | NO   |     |                     |       |
| waiting_trx_started          | datetime            | NO   |     | 0000-00-00 00:00:00 |       |
| waiting_trx_age              | time                | YES  |     | NULL                |       |
| waiting_trx_rows_locked      | bigint(21) unsigned | NO   |     | 0                   |       |
| waiting_trx_rows_modified    | bigint(21) unsigned | NO   |     | 0                   |       |
| waiting_pid                  | bigint(21) unsigned | NO   |     | 0                   |       |
| waiting_query                | longtext            | YES  |     | NULL                |       |
| waiting_lock_id              | varchar(81)         | NO   |     |                     |       |
| waiting_lock_mode            | varchar(32)         | NO   |     |                     |       |
| blocking_trx_id              | varchar(18)         | NO   |     |                     |       |
| blocking_pid                 | bigint(21) unsigned | NO   |     | 0                   |       |
| blocking_query               | longtext            | YES  |     | NULL                |       |
| blocking_lock_id             | varchar(81)         | NO   |     |                     |       |
| blocking_lock_mode           | varchar(32)         | NO   |     |                     |       |
| blocking_trx_started         | datetime            | NO   |     | 0000-00-00 00:00:00 |       |
| blocking_trx_age             | time                | YES  |     | NULL                |       |
| blocking_trx_rows_locked     | bigint(21) unsigned | NO   |     | 0                   |       |
| blocking_trx_rows_modified   | bigint(21) unsigned | NO   |     | 0                   |       |
| sql_kill_blocking_query      | varchar(32)         | YES  |     | NULL                |       |
| sql_kill_blocking_connection | varchar(26)         | YES  |     | NULL                |       |
+------------------------------+---------------------+------+-----+---------------------+-------+
26 rows in set (0.01 sec)

mysql> desc sys.x$innodb_lock_waits;
+------------------------------+---------------------+------+-----+---------------------+-------+
| Field                        | Type                | Null | Key | Default             | Extra |
+------------------------------+---------------------+------+-----+---------------------+-------+
| wait_started                 | datetime            | YES  |     | NULL                |       |
| wait_age                     | time                | YES  |     | NULL                |       |
| wait_age_secs                | bigint(21)          | YES  |     | NULL                |       |
| locked_table                 | varchar(1024)       | NO   |     |                     |       |
| locked_index                 | varchar(1024)       | YES  |     | NULL                |       |
| locked_type                  | varchar(32)         | NO   |     |                     |       |
| waiting_trx_id               | varchar(18)         | NO   |     |                     |       |
| waiting_trx_started          | datetime            | NO   |     | 0000-00-00 00:00:00 |       |
| waiting_trx_age              | time                | YES  |     | NULL                |       |
| waiting_trx_rows_locked      | bigint(21) unsigned | NO   |     | 0                   |       |
| waiting_trx_rows_modified    | bigint(21) unsigned | NO   |     | 0                   |       |
| waiting_pid                  | bigint(21) unsigned | NO   |     | 0                   |       |
| waiting_query                | varchar(1024)       | YES  |     | NULL                |       |
| waiting_lock_id              | varchar(81)         | NO   |     |                     |       |
| waiting_lock_mode            | varchar(32)         | NO   |     |                     |       |
| blocking_trx_id              | varchar(18)         | NO   |     |                     |       |
| blocking_pid                 | bigint(21) unsigned | NO   |     | 0                   |       |
| blocking_query               | varchar(1024)       | YES  |     | NULL                |       |
| blocking_lock_id             | varchar(81)         | NO   |     |                     |       |
| blocking_lock_mode           | varchar(32)         | NO   |     |                     |       |
| blocking_trx_started         | datetime            | NO   |     | 0000-00-00 00:00:00 |       |
| blocking_trx_age             | time                | YES  |     | NULL                |       |
| blocking_trx_rows_locked     | bigint(21) unsigned | NO   |     | 0                   |       |
| blocking_trx_rows_modified   | bigint(21) unsigned | NO   |     | 0                   |       |
| sql_kill_blocking_query      | varchar(32)         | YES  |     | NULL                |       |
| sql_kill_blocking_connection | varchar(26)         | YES  |     | NULL                |       |
+------------------------------+---------------------+------+-----+---------------------+-------+
26 rows in set (0.02 sec)
```

##### Example

```SQL
mysql> SELECT * FROM innodb_lock_waits\G
*************************** 1. row ***************************
                wait_started: 2014-11-11 13:39:20
                    wait_age: 00:00:07
               wait_age_secs: 7
                locked_table: `db1`.`t1`
                locked_index: PRIMARY
                 locked_type: RECORD
              waiting_trx_id: 867158
         waiting_trx_started: 2014-11-11 13:39:15
             waiting_trx_age: 00:00:12
     waiting_trx_rows_locked: 0
   waiting_trx_rows_modified: 0
                 waiting_pid: 3
               waiting_query: UPDATE t1 SET val = val + 1 WHERE id = 2
             waiting_lock_id: 867158:2363:3:3
           waiting_lock_mode: X
             blocking_trx_id: 867157
                blocking_pid: 4
              blocking_query: UPDATE t1 SET val = val + 1 + SLEEP(10) WHERE id = 2
            blocking_lock_id: 867157:2363:3:3
          blocking_lock_mode: X
        blocking_trx_started: 2014-11-11 13:39:11
            blocking_trx_age: 00:00:16
    blocking_trx_rows_locked: 1
  blocking_trx_rows_modified: 1
     sql_kill_blocking_query: KILL QUERY 4
sql_kill_blocking_connection: KILL 4
```

#### io_by_thread_by_latency / x$io_by_thread_by_latency

##### Description

Shows the top IO consumers by thread, ordered by total latency.

##### Structures

```SQL
mysql> desc io_by_thread_by_latency;
+----------------+---------------------+------+-----+---------+-------+
| Field          | Type                | Null | Key | Default | Extra |
+----------------+---------------------+------+-----+---------+-------+
| user           | varchar(128)        | YES  |     | NULL    |       |
| total          | decimal(42,0)       | YES  |     | NULL    |       |
| total_latency  | text                | YES  |     | NULL    |       |
| min_latency    | text                | YES  |     | NULL    |       |
| avg_latency    | text                | YES  |     | NULL    |       |
| max_latency    | text                | YES  |     | NULL    |       |
| thread_id      | bigint(20) unsigned | NO   |     | NULL    |       |
| processlist_id | bigint(20) unsigned | YES  |     | NULL    |       |
+----------------+---------------------+------+-----+---------+-------+
8 rows in set (0.14 sec)

mysql> desc x$io_by_thread_by_latency;
+----------------+---------------------+------+-----+---------+-------+
| Field          | Type                | Null | Key | Default | Extra |
+----------------+---------------------+------+-----+---------+-------+
| user           | varchar(128)        | YES  |     | NULL    |       |
| total          | decimal(42,0)       | YES  |     | NULL    |       |
| total_latency  | decimal(42,0)       | YES  |     | NULL    |       |
| min_latency    | bigint(20) unsigned | YES  |     | NULL    |       |
| avg_latency    | decimal(24,4)       | YES  |     | NULL    |       |
| max_latency    | bigint(20) unsigned | YES  |     | NULL    |       |
| thread_id      | bigint(20) unsigned | NO   |     | NULL    |       |
| processlist_id | bigint(20) unsigned | YES  |     | NULL    |       |
+----------------+---------------------+------+-----+---------+-------+
8 rows in set (0.03 sec)
```

##### Example

```SQL
mysql> select * from io_by_thread_by_latency;
+---------------------+-------+---------------+-------------+-------------+-------------+-----------+----------------+
| user                | total | total_latency | min_latency | avg_latency | max_latency | thread_id | processlist_id |
+---------------------+-------+---------------+-------------+-------------+-------------+-----------+----------------+
| root@localhost      | 11580 | 18.01 s       | 429.78 ns   | 1.12 ms     | 181.07 ms   |        25 |              6 |
| main                |  1358 | 1.31 s        | 475.02 ns   | 2.27 ms     | 350.70 ms   |         1 |           NULL |
| page_cleaner_thread |   654 | 147.44 ms     | 588.12 ns   | 225.44 us   | 46.41 ms    |        18 |           NULL |
| io_write_thread     |   131 | 107.75 ms     | 8.60 us     | 822.55 us   | 27.69 ms    |         8 |           NULL |
| io_write_thread     |    46 | 47.07 ms      | 10.64 us    | 1.02 ms     | 16.90 ms    |         9 |           NULL |
| io_write_thread     |    71 | 46.99 ms      | 9.11 us     | 661.81 us   | 17.04 ms    |        11 |           NULL |
| io_log_thread       |    20 | 21.01 ms      | 14.25 us    | 1.05 ms     | 7.08 ms     |         3 |           NULL |
| srv_master_thread   |    13 | 17.60 ms      | 8.49 us     | 1.35 ms     | 9.99 ms     |        16 |           NULL |
| srv_purge_thread    |     4 | 1.81 ms       | 34.31 us    | 452.45 us   | 1.02 ms     |        17 |           NULL |
| io_write_thread     |    19 | 951.39 us     | 9.75 us     | 50.07 us    | 297.47 us   |        10 |           NULL |
| signal_handler      |     3 | 218.03 us     | 21.64 us    | 72.68 us    | 154.84 us   |        19 |           NULL |
+---------------------+-------+---------------+-------------+-------------+-------------+-----------+----------------+
```

#### io_global_by_file_by_bytes / x$io_global_by_file_by_bytes

##### Description

Shows the top global IO consumers by bytes usage by file.

##### Structures

```SQL
mysql> desc io_global_by_file_by_bytes;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| file          | varchar(512)        | YES  |     | NULL    |       |
| count_read    | bigint(20) unsigned | NO   |     | NULL    |       |
| total_read    | text                | YES  |     | NULL    |       |
| avg_read      | text                | YES  |     | NULL    |       |
| count_write   | bigint(20) unsigned | NO   |     | NULL    |       |
| total_written | text                | YES  |     | NULL    |       |
| avg_write     | text                | YES  |     | NULL    |       |
| total         | text                | YES  |     | NULL    |       |
| write_pct     | decimal(26,2)       | NO   |     | 0.00    |       |
+---------------+---------------------+------+-----+---------+-------+
9 rows in set (0.15 sec)

mysql> desc x$io_global_by_file_by_bytes;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| file          | varchar(512)        | NO   |     | NULL    |       |
| count_read    | bigint(20) unsigned | NO   |     | NULL    |       |
| total_read    | bigint(20)          | NO   |     | NULL    |       |
| avg_read      | decimal(23,4)       | NO   |     | 0.0000  |       |
| count_write   | bigint(20) unsigned | NO   |     | NULL    |       |
| total_written | bigint(20)          | NO   |     | NULL    |       |
| avg_write     | decimal(23,4)       | NO   |     | 0.0000  |       |
| total         | bigint(21)          | NO   |     | 0       |       |
| write_pct     | decimal(26,2)       | NO   |     | 0.00    |       |
+---------------+---------------------+------+-----+---------+-------+
9 rows in set (0.14 sec)
```

##### Example

```SQL
mysql> SELECT * FROM io_global_by_file_by_bytes LIMIT 5;
+--------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
| file                                       | count_read | total_read | avg_read  | count_write | total_written | avg_write | total      | write_pct |
+--------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
| @@datadir/ibdata1                          |        147 | 4.27 MiB   | 29.71 KiB |           3 | 48.00 KiB     | 16.00 KiB | 4.31 MiB   |      1.09 |
| @@datadir/mysql/proc.MYD                   |        347 | 85.35 KiB  | 252 bytes |         111 | 19.08 KiB     | 176 bytes | 104.43 KiB |     18.27 |
| @@datadir/ib_logfile0                      |          6 | 68.00 KiB  | 11.33 KiB |           8 | 4.00 KiB      | 512 bytes | 72.00 KiB  |      5.56 |
| /opt/mysql/5.5.33/share/english/errmsg.sys |          3 | 43.68 KiB  | 14.56 KiB |           0 | 0 bytes       | 0 bytes   | 43.68 KiB  |      0.00 |
| /opt/mysql/5.5.33/share/charsets/Index.xml |          1 | 17.89 KiB  | 17.89 KiB |           0 | 0 bytes       | 0 bytes   | 17.89 KiB  |      0.00 |
+--------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
```

#### io_global_by_file_by_latency / x$io_global_by_file_by_latency

##### Description

Shows the top global IO consumers by latency by file.

##### Structures

```SQL
mysql> desc io_global_by_file_by_latency;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| file          | varchar(512)        | YES  |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | text                | YES  |     | NULL    |       |
| count_read    | bigint(20) unsigned | NO   |     | NULL    |       |
| read_latency  | text                | YES  |     | NULL    |       |
| count_write   | bigint(20) unsigned | NO   |     | NULL    |       |
| write_latency | text                | YES  |     | NULL    |       |
| count_misc    | bigint(20) unsigned | NO   |     | NULL    |       |
| misc_latency  | text                | YES  |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
9 rows in set (0.00 sec)

mysql> desc x$io_global_by_file_by_latency;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| file          | varchar(512)        | NO   |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | bigint(20) unsigned | NO   |     | NULL    |       |
| count_read    | bigint(20) unsigned | NO   |     | NULL    |       |
| read_latency  | bigint(20) unsigned | NO   |     | NULL    |       |
| count_write   | bigint(20) unsigned | NO   |     | NULL    |       |
| write_latency | bigint(20) unsigned | NO   |     | NULL    |       |
| count_misc    | bigint(20) unsigned | NO   |     | NULL    |       |
| misc_latency  | bigint(20) unsigned | NO   |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
9 rows in set (0.07 sec)
```

##### Example

```SQL
mysql> select * from io_global_by_file_by_latency limit 5;
+-----------------------------------------------------------+-------+---------------+------------+--------------+-------------+---------------+------------+--------------+
| file                                                      | total | total_latency | count_read | read_latency | count_write | write_latency | count_misc | misc_latency |
+-----------------------------------------------------------+-------+---------------+------------+--------------+-------------+---------------+------------+--------------+
| @@datadir/sys/wait_classes_global_by_avg_latency_raw.frm~ |    24 | 451.99 ms     |          0 | 0 ps         |           4 | 108.07 us     |         20 | 451.88 ms    |
| @@datadir/sys/innodb_buffer_stats_by_schema_raw.frm~      |    24 | 379.84 ms     |          0 | 0 ps         |           4 | 108.88 us     |         20 | 379.73 ms    |
| @@datadir/sys/io_by_thread_by_latency_raw.frm~            |    24 | 379.46 ms     |          0 | 0 ps         |           4 | 101.37 us     |         20 | 379.36 ms    |
| @@datadir/ibtmp1                                          |    53 | 373.45 ms     |          0 | 0 ps         |          48 | 246.08 ms     |          5 | 127.37 ms    |
| @@datadir/sys/statement_analysis_raw.frm~                 |    24 | 353.14 ms     |          0 | 0 ps         |           4 | 94.96 us      |         20 | 353.04 ms    |
+-----------------------------------------------------------+-------+---------------+------------+--------------+-------------+---------------+------------+--------------+
```

#### io_global_by_wait_by_bytes / x$io_global_by_wait_by_bytes

##### Description

Shows the top global IO consumer classes by bytes usage.

##### Structures

```SQL
mysql> desc io_global_by_wait_by_bytes;
+-----------------+---------------------+------+-----+---------+-------+
| Field           | Type                | Null | Key | Default | Extra |
+-----------------+---------------------+------+-----+---------+-------+
| event_name      | varchar(128)        | YES  |     | NULL    |       |
| total           | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency   | text                | YES  |     | NULL    |       |
| min_latency     | text                | YES  |     | NULL    |       |
| avg_latency     | text                | YES  |     | NULL    |       |
| max_latency     | text                | YES  |     | NULL    |       |
| count_read      | bigint(20) unsigned | NO   |     | NULL    |       |
| total_read      | text                | YES  |     | NULL    |       |
| avg_read        | text                | YES  |     | NULL    |       |
| count_write     | bigint(20) unsigned | NO   |     | NULL    |       |
| total_written   | text                | YES  |     | NULL    |       |
| avg_written     | text                | YES  |     | NULL    |       |
| total_requested | text                | YES  |     | NULL    |       |
+-----------------+---------------------+------+-----+---------+-------+
13 rows in set (0.02 sec)

mysql> desc x$io_global_by_wait_by_bytes;
+-----------------+---------------------+------+-----+---------+-------+
| Field           | Type                | Null | Key | Default | Extra |
+-----------------+---------------------+------+-----+---------+-------+
| event_name      | varchar(128)        | YES  |     | NULL    |       |
| total           | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency   | bigint(20) unsigned | NO   |     | NULL    |       |
| min_latency     | bigint(20) unsigned | NO   |     | NULL    |       |
| avg_latency     | bigint(20) unsigned | NO   |     | NULL    |       |
| max_latency     | bigint(20) unsigned | NO   |     | NULL    |       |
| count_read      | bigint(20) unsigned | NO   |     | NULL    |       |
| total_read      | bigint(20)          | NO   |     | NULL    |       |
| avg_read        | decimal(23,4)       | NO   |     | 0.0000  |       |
| count_write     | bigint(20) unsigned | NO   |     | NULL    |       |
| total_written   | bigint(20)          | NO   |     | NULL    |       |
| avg_written     | decimal(23,4)       | NO   |     | 0.0000  |       |
| total_requested | bigint(21)          | NO   |     | 0       |       |
+-----------------+---------------------+------+-----+---------+-------+
13 rows in set (0.01 sec)
```

##### Example

```SQL
mysql> select * from io_global_by_wait_by_bytes;
+--------------------+--------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
| event_name         | total  | total_latency | min_latency | avg_latency | max_latency | count_read | total_read | avg_read  | count_write | total_written | avg_written | total_requested |
+--------------------+--------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
| myisam/dfile       | 163681 | 983.13 ms     | 379.08 ns   | 6.01 us     | 22.06 ms    |      68737 | 127.31 MiB | 1.90 KiB  |     1012221 | 121.52 MiB    | 126 bytes   | 248.83 MiB      |
| myisam/kfile       |   1775 | 375.13 ms     | 1.02 us     | 211.34 µs   | 35.15 ms    |      54066 | 9.97 MiB   | 193 bytes |      428257 | 12.40 MiB     | 30 bytes    | 22.37 MiB       |
| sql/FRM            |  57889 | 8.40 s        | 19.44 ns    | 145.05 us   | 336.71 ms   |       8009 | 2.60 MiB   | 341 bytes |       14675 | 2.91 MiB      | 208 bytes   | 5.51 MiB        |
| sql/global_ddl_log |    164 | 75.96 ms      | 5.72 us     | 463.19 µs   | 7.43 ms     |         20 | 80.00 KiB  | 4.00 KiB  |          76 | 304.00 KiB    | 4.00 KiB    | 384.00 KiB      |
| sql/file_parser    |    419 | 601.37 ms     | 1.96 us     | 1.44 ms     | 37.14 ms    |         66 | 42.01 KiB  | 652 bytes |          64 | 226.98 KiB    | 3.55 KiB    | 268.99 KiB      |
| sql/binlog         |    190 | 6.79 s        | 1.56 us     | 35.76 ms    | 4.21 s      |         52 | 60.54 KiB  | 1.16 KiB  |           0 | 0 bytes       | 0 bytes     | 60.54 KiB       |
| sql/ERRMSG         |      5 | 2.03 s        | 8.61 us     | 405.40 ms   | 2.03 s      |          3 | 51.82 KiB  | 17.27 KiB |           0 | 0 bytes       | 0 bytes     | 51.82 KiB       |
| mysys/charset      |      3 | 196.52 us     | 17.61 µs    | 65.51 µs    | 137.33 µs   |          1 | 17.83 KiB  | 17.83 KiB |           0 | 0 bytes       | 0 bytes     | 17.83 KiB       |
| sql/partition      |     81 | 18.87 ms      | 888.08 ns   | 232.92 us   | 4.67 ms     |         66 | 2.75 KiB   | 43 bytes  |           8 | 288 bytes     | 36 bytes    | 3.04 KiB        |
| sql/dbopt          | 329166 | 26.95 s       | 2.06 us     | 81.89 µs    | 178.71 ms   |          0 | 0 bytes    | 0 bytes   |           9 | 585 bytes     | 65 bytes    | 585 bytes       |
| sql/relaylog       |      7 | 1.18 ms       | 838.84 ns   | 168.30 us   | 892.70 µs   |          0 | 0 bytes    | 0 bytes   |           1 | 120 bytes     | 120 bytes   | 120 bytes       |
| mysys/cnf          |      5 | 171.61 us     | 303.26 ns   | 34.32 µs    | 115.21 µs   |          3 | 56 bytes   | 19 bytes  |           0 | 0 bytes       | 0 bytes     | 56 bytes        |
| sql/pid            |      3 | 220.55 us     | 29.29 µs    | 73.52 µs    | 143.11 µs   |          0 | 0 bytes    | 0 bytes   |           1 | 5 bytes       | 5 bytes     | 5 bytes         |
| sql/casetest       |      1 | 121.19 us     | 121.19 µs   | 121.19 µs   | 121.19 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
| sql/binlog_index   |      5 | 593.47 us     | 1.07 µs     | 118.69 µs   | 535.90 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
| sql/misc           |     23 | 2.73 ms       | 65.14 us    | 118.50 µs   | 255.31 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
+--------------------+--------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
```

#### io_global_by_wait_by_latency / x$io_global_by_wait_by_latency

##### Description

Shows the top global IO consumers by latency.

##### Structures

```SQL
mysql> desc io_global_by_wait_by_latency;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| event_name    | varchar(128)        | YES  |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | text                | YES  |     | NULL    |       |
| avg_latency   | text                | YES  |     | NULL    |       |
| max_latency   | text                | YES  |     | NULL    |       |
| read_latency  | text                | YES  |     | NULL    |       |
| write_latency | text                | YES  |     | NULL    |       |
| misc_latency  | text                | YES  |     | NULL    |       |
| count_read    | bigint(20) unsigned | NO   |     | NULL    |       |
| total_read    | text                | YES  |     | NULL    |       |
| avg_read      | text                | YES  |     | NULL    |       |
| count_write   | bigint(20) unsigned | NO   |     | NULL    |       |
| total_written | text                | YES  |     | NULL    |       |
| avg_written   | text                | YES  |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
14 rows in set (0.19 sec)

mysql> desc x$io_global_by_wait_by_latency;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| event_name    | varchar(128)        | YES  |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | bigint(20) unsigned | NO   |     | NULL    |       |
| avg_latency   | bigint(20) unsigned | NO   |     | NULL    |       |
| max_latency   | bigint(20) unsigned | NO   |     | NULL    |       |
| read_latency  | bigint(20) unsigned | NO   |     | NULL    |       |
| write_latency | bigint(20) unsigned | NO   |     | NULL    |       |
| misc_latency  | bigint(20) unsigned | NO   |     | NULL    |       |
| count_read    | bigint(20) unsigned | NO   |     | NULL    |       |
| total_read    | bigint(20)          | NO   |     | NULL    |       |
| avg_read      | decimal(23,4)       | NO   |     | 0.0000  |       |
| count_write   | bigint(20) unsigned | NO   |     | NULL    |       |
| total_written | bigint(20)          | NO   |     | NULL    |       |
| avg_written   | decimal(23,4)       | NO   |     | 0.0000  |       |
+---------------+---------------------+------+-----+---------+-------+
14 rows in set (0.01 sec)
```

##### Example

```SQL
mysql> SELECT * FROM io_global_by_wait_by_latency;
+-------------------------+-------+---------------+-------------+-------------+--------------+---------------+--------------+------------+------------+-----------+-------------+---------------+-------------+
| event_name              | total | total_latency | avg_latency | max_latency | read_latency | write_latency | misc_latency | count_read | total_read | avg_read  | count_write | total_written | avg_written |
+-------------------------+-------+---------------+-------------+-------------+--------------+---------------+--------------+------------+------------+-----------+-------------+---------------+-------------+
| sql/file_parser         |  5433 | 30.20 s       | 5.56 ms     | 203.65 ms   | 22.08 ms     | 24.89 ms      | 30.16 s      |         24 | 6.18 KiB   | 264 bytes |         737 | 2.15 MiB      | 2.99 KiB    |
| innodb/innodb_data_file |  1344 | 1.52 s        | 1.13 ms     | 350.70 ms   | 203.82 ms    | 450.96 ms     | 868.21 ms    |        147 | 2.30 MiB   | 16.00 KiB |        1001 | 53.61 MiB     | 54.84 KiB   |
| innodb/innodb_log_file  |   828 | 893.48 ms     | 1.08 ms     | 30.11 ms    | 16.32 ms     | 705.89 ms     | 171.27 ms    |          6 | 68.00 KiB  | 11.33 KiB |         413 | 2.19 MiB      | 5.42 KiB    |
| myisam/kfile            |  7642 | 242.34 ms     | 31.71 us    | 19.27 ms    | 73.60 ms     | 23.48 ms      | 145.26 ms    |        758 | 135.63 KiB | 183 bytes |        4386 | 232.52 KiB    | 54 bytes    |
| myisam/dfile            | 12540 | 223.47 ms     | 17.82 us    | 32.50 ms    | 87.76 ms     | 16.97 ms      | 118.74 ms    |       5390 | 4.49 MiB   | 873 bytes |        1448 | 2.65 MiB      | 1.88 KiB    |
| csv/metadata            |     8 | 28.98 ms      | 3.62 ms     | 20.15 ms    | 399.27 us    | 0 ps          | 28.58 ms     |          2 | 70 bytes   | 35 bytes  |           0 | 0 bytes       | 0 bytes     |
| mysys/charset           |     3 | 24.24 ms      | 8.08 ms     | 24.15 ms    | 24.15 ms     | 0 ps          | 93.18 us     |          1 | 17.31 KiB  | 17.31 KiB |           0 | 0 bytes       | 0 bytes     |
| sql/ERRMSG              |     5 | 20.43 ms      | 4.09 ms     | 19.31 ms    | 20.32 ms     | 0 ps          | 103.20 us    |          3 | 58.97 KiB  | 19.66 KiB |           0 | 0 bytes       | 0 bytes     |
| mysys/cnf               |     5 | 11.37 ms      | 2.27 ms     | 11.28 ms    | 11.29 ms     | 0 ps          | 78.22 us     |          3 | 56 bytes   | 19 bytes  |           0 | 0 bytes       | 0 bytes     |
| sql/dbopt               |    57 | 4.04 ms       | 70.92 us    | 843.70 us   | 0 ps         | 186.43 us     | 3.86 ms      |          0 | 0 bytes    | 0 bytes   |           7 | 431 bytes     | 62 bytes    |
| csv/data                |     4 | 411.55 us     | 102.89 us   | 234.89 us   | 0 ps         | 0 ps          | 411.55 us    |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
| sql/misc                |    22 | 340.38 us     | 15.47 us    | 33.77 us    | 0 ps         | 0 ps          | 340.38 us    |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
| archive/data            |    39 | 277.86 us     | 7.12 us     | 16.18 us    | 0 ps         | 0 ps          | 277.86 us    |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
| sql/pid                 |     3 | 218.03 us     | 72.68 us    | 154.84 us   | 0 ps         | 21.64 us      | 196.39 us    |          0 | 0 bytes    | 0 bytes   |           1 | 6 bytes       | 6 bytes     |
| sql/casetest            |     5 | 197.15 us     | 39.43 us    | 126.31 us   | 0 ps         | 0 ps          | 197.15 us    |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
| sql/global_ddl_log      |     2 | 14.60 us      | 7.30 us     | 12.12 us    | 0 ps         | 0 ps          | 14.60 us     |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
+-------------------------+-------+---------------+-------------+-------------+--------------+---------------+--------------+------------+------------+-----------+-------------+---------------+-------------+
```

#### latest_file_io / x$latest_file_io

##### Description

Shows the latest file IO, by file / thread.

##### Structures

```SQL
mysql> desc latest_file_io;
+-----------+--------------+------+-----+---------+-------+
| Field     | Type         | Null | Key | Default | Extra |
+-----------+--------------+------+-----+---------+-------+
| thread    | varchar(149) | YES  |     | NULL    |       |
| file      | varchar(512) | YES  |     | NULL    |       |
| latency   | text         | YES  |     | NULL    |       |
| operation | varchar(32)  | NO   |     | NULL    |       |
| requested | text         | YES  |     | NULL    |       |
+-----------+--------------+------+-----+---------+-------+
5 rows in set (0.10 sec)

mysql> desc x$latest_file_io;
+-----------+---------------------+------+-----+---------+-------+
| Field     | Type                | Null | Key | Default | Extra |
+-----------+---------------------+------+-----+---------+-------+
| thread    | varchar(149)        | YES  |     | NULL    |       |
| file      | varchar(512)        | YES  |     | NULL    |       |
| latency   | bigint(20) unsigned | YES  |     | NULL    |       |
| operation | varchar(32)         | NO   |     | NULL    |       |
| requested | bigint(20)          | YES  |     | NULL    |       |
+-----------+---------------------+------+-----+---------+-------+
5 rows in set (0.05 sec)
```

##### Example

```SQL
mysql> select * from latest_file_io limit 5;
+----------------------+----------------------------------------+------------+-----------+-----------+
| thread               | file                                   | latency    | operation | requested |
+----------------------+----------------------------------------+------------+-----------+-----------+
| msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 9.26 us    | write     | 124 bytes |
| msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 4.00 us    | write     | 2 bytes   |
| msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 56.34 us   | close     | NULL      |
| msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYD             | 53.93 us   | close     | NULL      |
| msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 104.05 ms  | delete    | NULL      |
+----------------------+----------------------------------------+------------+-----------+-----------+
```

#### memory_by_host_by_current_bytes / x$memory_by_host_by_current_bytes

##### Description

Summarizes memory use by host using the 5.7 Performance Schema instrumentation.

When the host found is NULL, it is assumed to be a local "background" thread.

##### Structures

```SQL
mysql> desc memory_by_host_by_current_bytes;
+--------------------+---------------+------+-----+---------+-------+
| Field              | Type          | Null | Key | Default | Extra |
+--------------------+---------------+------+-----+---------+-------+
| host               | varchar(60)   | YES  |     | NULL    |       |
| current_count_used | decimal(41,0) | YES  |     | NULL    |       |
| current_allocated  | text          | YES  |     | NULL    |       |
| current_avg_alloc  | text          | YES  |     | NULL    |       |
| current_max_alloc  | text          | YES  |     | NULL    |       |
| total_allocated    | text          | YES  |     | NULL    |       |
+--------------------+---------------+------+-----+---------+-------+
6 rows in set (0.24 sec)

mysql> desc x$memory_by_host_by_current_bytes;
+--------------------+---------------+------+-----+---------+-------+
| Field              | Type          | Null | Key | Default | Extra |
+--------------------+---------------+------+-----+---------+-------+
| host               | varchar(60)   | YES  |     | NULL    |       |
| current_count_used | decimal(41,0) | YES  |     | NULL    |       |
| current_allocated  | decimal(41,0) | YES  |     | NULL    |       |
| current_avg_alloc  | decimal(45,4) | NO   |     | 0.0000  |       |
| current_max_alloc  | bigint(20)    | YES  |     | NULL    |       |
| total_allocated    | decimal(42,0) | YES  |     | NULL    |       |
+--------------------+---------------+------+-----+---------+-------+
6 rows in set (0.28 sec)
```

##### Example

```SQL
mysql> select * from memory_by_host_by_current_bytes WHERE host IS NOT NULL;
   +------------+--------------------+-------------------+-------------------+-------------------+-----------------+
   | host       | current_count_used | current_allocated | current_avg_alloc | current_max_alloc | total_allocated |
   +------------+--------------------+-------------------+-------------------+-------------------+-----------------+
   | background |               2773 | 10.84 MiB         | 4.00 KiB          | 8.00 MiB          | 30.69 MiB       |
   | localhost  |               1509 | 809.30 KiB        | 549 bytes         | 176.38 KiB        | 83.59 MiB       |
   +------------+--------------------+-------------------+-------------------+-------------------+-----------------+
```

#### memory_by_thread_by_current_bytes / x$memory_by_thread_by_current_bytes

##### Description

Summarizes memory use by user using the 5.7 Performance Schema instrumentation.

The user columns shows either the background or foreground user name appropriately.

##### Structures

```SQL
mysql> desc memory_by_thread_by_current_bytes;
+--------------------+---------------------+------+-----+---------+-------+
| Field              | Type                | Null | Key | Default | Extra |
+--------------------+---------------------+------+-----+---------+-------+
| thread_id          | bigint(20) unsigned | NO   |     | NULL    |       |
| user               | varchar(128)        | YES  |     | NULL    |       |
| current_count_used | decimal(41,0)       | YES  |     | NULL    |       |
| current_allocated  | text                | YES  |     | NULL    |       |
| current_avg_alloc  | text                | YES  |     | NULL    |       |
| current_max_alloc  | text                | YES  |     | NULL    |       |
| total_allocated    | text                | YES  |     | NULL    |       |
+--------------------+---------------------+------+-----+---------+-------+
7 rows in set (0.49 sec)

mysql> desc x$memory_by_thread_by_current_bytes;
+--------------------+---------------------+------+-----+---------+-------+
| Field              | Type                | Null | Key | Default | Extra |
+--------------------+---------------------+------+-----+---------+-------+
| thread_id          | bigint(20) unsigned | NO   |     | NULL    |       |
| user               | varchar(128)        | YES  |     | NULL    |       |
| current_count_used | decimal(41,0)       | YES  |     | NULL    |       |
| current_allocated  | decimal(41,0)       | YES  |     | NULL    |       |
| current_avg_alloc  | decimal(45,4)       | NO   |     | 0.0000  |       |
| current_max_alloc  | bigint(20)          | YES  |     | NULL    |       |
| total_allocated    | decimal(42,0)       | YES  |     | NULL    |       |
+--------------------+---------------------+------+-----+---------+-------+
7 rows in set (0.25 sec)
```

##### Example

```SQL
mysql> select * from sys.memory_by_thread_by_current_bytes limit 5;
+-----------+----------------+--------------------+-------------------+-------------------+-------------------+-----------------+
| thread_id | user           | current_count_used | current_allocated | current_avg_alloc | current_max_alloc | total_allocated |
+-----------+----------------+--------------------+-------------------+-------------------+-------------------+-----------------+
|         1 | sql/main       |              29333 | 166.02 MiB        | 5.80 KiB          | 131.13 MiB        | 196.00 MiB      |
|        55 | root@localhost |                175 | 1.04 MiB          | 6.09 KiB          | 350.86 KiB        | 67.37 MiB       |
|        58 | root@localhost |                236 | 368.13 KiB        | 1.56 KiB          | 312.05 KiB        | 130.34 MiB      |
|       904 | root@localhost |                 32 | 18.00 KiB         | 576 bytes         | 16.00 KiB         | 6.68 MiB        |
|       970 | root@localhost |                 12 | 16.80 KiB         | 1.40 KiB          | 16.00 KiB         | 1.20 MiB        |
+-----------+----------------+--------------------+-------------------+-------------------+-------------------+-----------------+
```

#### memory_by_user_by_current_bytes / x$memory_by_user_by_current_bytes

##### Description

Summarizes memory use by user using the 5.7 Performance Schema instrumentation.

When the user found is NULL, it is assumed to be a "background" thread.

##### Structures

```SQL
mysql> desc memory_by_user_by_current_bytes;
+--------------------+---------------+------+-----+---------+-------+
| Field              | Type          | Null | Key | Default | Extra |
+--------------------+---------------+------+-----+---------+-------+
| user               | varchar(32)   | YES  |     | NULL    |       |
| current_count_used | decimal(41,0) | YES  |     | NULL    |       |
| current_allocated  | text          | YES  |     | NULL    |       |
| current_avg_alloc  | text          | YES  |     | NULL    |       |
| current_max_alloc  | text          | YES  |     | NULL    |       |
| total_allocated    | text          | YES  |     | NULL    |       |
+--------------------+---------------+------+-----+---------+-------+
6 rows in set (0.06 sec)

mysql> desc x$memory_by_user_by_current_bytes;
+--------------------+---------------+------+-----+---------+-------+
| Field              | Type          | Null | Key | Default | Extra |
+--------------------+---------------+------+-----+---------+-------+
| user               | varchar(32)   | YES  |     | NULL    |       |
| current_count_used | decimal(41,0) | YES  |     | NULL    |       |
| current_allocated  | decimal(41,0) | YES  |     | NULL    |       |
| current_avg_alloc  | decimal(45,4) | NO   |     | 0.0000  |       |
| current_max_alloc  | bigint(20)    | YES  |     | NULL    |       |
| total_allocated    | decimal(42,0) | YES  |     | NULL    |       |
+--------------------+---------------+------+-----+---------+-------+
6 rows in set (0.12 sec)
```

##### Example

```SQL
mysql> select * from memory_by_user_by_current_bytes;
+------+--------------------+-------------------+-------------------+-------------------+-----------------+
| user | current_count_used | current_allocated | current_avg_alloc | current_max_alloc | total_allocated |
+------+--------------------+-------------------+-------------------+-------------------+-----------------+
| root |               1401 | 1.09 MiB          | 815 bytes         | 334.97 KiB        | 42.73 MiB       |
| mark |                201 | 496.08 KiB        | 2.47 KiB          | 334.97 KiB        | 5.50 MiB        |
+------+--------------------+-------------------+-------------------+-------------------+-----------------+
```

#### memory_global_by_current_bytes / x$memory_global_by_current_bytes

##### Description

Shows the current memory usage within the server globally broken down by allocation type.

##### Structures

```SQL
mysql> desc memory_global_by_current_bytes;
+-------------------+--------------+------+-----+---------+-------+
| Field             | Type         | Null | Key | Default | Extra |
+-------------------+--------------+------+-----+---------+-------+
| event_name        | varchar(128) | NO   |     | NULL    |       |
| current_count     | bigint(20)   | NO   |     | NULL    |       |
| current_alloc     | text         | YES  |     | NULL    |       |
| current_avg_alloc | text         | YES  |     | NULL    |       |
| high_count        | bigint(20)   | NO   |     | NULL    |       |
| high_alloc        | text         | YES  |     | NULL    |       |
| high_avg_alloc    | text         | YES  |     | NULL    |       |
+-------------------+--------------+------+-----+---------+-------+
7 rows in set (0.08 sec)

mysql> desc x$memory_global_by_current_bytes;
+-------------------+---------------+------+-----+---------+-------+
| Field             | Type          | Null | Key | Default | Extra |
+-------------------+---------------+------+-----+---------+-------+
| event_name        | varchar(128)  | NO   |     | NULL    |       |
| current_count     | bigint(20)    | NO   |     | NULL    |       |
| current_alloc     | bigint(20)    | NO   |     | NULL    |       |
| current_avg_alloc | decimal(23,4) | NO   |     | 0.0000  |       |
| high_count        | bigint(20)    | NO   |     | NULL    |       |
| high_alloc        | bigint(20)    | NO   |     | NULL    |       |
| high_avg_alloc    | decimal(23,4) | NO   |     | 0.0000  |       |
+-------------------+---------------+------+-----+---------+-------+
7 rows in set (0.16 sec)
```

##### Example

```SQL
mysql> select * from memory_global_by_current_bytes;
+----------------------------------------+---------------+---------------+-------------------+------------+------------+----------------+
| event_name                             | current_count | current_alloc | current_avg_alloc | high_count | high_alloc | high_avg_alloc |
+----------------------------------------+---------------+---------------+-------------------+------------+------------+----------------+
| memory/sql/TABLE_SHARE::mem_root       |           269 | 568.21 KiB    | 2.11 KiB          |        339 | 706.04 KiB | 2.08 KiB       |
| memory/sql/TABLE                       |           214 | 366.56 KiB    | 1.71 KiB          |        245 | 481.13 KiB | 1.96 KiB       |
| memory/sql/sp_head::main_mem_root      |            32 | 334.97 KiB    | 10.47 KiB         |        421 | 9.73 MiB   | 23.66 KiB      |
| memory/sql/Filesort_buffer::sort_keys  |             1 | 255.89 KiB    | 255.89 KiB        |          1 | 256.00 KiB | 256.00 KiB     |
| memory/mysys/array_buffer              |            82 | 121.66 KiB    | 1.48 KiB          |       1124 | 852.55 KiB | 777 bytes      |
...
+----------------------------------------+---------------+---------------+-------------------+------------+------------+----------------+
```

#### memory_global_total / x$memory_global_total

##### Description

Shows the total memory usage within the server globally.

##### Structures

```SQL
mysql> desc memory_global_total;
+-----------------+------+------+-----+---------+-------+
| Field           | Type | Null | Key | Default | Extra |
+-----------------+------+------+-----+---------+-------+
| total_allocated | text | YES  |     | NULL    |       |
+-----------------+------+------+-----+---------+-------+
1 row in set (0.07 sec)

mysql> desc x$memory_global_total;
+-----------------+---------------+------+-----+---------+-------+
| Field           | Type          | Null | Key | Default | Extra |
+-----------------+---------------+------+-----+---------+-------+
| total_allocated | decimal(41,0) | YES  |     | NULL    |       |
+-----------------+---------------+------+-----+---------+-------+
1 row in set (0.00 sec)
```

##### Example

```SQL
mysql> select * from memory_global_total;
+-----------------+
| total_allocated |
+-----------------+
| 458.44 MiB      |
+-----------------+
```

#### metrics

##### Description

Creates a union of the following information:

   *  performance_schema.global_status (information_schema.GLOBAL_STATUS in MySQL 5.6)
   *  information_schema.INNODB_METRICS
   *  Performance Schema global memory usage information (only in MySQL 5.7)
   *  Current time

In MySQL 5.7 it is required that performance_schema = ON, though there is no requirements to which
instruments and consumers that are enabled. See also the description of the Enabled column below.

For view has the following columns:

   * Variable_name: The name of the variable
   * Variable_value: The value of the variable
   * Type: The type of the variable. This will depend on the source, e.g. Global Status, InnoDB Metrics - ..., etc.
   * Enabled: Whether the variable is enabled or not. Possible values are 'YES', 'NO', 'PARTIAL'.
     PARTIAL is currently only supported for the memory usage variables and means some but not all of the memory/% instruments are enabled.

##### Structures

```SQL
mysql> DESC metrics;
+----------------+--------------+------+-----+---------+-------+
| Field          | Type         | Null | Key | Default | Extra |
+----------------+--------------+------+-----+---------+-------+
| Variable_name  | varchar(193) | YES  |     | NULL    |       |
| Variable_value | text         | YES  |     | NULL    |       |
| Type           | varchar(210) | YES  |     | NULL    |       |
| Enabled        | varchar(7)   | NO   |     |         |       |
+----------------+--------------+------+-----+---------+-------+
4 rows in set (0.00 sec)

mysq> DESC metrics_56;
+----------------+--------------+------+-----+---------+-------+
| Field          | Type         | Null | Key | Default | Extra |
+----------------+--------------+------+-----+---------+-------+
| Variable_name  | varchar(193) | YES  |     | NULL    |       |
| Variable_value | text         | YES  |     | NULL    |       |
| Type           | varchar(210) | YES  |     | NULL    |       |
| Enabled        | varchar(7)   | NO   |     |         |       |
+----------------+--------------+------+-----+---------+-------+
4 rows in set (0.01 sec)
```

##### Example

```SQL
mysql> SELECT * FROM metrics;
+-----------------------------------------------+-------------------------...+--------------------------------------+---------+
| Variable_name                                 | Variable_value          ...| Type                                 | Enabled |
+-----------------------------------------------+-------------------------...+--------------------------------------+---------+
| aborted_clients                               | 0                       ...| Global Status                        | YES     |
| aborted_connects                              | 0                       ...| Global Status                        | YES     |
| binlog_cache_disk_use                         | 0                       ...| Global Status                        | YES     |
| binlog_cache_use                              | 0                       ...| Global Status                        | YES     |
| binlog_stmt_cache_disk_use                    | 0                       ...| Global Status                        | YES     |
| binlog_stmt_cache_use                         | 0                       ...| Global Status                        | YES     |
| bytes_received                                | 217081                  ...| Global Status                        | YES     |
| bytes_sent                                    | 27257                   ...| Global Status                        | YES     |
...
| innodb_rwlock_x_os_waits                      | 0                       ...| InnoDB Metrics - server              | YES     |
| innodb_rwlock_x_spin_rounds                   | 2723                    ...| InnoDB Metrics - server              | YES     |
| innodb_rwlock_x_spin_waits                    | 1                       ...| InnoDB Metrics - server              | YES     |
| trx_active_transactions                       | 0                       ...| InnoDB Metrics - transaction         | NO      |
...
| trx_rseg_current_size                         | 0                       ...| InnoDB Metrics - transaction         | NO      |
| trx_rseg_history_len                          | 4                       ...| InnoDB Metrics - transaction         | YES     |
| trx_rw_commits                                | 0                       ...| InnoDB Metrics - transaction         | NO      |
| trx_undo_slots_cached                         | 0                       ...| InnoDB Metrics - transaction         | NO      |
| trx_undo_slots_used                           | 0                       ...| InnoDB Metrics - transaction         | NO      |
| memory_current_allocated                      | 138244216               ...| Performance Schema                   | PARTIAL |
| memory_total_allocated                        | 138244216               ...| Performance Schema                   | PARTIAL |
| NOW()                                         | 2015-05-31 13:27:50.382 ...| System Time                          | YES     |
| UNIX_TIMESTAMP()                              | 1433042870.382          ...| System Time                          | YES     |
+-----------------------------------------------+-------------------------...+--------------------------------------+---------+
412 rows in set (0.02 sec)
```

#### processlist / x$processlist

##### Description

A detailed non-blocking processlist view to replace [INFORMATION_SCHEMA. | SHOW FULL] PROCESSLIST.

Performs less locking than the legacy sources, whilst giving extra information.

The output includes both background threads and user connections by default.  See also `session` / `x$session`
for a view that contains only user session information.

##### Structures (5.7)

```SQL
mysql> desc processlist;
+------------------------+------------------------------------------+------+-----+---------+-------+
| Field                  | Type                                     | Null | Key | Default | Extra |
+------------------------+------------------------------------------+------+-----+---------+-------+
| thd_id                 | bigint(20) unsigned                      | NO   |     | NULL    |       |
| conn_id                | bigint(20) unsigned                      | YES  |     | NULL    |       |
| user                   | varchar(128)                             | YES  |     | NULL    |       |
| db                     | varchar(64)                              | YES  |     | NULL    |       |
| command                | varchar(16)                              | YES  |     | NULL    |       |
| state                  | varchar(64)                              | YES  |     | NULL    |       |
| time                   | bigint(20)                               | YES  |     | NULL    |       |
| current_statement      | longtext                                 | YES  |     | NULL    |       |
| statement_latency      | text                                     | YES  |     | NULL    |       |
| progress               | decimal(26,2)                            | YES  |     | NULL    |       |
| lock_latency           | text                                     | YES  |     | NULL    |       |
| rows_examined          | bigint(20) unsigned                      | YES  |     | NULL    |       |
| rows_sent              | bigint(20) unsigned                      | YES  |     | NULL    |       |
| rows_affected          | bigint(20) unsigned                      | YES  |     | NULL    |       |
| tmp_tables             | bigint(20) unsigned                      | YES  |     | NULL    |       |
| tmp_disk_tables        | bigint(20) unsigned                      | YES  |     | NULL    |       |
| full_scan              | varchar(3)                               | NO   |     |         |       |
| last_statement         | longtext                                 | YES  |     | NULL    |       |
| last_statement_latency | text                                     | YES  |     | NULL    |       |
| current_memory         | text                                     | YES  |     | NULL    |       |
| last_wait              | varchar(128)                             | YES  |     | NULL    |       |
| last_wait_latency      | text                                     | YES  |     | NULL    |       |
| source                 | varchar(64)                              | YES  |     | NULL    |       |
| trx_latency            | text                                     | YES  |     | NULL    |       |
| trx_state              | enum('ACTIVE','COMMITTED','ROLLED BACK') | YES  |     | NULL    |       |
| trx_autocommit         | enum('YES','NO')                         | YES  |     | NULL    |       |
| pid                    | varchar(1024)                            | YES  |     | NULL    |       |
| program_name           | varchar(1024)                            | YES  |     | NULL    |       |
+------------------------+------------------------------------------+------+-----+---------+-------+
28 rows in set (0.04 sec)

mysql> desc x$processlist;
+------------------------+------------------------------------------+------+-----+---------+-------+
| Field                  | Type                                     | Null | Key | Default | Extra |
+------------------------+------------------------------------------+------+-----+---------+-------+
| thd_id                 | bigint(20) unsigned                      | NO   |     | NULL    |       |
| conn_id                | bigint(20) unsigned                      | YES  |     | NULL    |       |
| user                   | varchar(128)                             | YES  |     | NULL    |       |
| db                     | varchar(64)                              | YES  |     | NULL    |       |
| command                | varchar(16)                              | YES  |     | NULL    |       |
| state                  | varchar(64)                              | YES  |     | NULL    |       |
| time                   | bigint(20)                               | YES  |     | NULL    |       |
| current_statement      | longtext                                 | YES  |     | NULL    |       |
| statement_latency      | bigint(20) unsigned                      | YES  |     | NULL    |       |
| progress               | decimal(26,2)                            | YES  |     | NULL    |       |
| lock_latency           | bigint(20) unsigned                      | YES  |     | NULL    |       |
| rows_examined          | bigint(20) unsigned                      | YES  |     | NULL    |       |
| rows_sent              | bigint(20) unsigned                      | YES  |     | NULL    |       |
| rows_affected          | bigint(20) unsigned                      | YES  |     | NULL    |       |
| tmp_tables             | bigint(20) unsigned                      | YES  |     | NULL    |       |
| tmp_disk_tables        | bigint(20) unsigned                      | YES  |     | NULL    |       |
| full_scan              | varchar(3)                               | NO   |     |         |       |
| last_statement         | longtext                                 | YES  |     | NULL    |       |
| last_statement_latency | bigint(20) unsigned                      | YES  |     | NULL    |       |
| current_memory         | decimal(41,0)                            | YES  |     | NULL    |       |
| last_wait              | varchar(128)                             | YES  |     | NULL    |       |
| last_wait_latency      | varchar(20)                              | YES  |     | NULL    |       |
| source                 | varchar(64)                              | YES  |     | NULL    |       |
| trx_latency            | bigint(20) unsigned                      | YES  |     | NULL    |       |
| trx_state              | enum('ACTIVE','COMMITTED','ROLLED BACK') | YES  |     | NULL    |       |
| trx_autocommit         | enum('YES','NO')                         | YES  |     | NULL    |       |
| pid                    | varchar(1024)                            | YES  |     | NULL    |       |
| program_name           | varchar(1024)                            | YES  |     | NULL    |       |
+------------------------+------------------------------------------+------+-----+---------+-------+
28 rows in set (0.01 sec)
```

##### Example

```SQL
mysql> select * from sys.processlist where conn_id is not null and command != 'daemon' and conn_id != connection_id()\G
*************************** 1. row ***************************
                thd_id: 44524
               conn_id: 44502
                  user: msandbox@localhost
                    db: test
               command: Query
                 state: alter table (flush)
                  time: 18
     current_statement: alter table t1 add column g int
     statement_latency: 18.45 s
              progress: 98.84
          lock_latency: 265.43 ms
         rows_examined: 0
             rows_sent: 0
         rows_affected: 0
            tmp_tables: 0
       tmp_disk_tables: 0
             full_scan: NO
        last_statement: NULL
last_statement_latency: NULL
        current_memory: 664.06 KiB
             last_wait: wait/io/file/innodb/innodb_data_file
     last_wait_latency: 1.07 us
                source: fil0fil.cc:5146
           trx_latency: NULL
             trx_state: NULL
        trx_autocommit: NULL
                   pid: 4212
          program_name: mysql
```

#### ps_check_lost_instrumentation

##### Description

Used to check whether Performance Schema is not able to monitor all runtime data - only returns variables that have lost instruments

##### Structure

```SQL
mysql> desc ps_check_lost_instrumentation;
+----------------+---------------+------+-----+---------+-------+
| Field          | Type          | Null | Key | Default | Extra |
+----------------+---------------+------+-----+---------+-------+
| variable_name  | varchar(64)   | NO   |     |         |       |
| variable_value | varchar(1024) | YES  |     | NULL    |       |
+----------------+---------------+------+-----+---------+-------+
2 rows in set (0.09 sec)
```

##### Example

```SQL
mysql> select * from ps_check_lost_instrumentation;
+----------------------------------------+----------------+
| variable_name                          | variable_value |
+----------------------------------------+----------------+
| Performance_schema_file_handles_lost   | 101223         |
| Performance_schema_file_instances_lost | 1231           |
+----------------------------------------+----------------+
```

#### schema_auto_increment_columns

##### Description

Present current auto_increment usage/capacity in all tables.

##### Structures

```SQL
mysql> desc schema_auto_increment_columns;
+----------------------+------------------------+------+-----+---------+-------+
| Field                | Type                   | Null | Key | Default | Extra |
+----------------------+------------------------+------+-----+---------+-------+
| table_schema         | varchar(64)            | NO   |     |         |       |
| table_name           | varchar(64)            | NO   |     |         |       |
| column_name          | varchar(64)            | NO   |     |         |       |
| data_type            | varchar(64)            | NO   |     |         |       |
| column_type          | longtext               | NO   |     | NULL    |       |
| is_signed            | int(1)                 | NO   |     | 0       |       |
| is_unsigned          | int(1)                 | NO   |     | 0       |       |
| max_value            | bigint(21) unsigned    | YES  |     | NULL    |       |
| auto_increment       | bigint(21) unsigned    | YES  |     | NULL    |       |
| auto_increment_ratio | decimal(25,4) unsigned | YES  |     | NULL    |       |
+----------------------+------------------------+------+-----+---------+-------+
```

##### Example

```SQL
mysql> select * from schema_auto_increment_columns limit 5;
+-------------------+-------------------+-------------+-----------+-------------+-----------+-------------+---------------------+----------------+----------------------+
| table_schema      | table_name        | column_name | data_type | column_type | is_signed | is_unsigned | max_value           | auto_increment | auto_increment_ratio |
+-------------------+-------------------+-------------+-----------+-------------+-----------+-------------+---------------------+----------------+----------------------+
| test              | t1                | i           | tinyint   | tinyint(4)  |         1 |           0 |                 127 |             34 |               0.2677 |
| mem__advisor_text | template_meta     | hib_id      | int       | int(11)     |         1 |           0 |          2147483647 |            516 |               0.0000 |
| mem__advisors     | advisor_schedules | schedule_id | int       | int(11)     |         1 |           0 |          2147483647 |            249 |               0.0000 |
| mem__advisors     | app_identity_path | hib_id      | int       | int(11)     |         1 |           0 |          2147483647 |            251 |               0.0000 |
| mem__bean_config  | plists            | id          | bigint    | bigint(20)  |         1 |           0 | 9223372036854775807 |              1 |               0.0000 |
+-------------------+-------------------+-------------+-----------+-------------+-----------+-------------+---------------------+----------------+----------------------+
```

#### schema_index_statistics / x$schema_index_statistics

##### Description

Statistics around indexes.

Ordered by the total wait time descending - top indexes are most contended.

##### Structures

```SQL
mysql> desc schema_index_statistics;
+----------------+---------------------+------+-----+---------+-------+
| Field          | Type                | Null | Key | Default | Extra |
+----------------+---------------------+------+-----+---------+-------+
| table_schema   | varchar(64)         | YES  |     | NULL    |       |
| table_name     | varchar(64)         | YES  |     | NULL    |       |
| index_name     | varchar(64)         | YES  |     | NULL    |       |
| rows_selected  | bigint(20) unsigned | NO   |     | NULL    |       |
| select_latency | text                | YES  |     | NULL    |       |
| rows_inserted  | bigint(20) unsigned | NO   |     | NULL    |       |
| insert_latency | text                | YES  |     | NULL    |       |
| rows_updated   | bigint(20) unsigned | NO   |     | NULL    |       |
| update_latency | text                | YES  |     | NULL    |       |
| rows_deleted   | bigint(20) unsigned | NO   |     | NULL    |       |
| delete_latency | text                | YES  |     | NULL    |       |
+----------------+---------------------+------+-----+---------+-------+
11 rows in set (0.17 sec)

mysql> desc x$schema_index_statistics;
+----------------+---------------------+------+-----+---------+-------+
| Field          | Type                | Null | Key | Default | Extra |
+----------------+---------------------+------+-----+---------+-------+
| table_schema   | varchar(64)         | YES  |     | NULL    |       |
| table_name     | varchar(64)         | YES  |     | NULL    |       |
| index_name     | varchar(64)         | YES  |     | NULL    |       |
| rows_selected  | bigint(20) unsigned | NO   |     | NULL    |       |
| select_latency | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_inserted  | bigint(20) unsigned | NO   |     | NULL    |       |
| insert_latency | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_updated   | bigint(20) unsigned | NO   |     | NULL    |       |
| update_latency | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_deleted   | bigint(20) unsigned | NO   |     | NULL    |       |
| delete_latency | bigint(20) unsigned | NO   |     | NULL    |       |
+----------------+---------------------+------+-----+---------+-------+
11 rows in set (0.42 sec)
```

##### Example

```SQL
mysql> select * from schema_index_statistics limit 5;
+------------------+-------------+------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
| table_schema     | table_name  | index_name | rows_selected | select_latency | rows_inserted | insert_latency | rows_updated | update_latency | rows_deleted | delete_latency |
+------------------+-------------+------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
| mem              | mysqlserver | PRIMARY    |          6208 | 108.27 ms      |             0 | 0 ps           |         5470 | 1.47 s         |            0 | 0 ps           |
| mem              | innodb      | PRIMARY    |          4666 | 76.27 ms       |             0 | 0 ps           |         4454 | 571.47 ms      |            0 | 0 ps           |
| mem              | connection  | PRIMARY    |          1064 | 20.98 ms       |             0 | 0 ps           |         1064 | 457.30 ms      |            0 | 0 ps           |
| mem              | environment | PRIMARY    |          5566 | 151.17 ms      |             0 | 0 ps           |          694 | 252.57 ms      |            0 | 0 ps           |
| mem              | querycache  | PRIMARY    |          1698 | 27.99 ms       |             0 | 0 ps           |         1698 | 371.72 ms      |            0 | 0 ps           |
+------------------+-------------+------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
```

#### schema_object_overview

##### Description

Shows an overview of the types of objects within each schema

Note: On instances with a large numbers of objects, this could take some time to execute, and may not be recommended.

##### Structure

```SQL
mysql> desc schema_object_overview;
+-------------+-------------+------+-----+---------+-------+
| Field       | Type        | Null | Key | Default | Extra |
+-------------+-------------+------+-----+---------+-------+
| db          | varchar(64) | NO   |     |         |       |
| object_type | varchar(64) | NO   |     |         |       |
| count       | bigint(21)  | NO   |     | 0       |       |
+-------------+-------------+------+-----+---------+-------+
3 rows in set (0.08 sec)
```

##### Example

```SQL
mysql> select * from schema_object_overview;
+--------------------+---------------+-------+
| db                 | object_type   | count |
+--------------------+---------------+-------+
| information_schema | SYSTEM VIEW   |    60 |
| mysql              | BASE TABLE    |    31 |
| mysql              | INDEX (BTREE) |    69 |
| performance_schema | BASE TABLE    |    76 |
| sys                | BASE TABLE    |     1 |
| sys                | FUNCTION      |    12 |
| sys                | INDEX (BTREE) |     1 |
| sys                | PROCEDURE     |    22 |
| sys                | TRIGGER       |     2 |
| sys                | VIEW          |    91 |
+--------------------+---------------+-------+
10 rows in set (1.58 sec)
```

#### schema_table_statistics / x$schema_table_statistics

##### Description

Statistics around tables.

Ordered by the total wait time descending - top tables are most contended.

Also includes the helper view (used by schema_table_statistics_with_buffer as well):

* x$ps_schema_table_statistics_io

##### Structures

```SQL
mysql> desc schema_table_statistics;
+-------------------+---------------------+------+-----+---------+-------+
| Field             | Type                | Null | Key | Default | Extra |
+-------------------+---------------------+------+-----+---------+-------+
| table_schema      | varchar(64)         | YES  |     | NULL    |       |
| table_name        | varchar(64)         | YES  |     | NULL    |       |
| total_latency     | text                | YES  |     | NULL    |       |
| rows_fetched      | bigint(20) unsigned | NO   |     | NULL    |       |
| fetch_latency     | text                | YES  |     | NULL    |       |
| rows_inserted     | bigint(20) unsigned | NO   |     | NULL    |       |
| insert_latency    | text                | YES  |     | NULL    |       |
| rows_updated      | bigint(20) unsigned | NO   |     | NULL    |       |
| update_latency    | text                | YES  |     | NULL    |       |
| rows_deleted      | bigint(20) unsigned | NO   |     | NULL    |       |
| delete_latency    | text                | YES  |     | NULL    |       |
| io_read_requests  | decimal(42,0)       | YES  |     | NULL    |       |
| io_read           | text                | YES  |     | NULL    |       |
| io_read_latency   | text                | YES  |     | NULL    |       |
| io_write_requests | decimal(42,0)       | YES  |     | NULL    |       |
| io_write          | text                | YES  |     | NULL    |       |
| io_write_latency  | text                | YES  |     | NULL    |       |
| io_misc_requests  | decimal(42,0)       | YES  |     | NULL    |       |
| io_misc_latency   | text                | YES  |     | NULL    |       |
+-------------------+---------------------+------+-----+---------+-------+
19 rows in set (0.12 sec)

mysql> desc x$schema_table_statistics;
+-------------------+---------------------+------+-----+---------+-------+
| Field             | Type                | Null | Key | Default | Extra |
+-------------------+---------------------+------+-----+---------+-------+
| table_schema      | varchar(64)         | YES  |     | NULL    |       |
| table_name        | varchar(64)         | YES  |     | NULL    |       |
| total_latency     | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_fetched      | bigint(20) unsigned | NO   |     | NULL    |       |
| fetch_latency     | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_inserted     | bigint(20) unsigned | NO   |     | NULL    |       |
| insert_latency    | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_updated      | bigint(20) unsigned | NO   |     | NULL    |       |
| update_latency    | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_deleted      | bigint(20) unsigned | NO   |     | NULL    |       |
| delete_latency    | bigint(20) unsigned | NO   |     | NULL    |       |
| io_read_requests  | decimal(42,0)       | YES  |     | NULL    |       |
| io_read           | decimal(41,0)       | YES  |     | NULL    |       |
| io_read_latency   | decimal(42,0)       | YES  |     | NULL    |       |
| io_write_requests | decimal(42,0)       | YES  |     | NULL    |       |
| io_write          | decimal(41,0)       | YES  |     | NULL    |       |
| io_write_latency  | decimal(42,0)       | YES  |     | NULL    |       |
| io_misc_requests  | decimal(42,0)       | YES  |     | NULL    |       |
| io_misc_latency   | decimal(42,0)       | YES  |     | NULL    |       |
+-------------------+---------------------+------+-----+---------+-------+
19 rows in set (0.13 sec)

mysql> desc x$ps_schema_table_statistics_io;
+---------------------------+---------------+------+-----+---------+-------+
| Field                     | Type          | Null | Key | Default | Extra |
+---------------------------+---------------+------+-----+---------+-------+
| table_schema              | varchar(64)   | YES  |     | NULL    |       |
| table_name                | varchar(64)   | YES  |     | NULL    |       |
| count_read                | decimal(42,0) | YES  |     | NULL    |       |
| sum_number_of_bytes_read  | decimal(41,0) | YES  |     | NULL    |       |
| sum_timer_read            | decimal(42,0) | YES  |     | NULL    |       |
| count_write               | decimal(42,0) | YES  |     | NULL    |       |
| sum_number_of_bytes_write | decimal(41,0) | YES  |     | NULL    |       |
| sum_timer_write           | decimal(42,0) | YES  |     | NULL    |       |
| count_misc                | decimal(42,0) | YES  |     | NULL    |       |
| sum_timer_misc            | decimal(42,0) | YES  |     | NULL    |       |
+---------------------------+---------------+------+-----+---------+-------+
10 rows in set (0.10 sec)
```

##### Example

```SQL
mysql> select * from schema_table_statistics\G
*************************** 1. row ***************************
     table_schema: sys
       table_name: sys_config
    total_latency: 0 ps
     rows_fetched: 0
    fetch_latency: 0 ps
    rows_inserted: 0
   insert_latency: 0 ps
     rows_updated: 0
   update_latency: 0 ps
     rows_deleted: 0
   delete_latency: 0 ps
 io_read_requests: 8
          io_read: 2.28 KiB
  io_read_latency: 727.32 us
io_write_requests: 0
         io_write: 0 bytes
 io_write_latency: 0 ps
 io_misc_requests: 10
  io_misc_latency: 126.88 us
```

#### schema_redundant_indexes / x$schema_flattened_keys

##### Description

Shows indexes which are made redundant (or duplicate) by other (dominant) keys.

Also includes the the helper view `x$schema_flattened_keys`.

##### Structures

```SQL
mysql> desc sys.schema_redundant_indexes;
+----------------------------+--------------+------+-----+---------+-------+
| Field                      | Type         | Null | Key | Default | Extra |
+----------------------------+--------------+------+-----+---------+-------+
| table_schema               | varchar(64)  | NO   |     |         |       |
| table_name                 | varchar(64)  | NO   |     |         |       |
| redundant_index_name       | varchar(64)  | NO   |     |         |       |
| redundant_index_columns    | text         | YES  |     | NULL    |       |
| redundant_index_non_unique | bigint(1)    | YES  |     | NULL    |       |
| dominant_index_name        | varchar(64)  | NO   |     |         |       |
| dominant_index_columns     | text         | YES  |     | NULL    |       |
| dominant_index_non_unique  | bigint(1)    | YES  |     | NULL    |       |
| subpart_exists             | int(1)       | NO   |     | 0       |       |
| sql_drop_index             | varchar(223) | YES  |     | NULL    |       |
+----------------------------+--------------+------+-----+---------+-------+
10 rows in set (0.00 sec)

mysql> desc sys.x$schema_flattened_keys;
+----------------+-------------+------+-----+---------+-------+
| Field          | Type        | Null | Key | Default | Extra |
+----------------+-------------+------+-----+---------+-------+
| table_schema   | varchar(64) | NO   |     |         |       |
| table_name     | varchar(64) | NO   |     |         |       |
| index_name     | varchar(64) | NO   |     |         |       |
| non_unique     | bigint(1)   | YES  |     | NULL    |       |
| subpart_exists | bigint(1)   | YES  |     | NULL    |       |
| index_columns  | text        | YES  |     | NULL    |       |
+----------------+-------------+------+-----+---------+-------+
6 rows in set (0.00 sec)
```

##### Example

```SQL
mysql> select * from sys.schema_redundant_indexes\G
*************************** 1. row ***************************
              table_schema: test
                table_name: rkey
      redundant_index_name: j
   redundant_index_columns: j
redundant_index_non_unique: 1
       dominant_index_name: j_2
    dominant_index_columns: j,k
 dominant_index_non_unique: 1
            subpart_exists: 0
            sql_drop_index: ALTER TABLE `test`.`rkey` DROP INDEX `j`
1 row in set (0.20 sec)

mysql> SHOW CREATE TABLE test.rkey\G
*************************** 1. row ***************************
       Table: rkey
Create Table: CREATE TABLE `rkey` (
  `i` int(11) NOT NULL,
  `j` int(11) DEFAULT NULL,
  `k` int(11) DEFAULT NULL,
  PRIMARY KEY (`i`),
  KEY `j` (`j`),
  KEY `j_2` (`j`,`k`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1
1 row in set (0.06 sec)
```

#### schema_table_lock_waits / x$schema_table_lock_waits

##### Description

Shows sessions that are blocked waiting on table metadata locks, and who is blocking them.

##### Structures

```SQL
mysql> desc schema_table_lock_waits;
+------------------------------+---------------------+------+-----+---------+-------+
| Field                        | Type                | Null | Key | Default | Extra |
+------------------------------+---------------------+------+-----+---------+-------+
| object_schema                | varchar(64)         | YES  |     | NULL    |       |
| object_name                  | varchar(64)         | YES  |     | NULL    |       |
| waiting_thread_id            | bigint(20) unsigned | NO   |     | NULL    |       |
| waiting_pid                  | bigint(20) unsigned | YES  |     | NULL    |       |
| waiting_account              | text                | YES  |     | NULL    |       |
| waiting_lock_type            | varchar(32)         | NO   |     | NULL    |       |
| waiting_lock_duration        | varchar(32)         | NO   |     | NULL    |       |
| waiting_query                | longtext            | YES  |     | NULL    |       |
| waiting_query_secs           | bigint(20)          | YES  |     | NULL    |       |
| waiting_query_rows_affected  | bigint(20) unsigned | YES  |     | NULL    |       |
| waiting_query_rows_examined  | bigint(20) unsigned | YES  |     | NULL    |       |
| blocking_thread_id           | bigint(20) unsigned | NO   |     | NULL    |       |
| blocking_pid                 | bigint(20) unsigned | YES  |     | NULL    |       |
| blocking_account             | text                | YES  |     | NULL    |       |
| blocking_lock_type           | varchar(32)         | NO   |     | NULL    |       |
| blocking_lock_duration       | varchar(32)         | NO   |     | NULL    |       |
| sql_kill_blocking_query      | varchar(31)         | YES  |     | NULL    |       |
| sql_kill_blocking_connection | varchar(25)         | YES  |     | NULL    |       |
+------------------------------+---------------------+------+-----+---------+-------+
18 rows in set (0.15 sec)

mysql> desc x$schema_table_lock_waits;
+------------------------------+---------------------+------+-----+---------+-------+
| Field                        | Type                | Null | Key | Default | Extra |
+------------------------------+---------------------+------+-----+---------+-------+
| object_schema                | varchar(64)         | YES  |     | NULL    |       |
| object_name                  | varchar(64)         | YES  |     | NULL    |       |
| waiting_thread_id            | bigint(20) unsigned | NO   |     | NULL    |       |
| waiting_pid                  | bigint(20) unsigned | YES  |     | NULL    |       |
| waiting_account              | text                | YES  |     | NULL    |       |
| waiting_lock_type            | varchar(32)         | NO   |     | NULL    |       |
| waiting_lock_duration        | varchar(32)         | NO   |     | NULL    |       |
| waiting_query                | longtext            | YES  |     | NULL    |       |
| waiting_query_secs           | bigint(20)          | YES  |     | NULL    |       |
| waiting_query_rows_affected  | bigint(20) unsigned | YES  |     | NULL    |       |
| waiting_query_rows_examined  | bigint(20) unsigned | YES  |     | NULL    |       |
| blocking_thread_id           | bigint(20) unsigned | NO   |     | NULL    |       |
| blocking_pid                 | bigint(20) unsigned | YES  |     | NULL    |       |
| blocking_account             | text                | YES  |     | NULL    |       |
| blocking_lock_type           | varchar(32)         | NO   |     | NULL    |       |
| blocking_lock_duration       | varchar(32)         | NO   |     | NULL    |       |
| sql_kill_blocking_query      | varchar(31)         | YES  |     | NULL    |       |
| sql_kill_blocking_connection | varchar(25)         | YES  |     | NULL    |       |
+------------------------------+---------------------+------+-----+---------+-------+
18 rows in set (0.03 sec)
```

##### Example

```SQL
mysql> select * from sys.schema_table_lock_waits\G
*************************** 1. row ***************************
               object_schema: test
                 object_name: t
           waiting_thread_id: 43
                 waiting_pid: 21
             waiting_account: msandbox@localhost
           waiting_lock_type: SHARED_UPGRADABLE
       waiting_lock_duration: TRANSACTION
               waiting_query: alter table test.t add foo int
          waiting_query_secs: 988
 waiting_query_rows_affected: 0
 waiting_query_rows_examined: 0
          blocking_thread_id: 42
                blocking_pid: 20
            blocking_account: msandbox@localhost
          blocking_lock_type: SHARED_NO_READ_WRITE
      blocking_lock_duration: TRANSACTION
     sql_kill_blocking_query: KILL QUERY 20
sql_kill_blocking_connection: KILL 20
```

#### schema_table_statistics_with_buffer / x$schema_table_statistics_with_buffer

##### Description

Statistics around tables.

Ordered by the total wait time descending - top tables are most contended.

More statistics such as caching stats for the InnoDB buffer pool with InnoDB tables

Uses the x$ps_schema_table_statistics_io helper view from schema_table_statistics.

##### Structures

```SQL
mysql> desc schema_table_statistics_with_buffer;
+----------------------------+---------------------+------+-----+---------+-------+
| Field                      | Type                | Null | Key | Default | Extra |
+----------------------------+---------------------+------+-----+---------+-------+
| table_schema               | varchar(64)         | YES  |     | NULL    |       |
| table_name                 | varchar(64)         | YES  |     | NULL    |       |
| rows_fetched               | bigint(20) unsigned | NO   |     | NULL    |       |
| fetch_latency              | text                | YES  |     | NULL    |       |
| rows_inserted              | bigint(20) unsigned | NO   |     | NULL    |       |
| insert_latency             | text                | YES  |     | NULL    |       |
| rows_updated               | bigint(20) unsigned | NO   |     | NULL    |       |
| update_latency             | text                | YES  |     | NULL    |       |
| rows_deleted               | bigint(20) unsigned | NO   |     | NULL    |       |
| delete_latency             | text                | YES  |     | NULL    |       |
| io_read_requests           | decimal(42,0)       | YES  |     | NULL    |       |
| io_read                    | text                | YES  |     | NULL    |       |
| io_read_latency            | text                | YES  |     | NULL    |       |
| io_write_requests          | decimal(42,0)       | YES  |     | NULL    |       |
| io_write                   | text                | YES  |     | NULL    |       |
| io_write_latency           | text                | YES  |     | NULL    |       |
| io_misc_requests           | decimal(42,0)       | YES  |     | NULL    |       |
| io_misc_latency            | text                | YES  |     | NULL    |       |
| innodb_buffer_allocated    | text                | YES  |     | NULL    |       |
| innodb_buffer_data         | text                | YES  |     | NULL    |       |
| innodb_buffer_free         | text                | YES  |     | NULL    |       |
| innodb_buffer_pages        | bigint(21)          | YES  |     | 0       |       |
| innodb_buffer_pages_hashed | bigint(21)          | YES  |     | 0       |       |
| innodb_buffer_pages_old    | bigint(21)          | YES  |     | 0       |       |
| innodb_buffer_rows_cached  | decimal(44,0)       | YES  |     | 0       |       |
+----------------------------+---------------------+------+-----+---------+-------+
25 rows in set (0.05 sec)

mysql> desc x$schema_table_statistics_with_buffer;
+----------------------------+---------------------+------+-----+---------+-------+
| Field                      | Type                | Null | Key | Default | Extra |
+----------------------------+---------------------+------+-----+---------+-------+
| table_schema               | varchar(64)         | YES  |     | NULL    |       |
| table_name                 | varchar(64)         | YES  |     | NULL    |       |
| rows_fetched               | bigint(20) unsigned | NO   |     | NULL    |       |
| fetch_latency              | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_inserted              | bigint(20) unsigned | NO   |     | NULL    |       |
| insert_latency             | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_updated               | bigint(20) unsigned | NO   |     | NULL    |       |
| update_latency             | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_deleted               | bigint(20) unsigned | NO   |     | NULL    |       |
| delete_latency             | bigint(20) unsigned | NO   |     | NULL    |       |
| io_read_requests           | decimal(42,0)       | YES  |     | NULL    |       |
| io_read                    | decimal(41,0)       | YES  |     | NULL    |       |
| io_read_latency            | decimal(42,0)       | YES  |     | NULL    |       |
| io_write_requests          | decimal(42,0)       | YES  |     | NULL    |       |
| io_write                   | decimal(41,0)       | YES  |     | NULL    |       |
| io_write_latency           | decimal(42,0)       | YES  |     | NULL    |       |
| io_misc_requests           | decimal(42,0)       | YES  |     | NULL    |       |
| io_misc_latency            | decimal(42,0)       | YES  |     | NULL    |       |
| innodb_buffer_allocated    | decimal(43,0)       | YES  |     | NULL    |       |
| innodb_buffer_data         | decimal(43,0)       | YES  |     | NULL    |       |
| innodb_buffer_free         | decimal(44,0)       | YES  |     | NULL    |       |
| innodb_buffer_pages        | bigint(21)          | YES  |     | 0       |       |
| innodb_buffer_pages_hashed | bigint(21)          | YES  |     | 0       |       |
| innodb_buffer_pages_old    | bigint(21)          | YES  |     | 0       |       |
| innodb_buffer_rows_cached  | decimal(44,0)       | YES  |     | 0       |       |
+----------------------------+---------------------+------+-----+---------+-------+
25 rows in set (0.17 sec)
```

##### Example

```SQL
mysql> select * from schema_table_statistics_with_buffer limit 1\G
*************************** 1. row ***************************
                 table_schema: mem
                   table_name: mysqlserver
                 rows_fetched: 27087
                fetch_latency: 442.72 ms
                rows_inserted: 2
               insert_latency: 185.04 us
                 rows_updated: 5096
               update_latency: 1.39 s
                 rows_deleted: 0
               delete_latency: 0 ps
             io_read_requests: 2565
                io_read_bytes: 1121627
              io_read_latency: 10.07 ms
            io_write_requests: 1691
               io_write_bytes: 128383
             io_write_latency: 14.17 ms
             io_misc_requests: 2698
              io_misc_latency: 433.66 ms
          innodb_buffer_pages: 19
   innodb_buffer_pages_hashed: 19
      innodb_buffer_pages_old: 19
innodb_buffer_bytes_allocated: 311296
     innodb_buffer_bytes_data: 1924
    innodb_buffer_rows_cached: 2
```

#### schema_tables_with_full_table_scans / x$schema_tables_with_full_table_scans

##### Description

Finds tables that are being accessed by full table scans ordering by the number of rows scanned descending.

##### Structures

```SQL
mysql> desc schema_tables_with_full_table_scans;
+-------------------+---------------------+------+-----+---------+-------+
| Field             | Type                | Null | Key | Default | Extra |
+-------------------+---------------------+------+-----+---------+-------+
| object_schema     | varchar(64)         | YES  |     | NULL    |       |
| object_name       | varchar(64)         | YES  |     | NULL    |       |
| rows_full_scanned | bigint(20) unsigned | NO   |     | NULL    |       |
| latency           | text                | YES  |     | NULL    |       |
+-------------------+---------------------+------+-----+---------+-------+
4 rows in set (0.02 sec)

mysql> desc x$schema_tables_with_full_table_scans;
+-------------------+---------------------+------+-----+---------+-------+
| Field             | Type                | Null | Key | Default | Extra |
+-------------------+---------------------+------+-----+---------+-------+
| object_schema     | varchar(64)         | YES  |     | NULL    |       |
| object_name       | varchar(64)         | YES  |     | NULL    |       |
| rows_full_scanned | bigint(20) unsigned | NO   |     | NULL    |       |
| latency           | bigint(20) unsigned | NO   |     | NULL    |       |
+-------------------+---------------------+------+-----+---------+-------+
4 rows in set (0.03 sec)
```

##### Example

```SQL
mysql> select * from schema_tables_with_full_table_scans limit 5;
+--------------------+--------------------------------+-------------------+-----------+
| object_schema      | object_name                    | rows_full_scanned | latency   |
+--------------------+--------------------------------+-------------------+-----------+
| mem30__instruments | fsstatistics                   |          10207042 | 13.10 s   |
| mem30__instruments | preparedstatementapidata       |            436428 | 973.27 ms |
| mem30__instruments | mysqlprocessactivity           |            411702 | 282.07 ms |
| mem30__instruments | querycachequeriesincachedata   |            374011 | 767.15 ms |
| mem30__instruments | rowaccessesdata                |            322321 | 1.55 s    |
+--------------------+--------------------------------+-------------------+-----------+
```

#### schema_unused_indexes

##### Description

Finds indexes that have had no events against them (and hence, no usage).

To trust whether the data from this view is representative of your workload, you should ensure that the server has been up for a representative amount of time before using it.

PRIMARY (key) indexes are ignored.

##### Structure

```SQL
mysql> desc schema_unused_indexes;
+---------------+-------------+------+-----+---------+-------+
| Field         | Type        | Null | Key | Default | Extra |
+---------------+-------------+------+-----+---------+-------+
| object_schema | varchar(64) | YES  |     | NULL    |       |
| object_name   | varchar(64) | YES  |     | NULL    |       |
| index_name    | varchar(64) | YES  |     | NULL    |       |
+---------------+-------------+------+-----+---------+-------+
3 rows in set (0.09 sec)
```

##### Example

```SQL
mysql> select * from schema_unused_indexes limit 5;
+--------------------+---------------------+--------------------+
| object_schema      | object_name         | index_name         |
+--------------------+---------------------+--------------------+
| mem30__bean_config | plists              | path               |
| mem30__config      | group_selections    | name               |
| mem30__config      | notification_groups | name               |
| mem30__config      | user_form_defaults  | FKC1AEF1F9E7EE2CFB |
| mem30__enterprise  | whats_new_entries   | entryId            |
+--------------------+---------------------+--------------------+
```

#### session / x$session

##### Description

A detailed non-blocking processlist view to replace [INFORMATION_SCHEMA. | SHOW FULL] PROCESSLIST.

Performs less locking than the legacy sources, whilst giving extra information.

The output of this view is restricted to threads from user sessions.  See also processlist / x$processlist which contains both user and background threads.

##### Structures (5.7)

```SQL
mysql> desc session;
+------------------------+------------------------------------------+------+-----+---------+-------+
| Field                  | Type                                     | Null | Key | Default | Extra |
+------------------------+------------------------------------------+------+-----+---------+-------+
| thd_id                 | bigint(20) unsigned                      | NO   |     | NULL    |       |
| conn_id                | bigint(20) unsigned                      | YES  |     | NULL    |       |
| user                   | varchar(128)                             | YES  |     | NULL    |       |
| db                     | varchar(64)                              | YES  |     | NULL    |       |
| command                | varchar(16)                              | YES  |     | NULL    |       |
| state                  | varchar(64)                              | YES  |     | NULL    |       |
| time                   | bigint(20)                               | YES  |     | NULL    |       |
| current_statement      | longtext                                 | YES  |     | NULL    |       |
| statement_latency      | text                                     | YES  |     | NULL    |       |
| progress               | decimal(26,2)                            | YES  |     | NULL    |       |
| lock_latency           | text                                     | YES  |     | NULL    |       |
| rows_examined          | bigint(20) unsigned                      | YES  |     | NULL    |       |
| rows_sent              | bigint(20) unsigned                      | YES  |     | NULL    |       |
| rows_affected          | bigint(20) unsigned                      | YES  |     | NULL    |       |
| tmp_tables             | bigint(20) unsigned                      | YES  |     | NULL    |       |
| tmp_disk_tables        | bigint(20) unsigned                      | YES  |     | NULL    |       |
| full_scan              | varchar(3)                               | NO   |     |         |       |
| last_statement         | longtext                                 | YES  |     | NULL    |       |
| last_statement_latency | text                                     | YES  |     | NULL    |       |
| current_memory         | text                                     | YES  |     | NULL    |       |
| last_wait              | varchar(128)                             | YES  |     | NULL    |       |
| last_wait_latency      | text                                     | YES  |     | NULL    |       |
| source                 | varchar(64)                              | YES  |     | NULL    |       |
| trx_latency            | text                                     | YES  |     | NULL    |       |
| trx_state              | enum('ACTIVE','COMMITTED','ROLLED BACK') | YES  |     | NULL    |       |
| trx_autocommit         | enum('YES','NO')                         | YES  |     | NULL    |       |
| pid                    | varchar(1024)                            | YES  |     | NULL    |       |
| program_name           | varchar(1024)                            | YES  |     | NULL    |       |
+------------------------+------------------------------------------+------+-----+---------+-------+
28 rows in set (0.00 sec)

mysql> desc x$session;
+------------------------+------------------------------------------+------+-----+---------+-------+
| Field                  | Type                                     | Null | Key | Default | Extra |
+------------------------+------------------------------------------+------+-----+---------+-------+
| thd_id                 | bigint(20) unsigned                      | NO   |     | NULL    |       |
| conn_id                | bigint(20) unsigned                      | YES  |     | NULL    |       |
| user                   | varchar(128)                             | YES  |     | NULL    |       |
| db                     | varchar(64)                              | YES  |     | NULL    |       |
| command                | varchar(16)                              | YES  |     | NULL    |       |
| state                  | varchar(64)                              | YES  |     | NULL    |       |
| time                   | bigint(20)                               | YES  |     | NULL    |       |
| current_statement      | longtext                                 | YES  |     | NULL    |       |
| statement_latency      | bigint(20) unsigned                      | YES  |     | NULL    |       |
| progress               | decimal(26,2)                            | YES  |     | NULL    |       |
| lock_latency           | bigint(20) unsigned                      | YES  |     | NULL    |       |
| rows_examined          | bigint(20) unsigned                      | YES  |     | NULL    |       |
| rows_sent              | bigint(20) unsigned                      | YES  |     | NULL    |       |
| rows_affected          | bigint(20) unsigned                      | YES  |     | NULL    |       |
| tmp_tables             | bigint(20) unsigned                      | YES  |     | NULL    |       |
| tmp_disk_tables        | bigint(20) unsigned                      | YES  |     | NULL    |       |
| full_scan              | varchar(3)                               | NO   |     |         |       |
| last_statement         | longtext                                 | YES  |     | NULL    |       |
| last_statement_latency | bigint(20) unsigned                      | YES  |     | NULL    |       |
| current_memory         | decimal(41,0)                            | YES  |     | NULL    |       |
| last_wait              | varchar(128)                             | YES  |     | NULL    |       |
| last_wait_latency      | varchar(20)                              | YES  |     | NULL    |       |
| source                 | varchar(64)                              | YES  |     | NULL    |       |
| trx_latency            | bigint(20) unsigned                      | YES  |     | NULL    |       |
| trx_state              | enum('ACTIVE','COMMITTED','ROLLED BACK') | YES  |     | NULL    |       |
| trx_autocommit         | enum('YES','NO')                         | YES  |     | NULL    |       |
| pid                    | varchar(1024)                            | YES  |     | NULL    |       |
| program_name           | varchar(1024)                            | YES  |     | NULL    |       |
+------------------------+------------------------------------------+------+-----+---------+-------+
28 rows in set (0.00 sec)
```

##### Example

```SQL
mysql> select * from sys.session\G
*************************** 1. row ***************************
                thd_id: 24
               conn_id: 2
                  user: root@localhost
                    db: sys
               command: Query
                 state: Sending data
                  time: 0
     current_statement: select * from sys.session
     statement_latency: 137.22 ms
              progress: NULL
          lock_latency: 33.75 ms
         rows_examined: 0
             rows_sent: 0
         rows_affected: 0
            tmp_tables: 4
       tmp_disk_tables: 1
             full_scan: YES
        last_statement: NULL
last_statement_latency: NULL
        current_memory: 3.26 MiB
             last_wait: wait/synch/mutex/innodb/file_format_max_mutex
     last_wait_latency: 64.09 ns
                source: trx0sys.cc:778
           trx_latency: 7.88 s
             trx_state: ACTIVE
        trx_autocommit: NO
                   pid: 4212
          program_name: mysql
```

#### session_ssl_status

##### Description

Shows SSL version, cipher and the count of re-used SSL sessions per connection

##### Structures

```SQL
mysql> desc sys.session_ssl_status;
+---------------------+---------------------+------+-----+---------+-------+
| Field               | Type                | Null | Key | Default | Extra |
+---------------------+---------------------+------+-----+---------+-------+
| thread_id           | bigint(20) unsigned | NO   |     | NULL    |       |
| ssl_version         | varchar(1024)       | YES  |     | NULL    |       |
| ssl_cipher          | varchar(1024)       | YES  |     | NULL    |       |
| ssl_sessions_reused | varchar(1024)       | YES  |     | NULL    |       |
+---------------------+---------------------+------+-----+---------+-------+
4 rows in set (0.00 sec)
```

##### Example

```SQL
mysql> select * from session_ssl_status;
+-----------+-------------+--------------------+---------------------+
| thread_id | ssl_version | ssl_cipher         | ssl_sessions_reused |
+-----------+-------------+--------------------+---------------------+
|        26 | TLSv1       | DHE-RSA-AES256-SHA | 0                   |
|        27 | TLSv1       | DHE-RSA-AES256-SHA | 0                   |
|        28 | TLSv1       | DHE-RSA-AES256-SHA | 0                   |
+-----------+-------------+--------------------+---------------------+
3 rows in set (0.00 sec)
```

#### statement_analysis / x$statement_analysis

##### Description

Lists a normalized statement view with aggregated statistics, mimics the MySQL Enterprise Monitor Query Analysis view, ordered by the total execution time per normalized statement

##### Structures

```SQL
mysql> desc statement_analysis;
+-------------------+---------------------+------+-----+---------------------+-------+
| Field             | Type                | Null | Key | Default             | Extra |
+-------------------+---------------------+------+-----+---------------------+-------+
| query             | longtext            | YES  |     | NULL                |       |
| db                | varchar(64)         | YES  |     | NULL                |       |
| full_scan         | varchar(1)          | NO   |     |                     |       |
| exec_count        | bigint(20) unsigned | NO   |     | NULL                |       |
| err_count         | bigint(20) unsigned | NO   |     | NULL                |       |
| warn_count        | bigint(20) unsigned | NO   |     | NULL                |       |
| total_latency     | text                | YES  |     | NULL                |       |
| max_latency       | text                | YES  |     | NULL                |       |
| avg_latency       | text                | YES  |     | NULL                |       |
| lock_latency      | text                | YES  |     | NULL                |       |
| rows_sent         | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_sent_avg     | decimal(21,0)       | NO   |     | 0                   |       |
| rows_examined     | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_examined_avg | decimal(21,0)       | NO   |     | 0                   |       |
| rows_affected     | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_affected_avg | decimal(21,0)       | NO   |     | 0                   |       |
| tmp_tables        | bigint(20) unsigned | NO   |     | NULL                |       |
| tmp_disk_tables   | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_sorted       | bigint(20) unsigned | NO   |     | NULL                |       |
| sort_merge_passes | bigint(20) unsigned | NO   |     | NULL                |       |
| digest            | varchar(32)         | YES  |     | NULL                |       |
| first_seen        | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| last_seen         | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
+-------------------+---------------------+------+-----+---------------------+-------+
23 rows in set (0.26 sec)

mysql> desc x$statement_analysis;
+-------------------+---------------------+------+-----+---------------------+-------+
| Field             | Type                | Null | Key | Default             | Extra |
+-------------------+---------------------+------+-----+---------------------+-------+
| query             | longtext            | YES  |     | NULL                |       |
| db                | varchar(64)         | YES  |     | NULL                |       |
| full_scan         | varchar(1)          | NO   |     |                     |       |
| exec_count        | bigint(20) unsigned | NO   |     | NULL                |       |
| err_count         | bigint(20) unsigned | NO   |     | NULL                |       |
| warn_count        | bigint(20) unsigned | NO   |     | NULL                |       |
| total_latency     | bigint(20) unsigned | NO   |     | NULL                |       |
| max_latency       | bigint(20) unsigned | NO   |     | NULL                |       |
| avg_latency       | bigint(20) unsigned | NO   |     | NULL                |       |
| lock_latency      | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_sent         | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_sent_avg     | decimal(21,0)       | NO   |     | 0                   |       |
| rows_examined     | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_examined_avg | decimal(21,0)       | NO   |     | 0                   |       |
| rows_affected     | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_affected_avg | decimal(21,0)       | NO   |     | 0                   |       |
| tmp_tables        | bigint(20) unsigned | NO   |     | NULL                |       |
| tmp_disk_tables   | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_sorted       | bigint(20) unsigned | NO   |     | NULL                |       |
| sort_merge_passes | bigint(20) unsigned | NO   |     | NULL                |       |
| digest            | varchar(32)         | YES  |     | NULL                |       |
| first_seen        | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| last_seen         | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
+-------------------+---------------------+------+-----+---------------------+-------+
23 rows in set (0.27 sec)
```

##### Example

```SQL
mysql> select * from statement_analysis limit 1\G
*************************** 1. row ***************************
            query: SELECT * FROM `schema_object_o ... MA` , `information_schema` ...
               db: sys
        full_scan: *
       exec_count: 2
        err_count: 0
       warn_count: 0
    total_latency: 16.75 s
      max_latency: 16.57 s
      avg_latency: 8.38 s
     lock_latency: 16.69 s
        rows_sent: 84
    rows_sent_avg: 42
    rows_examined: 20012
rows_examined_avg: 10006
    rows_affected: 0
rows_affected_avg: 0
       tmp_tables: 378
  tmp_disk_tables: 66
      rows_sorted: 168
sort_merge_passes: 0
           digest: 54f9bd520f0bbf15db0c2ed93386bec9
       first_seen: 2014-03-07 13:13:41
        last_seen: 2014-03-07 13:13:48
```

#### statements_with_errors_or_warnings / x$statements_with_errors_or_warnings

##### Description

Lists all normalized statements that have raised errors or warnings.

##### Structures

```SQL
mysql> desc statements_with_errors_or_warnings;
+-------------+---------------------+------+-----+---------------------+-------+
| Field       | Type                | Null | Key | Default             | Extra |
+-------------+---------------------+------+-----+---------------------+-------+
| query       | longtext            | YES  |     | NULL                |       |
| db          | varchar(64)         | YES  |     | NULL                |       |
| exec_count  | bigint(20) unsigned | NO   |     | NULL                |       |
| errors      | bigint(20) unsigned | NO   |     | NULL                |       |
| error_pct   | decimal(27,4)       | NO   |     | 0.0000              |       |
| warnings    | bigint(20) unsigned | NO   |     | NULL                |       |
| warning_pct | decimal(27,4)       | NO   |     | 0.0000              |       |
| first_seen  | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| last_seen   | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| digest      | varchar(32)         | YES  |     | NULL                |       |
+-------------+---------------------+------+-----+---------------------+-------+
10 rows in set (0.55 sec)

mysql> desc x$statements_with_errors_or_warnings;
+-------------+---------------------+------+-----+---------------------+-------+
| Field       | Type                | Null | Key | Default             | Extra |
+-------------+---------------------+------+-----+---------------------+-------+
| query       | longtext            | YES  |     | NULL                |       |
| db          | varchar(64)         | YES  |     | NULL                |       |
| exec_count  | bigint(20) unsigned | NO   |     | NULL                |       |
| errors      | bigint(20) unsigned | NO   |     | NULL                |       |
| error_pct   | decimal(27,4)       | NO   |     | 0.0000              |       |
| warnings    | bigint(20) unsigned | NO   |     | NULL                |       |
| warning_pct | decimal(27,4)       | NO   |     | 0.0000              |       |
| first_seen  | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| last_seen   | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| digest      | varchar(32)         | YES  |     | NULL                |       |
+-------------+---------------------+------+-----+---------------------+-------+
10 rows in set (0.25 sec)
```

##### Example

```SQL
mysql> select * from statements_with_errors_or_warnings LIMIT 1\G
*************************** 1. row ***************************
      query: CREATE OR REPLACE ALGORITHM =  ... _delete` AS `rows_deleted` ...
         db: sys
 exec_count: 2
     errors: 1
  error_pct: 50.0000
   warnings: 0
warning_pct: 0.0000
 first_seen: 2014-03-07 12:56:54
  last_seen: 2014-03-07 13:01:01
     digest: 943a788859e623d5f7798ba0ae0fd8a9
```

#### statements_with_full_table_scans / x$statements_with_full_table_scans

##### Description

Lists all normalized statements that use have done a full table scan ordered by number the percentage of times a full scan was done, then by the statement latency.

This view ignores SHOW statements, as these always cause a full table scan, and there is nothing that can be done about this.

##### Structures

```SQL
mysql> desc statements_with_full_table_scans;
+--------------------------+------------------------+------+-----+---------------------+-------+
| Field                    | Type                   | Null | Key | Default             | Extra |
+--------------------------+------------------------+------+-----+---------------------+-------+
| query                    | longtext               | YES  |     | NULL                |       |
| db                       | varchar(64)            | YES  |     | NULL                |       |
| exec_count               | bigint(20) unsigned    | NO   |     | NULL                |       |
| total_latency            | text                   | YES  |     | NULL                |       |
| no_index_used_count      | bigint(20) unsigned    | NO   |     | NULL                |       |
| no_good_index_used_count | bigint(20) unsigned    | NO   |     | NULL                |       |
| no_index_used_pct        | decimal(24,0)          | NO   |     | 0                   |       |
| rows_sent                | bigint(20) unsigned    | NO   |     | NULL                |       |
| rows_examined            | bigint(20) unsigned    | NO   |     | NULL                |       |
| rows_sent_avg            | decimal(21,0) unsigned | YES  |     | NULL                |       |
| rows_examined_avg        | decimal(21,0) unsigned | YES  |     | NULL                |       |
| first_seen               | timestamp              | NO   |     | 0000-00-00 00:00:00 |       |
| last_seen                | timestamp              | NO   |     | 0000-00-00 00:00:00 |       |
| digest                   | varchar(32)            | YES  |     | NULL                |       |
+--------------------------+------------------------+------+-----+---------------------+-------+
14 rows in set (0.04 sec)

mysql> desc x$statements_with_full_table_scans;
+--------------------------+------------------------+------+-----+---------------------+-------+
| Field                    | Type                   | Null | Key | Default             | Extra |
+--------------------------+------------------------+------+-----+---------------------+-------+
| query                    | longtext               | YES  |     | NULL                |       |
| db                       | varchar(64)            | YES  |     | NULL                |       |
| exec_count               | bigint(20) unsigned    | NO   |     | NULL                |       |
| total_latency            | bigint(20) unsigned    | NO   |     | NULL                |       |
| no_index_used_count      | bigint(20) unsigned    | NO   |     | NULL                |       |
| no_good_index_used_count | bigint(20) unsigned    | NO   |     | NULL                |       |
| no_index_used_pct        | decimal(24,0)          | NO   |     | 0                   |       |
| rows_sent                | bigint(20) unsigned    | NO   |     | NULL                |       |
| rows_examined            | bigint(20) unsigned    | NO   |     | NULL                |       |
| rows_sent_avg            | decimal(21,0) unsigned | YES  |     | NULL                |       |
| rows_examined_avg        | decimal(21,0) unsigned | YES  |     | NULL                |       |
| first_seen               | timestamp              | NO   |     | 0000-00-00 00:00:00 |       |
| last_seen                | timestamp              | NO   |     | 0000-00-00 00:00:00 |       |
| digest                   | varchar(32)            | YES  |     | NULL                |       |
+--------------------------+------------------------+------+-----+---------------------+-------+
14 rows in set (0.14 sec)
```

##### Example

```SQL
mysql> select * from statements_with_full_table_scans limit 1\G
*************************** 1. row ***************************
                   query: SELECT * FROM `schema_tables_w ... ex_usage` . `COUNT_READ` DESC
                      db: sys
              exec_count: 1
           total_latency: 88.20 ms
     no_index_used_count: 1
no_good_index_used_count: 0
       no_index_used_pct: 100
               rows_sent: 0
           rows_examined: 1501
           rows_sent_avg: 0
       rows_examined_avg: 1501
              first_seen: 2014-03-07 13:58:20
               last_seen: 2014-03-07 13:58:20
                  digest: 64baecd5c1e1e1651a6b92e55442a288
```

#### statements_with_runtimes_in_95th_percentile / x$statements_with_runtimes_in_95th_percentile

##### Description

Lists all statements whose average runtime, in microseconds, is in the top 95th percentile.

Also includes two helper views:

* x$ps_digest_avg_latency_distribution
* x$ps_digest_95th_percentile_by_avg_us

##### Structures

```SQL
mysql> desc statements_with_runtimes_in_95th_percentile;
+-------------------+---------------------+------+-----+---------------------+-------+
| Field             | Type                | Null | Key | Default             | Extra |
+-------------------+---------------------+------+-----+---------------------+-------+
| query             | longtext            | YES  |     | NULL                |       |
| db                | varchar(64)         | YES  |     | NULL                |       |
| full_scan         | varchar(1)          | NO   |     |                     |       |
| exec_count        | bigint(20) unsigned | NO   |     | NULL                |       |
| err_count         | bigint(20) unsigned | NO   |     | NULL                |       |
| warn_count        | bigint(20) unsigned | NO   |     | NULL                |       |
| total_latency     | text                | YES  |     | NULL                |       |
| max_latency       | text                | YES  |     | NULL                |       |
| avg_latency       | text                | YES  |     | NULL                |       |
| rows_sent         | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_sent_avg     | decimal(21,0)       | NO   |     | 0                   |       |
| rows_examined     | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_examined_avg | decimal(21,0)       | NO   |     | 0                   |       |
| first_seen        | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| last_seen         | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| digest            | varchar(32)         | YES  |     | NULL                |       |
+-------------------+---------------------+------+-----+---------------------+-------+
16 rows in set (0.11 sec)

mysql> desc x$statements_with_runtimes_in_95th_percentile;
+-------------------+---------------------+------+-----+---------------------+-------+
| Field             | Type                | Null | Key | Default             | Extra |
+-------------------+---------------------+------+-----+---------------------+-------+
| query             | longtext            | YES  |     | NULL                |       |
| db                | varchar(64)         | YES  |     | NULL                |       |
| full_scan         | varchar(1)          | NO   |     |                     |       |
| exec_count        | bigint(20) unsigned | NO   |     | NULL                |       |
| err_count         | bigint(20) unsigned | NO   |     | NULL                |       |
| warn_count        | bigint(20) unsigned | NO   |     | NULL                |       |
| total_latency     | bigint(20) unsigned | NO   |     | NULL                |       |
| max_latency       | bigint(20) unsigned | NO   |     | NULL                |       |
| avg_latency       | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_sent         | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_sent_avg     | decimal(21,0)       | NO   |     | 0                   |       |
| rows_examined     | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_examined_avg | decimal(21,0)       | NO   |     | 0                   |       |
| first_seen        | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| last_seen         | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| digest            | varchar(32)         | YES  |     | NULL                |       |
+-------------------+---------------------+------+-----+---------------------+-------+
16 rows in set (0.00 sec)

mysql> desc x$ps_digest_avg_latency_distribution;
+--------+---------------+------+-----+---------+-------+
| Field  | Type          | Null | Key | Default | Extra |
+--------+---------------+------+-----+---------+-------+
| cnt    | bigint(21)    | NO   |     | 0       |       |
| avg_us | decimal(21,0) | YES  |     | NULL    |       |
+--------+---------------+------+-----+---------+-------+
2 rows in set (0.10 sec)

mysql> desc x$ps_digest_95th_percentile_by_avg_us;
+------------+---------------+------+-----+---------+-------+
| Field      | Type          | Null | Key | Default | Extra |
+------------+---------------+------+-----+---------+-------+
| avg_us     | decimal(21,0) | YES  |     | NULL    |       |
| percentile | decimal(46,4) | NO   |     | 0.0000  |       |
+------------+---------------+------+-----+---------+-------+
2 rows in set (0.15 sec)
```

##### Example

```SQL
mysql> select * from statements_with_runtimes_in_95th_percentile\G
*************************** 1. row ***************************
            query: SELECT * FROM `schema_object_o ... MA` , `information_schema` ...
               db: sys
        full_scan: *
       exec_count: 2
        err_count: 0
       warn_count: 0
    total_latency: 16.75 s
      max_latency: 16.57 s
      avg_latency: 8.38 s
        rows_sent: 84
    rows_sent_avg: 42
    rows_examined: 20012
rows_examined_avg: 10006
       first_seen: 2014-03-07 13:13:41
        last_seen: 2014-03-07 13:13:48
           digest: 54f9bd520f0bbf15db0c2ed93386bec9
```

#### statements_with_sorting / x$statements_with_sorting

##### Description

Lists all normalized statements that have done sorts, ordered by total_latency descending.

##### Structures

```SQL
mysql> desc statements_with_sorting;
+-------------------+---------------------+------+-----+---------------------+-------+
| Field             | Type                | Null | Key | Default             | Extra |
+-------------------+---------------------+------+-----+---------------------+-------+
| query             | longtext            | YES  |     | NULL                |       |
| db                | varchar(64)         | YES  |     | NULL                |       |
| exec_count        | bigint(20) unsigned | NO   |     | NULL                |       |
| total_latency     | text                | YES  |     | NULL                |       |
| sort_merge_passes | bigint(20) unsigned | NO   |     | NULL                |       |
| avg_sort_merges   | decimal(21,0)       | NO   |     | 0                   |       |
| sorts_using_scans | bigint(20) unsigned | NO   |     | NULL                |       |
| sort_using_range  | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_sorted       | bigint(20) unsigned | NO   |     | NULL                |       |
| avg_rows_sorted   | decimal(21,0)       | NO   |     | 0                   |       |
| first_seen        | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| last_seen         | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| digest            | varchar(32)         | YES  |     | NULL                |       |
+-------------------+---------------------+------+-----+---------------------+-------+
13 rows in set (0.01 sec)

mysql> desc x$statements_with_sorting;
+-------------------+---------------------+------+-----+---------------------+-------+
| Field             | Type                | Null | Key | Default             | Extra |
+-------------------+---------------------+------+-----+---------------------+-------+
| query             | longtext            | YES  |     | NULL                |       |
| db                | varchar(64)         | YES  |     | NULL                |       |
| exec_count        | bigint(20) unsigned | NO   |     | NULL                |       |
| total_latency     | bigint(20) unsigned | NO   |     | NULL                |       |
| sort_merge_passes | bigint(20) unsigned | NO   |     | NULL                |       |
| avg_sort_merges   | decimal(21,0)       | NO   |     | 0                   |       |
| sorts_using_scans | bigint(20) unsigned | NO   |     | NULL                |       |
| sort_using_range  | bigint(20) unsigned | NO   |     | NULL                |       |
| rows_sorted       | bigint(20) unsigned | NO   |     | NULL                |       |
| avg_rows_sorted   | decimal(21,0)       | NO   |     | 0                   |       |
| first_seen        | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| last_seen         | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| digest            | varchar(32)         | YES  |     | NULL                |       |
+-------------------+---------------------+------+-----+---------------------+-------+
13 rows in set (0.04 sec)
```

##### Example

```SQL
mysql> select * from statements_with_sorting limit 1\G
*************************** 1. row ***************************
            query: SELECT * FROM `schema_object_o ... MA` , `information_schema` ...
               db: sys
       exec_count: 2
    total_latency: 16.75 s
sort_merge_passes: 0
  avg_sort_merges: 0
sorts_using_scans: 12
 sort_using_range: 0
      rows_sorted: 168
  avg_rows_sorted: 84
       first_seen: 2014-03-07 13:13:41
        last_seen: 2014-03-07 13:13:48
           digest: 54f9bd520f0bbf15db0c2ed93386bec9
```

#### statements_with_temp_tables / x$statements_with_temp_tables

##### Description

Lists all normalized statements that use temporary tables ordered by number of on disk temporary tables descending first, then by the number of memory tables.

##### Structures

```SQL
mysql> desc statements_with_temp_tables;
+--------------------------+---------------------+------+-----+---------------------+-------+
| Field                    | Type                | Null | Key | Default             | Extra |
+--------------------------+---------------------+------+-----+---------------------+-------+
| query                    | longtext            | YES  |     | NULL                |       |
| db                       | varchar(64)         | YES  |     | NULL                |       |
| exec_count               | bigint(20) unsigned | NO   |     | NULL                |       |
| total_latency            | text                | YES  |     | NULL                |       |
| memory_tmp_tables        | bigint(20) unsigned | NO   |     | NULL                |       |
| disk_tmp_tables          | bigint(20) unsigned | NO   |     | NULL                |       |
| avg_tmp_tables_per_query | decimal(21,0)       | NO   |     | 0                   |       |
| tmp_tables_to_disk_pct   | decimal(24,0)       | NO   |     | 0                   |       |
| first_seen               | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| last_seen                | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| digest                   | varchar(32)         | YES  |     | NULL                |       |
+--------------------------+---------------------+------+-----+---------------------+-------+
11 rows in set (0.30 sec)

mysql> desc x$statements_with_temp_tables;
+--------------------------+---------------------+------+-----+---------------------+-------+
| Field                    | Type                | Null | Key | Default             | Extra |
+--------------------------+---------------------+------+-----+---------------------+-------+
| query                    | longtext            | YES  |     | NULL                |       |
| db                       | varchar(64)         | YES  |     | NULL                |       |
| exec_count               | bigint(20) unsigned | NO   |     | NULL                |       |
| total_latency            | bigint(20) unsigned | NO   |     | NULL                |       |
| memory_tmp_tables        | bigint(20) unsigned | NO   |     | NULL                |       |
| disk_tmp_tables          | bigint(20) unsigned | NO   |     | NULL                |       |
| avg_tmp_tables_per_query | decimal(21,0)       | NO   |     | 0                   |       |
| tmp_tables_to_disk_pct   | decimal(24,0)       | NO   |     | 0                   |       |
| first_seen               | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| last_seen                | timestamp           | NO   |     | 0000-00-00 00:00:00 |       |
| digest                   | varchar(32)         | YES  |     | NULL                |       |
+--------------------------+---------------------+------+-----+---------------------+-------+
11 rows in set (0.05 sec)
```

##### Example

```SQL
mysql> select * from statements_with_temp_tables limit 1\G
*************************** 1. row ***************************
                   query: SELECT * FROM `schema_object_o ... MA` , `information_schema` ...
                      db: sys
              exec_count: 2
           total_latency: 16.75 s
       memory_tmp_tables: 378
         disk_tmp_tables: 66
avg_tmp_tables_per_query: 189
  tmp_tables_to_disk_pct: 17
              first_seen: 2014-03-07 13:13:41
               last_seen: 2014-03-07 13:13:48
                  digest: 54f9bd520f0bbf15db0c2ed93386bec9
```

#### user_summary / x$user_summary

##### Description

Summarizes statement activity, file IO and connections by user.

When the user found is NULL, it is assumed to be a "background" thread.

##### Structures (5.7)

```SQL
mysql> desc user_summary;
+------------------------+---------------+------+-----+---------+-------+
| Field                  | Type          | Null | Key | Default | Extra |
+------------------------+---------------+------+-----+---------+-------+
| user                   | varchar(32)   | YES  |     | NULL    |       |
| statements             | decimal(64,0) | YES  |     | NULL    |       |
| statement_latency      | text          | YES  |     | NULL    |       |
| statement_avg_latency  | text          | YES  |     | NULL    |       |
| table_scans            | decimal(65,0) | YES  |     | NULL    |       |
| file_ios               | decimal(64,0) | YES  |     | NULL    |       |
| file_io_latency        | text          | YES  |     | NULL    |       |
| current_connections    | decimal(41,0) | YES  |     | NULL    |       |
| total_connections      | decimal(41,0) | YES  |     | NULL    |       |
| unique_hosts           | bigint(21)    | NO   |     | 0       |       |
| current_memory         | text          | YES  |     | NULL    |       |
| total_memory_allocated | text          | YES  |     | NULL    |       |
+------------------------+---------------+------+-----+---------+-------+
12 rows in set (0.00 sec)

mysql> desc x$user_summary;
+------------------------+---------------+------+-----+---------+-------+
| Field                  | Type          | Null | Key | Default | Extra |
+------------------------+---------------+------+-----+---------+-------+
| user                   | varchar(32)   | YES  |     | NULL    |       |
| statements             | decimal(64,0) | YES  |     | NULL    |       |
| statement_latency      | decimal(64,0) | YES  |     | NULL    |       |
| statement_avg_latency  | decimal(65,4) | NO   |     | 0.0000  |       |
| table_scans            | decimal(65,0) | YES  |     | NULL    |       |
| file_ios               | decimal(64,0) | YES  |     | NULL    |       |
| file_io_latency        | decimal(64,0) | YES  |     | NULL    |       |
| current_connections    | decimal(41,0) | YES  |     | NULL    |       |
| total_connections      | decimal(41,0) | YES  |     | NULL    |       |
| unique_hosts           | bigint(21)    | NO   |     | 0       |       |
| current_memory         | decimal(63,0) | YES  |     | NULL    |       |
| total_memory_allocated | decimal(64,0) | YES  |     | NULL    |       |
+------------------------+---------------+------+-----+---------+-------+
12 rows in set (0.01 sec)
```

##### Example

```SQL
mysql> select * from user_summary\G
*************************** 1. row ***************************
                  user: root
            statements: 4981
     statement_latency: 26.54 s
 statement_avg_latency: 5.33 ms
           table_scans: 74
              file_ios: 7792
       file_io_latency: 40.08 s
   current_connections: 1
     total_connections: 2
          unique_hosts: 1
        current_memory: 3.57 MiB
total_memory_allocated: 83.37 MiB
*************************** 2. row ***************************
                  user: background
            statements: 0
     statement_latency: 0 ps
 statement_avg_latency: 0 ps
           table_scans: 0
              file_ios: 1618
       file_io_latency: 4.78 s
   current_connections: 21
     total_connections: 23
          unique_hosts: 0
        current_memory: 165.94 MiB
total_memory_allocated: 197.29 MiB
```

#### user_summary_by_file_io / x$user_summary_by_file_io

##### Description

Summarizes file IO totals per user.

When the user found is NULL, it is assumed to be a "background" thread.

##### Structures

```SQL
mysql> desc user_summary_by_file_io;
+------------+---------------+------+-----+---------+-------+
| Field      | Type          | Null | Key | Default | Extra |
+------------+---------------+------+-----+---------+-------+
| user       | varchar(32)   | YES  |     | NULL    |       |
| ios        | decimal(42,0) | YES  |     | NULL    |       |
| io_latency | text          | YES  |     | NULL    |       |
+------------+---------------+------+-----+---------+-------+
3 rows in set (0.20 sec)

mysql> desc x$user_summary_by_file_io;
+------------+---------------+------+-----+---------+-------+
| Field      | Type          | Null | Key | Default | Extra |
+------------+---------------+------+-----+---------+-------+
| user       | varchar(32)   | YES  |     | NULL    |       |
| ios        | decimal(42,0) | YES  |     | NULL    |       |
| io_latency | decimal(42,0) | YES  |     | NULL    |       |
+------------+---------------+------+-----+---------+-------+
3 rows in set (0.02 sec)
```

##### Example

```SQL
mysql> select * from user_summary_by_file_io;
+------------+-------+------------+
| user       | ios   | io_latency |
+------------+-------+------------+
| root       | 26457 | 21.58 s    |
| background |  1189 | 394.21 ms  |
+------------+-------+------------+
```

#### user_summary_by_file_io_type / x$user_summary_by_file_io_type

##### Description

Summarizes file IO by event type per user.

When the user found is NULL, it is assumed to be a "background" thread.

##### Structures

```SQL
mysql> desc user_summary_by_file_io_type;
+-------------+---------------------+------+-----+---------+-------+
| Field       | Type                | Null | Key | Default | Extra |
+-------------+---------------------+------+-----+---------+-------+
| user        | varchar(32)         | YES  |     | NULL    |       |
| event_name  | varchar(128)        | NO   |     | NULL    |       |
| total       | bigint(20) unsigned | NO   |     | NULL    |       |
| latency     | text                | YES  |     | NULL    |       |
| max_latency | text                | YES  |     | NULL    |       |
+-------------+---------------------+------+-----+---------+-------+
5 rows in set (0.02 sec)

mysql> desc x$user_summary_by_file_io_type;
+-------------+---------------------+------+-----+---------+-------+
| Field       | Type                | Null | Key | Default | Extra |
+-------------+---------------------+------+-----+---------+-------+
| user        | varchar(32)         | YES  |     | NULL    |       |
| event_name  | varchar(128)        | NO   |     | NULL    |       |
| total       | bigint(20) unsigned | NO   |     | NULL    |       |
| latency     | bigint(20) unsigned | NO   |     | NULL    |       |
| max_latency | bigint(20) unsigned | NO   |     | NULL    |       |
+-------------+---------------------+------+-----+---------+-------+
5 rows in set (0.00 sec)
```

##### Example

```SQL
mysql> select * from user_summary_by_file_io_type;
+------------+--------------------------------------+-------+-----------+-------------+
| user       | event_name                           | total | latency   | max_latency |
+------------+--------------------------------------+-------+-----------+-------------+
| background | wait/io/file/innodb/innodb_data_file |  1434 | 3.29 s    | 147.56 ms   |
| background | wait/io/file/sql/FRM                 |   910 | 286.61 ms | 32.92 ms    |
| background | wait/io/file/sql/relaylog            |     9 | 252.28 ms | 144.17 ms   |
| background | wait/io/file/sql/binlog              |    56 | 193.73 ms | 153.72 ms   |
| background | wait/io/file/sql/binlog_index        |    22 | 183.02 ms | 81.83 ms    |
| background | wait/io/file/innodb/innodb_log_file  |    20 | 117.17 ms | 36.53 ms    |
| background | wait/io/file/sql/relaylog_index      |     9 | 50.15 ms  | 48.04 ms    |
| background | wait/io/file/sql/ERRMSG              |     5 | 35.41 ms  | 31.78 ms    |
| background | wait/io/file/myisam/kfile            |    67 | 18.14 ms  | 9.00 ms     |
| background | wait/io/file/mysys/charset           |     3 | 7.46 ms   | 4.13 ms     |
| background | wait/io/file/sql/casetest            |     5 | 6.01 ms   | 5.86 ms     |
| background | wait/io/file/sql/pid                 |     3 | 5.96 ms   | 3.06 ms     |
| background | wait/io/file/myisam/dfile            |    43 | 980.38 us | 152.46 us   |
| background | wait/io/file/mysys/cnf               |     5 | 154.97 us | 58.87 us    |
| background | wait/io/file/sql/global_ddl_log      |     2 | 18.64 us  | 16.40 us    |
| root       | wait/io/file/sql/file_parser         | 11048 | 48.79 s   | 201.11 ms   |
| root       | wait/io/file/innodb/innodb_data_file |  4699 | 3.02 s    | 46.93 ms    |
| root       | wait/io/file/sql/FRM                 | 10403 | 2.38 s    | 61.72 ms    |
| root       | wait/io/file/myisam/dfile            | 22143 | 726.77 ms | 308.79 ms   |
| root       | wait/io/file/myisam/kfile            |  6213 | 435.35 ms | 88.76 ms    |
| root       | wait/io/file/sql/dbopt               |   159 | 130.86 ms | 15.46 ms    |
| root       | wait/io/file/csv/metadata            |     8 | 86.60 ms  | 50.32 ms    |
| root       | wait/io/file/sql/binlog              |    15 | 38.79 ms  | 9.40 ms     |
| root       | wait/io/file/sql/misc                |    21 | 22.33 ms  | 15.30 ms    |
| root       | wait/io/file/csv/data                |     4 | 297.46 us | 111.93 us   |
| root       | wait/io/file/archive/data            |     3 | 54.10 us  | 40.74 us    |
+------------+--------------------------------------+-------+-----------+-------------+
```

#### user_summary_by_stages / x$user_summary_by_stages

##### Description

Summarizes stages by user, ordered by user and total latency per stage.

When the user found is NULL, it is assumed to be a "background" thread.

##### Structures

```SQL
mysql> desc user_summary_by_stages;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| user          | varchar(32)         | YES  |     | NULL    |       |
| event_name    | varchar(128)        | NO   |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | text                | YES  |     | NULL    |       |
| avg_latency   | text                | YES  |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
5 rows in set (0.01 sec)

mysql> desc x$user_summary_by_stages;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| user          | varchar(16)         | YES  |     | NULL    |       |
| event_name    | varchar(128)        | NO   |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | bigint(20) unsigned | NO   |     | NULL    |       |
| avg_latency   | bigint(20) unsigned | NO   |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
5 rows in set (0.05 sec)
```

##### Example

```SQL
mysql> select * from user_summary_by_stages;
+------+--------------------------------+-------+---------------+-------------+
| user | event_name                     | total | total_latency | avg_latency |
+------+--------------------------------+-------+---------------+-------------+
| root | stage/sql/Opening tables       |   889 | 1.97 ms       | 2.22 us     |
| root | stage/sql/Creating sort index  |     4 | 1.79 ms       | 446.30 us   |
| root | stage/sql/init                 |    10 | 312.27 us     | 31.23 us    |
| root | stage/sql/checking permissions |    10 | 300.62 us     | 30.06 us    |
| root | stage/sql/freeing items        |     5 | 85.89 us      | 17.18 us    |
| root | stage/sql/statistics           |     5 | 79.15 us      | 15.83 us    |
| root | stage/sql/preparing            |     5 | 69.12 us      | 13.82 us    |
| root | stage/sql/optimizing           |     5 | 53.11 us      | 10.62 us    |
| root | stage/sql/Sending data         |     5 | 44.66 us      | 8.93 us     |
| root | stage/sql/closing tables       |     5 | 37.54 us      | 7.51 us     |
| root | stage/sql/System lock          |     5 | 34.28 us      | 6.86 us     |
| root | stage/sql/query end            |     5 | 24.37 us      | 4.87 us     |
| root | stage/sql/end                  |     5 | 8.60 us       | 1.72 us     |
| root | stage/sql/Sorting result       |     5 | 8.33 us       | 1.67 us     |
| root | stage/sql/executing            |     5 | 5.37 us       | 1.07 us     |
| root | stage/sql/cleaning up          |     5 | 4.60 us       | 919.00 ns   |
+------+--------------------------------+-------+---------------+-------------+
```

#### user_summary_by_statement_latency / x$user_summary_by_statement_latency

##### Description

Summarizes overall statement statistics by user.

When the user found is NULL, it is assumed to be a "background" thread.

##### Structures

```SQL
mysql> desc user_summary_by_statement_latency;
+---------------+---------------+------+-----+---------+-------+
| Field         | Type          | Null | Key | Default | Extra |
+---------------+---------------+------+-----+---------+-------+
| user          | varchar(32)   | YES  |     | NULL    |       |
| total         | decimal(42,0) | YES  |     | NULL    |       |
| total_latency | text          | YES  |     | NULL    |       |
| max_latency   | text          | YES  |     | NULL    |       |
| lock_latency  | text          | YES  |     | NULL    |       |
| rows_sent     | decimal(42,0) | YES  |     | NULL    |       |
| rows_examined | decimal(42,0) | YES  |     | NULL    |       |
| rows_affected | decimal(42,0) | YES  |     | NULL    |       |
| full_scans    | decimal(43,0) | YES  |     | NULL    |       |
+---------------+---------------+------+-----+---------+-------+
9 rows in set (0.00 sec)

mysql> desc x$user_summary_by_statement_latency;
+---------------+---------------+------+-----+---------+-------+
| Field         | Type          | Null | Key | Default | Extra |
+---------------+---------------+------+-----+---------+-------+
| user          | varchar(32)   | YES  |     | NULL    |       |
| total         | decimal(42,0) | YES  |     | NULL    |       |
| total_latency | decimal(42,0) | YES  |     | NULL    |       |
| max_latency   | decimal(42,0) | YES  |     | NULL    |       |
| lock_latency  | decimal(42,0) | YES  |     | NULL    |       |
| rows_sent     | decimal(42,0) | YES  |     | NULL    |       |
| rows_examined | decimal(42,0) | YES  |     | NULL    |       |
| rows_affected | decimal(42,0) | YES  |     | NULL    |       |
| full_scans    | decimal(43,0) | YES  |     | NULL    |       |
+---------------+---------------+------+-----+---------+-------+
9 rows in set (0.28 sec)
```

##### Example

```SQL
mysql> select * from user_summary_by_statement_latency;
+------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
| user | total | total_latency | max_latency | lock_latency | rows_sent | rows_examined | rows_affected | full_scans |
+------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
| root |  3381 | 00:02:09.13   | 1.48 s      | 1.07 s       |      1151 |         93947 |           150 |         91 |
+------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
```

#### user_summary_by_statement_type / x$user_summary_by_statement_type

##### Description

Summarizes the types of statements executed by each user.

When the user found is NULL, it is assumed to be a "background" thread.

##### Structures

```SQL
mysql> desc user_summary_by_statement_type;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| user          | varchar(32)         | YES  |     | NULL    |       |
| statement     | varchar(128)        | YES  |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | text                | YES  |     | NULL    |       |
| max_latency   | text                | YES  |     | NULL    |       |
| lock_latency  | text                | YES  |     | NULL    |       |
| rows_sent     | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_examined | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_affected | bigint(20) unsigned | NO   |     | NULL    |       |
| full_scans    | bigint(21) unsigned | NO   |     | 0       |       |
+---------------+---------------------+------+-----+---------+-------+
10 rows in set (0.21 sec)

mysql> desc x$user_summary_by_statement_type;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| user          | varchar(32)         | YES  |     | NULL    |       |
| statement     | varchar(128)        | YES  |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | bigint(20) unsigned | NO   |     | NULL    |       |
| max_latency   | bigint(20) unsigned | NO   |     | NULL    |       |
| lock_latency  | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_sent     | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_examined | bigint(20) unsigned | NO   |     | NULL    |       |
| rows_affected | bigint(20) unsigned | NO   |     | NULL    |       |
| full_scans    | bigint(21) unsigned | NO   |     | 0       |       |
+---------------+---------------------+------+-----+---------+-------+
10 rows in set (0.37 sec)
```

##### Example

```SQL
mysql> select * from user_summary_by_statement_type;
+------+------------------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
| user | statement        | total | total_latency | max_latency | lock_latency | rows_sent | rows_examined | rows_affected | full_scans |
+------+------------------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
| root | create_view      |  1332 | 00:03:39.08   | 677.76 ms   | 494.56 ms    |         0 |             0 |             0 |          0 |
| root | select           |    88 | 20.13 s       | 16.57 s     | 17.40 s      |      1804 |         77285 |             0 |         48 |
| root | drop_db          |    16 | 6.83 s        | 1.14 s      | 5.73 s       |         0 |             0 |           953 |          0 |
| root | drop_view        |   392 | 1.70 s        | 739.49 ms   | 0 ps         |         0 |             0 |             0 |          0 |
| root | show_databases   |    16 | 1.37 s        | 587.44 ms   | 1.31 ms      |       400 |           400 |             0 |         16 |
| root | show_tables      |    34 | 676.78 ms     | 167.04 ms   | 3.46 ms      |      1087 |          1087 |             0 |         34 |
| root | create_db        |    22 | 334.90 ms     | 38.93 ms    | 0 ps         |         0 |             0 |            22 |          0 |
| root | create_procedure |   352 | 250.02 ms     | 21.90 ms    | 165.17 ms    |         0 |             0 |             0 |          0 |
| root | drop_function    |   176 | 122.44 ms     | 69.18 ms    | 87.24 ms     |         0 |             0 |             0 |          0 |
| root | create_function  |   176 | 76.12 ms      | 1.36 ms     | 49.50 ms     |         0 |             0 |             0 |          0 |
| root | drop_procedure   |   352 | 67.41 ms      | 1.57 ms     | 36.22 ms     |         0 |             0 |             0 |          0 |
| root | update           |     2 | 41.75 ms      | 35.96 ms    | 35.52 ms     |         0 |           557 |           338 |          0 |
| root | error            |     3 | 17.22 ms      | 17.05 ms    | 0 ps         |         0 |             0 |             0 |          0 |
| root | set_option       |    88 | 8.02 ms       | 1.63 ms     | 0 ps         |         0 |             0 |             0 |          0 |
| root | call_procedure   |     2 | 2.98 ms       | 2.29 ms     | 95.00 us     |         0 |             0 |             0 |          0 |
| root | Init DB          |    22 | 1.07 ms       | 117.65 us   | 0 ps         |         0 |             0 |             0 |          0 |
| root | show_status      |     1 | 408.69 us     | 408.69 us   | 102.00 us    |        23 |            23 |             0 |          1 |
+------+------------------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
```

#### wait_classes_global_by_avg_latency / x$wait_classes_global_by_avg_latency

##### Description

Lists the top wait classes by average latency, ignoring idle (this may be very large).

##### Structures

```SQL
mysql> desc wait_classes_global_by_avg_latency;
+---------------+---------------+------+-----+---------+-------+
| Field         | Type          | Null | Key | Default | Extra |
+---------------+---------------+------+-----+---------+-------+
| event_class   | varchar(128)  | YES  |     | NULL    |       |
| total         | decimal(42,0) | YES  |     | NULL    |       |
| total_latency | text          | YES  |     | NULL    |       |
| min_latency   | text          | YES  |     | NULL    |       |
| avg_latency   | text          | YES  |     | NULL    |       |
| max_latency   | text          | YES  |     | NULL    |       |
+---------------+---------------+------+-----+---------+-------+
6 rows in set (0.11 sec)

mysql> desc x$wait_classes_global_by_avg_latency;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| event_class   | varchar(128)        | YES  |     | NULL    |       |
| total         | decimal(42,0)       | YES  |     | NULL    |       |
| total_latency | decimal(42,0)       | YES  |     | NULL    |       |
| min_latency   | bigint(20) unsigned | YES  |     | NULL    |       |
| avg_latency   | decimal(46,4)       | NO   |     | 0.0000  |       |
| max_latency   | bigint(20) unsigned | YES  |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
6 rows in set (0.02 sec)
```

##### Example

```SQL
mysql> select * from wait_classes_global_by_avg_latency where event_class != 'idle';
+-------------------+--------+---------------+-------------+-------------+-------------+
| event_class       | total  | total_latency | min_latency | avg_latency | max_latency |
+-------------------+--------+---------------+-------------+-------------+-------------+
| wait/io/file      | 543123 | 44.60 s       | 19.44 ns    | 82.11 us    | 4.21 s      |
| wait/io/table     |  22002 | 766.60 ms     | 148.72 ns   | 34.84 us    | 44.97 ms    |
| wait/io/socket    |  79613 | 967.17 ms     | 0 ps        | 12.15 us    | 27.10 ms    |
| wait/lock/table   |  35409 | 18.68 ms      | 65.45 ns    | 527.51 ns   | 969.88 us   |
| wait/synch/rwlock |  37935 | 4.61 ms       | 21.38 ns    | 121.61 ns   | 34.65 us    |
| wait/synch/mutex  | 390622 | 18.60 ms      | 19.44 ns    | 47.61 ns    | 10.32 us    |
+-------------------+--------+---------------+-------------+-------------+-------------+
```

#### wait_classes_global_by_latency / x$wait_classes_global_by_latency

##### Description

Lists the top wait classes by total latency, ignoring idle (this may be very large).

##### Structures

```SQL
mysql> desc wait_classes_global_by_latency;
+---------------+---------------+------+-----+---------+-------+
| Field         | Type          | Null | Key | Default | Extra |
+---------------+---------------+------+-----+---------+-------+
| event_class   | varchar(128)  | YES  |     | NULL    |       |
| total         | decimal(42,0) | YES  |     | NULL    |       |
| total_latency | text          | YES  |     | NULL    |       |
| min_latency   | text          | YES  |     | NULL    |       |
| avg_latency   | text          | YES  |     | NULL    |       |
| max_latency   | text          | YES  |     | NULL    |       |
+---------------+---------------+------+-----+---------+-------+
6 rows in set (0.00 sec)

mysql> desc x$wait_classes_global_by_latency;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| event_class   | varchar(128)        | YES  |     | NULL    |       |
| total         | decimal(42,0)       | YES  |     | NULL    |       |
| total_latency | decimal(42,0)       | YES  |     | NULL    |       |
| min_latency   | bigint(20) unsigned | YES  |     | NULL    |       |
| avg_latency   | decimal(46,4)       | NO   |     | 0.0000  |       |
| max_latency   | bigint(20) unsigned | YES  |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
6 rows in set (0.02 sec)
```

##### Example

```SQL
mysql> select * from wait_classes_global_by_latency;
+-------------------+--------+---------------+-------------+-------------+-------------+
| event_class       | total  | total_latency | min_latency | avg_latency | max_latency |
+-------------------+--------+---------------+-------------+-------------+-------------+
| wait/io/file      | 550470 | 46.01 s       | 19.44 ns    | 83.58 us    | 4.21 s      |
| wait/io/socket    | 228833 | 2.71 s        | 0 ps        | 11.86 us    | 29.93 ms    |
| wait/io/table     |  64063 | 1.89 s        | 99.79 ns    | 29.43 us    | 68.07 ms    |
| wait/lock/table   |  76029 | 47.19 ms      | 65.45 ns    | 620.74 ns   | 969.88 us   |
| wait/synch/mutex  | 635925 | 34.93 ms      | 19.44 ns    | 54.93 ns    | 107.70 us   |
| wait/synch/rwlock |  61287 | 7.62 ms       | 21.38 ns    | 124.37 ns   | 34.65 us    |
+-------------------+--------+---------------+-------------+-------------+-------------+
```

#### waits_by_user_by_latency / x$waits_by_user_by_latency

##### Description

Lists the top wait events per user by their total latency, ignoring idle (this may be very large) per user.

##### Structures

```SQL
mysql> desc waits_by_user_by_latency;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| user          | varchar(32)         | YES  |     | NULL    |       |
| event         | varchar(128)        | NO   |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | text                | YES  |     | NULL    |       |
| avg_latency   | text                | YES  |     | NULL    |       |
| max_latency   | text                | YES  |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
6 rows in set (0.00 sec)

mysql> desc x$waits_by_user_by_latency;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| user          | varchar(32)         | YES  |     | NULL    |       |
| event         | varchar(128)        | NO   |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | bigint(20) unsigned | NO   |     | NULL    |       |
| avg_latency   | bigint(20) unsigned | NO   |     | NULL    |       |
| max_latency   | bigint(20) unsigned | NO   |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
6 rows in set (0.30 sec)
```

##### Example

```SQL
mysql> select * from waits_by_user_by_latency;
+------+-----------------------------------------------------+--------+---------------+-------------+-------------+
| user | event                                               | total  | total_latency | avg_latency | max_latency |
+------+-----------------------------------------------------+--------+---------------+-------------+-------------+
| root | wait/io/file/sql/file_parser                        |  13743 | 00:01:00.46   | 4.40 ms     | 231.88 ms   |
| root | wait/io/file/innodb/innodb_data_file                |   4699 | 3.02 s        | 643.38 us   | 46.93 ms    |
| root | wait/io/file/sql/FRM                                |  11462 | 2.60 s        | 226.83 us   | 61.72 ms    |
| root | wait/io/file/myisam/dfile                           |  26776 | 746.70 ms     | 27.89 us    | 308.79 ms   |
| root | wait/io/file/myisam/kfile                           |   7126 | 462.66 ms     | 64.93 us    | 88.76 ms    |
| root | wait/io/file/sql/dbopt                              |    179 | 137.58 ms     | 768.59 us   | 15.46 ms    |
| root | wait/io/file/csv/metadata                           |      8 | 86.60 ms      | 10.82 ms    | 50.32 ms    |
| root | wait/synch/mutex/mysys/IO_CACHE::append_buffer_lock | 798080 | 66.46 ms      | 82.94 ns    | 161.03 us   |
| root | wait/io/file/sql/binlog                             |     19 | 49.11 ms      | 2.58 ms     | 9.40 ms     |
| root | wait/io/file/sql/misc                               |     26 | 22.38 ms      | 860.80 us   | 15.30 ms    |
| root | wait/io/file/csv/data                               |      4 | 297.46 us     | 74.37 us    | 111.93 us   |
| root | wait/synch/rwlock/sql/MDL_lock::rwlock              |    944 | 287.86 us     | 304.62 ns   | 874.64 ns   |
| root | wait/io/file/archive/data                           |      4 | 82.71 us      | 20.68 us    | 40.74 us    |
| root | wait/synch/mutex/myisam/MYISAM_SHARE::intern_lock   |     60 | 12.21 us      | 203.20 ns   | 512.72 ns   |
| root | wait/synch/mutex/innodb/trx_mutex                   |     81 | 5.93 us       | 73.14 ns    | 252.59 ns   |
+------+-----------------------------------------------------+--------+---------------+-------------+-------------+
```

#### waits_by_host_by_latency / x$waits_by_host_by_latency

##### Description

Lists the top wait events per host by their total latency, ignoring idle (this may be very large) per host.

##### Structures

```SQL
mysql> desc waits_by_host_by_latency;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| host          | varchar(60)         | YES  |     | NULL    |       |
| event         | varchar(128)        | NO   |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | text                | YES  |     | NULL    |       |
| avg_latency   | text                | YES  |     | NULL    |       |
| max_latency   | text                | YES  |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
6 rows in set (0.36 sec)

mysql> desc x$waits_by_host_by_latency;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| host          | varchar(60)         | YES  |     | NULL    |       |
| event         | varchar(128)        | NO   |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | bigint(20) unsigned | NO   |     | NULL    |       |
| avg_latency   | bigint(20) unsigned | NO   |     | NULL    |       |
| max_latency   | bigint(20) unsigned | NO   |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
6 rows in set (0.25 sec)
```

##### Example

```SQL
 mysql> select * from waits_by_host_by_latency;
  +------+-----------------------------------------------------+--------+---------------+-------------+-------------+
  | host | event                                               | total  | total_latency | avg_latency | max_latency |
  +------+-----------------------------------------------------+--------+---------------+-------------+-------------+
  | hal1 | wait/io/file/sql/file_parser                        |  13743 | 00:01:00.46   | 4.40 ms     | 231.88 ms   |
  | hal1 | wait/io/file/innodb/innodb_data_file                |   4699 | 3.02 s        | 643.38 us   | 46.93 ms    |
  | hal1 | wait/io/file/sql/FRM                                |  11462 | 2.60 s        | 226.83 us   | 61.72 ms    |
  | hal1 | wait/io/file/myisam/dfile                           |  26776 | 746.70 ms     | 27.89 us    | 308.79 ms   |
  | hal1 | wait/io/file/myisam/kfile                           |   7126 | 462.66 ms     | 64.93 us    | 88.76 ms    |
  | hal1 | wait/io/file/sql/dbopt                              |    179 | 137.58 ms     | 768.59 us   | 15.46 ms    |
  | hal1 | wait/io/file/csv/metadata                           |      8 | 86.60 ms      | 10.82 ms    | 50.32 ms    |
  | hal1 | wait/synch/mutex/mysys/IO_CACHE::append_buffer_lock | 798080 | 66.46 ms      | 82.94 ns    | 161.03 us   |
  | hal1 | wait/io/file/sql/binlog                             |     19 | 49.11 ms      | 2.58 ms     | 9.40 ms     |
  | hal1 | wait/io/file/sql/misc                               |     26 | 22.38 ms      | 860.80 us   | 15.30 ms    |
  | hal1 | wait/io/file/csv/data                               |      4 | 297.46 us     | 74.37 us    | 111.93 us   |
  | hal1 | wait/synch/rwlock/sql/MDL_lock::rwlock              |    944 | 287.86 us     | 304.62 ns   | 874.64 ns   |
  | hal1 | wait/io/file/archive/data                           |      4 | 82.71 us      | 20.68 us    | 40.74 us    |
  | hal1 | wait/synch/mutex/myisam/MYISAM_SHARE::intern_lock   |     60 | 12.21 us      | 203.20 ns   | 512.72 ns   |
  | hal1 | wait/synch/mutex/innodb/trx_mutex                   |     81 | 5.93 us       | 73.14 ns    | 252.59 ns   |
  +------+-----------------------------------------------------+--------+---------------+-------------+-------------+
```

#### waits_global_by_latency / x$waits_global_by_latency

##### Description

Lists the top wait events by their total latency, ignoring idle (this may be very large).

##### Structures

```SQL
mysql> desc waits_global_by_latency;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| events        | varchar(128)        | NO   |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | text                | YES  |     | NULL    |       |
| avg_latency   | text                | YES  |     | NULL    |       |
| max_latency   | text                | YES  |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
5 rows in set (0.01 sec)

mysql> desc x$waits_global_by_latency;
+---------------+---------------------+------+-----+---------+-------+
| Field         | Type                | Null | Key | Default | Extra |
+---------------+---------------------+------+-----+---------+-------+
| events        | varchar(128)        | NO   |     | NULL    |       |
| total         | bigint(20) unsigned | NO   |     | NULL    |       |
| total_latency | bigint(20) unsigned | NO   |     | NULL    |       |
| avg_latency   | bigint(20) unsigned | NO   |     | NULL    |       |
| max_latency   | bigint(20) unsigned | NO   |     | NULL    |       |
+---------------+---------------------+------+-----+---------+-------+
5 rows in set (0.03 sec)
```

##### Example

```SQL
mysql> select * from waits_global_by_latency;
+-----------------------------------------------------+---------+---------------+-------------+-------------+
| events                                              | total   | total_latency | avg_latency | max_latency |
+-----------------------------------------------------+---------+---------------+-------------+-------------+
| wait/io/file/sql/file_parser                        | 14936   | 00:01:06.64   | 4.46 ms     | 231.88 ms   |
| wait/io/file/innodb/innodb_data_file                |    6133 | 6.31 s        | 1.03 ms     | 147.56 ms   |
| wait/io/file/sql/FRM                                |   12677 | 2.83 s        | 223.37 us   | 40.86 ms    |
| wait/io/file/myisam/dfile                           |   28446 | 754.40 ms     | 26.52 us    | 308.79 ms   |
| wait/io/file/myisam/kfile                           |    7572 | 491.17 ms     | 64.87 us    | 88.76 ms    |
| wait/io/file/sql/relaylog                           |       9 | 252.28 ms     | 28.03 ms    | 144.17 ms   |
| wait/io/file/sql/binlog                             |      76 | 242.87 ms     | 3.20 ms     | 153.72 ms   |
| wait/io/file/sql/binlog_index                       |      21 | 173.07 ms     | 8.24 ms     | 81.83 ms    |
| wait/io/file/sql/dbopt                              |     184 | 149.52 ms     | 812.62 us   | 15.46 ms    |
| wait/io/file/innodb/innodb_log_file                 |      20 | 117.17 ms     | 5.86 ms     | 36.53 ms    |
| wait/synch/mutex/mysys/IO_CACHE::append_buffer_lock | 1197128 | 99.27 ms      | 82.56 ns    | 161.03 us   |
| wait/io/file/csv/metadata                           |       8 | 86.60 ms      | 10.82 ms    | 50.32 ms    |
| wait/io/file/sql/relaylog_index                     |      10 | 60.10 ms      | 6.01 ms     | 48.04 ms    |
| wait/io/file/sql/ERRMSG                             |       5 | 35.41 ms      | 7.08 ms     | 31.78 ms    |
| wait/io/file/sql/misc                               |      28 | 22.40 ms      | 800.06 us   | 15.30 ms    |
| wait/io/file/mysys/charset                          |       3 | 7.46 ms       | 2.49 ms     | 4.13 ms     |
| wait/io/file/sql/casetest                           |       5 | 6.01 ms       | 1.20 ms     | 5.86 ms     |
| wait/io/file/sql/pid                                |       3 | 5.96 ms       | 1.99 ms     | 3.06 ms     |
| wait/synch/rwlock/sql/MDL_lock::rwlock              |    1396 | 420.58 us     | 301.22 ns   | 874.64 ns   |
| wait/io/file/csv/data                               |       4 | 297.46 us     | 74.37 us    | 111.93 us   |
| wait/io/file/mysys/cnf                              |       5 | 154.97 us     | 30.99 us    | 58.87 us    |
| wait/io/file/archive/data                           |       4 | 82.71 us      | 20.68 us    | 40.74 us    |
| wait/synch/mutex/myisam/MYISAM_SHARE::intern_lock   |      90 | 19.23 us      | 213.38 ns   | 576.81 ns   |
| wait/io/file/sql/global_ddl_log                     |       2 | 18.64 us      | 9.32 us     | 16.40 us    |
| wait/synch/mutex/innodb/trx_mutex                   |     108 | 8.23 us       | 76.15 ns    | 365.69 ns   |
+-----------------------------------------------------+---------+---------------+-------------+-------------+
```

