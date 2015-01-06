

FILES=./config*.exp
for f in $FILES
do
	echo "Found file $f file ..."
	./$f
done
