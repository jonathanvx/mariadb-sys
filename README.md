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

