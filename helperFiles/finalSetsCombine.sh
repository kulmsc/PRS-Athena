ls | while read line; do
	name=`echo $line | cut -f1 -d'.'`
	ver=`echo $line | cut -f3 -d'.'`
	method=`echo $line | cut -f2 -d'.'`
	addOn=$1
	setNum=$2
	cat $line >> /home/kulmsc/athena/workDir/workingSets/${name}.${ver}.${setNum}.final.set.${method}.${addOn}
done

ls /home/kulmsc/athena/workDir/workingSets/*.final.* | while read line; do
	gzip $line
done
