#this file combines the things into workingResults/Sets and gets them into finalResults/Sets

# 1 - train or test   2 - the method   3 - addOn name
if [ $# -eq 0 ]; then
        echo "1 - train or test  |  2 - the method  | 3 - addOn Name"
else

tort=$1
method=$2
addOn=$3

if [ -f /home/kulmsc/athena/workDir/finalResults/${method}.${tort}.${addOn}.1.1.gz ]; then
        hiNum=`ls /home/kulmsc/athena/workDir/finalResults | fgrep ${method}.${tort}.${addOn} | cut -f5 -d'.' | sort | tail -1`
        let setNum=hiNum+1
else
        setNum=1
fi

if [ $tort == "train" ]; then
	cd /home/kulmsc/athena/workDir/workingSets
	/home/kulmsc/athena/workDir/helperFiles/finalSetsCombine.sh $addOn $setNum
	mv *gz ../finalSets
fi

cd /home/kulmsc/athena/workDir/workingResults
python /home/kulmsc/athena/workDir/helperFiles/finalResultsCombine.py

numGrand=`ls grand* | wc -l`
setNum=1
for (( num=1; num<=$numGrand; num++ )); do
	#mv grandField${num}.gz ../finalResults/${method}.${tort}.${addOn}.${num}.${setNum}.gz
	mv grandField${num}.gz ${method}.${tort}.${addOn}.${num}.${setNum}.gz
done
cd ..
fi
