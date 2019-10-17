#!/bin/bash

#Variables
COPYDATE=$(date +"%Y-%m-%d %T")
FILEDATE=$(date +"%Y-%m-%d")
COMMENT=1

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
SERVERIP=$(cat $LOGDIR/server.txt)
CRED=$(cat $LOGDIR/user.txt)
CREDFILE=$LOGDIR/user.txt
SERVERFILE=$LOGDIR/server.txt
SHAREDPATH=/srv/shared


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
	
	if [ ! -f "$CREDFILE" ];
	then echo $COPYDATE Step $COMMENT: ERROR User credentials file not accessible, exiting >> $LASTRUN
	exit 2
	fi

	if [ ! -f "$SERVERFILE" ];
	then echo $COPYDATE Step $COMMENT: ERROR Server IP file list not accessible, exiting >> $LASTRUN
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

file_count () {

	case $1 in 
		source)
		SRCAVICOUNT=$(ls $CAMPATH/*.avi | wc -l)
		SRCJPGCOUNT=$(ls $CAMPATH/*.jpg | wc -l)
		echo $SRCAVICOUNT AVI FILES AND $SRCJPGCOUNT JPG FILES
		#echo $COPYDATE Step $COMMENT: $SRCAVICOUNT video files to be copied and $SRCJPGCOUNT images to be copied >> $LASTRUN
		let "COMMENT ++"
		;;
		target)
		TRGAVICOUNT=$(ls $SHAREDPATH/*.avi | wc -l)
		TRGJPGCOUNT=$(ls $SHAREDPATH/*.jpg | wc -l)
		echo $TRGAVICOUNT AVI FILES AND $TRGJPGCOUNT JPGFILES
		#echo $COPYDATE Step $COMMENT: $TRGAVICOUNT video files were copied and $TRGJPGCOUNT images were copied >> $LASTRUN
		let "COMMENT ++"
		;;
		*)
		echo $COPYDATE Step $COMMENT: Unknown option provided to file_count, exiting >> $LASTRUN
		let "COMMENT ++"
		;;
	esac

}


copy_files (){

	echo $COPYDATE Step $COMMENT: Copying .avi files to the backup server >> $LASTRUN
	let "COMMENT ++"

	#Copy .avi files
	scp -i $SSHKEY $CAMPATH/*.avi $CRED@$SERVERIP:$SERVERPATH/avi 2>>$AVILOG 

	echo $COPYDATE Step $COMMENT: Copying .jpg files to the backup server >>$LASTRUN
	let "COMMENT ++"

	#Copy .jpg files
	scp -i $SSHKEY $CAMPATH/*.jpg $CRED@$SERVERIP:$SERVERPATH/jpg 2>>$JPGLOG 

	echo $COPYDATE Step $COMMENT: Copy completed >>$LASTRUN
	let "COMMENT ++"

}

process_exit () {

	echo $COPYDATE Step $COMMENT: Setting run result flag >>$LASTRUN
	let "COMMENT ++"

	echo 0 >$RUNRESULT

	echo $COPYDATE Step $COMMENT: Copying logs to backup server >>$LASTRUN
	let "COMMENT ++"

	scp -i $SSHKEY $AVILOG $CRED@$SERVERIP:$SERVERPATH/avi_error.txt
	scp -i $SSHKEY $JPGLOG $CRED@$SERVERIP:$SERVERPATH/jpg_error.txt
	scp -i $SSHKEY $RUNRESULT $CRED@$SERVERIP:$SERVERPATH/run_result.txt

	echo $COPYDATE Step $COMMENT: Logs copied to backup server >>$LASTRUN
	let "COMMENT ++"
	echo $COPYDATE Step $COMMENT: Process completed >>$LASTRUN
	let "COMMENT++"

}


#Main

#server_check
#log_setup
#path_check
file_count source
#copy_files
file_count target
#process_exit

