method=$1

if [ $# -eq 0 ]; then
        echo "no argument"
else

#find the max store filled
for i in {1..10};do 
	x=`ls store${i} | wc -l`
	if [ $x -gt 0 ]; then
		 maxDir=$i
	fi
done


#get the number of file types created
rm temp
for i in {1..10};do
        ls store${i} | while read line; do
                echo $line  >> temp
        done
done                                   #change here pos of method  
maxPos=`cat temp | fgrep $method | cut -f2 -d'.' | cut -f1 -d'-' | sort | uniq | wc -l`

for (( i=1; i<=$maxDir; i++ )); do
	echo $i
	cd store$i
	python /home/kulmsc/athena/workDir/helperFiles/testCombo.py $i $maxPos $method &
	echo $i $maxPos $method
	sleep 1
	cd ..
done

wait


for (( i=1; i<=$maxDir; i++ )); do
	mv store${i}/field* results
done
fi
