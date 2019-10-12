#!/bin/bash

#File Paths
LOGDIR=~/cleanup_logs
LASTRUN=~/cleanup_logs/last_run_log.txt
DAILYDIR=$LOGDIR/$FILEDATE
DAILYLOG=$DAILYDIR/daily_log.txt
AVILOG=$DAILYDIR/avi_error.txt
JPGLOG=$DAILYDIR/jpg_error.txt
RUNRESULT=$LOGDIR/run_result.txt
SSHKEY=~/.ssh/backup_key
CAMPATH=/var/lib/motion
SERVERPATH=/srv/motion

#Variables
COPYDATE=$(date +"%Y-%m-%d %T")
FILEDATE=$(date +"%Y-%m-%d")
SERVERIP=$LOGDIR/server.txt
USER=$LOGDIR/user.txt
COMMENT=1

#Log Setup Function
log_setup() {

	echo $COPYDATE Step $COMMENT: Creating log directory and log files >> $LASTRUN
	let "COMMENT++"
	
	echo 1> $RUNRESULT
	mkdir $DAILYDIR
	touch $DAILYLOG
	touch $AVILOG
	touch $JPGLOG
}

#Path check function
path_check() {

	echo $COPYDATE Step $COMMENT: Checking log files were created >> $LASTRUN
	let "COMMENT ++"

	if [ ! -d "$DAILYDIR" ];
	then  echo $COPYDATE Step $COMMENT: ERROR Directory $DAILYDIR not created, exiting >> $LASTRUN 
	exit 2 
	fi

	if [ ! -f "$DAILYLOG" ];
	then echo $COPYDATE Step $COMMENT: ERROR File $DAILYLOG not created, exiting >> $LASTRUN
	exit 2
	fi

	if [ ! -f "$AVILOG" ];
	then echo $COPYDATE Step $COMMENT: ERROR File $AVILOG not created, exiting >> $LASTRUN
	exit 2
	fi

	if [ ! -f "$JPGLOG" ];
	then echo $COPYDATE Step $COMMENT: ERROR File $JPGLOG not created, exiting >> $LASTRUN
	exit 2
	fi

	if [ ! -f "$SSHKEY" ];
	then echo $COPYDATE Step $COMMENT: ERROR SSH Keyfile not accessible, exiting >> $LASTRUN
	exit 2
	fi
	
	echo $COPYDATE Step $COMMENT: Log files were created successfully >> $LASTRUN
	let "COMMENT ++"		
}

#Server check function
server_check () {

	echo $COPYDATE Step $COMMENT: Checking $SERVERIP is accessible >> $LASTRUN
	let "COMMENT ++"
	
	#Check server port 22 accessible, result = 0 is yes, > 0 is no
	nc -z $SERVERIP 22
	SERVERSTATUS=$?
	
	if [ $SERVERSTATUS -ne 0 ]
	then 
		echo $COPYDATE Step $COMMENT: $SERVERIP is unreachable, exiting >> $LASTRUN
		exit 2
	else 
		echo $COPYDATE Step $COMMENT: $SERVERIP is up >> $LASTRUN
		let "COMMENT ++"
	fi

}

copy_files (){

	echo $COPYDATE Step $COMMENT: Copying .avi files to the backup server >> $LASTRUN
	let "COMMENT ++"

	#Copy .avi files
	scp -i $SSHKEY $CAMPATH/*.avi backup@$SERVERIP:$SERVERPATH/avi 2>>$AVILOG 

	echo $COPYDATE Step $COMMENT: Copying .jpg files to the backup server >>$LASTRUN
	let "COMMENT ++"

	#Copy .jpg files
	scp -i $SSHKEY $CAMPATH/*.jpg backup@$SERVERIP:$SERVERPATH/jpg 2>>$JPGLOG 

	echo $COPYDATE Step $COMMENT: Copy completed >>$LASTRUN
	let "COMMENT ++"

}

process_exit () {

	echo $COPYDATE Step $COMMENT: Setting run result flag >>$LASTRUN
	let "COMMENT ++"

	echo 0 >$RUNRESULT

	echo $COPYDATE Step $COMMENT: Copying logs to backup server >>$LASTRUN
	let "COMMENT ++"

	scp -i $SSHKEY $AVILOG backup@$SERVERIP:$SERVERPATH/avi_error.txt
	scp -i $SSHKEY $JPGLOG backup@$SERVERIP:$SERVERPATH/jpg_error.txt
	scp -i $SSHKEY $RUNRESULT backup@$SERVERIP:$SERVERPATH/run_result.txt

	echo $COPYDATE Step $COMMENT: Logs copied to backup server >>$LASTRUN
	let "COMMENT ++"
	echo $COPYDATE Step $COMMENT: Process completed >>$LASTRUN
	let "COMMENT++"

}


#Main

server_check
log_setup
path_check
copy_files
process_exit
