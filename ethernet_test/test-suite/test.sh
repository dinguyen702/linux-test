rm -r sent.lock
rm -r /home/vince/sent.lock

#
# Had to bang out a function to send an email since my 
# home AT&T ISP occasionally returns "can't be found"
# for DNS lookups to smtp.gmail.com for some #$$& 
# reason. Bahhh!!
function email_message() {
	DATE=`date +\%Y-\%m-\%d-at-\%H:\%M:\%S`
	SUBJECT=${1}
	BODY=${2}
	rc=1
	count=0
	while [ $rc -eq 1 ]
	do
		if [ $# -eq 3 ] 
		then
			echo "$BODY" | mutt -a ${3} -s "$SUBJECT $DATE" -- vbridger@altera.com
		elif [ $# -eq 2 ]
		then
			echo "$BODY" | mutt -s "$SUBJECT $DATE" -- vbridger@altera.com
		fi
		rc=$?
		(( count++ ))
	done
}


## global status, assume pass - 0 - unless a test fails. 
## used to output/send summary status at the end of the
## test.
globalStatus=0

# ${1} - status to check. 0 for pass, otherwise a failure
# ${2} - SUBJ to send
# ${3} - logfile to send if failure
function chkAndReport() {
	echo "${2} returned status ${1}\r"
	if [ ${1} -eq 0 ]
	then 
		SUBJ="${2} Passed!" 
		echo $SUBJ
		email_message "$SUBJ" "$SUBJ"
	else 
		SUBJ="${2} Failed!" 
		echo $SUBJ
		globalStatus=1
		email_message "$SUBJ" "$SUBJ" ${3}
	fi
}

FILES=./emactest*.exp
for f in $FILES
do
	./reboottrgt.exp > reboottrgt.log
	chkAndReport "$?" "Reboot Target " reboottrgt.log

	echo "Executing $f ...\r"
	./$f > $f.log
	chkAndReport "$?" "$f test " $f.log
done

if [ $globalStatus -eq 0 ]
then 
	SUBJ="Tests Complete: All tests Passed!" 
	echo $SUBJ
	email_message "$SUBJ" "$SUBJ"
else 
	SUBJ="Tests Complete: One or more tests Failed!" 
	echo $SUBJ
	set globalStatus 1
	email_message "$SUBJ" "$SUBJ" 
fi

rm *.log

