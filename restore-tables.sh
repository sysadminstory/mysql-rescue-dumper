#!/bin/bash

# restore-tables.sh
# Descr: Restore MySQL table data from separate SQL files.
# Usage: Run without args for usage info.
# Author: sysadminstory
# Notes:
#  * Script will prompt for password for db access.
#  * Input files are read from the directory specified on command-line.

usage()
{
	echo "MySQL Rescue dumper restore script"
	echo ""
	echo "Usage: "
	echo " $(basename $0) -h <db_host> -u <db_user> -i <output_dir>"
	echo " $(basename $0) -h"
	echo ""
	echo "Options:"
	echo " -s <db_host>		Database Host"
	echo " -u <db_user>		Database Username"
	echo " -i <inout_dir>	Output Directory"
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
while getopts "s:u:i:h" o; do
	case "${o}" in
		s)
			DBHOST=${OPTARG}
			;;
		u)
			DBUSER=${OPTARG}
			;;
		i)
			DIR=${OPTARG}
			;;
		*|h)
			usage
			;;
	esac
done

# Check if all parameters are set
if [[ -z "$DBHOST" || -z "$DBUSER" || -z "$DIR" ]]
then
	usage
fi


# If the destination directory doesn't exist, create it
if [ ! -d "$DIR" ]
then
	echo "Input directory '$DIR' does not exist"
	exit 2
fi

# Ask for the password
read -p "Database Server Password :" -s DBPASS

# List the databases of the input directory
DBS=$(ls -1 $DIR | cut -d'.' -f 1 | sort | uniq)


TOTAL_TABLE_COUNT=0
TOTAL_TABLE_COUNT_FAILED=0
TOTAL_TABLE_COUNT_SUCCESS=0
FAILED_FILES=""

for DB in $DBS
do
	echo "Restoring tables from separate SQL files to database '$DB' from directory '$DIR'"

	# Init database statistics vars
	TABLE_COUNT=0
	TABLE_COUNT_FAILED=0
	TABLE_COUNT_SUCCESS=0

	for TABLEFILE in $DIR/$DB.*.sql
	do
		echo "Importing file : $TABLEFILE"
		mysql -h $DBHOST -u $DBUSER $DB < $TABLEFILE
		# If the retore fails
		if [ $? -ne 0 ]
		then
			echo "Import of file '$TABLEFILE' failed !"
			TABLE_COUNT_FAILED=$(( TABLE_COUNT_FAILED + 1 ))
			FAILED_FILES=$"$FAILED_TABLES\n$TABLEFILE"
		else

			TABLE_COUNT_SUCCESS=$(( TABLE_COUNT_SUCCESS + 1 ))
		fi
		TABLE_COUNT=$(( TABLE_COUNT + 1 ))
	done

	echo "$TABLE_COUNT_SUCCESS/$TABLE_COUNT table(s) imported to database '$DB' from directory '$DIR' ($TABLE_COUNT_FAILED table(s) failed)"

	TOTAL_TABLE_COUNT=$(( TOTAL_TABLE_COUNT + TABLE_COUNT ))
	TOTAL_TABLE_COUNT_FAILED=$(( TOTAL_TABLE_COUNT_FAILED + TABLE_COUNT_FAILED ))
	TOTAL_TABLE_COUNT_SUCCESS=$(( TOTAL_TABLE_COUNT_SUCCESS + TABLE_COUNT_SUCCESS ))

done

# Show some statistics
echo "Statistics :"
echo "Tried to import $TOTAL_TABLE_COUNT table(s)"
echo "$TOTAL_TABLE_COUNT_FAILED table(s) import failed"
echo "$TOTAL_TABLE_COUNT_SUCCESS table(s) import were successful"
# Show the info about the failed dumps if needed
if [ "$TOTAL_TABLE_COUNT_FAILED" -gt 0 ]
then
	echo
	echo "The following file(s) failed :"
	echo -e $FAILED_FILES
fi
