if [ $# -eq 0 ]; then
        echo "1 - to subset by"
else

ls | fgrep $1  | while read line; do
	author=`echo $line | cut -f1 -d'.'`
	method=`echo $line | cut -f2 -d'.'`
	ver=`echo $line | cut -f6 -d'.'`
	#baseName="${line::-3}"
	for chr in {1..22}; do
		zcat $line | awk -v var="$chr" '$1 == var {print $0}' | gzip > /home/kulmsc/athena/forScoring/chr${chr}/${author}.${method}-${ver}.${chr}.gz
	done
done
fi
