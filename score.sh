r35

#copy over the files
cp ../allScores .
cp ../totalControl.sh .
cp ../totalScore.sh .

rm -r dir*

if [ ! -d "logs" ]; then
	mkdir logs
else
	rm logs/*
fi

if [ ! -d "sets" ]; then
	mkdir sets
	cd sets
	for i in {1..22}; do
		mkdir chr$i
	done
	cd ..
fi

#do the scoring
./totalControl.sh 1
