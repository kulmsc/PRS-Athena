#serverNumber=`echo $HOSTNAME | cut -f1 -d'.' | cut -f2 -d'0'`
#let serverNumber=serverNumber-1
serverNumber=1

for i in {1..22}; do
	ls /home/kulmsc/athena/workDir/kulmsc/sets/chr$i | fgrep $1 |  while read line; do
		author=`echo $line | cut -f1 -d'.'`
		method=`echo $line | cut -f4 -d'.'`
		ver=`echo $line | cut -f6 -d'.'`
		cat /home/kulmsc/athena/workDir/kulmsc/sets/chr${i}/$line >> /home/kulmsc/athena/workDir/kulmsc/sets/${author}.${method}.${ver}.${serverNumber}.set
                #echo $author
                #echo $sets
	done
	cd ..
done
