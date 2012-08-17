#!/bin/bash

#This script is for exporting your restored
#MySQL data directory into .sql files.  It 
#is not meant to be used on your current 
#MySQL data directory.

SOCKET=/tmp/mysql_sock
PID=/tmp/mysql_pid
ERROR_LOG=/tmp/mysql_restore.log
CURDATADIR=$(mysql -uadmin -p`cat /etc/psa/.psa.shadow` -Ns -e"show variables like 'datadir';"| awk '{print $2}')
#Where is your data?
echo "Please provide the full path of your MySQL data directory that was restored:";

read DATADIR

if [ ! -d "$DATADIR" ]; then
	echo "This directory does not exist. Exiting.";
	exit 0;
fi

if [ "$DATADIR" ==  $CURDATADIR -o "$DATADIR" == ${CURDATADIR%/} ]; then
	echo "This data directory is already being used by MySQL. Exiting.";
        exit 0;
fi

echo "Please provide the full path of the directory you would like to place your .sql files in:";

read RESTOREDIR

if [ ! -d "$RESTOREDIR" ]; then
	echo "Creating directory $RESTOREDIR, since it doesn't seem to exist..";
	mkdir -p $RESTOREDIR;
fi

#Start MySQL instance
echo "Starting MySQL instance...";
/usr/bin/mysqld_safe --user=mysql --datadir=$DATADIR --log-error=$ERROR_LOG  --pid-file=$PID --skip-external-locking --skip-networking --socket=$SOCKET 2>&1 > /dev/null  &

sleep 5 ;
echo "MySQL started with the proccess: $(cat /tmp/mysql_pid)";
echo " ";

echo "Exporting databases:";

#Export the databases
mysql -u'admin' -p$(cat /etc/psa/.psa.shadow) --socket=$SOCKET -Ns -e'show databases;'| perl -ne 'print unless /\b(mysql|psa|horde|atmail|information_schema|apsc|sitebuilder.*|phpmyadmin.*)\b/'|while read x
	do
		echo -n "Dumping $x ...";
		 mysqldump --add-drop-table -u'admin' --socket=$SOCKET -p$(cat /etc/psa/.psa.shadow) $x > "$RESTOREDIR"/$x.sql;
		echo "Finished.";
	done

#Finish up and close the process
kill -15 $( cat /tmp/mysql_pid ) ;
sleep 5 ;
echo  " ";

echo "Done.  Your databases have been exported to $RESTOREDIR.";
