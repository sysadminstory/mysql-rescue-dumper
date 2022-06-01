# Mysql Rescue Dumper

This two scripts permits to dump and restore the tables of a complete MySQL server. This scripts helps to extract the most possible data in case of a crashing MySQL server during a dump (for example, a MySQL server with a crashed innodb tablespace, where `innodb_force_recovery=6` don't prevent MySQL to crash).

## Dumping table

The dump is done with the script `dump-tables.sh`
Every table is dumped separately. If a table dump fails, then the MySQL service will be restarted and the next table will be dumped.

To see how to use the script, start it without parameters.

## Importing table

The import is done with the script `restore-tables.sh`
Every table is imported separately.

To see how to use the script, start it without parameters.
