




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

./jumbo.exp > jumbo.log
rc=$?
if [ $rc -eq 0 ]
then 
	SUBJ="Jumbo tests Passed!" 
	echo $SUBJ
	email_message "$SUBJ" "$SUBJ"
else 
	SUBJ="Jumbo tests Failed!" 
	echo $SUBJ
	globalStatus=1
	email_message "$SUBJ" "$SUBJ" jumbo.log
fi
