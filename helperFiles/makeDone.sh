
rm temp
for i in {1..48};do
        ls /home/kulmsc/athena/workDir/kulmsc/store${i} | while read line; do
                echo $line >> temp
        done
done

cat temp | cut -f3 -d'.' | sort | uniq | while read chr; do
	rm dones.$chr
	cat temp | fgrep ss.${chr}.$1 | cut -f1 -d'.' | sort | uniq -c >> /home/kulmsc/athena/workDir/kulmsc/dones.$chr
done

