#!/bin/bash

###
# Author: Olaf Reitmaier <olafrv@gmail.com>
#
# MySQL replication status check as Nagios plugin (to be run from Nagios Server):
#
# Result: returns a Nagios status code:
# - 0 with its respective message (i.e. "STATUS: OK")
# - 1 if a warning (WARNING) with a descriptive message
# - 2 if there is a critical error (CRITICAL) with a descriptive message
##

MODE=$1   # -d to show and exit, -n to check and return Nagios status code
ROLE=$2   # master or slave
MYIP=$3   # MySQL server IPv4 address (or hostname)
MYPO=$4   # MySQL server port
MYUS=$5   # MySQL username
MYPW=$6   # MySQL password

CMD="/usr/bin/mysql -h $MYIP -P $MYPO -u $MYUS -p$MYPW"
FOUT="/tmp/check_mysql_replication_${ROLE}_${MYIP}_${MYPO}"

rm -f $FOUT;
DELETED=$?
if [ $DELETED -ne 0 ]
then
	echo "Can't write output file: $FOUT"
	exit 2
fi

if [ "$MODE" == "-d" ]
then
	echo -n "show $ROLE status \G" | $CMD
elif [ "$MODE" == "-n" ]
then

	echo -n ";" | $CMD 2>&1 >/dev/null
	MYSQL_STATUS=$? 
	if [ $MYSQL_STATUS -eq 0 ]
	then 
		MYSQL_STATUS_MSG="OK ($MYSQL_STATUS)"    
		echo -n "MYSQL_STATUS: $MYSQL_STATUS_MSG";
	else
		MYSQL_STATUS_MSG="Error ($MYSQL_STATUS)"    
		echo -n "MYSQL_STATUS: $MYSQL_STATUS_MSG";
		echo -n -e "\n"
		exit 2
	fi
	
	echo "show $ROLE status \G" | $CMD > $FOUT

	if [ "$ROLE" == "master" ]
	then
		# MM = MySQL Master
		MM_FILE=$(cat $FOUT | grep "File:" | cut -d":" -f2 | sed 's/ //g')
		MM_POSITION=$(cat $FOUT | grep "Position:" | cut -d":" -f2 | sed 's/ //g')
		echo -n " MYSQL_MASTER: $MM_POSITION ($MM_FILE)"
	else
		# MS = MySQL Slave
		MS_IO_RUN=$(cat $FOUT | grep "Slave_IO_Running:" | cut -d":" -f2 | sed 's/ //g')
		MS_IO_ERRNO=$(cat $FOUT | grep " Last_IO_Errno:" | cut -d":" -f2 | sed 's/ //g')
		MS_IO_ERR=$(cat $FOUT | grep " Last_IO_Error:" | cut -d":" -f2 | sed 's/ //g')
		MS_SQL_RUN=$(cat $FOUT | grep " Slave_SQL_Running:" | cut -d":" -f2 | sed 's/ //g')
		MS_SQL_ERRNO=$(cat $FOUT | grep " Last_SQL_Errno:" | cut -d":" -f2 | sed 's/ //g')
		MS_SQL_ERR=$(cat $FOUT | grep " Last_SQL_Error:" | cut -d":" -f2 | sed 's/ //g')
				
		echo -n " MYSQL_SLAVE_IO: $MS_IO_RUN" 
		if [ "$MS_IO_ERRNO" != "0" ]
		then
			echo -n " MYSQL_SLAVE_IO_ERROR: ${MS_IO_ERRNO}: ${MS_IO_ERR:0:100}"
		fi

		echo -n " MYSQL_SLAVE_SQL: $MS_SQL_RUN" 
		if [ "$MS_SQL_ERRNO" != "0" ]
		then 
			echo -n " MYSQL_SLAVE_SQL_ERROR: ${MS_SQL_ERRNO}: ${MS_SQL_ERR:0:100}"
		fi

		if [ "$MS_SQL_RUN" != "Yes" ] || [ "$MS_IO_RUN" != "Yes" ] || [ "$MS_IO_ERRNO" != "0" ] || [ "$MS_SQL_ERRNO" != "0" ]
		then
			echo -n -e "\n"
			exit 2
		fi
	fi

else
	echo -n "Execute: bash check_mysql.sh [-d|-n] [master|slave] <IP> <Port> <Username> <Password>"
fi

echo -n -e "\n"
