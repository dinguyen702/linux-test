
function email_fail() {
	DATE=`date +\%Y-\%m-\%d-at-\%H:\%M:\%S`
	SUBJECT=${1}
	BODY=${2}
	rc=1
	count=0
	while [ $rc -eq 1 ]
	do
		echo "$BODY" | mutt -a ${3} -s "$SUBJECT $DATE" -- vbridger@altera.com
		rc=$?
		(( count++ ))
	done
	echo $count
}


function email_pass() {
	DATE=`date +\%Y-\%m-\%d-at-\%H:\%M:\%S`
	SUBJECT=${1}
	BODY=${2}
	rc=1
	count=0
	while [ $rc -eq 1 ]
	do
		echo "$BODY" | mutt -s "$SUBJECT $DATE" -- vbridger@altera.com
		rc=$?
		(( count++ ))
	done
	echo $count
}

for i in {1..10}
do
	sudo ifconfig eth0 down
	sudo ifconfig eth0 up
	email_fail "subj fail " "body fail " vlan.log  
	email_pass "subj pass " "body pass "
done

