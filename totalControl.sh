phaseNum=$1

cp /home/kulmsc/slurm/input/smallFiles/phase${phaseNum}.eid phase.eid

maxDirs=10
maxJobs=10
chrStart=1
chrStop=10

if [ $# -eq 0 ]; then
        echo "no argument"
else
	echo "have argument" $1
	rm possDirs
	for (( i=1; i<=$maxDirs; i++ )); do
		mkdir dir$i
		if [ ! -d store$i ]; then
			mkdir store$i
		fi
		echo $i >> possDirs
	done
	echo True > possAccess

	for (( num=$chrStart; num<=$chrStop; num++ )); do
		echo chromosome $num
		cat allScores | while read score; do		
			echo $score
			#change report here and in totalScore!!!
			ls /home/kulmsc/athena/forScoring/chr${num} | grep gz$ | while read line; do
				echo the file is $line

				author=`echo $line | cut -f1 -d'.'`
				constSetFile=0
				for (( storeNum=1; storeNum<=$maxDirs; storeNum++ )); do
					setFiles=`ls store${storeNum}/${author}.ss.${num}.${score}.* 2> /dev/null | wc -l`
					if [ $setFiles -gt 0 ]; then
						constSetFile=1
					fi
				done

				if [ $constSetFile -eq 0 ]; then
					echo onto scoring
					./totalScore.sh $num $line $score &> logs/${line}.${num}.${score}.log &
					sleep $(( ( RANDOM % 30 )  + 1 ))
				fi

				goOn=False
				while [ $goOn == "False" ]; do
					openSlots=`cat possDirs | wc -l`
					if [ $openSlots -gt 0 ]; then
						echo NOW WE CAN GO
						goOn=True
					else
						echo MUST WAIT FOR ROOM TO GO
						sleep $(( ( RANDOM % 30 )  + 1 ))
						openSlots=`cat possDirs | wc -l`
					fi
				done
			done		
		done
	done
fi
