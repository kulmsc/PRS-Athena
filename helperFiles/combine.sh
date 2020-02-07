#this file gets things from the store and sets directory into workingResults/Sets

# 1 - train or test   2 - the method

if [ $# -eq 0 ]; then
        echo "1 - train or test  |  2 - the method"
else

rm /home/kulmsc/athena/workDir/workingResults/*
rm /home/kulmsc/athena/workDir/workingSets/*
rm /home/kulmsc/athena/workDir/kulmsc/results/*
rm /home/kulmsc/athena/workDir/kulmsc/sets/*set

if [ $1 == "train" ]; then
	echo going train
	/home/kulmsc/athena/workDir/helperFiles/trainCombine.sh $2

	/home/kulmsc/athena/workDir/helperFiles/combineSets.sh $2
	cp /home/kulmsc/athena/workDir/kulmsc/sets/*set /home/kulmsc/athena/workDir/workingSets
fi

if [ $1 == "test" ]; then
        echo going test
	/home/kulmsc/athena/workDir/helperFiles/testCombine.sh $2
fi

cp /home/kulmsc/athena/workDir/kulmsc/results/* /home/kulmsc/athena/workDir/workingResults
fi
