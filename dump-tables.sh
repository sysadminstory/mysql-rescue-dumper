#!/bin/bash

# dump-tables.sh
# Descr: Dump MySQL table data into separate SQL files for every database.
# Usage: Run without args for usage info.
# Author: sysadminstory
# Notes:
#  * Script will prompt for password for db access.
#  * Script will restart the MySQL service if a dump fails
#  * Output files are written from the directory specified on command-line.

usage()
{
	echo "MySQL Rescue dumper dump script"
	echo ""
	echo "Usage: "
	echo " $(basename $0) -h <db_host> -u <db_user> -o <output_dir> -r <restart_command> [-d <delay>]"
	echo " $(basename $0) -h"
	echo ""
	echo "Options:"
	echo " -s <db_host>		Database Host"
	echo " -u <db_user>		Database Username"
	echo " -o <output_dir>	Output Directory"
	echo " -r <restart_command>	MySQL Service restart command"
	echo " -d <delay>		Delay in seconds to wait after restarting MySQL Service [default: 5]" 
	echo " -h			Show this help" 
	exit 1
}

# Clear variables
unset DBHOST
unset DBUSER
unset DIR
unset RESTART
unset DELAY

# Set default values
DELAY=5

# Handle arguments
while getopts "s:u:o:r:d:h" o; do
	case "${o}" in
		s)
			DBHOST=${OPTARG}
			;;
		u)
			DBUSER=${OPTARG}
			;;
		o)
			DIR=${OPTARG}
			;;
		r)
			RESTART=${OPTARG}
			;;
		d)
			DELAY=${OPTARG}
			;;
		*|h)
			usage
			;;
	esac
done

# Check if all parameters are set
if [[ -z "$DBHOST" || -z "$DBUSER" || -z "$DIR" || -z "$RESTART" || -z "$DELAY" ]]
then
	usage
fi

# If the destination directory doesn't exist, create it
if [ ! -d "$DIR" ]
then
	echo "Creating output directory '$DIR'"
	mkdir -p $DIR
fi

# Ask for the password
read -p "Database Server Password :" -s DBPASS

# Get the list of database excluding 'information_schema'
DBS=$(mysql -B -s -h"$DBHOST" -u"$DBUSER" -p"$DBPASS" -e 'show databases' | grep -v information_schema)

# Init global statistics vars
TOTAL_TABLE_COUNT=0
TOTAL_TABLE_COUNT_FAILED=0
TOTAL_TABLE_COUNT_SUCCESS=0
FAILED_TABLES=""

for DB in $DBS
do
	echo "Dumping tables into separate SQL files for database '$DB' into the directory '$DIR'"

	# Init database statistics vars
	TABLE_COUNT=0
	TABLE_COUNT_FAILED=0
	TABLE_COUNT_SUCCESS=0

	# Get the list of tables
	TABLES=$(mysql -NBA -h"$DBHOST" -u"$DBUSER" -p"$DBPASS" -D $DB -e 'show tables') 
	for TABLE in $TABLES 
	do
		echo "Dumping Table : $DB.$TABLE"
		mysqldump -f -h"$DBHOST" -u"$DBUSER" -p"$DBPASS" $DB $TABLE --result-file=$DIR/$DB.$TABLE.sql
		
		# If the dumps fails
		if [ $? -ne 0 ]
		then
			echo "Dump of table $DB.$TABLE failed !"
			echo "Restarting MySQL using command '$RESTART'"
			# Try to restart the MySQL daelon using the command provided
			$RESTART
			echo "Wating $DELAY seconds before continuing ..."
			sleep 10
			TABLE_COUNT_FAILED=$(( TABLE_COUNT_FAILED + 1 ))
			FAILED_TABLES=$"$FAILED_TABLES\n$DB.$TABLE"
		else

			TABLE_COUNT_SUCCESS=$(( TABLE_COUNT_SUCCESS + 1 ))
		fi
		TABLE_COUNT=$(( TABLE_COUNT + 1 ))
	done

	echo "$TABLE_COUNT_SUCCESS/$TABLE_COUNT table(s) dumped from database '$DB' into the directory '$DIR' ($TABLE_COUNT_FAILED table(s) failed)"

	# Calculate global statistics
	TOTAL_TABLE_COUNT=$(( TOTAL_TABLE_COUNT + TABLE_COUNT ))
	TOTAL_TABLE_COUNT_FAILED=$(( TOTAL_TABLE_COUNT_FAILED + TABLE_COUNT_FAILED ))
	TOTAL_TABLE_COUNT_SUCCESS=$(( TOTAL_TABLE_COUNT_SUCCESS + TABLE_COUNT_SUCCESS ))
done

# Show the statistics
echo "Statistics :"
echo "Tried to dump $TOTAL_TABLE_COUNT table(s)"
echo "$TOTAL_TABLE_COUNT_FAILED table(s) dump failed"
echo "$TOTAL_TABLE_COUNT_SUCCESS table(s) dump were successful"
# Show the info about the failed dumps if needed
if [ "$TOTAL_TABLE_COUNT_FAILED" -gt 0 ]
then
	echo
	echo "The following table dump failed :"
	echo -e $FAILED_TABLES
fi
