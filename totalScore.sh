echo begin scoring

chr=$1
file=$2
score=$3
infoLim=0.3
mafLim=0.01
export OMP_NUM_THREADS=2

echo THE SCORE IS $score

#DETERMINE THE DIRECTORY #######################
toOpen=`cat possAccess`
keepGoing=True
while [ $keepGoing == "True" ]; do
        if [ $toOpen == "True" ]; then
                echo False > possAccess
                dir=`head -1 possDirs`
                grep -v -w $dir possDirs > tempPoss; mv tempPoss  possDirs
                echo True > possAccess
                keepGoing=False
        else
                toOpen=`cat possAccess`
                sleep 1
        fi
done
echo we are in directory $dir
echo the chr is $chr
##################################################


######################################################################################
#DETERMINE IF WHOLE NEW.BED MUST BE MADE #############################################
#files are ready
if [ -f  ready.{$chr} ]; then
        echo all prepared
#in the process of making files
elif [ -f willBe.${chr} ]; then
        keepGoing=True
        while [ $keepGoing == "True" ]; do
                if [ -f ready.$chr ]; then
                        keepGoing=False
                else
                        sleep $(( ( RANDOM % 30 )  + 1 ))
                fi
        done
#will have to make files
else
        echo yep > willBe.${chr}
        numBgens=`ls *bgen | wc -l`
        checkGoing=True
        while [ $checkGoing == "True" ];do
                if [ $numBgens -ge 1 ]; then
                        echo waiting for no bgens
                        numBgens=`ls *bgen | wc -l`
                        sleep $(( ( RANDOM % 30 )  + 1 ))
                else
                        checkGoing=False
                fi
        done

        echo must do the prep work
	ls /athena/elementolab/scratch/kulmsc/forScoring/chr$chr | grep gz$ | grep -v split | while read rsLine; do
                zcat /athena/elementolab/scratch/kulmsc/forScoring/chr${chr}/$rsLine | awk -v var="$infoLim" '$7 > var {print $0}' | \
                awk '{ if (!($4=="A" && $5=="T" || $4 =="T" && $5 =="A" || $4 =="C" && $5 =="G" || $4 =="G" && $5 =="C") ) print $0; }' | \
                awk 'length($4) == 1 {print $0}' | awk 'length($5) == 1 {print $0}' | \
                awk '$10 > 0 {print $0}' | fgrep -v NA | fgrep -v nf | cut -f2 | sort | uniq -u >> allRsid.$chr
        done

        bgenix -g /athena/elementolab/scratch/kulmsc/ukbiobank/imputed/ukbb.${chr}.bgen -incl-rsids allRsid.$chr > new.${chr}.bgen
        rm chr${chr}.bgen chr${chr}.bgen.bgi
        plink2 --memory 4000 --bgen new.${chr}.bgen --sample /athena/elementolab/scratch/kulmsc/ukbiobank/imputed/ukbb.${chr}.sample --make-bed --out realTemp.$chr --threads 1
	plink --memory 4000 --bfile realTemp.$chr --keep-fam phase.eid --make-bed --out new.temp.${chr} --threads 1
	rm realTemp.${chr}.*
        plink --memory 4000 --bfile new.temp.${chr} --freq --out new.temp.${chr} --threads 1
        sed 's/  */\t/g' new.temp.${chr}.frq  | tail -n +2 | awk '$5 < 0.01 {print $2}' | sort | uniq -u > badRsids.${chr}
        cat new.temp.${chr}.bim | cut -f2 | sort | uniq -d >> badRsids.${chr}
        plink --memory 4000 --bfile new.temp.${chr} --exclude badRsids.${chr} --make-bed --out new.${chr} --threads 1
        cat new.${chr}.bim | cut -f2 > goodRsids.${chr}
        rm new.${chr}.bgen new.temp.${chr}.* chr${chr}.sample
	plink --bfile new.${chr} --freq --out new.${chr}

	if [ $score == "stackCT" ]; then
	        if [ ! -f new.${chr}.filter.rds ]; then
	                if [ ! -f willBeStack.$chr ]; then
	                        echo willBeStack > willBeStack.$chr
	                        rm new.${chr}.filter*
	                        plink --bfile new.$chr --geno 0.01 --fill-missing-a2 --make-bed --out new.${chr}.filter
	                        Rscript ~/prsDatabase/makeStackRds.R $chr
	                        rm new.${chr}.filter.bed
	                        rm new.${chr}.filter.bim
	                        rm new.${chr}.filter.fam
	                else
	                        while [ ! -f new.${chr}.filter.rds ];do
	                                sleep 30
	                        done
	                fi
	        fi
	fi



        echo goodToGo > ready.$chr
fi

# DONE MAKING WHOLE BED #########################################################################
#################################################################################################


################################################################################################
# BEGIN SCORING ################################################################################
cd dir$dir
echo $dir > info
echo $chr >> info
echo $file >> info
echo $score >> info

zcat /athena/elementolab/scratch/kulmsc/forScoring/chr${chr}/$file | awk -v var="$infoLim" '$7 > var {print $0}' | \
        awk '{ if (!($4=="A" && $5=="T" || $4 =="T" && $5 =="A" || $4 =="C" && $5 =="G" || $4 =="G" && $5 =="C") ) print $0; }' | \
        awk 'length($4) == 1 {print $0}' | awk 'length($5) == 1 {print $0}' | \
	awk '$10 > 0 {print $0}' | fgrep -v NA | fgrep -v nf | sort -k2 | rev | uniq -f8 -u | rev > preSummStat
fgrep -w -f ../goodRsids.${chr} preSummStat > temp; mv temp preSummStat
ls ../store* | fgrep ss > storeRecord
baseName="${file::-3}"

echo NOW WE DO THE SCORING
if [ $score == "report" ]; then
	plink --threads 1 --bfile ../new.${chr} --score preSummStat 2 4 8 sum --out score.1

	for i in 1; do
	        if [ -f score.${i}.profile ]; then
	        	sed 's/ \+/\t/g' score.${i}.profile | cut -f7 > ../store${dir}/${baseName}.${score}.${chr}.${i}
	                gzip ../store${dir}/${baseName}.${score}.${chr}.${i}
	        fi
	done


elif [ $score == "clump" ]; then
        cp /home/kulmsc/slurm/input/smallFiles/fileHeader .
        cat fileHeader preSummStat > temp ; mv temp preSummStat

        i=1
	for plim in 0.00000005 0.00005 0.05 0.5; do
                for r2lim in 0.25 0.5 0.75; do
			checkFile=`cat storeRecord | fgrep ${baseName}.${score}.${chr}.${i} | wc -l`
			if [ $checkFile -eq 0 ]; then
	                plink --memory 4000 --threads 1 --bfile ../new.${chr}  --clump preSummStat --clump-p1 $plim --clump-r2 $r2lim
	                if [ -f plink.clumped ]; then
	                        sed -e 's/ [ ]*/\t/g' plink.clumped | sed '/^\s*$/d' | cut -f4 | tail -n +2 > doneRsids
	                        fgrep -f doneRsids preSummStat > summStat
	                        plink --threads 1 --bfile ../new.${chr} --score summStat 2 4 8 sum
	                        mv summStat ../sets/chr${chr}/${baseName}.${score}.${chr}.${i}
	                        if [ -f plink.profile ]; then
	                                sed 's/ \+/\t/g' plink.profile | cut -f7 > ../store${dir}/${baseName}.${score}.${chr}.${i}
	                                gzip ../store${dir}/${baseName}.${score}.${chr}.${i}
	                                rm plink.profile
	                        fi
	                        rm plink.clumped
	                fi
        	        let i=i+1
			fi
		done
        done

elif [ $score == "sblup" ]; then  #WARNING - HIGH MEMORY USAGE
	checkFile=`cat storeRecord | fgrep ${baseName}.${score}.${chr}.1 | wc -l`
        if [ $checkFile -eq 0 ]; then
        cp /home/kulmsc/athena/workDir/extraFiles/makeMA.R .
        cp /home/kulmsc/athena/workDir/extraFiles/pToStat .
        cp /home/kulmsc/athena/workDir/extraFiles/metaData .
        cp /home/kulmsc/athena/workDir/extraFiles/allH2 .

        author=`echo $file | cut -f1 -d'.'`
        sampSize=`cat metaData | fgrep $author | cut -f2`
        numSnps=`cat metaData | fgrep $author | cut -f3`
        herit=`cat allH2 | fgrep $author | cut -f2 -d' '`
        param=`echo "scale=4; $numSnps * (1/$herit)" | bc`

	cat preSummStat > win.ss
        cat win.ss | cut -f2 | fgrep -w -f /athena/elementolab/scratch/kulmsc/refs/hapmapSnps > extraRsids
        plink --memory 4000 --bfile ../new.$chr --chr $chr --extract extraRsids --make-bed --out win
        Rscript makeMA.R $sampSize
        gcta64 --bfile win --cojo-file ss.ma --cojo-sblup $param --cojo-wind 100 --thread-num 1 --out part
        cat part.sblup.cojo >> sblup.sblup.cojo

        cat sblup.sblup.cojo | cut -f1 | sort | uniq > rsids
        cat preSummStat | fgrep -w -f rsids | sort -k2 > summStat
        cat sblup.sblup.cojo | sort -k1 > sblup
        cat sblup | cut -f4 > newBeta
        cat summStat | cut -f1-7 > part1; cat summStat | cut -f9-10 > part2
        paste part1 newBeta part2 > finalSummStat

        plink --memory 4000 --threads 1 --bfile ../new.${chr}  --score finalSummStat 2 4 8 sum
        if [ -f plink.profile ]; then
                sed 's/ \+/\t/g' plink.profile | cut -f7 > ../store${dir}/${baseName}.${score}.${chr}.1
                gzip ../store${dir}/${baseName}.${score}.${chr}.1
        fi
        mv finalSummStat ../sets/chr${chr}/${baseName}.${score}.${chr}.1
	fi


elif [ $score == "ldpred" ]; then
	checkFile=`cat storeRecord | fgrep ${baseName}.${score}.${chr}.1 | wc -l`
        if [ $checkFile -eq 0 ]; then
        python /athena/elementolab/scratch/kulmsc/workDir/extraFiles/makeLDPredStandard.py
        cp ~/athena/workDir/extraFiles/makeLDPredSet.R .
        authorName=`echo $file | cut -f1 -d'.'`
        sampleSize=`cat /athena/elementolab/scratch/kulmsc/workDir/extraFiles/metaData | grep $authorName | cut -f2`
        numberSnps=`cat /athena/elementolab/scratch/kulmsc/workDir/extraFiles/metaData | grep $authorName | cut -f3`
        let ldr=numberSnps/4500

        taskset -c $dir python ~/bin/LDPred.py coord --gf=/athena/elementolab/scratch/kulmsc/refs/ukbbRef/ukbb.ref.$chr --ssf=summStat --N=$sampleSize --out=madeCoord --ssf-format=STANDARD
        #taskset -c $dir python ~/bin/LDPred.py coord --gf=/athena/elementolab/scratch/kulmsc/refs/1000genomes/eur.chr$chr --ssf=summStat --N=$sampleSize --out=madeCoord --ssf-format=STANDARD
	#taskset -c $dir python ~/bin/LDPred.py coord --gf=/athena/elementolab/scratch/kulmsc/refs/ukbbRef/ukbb.ref.$chr --ssf=summStat --N=$sampleSize --out=madeCoord --A1 a1 --A2 a2 --pos pos --chr hg19chrc --pval p --eff or --rs snpid
	for f in 0.5 0.3 0.1 0.05 0.01; do
		taskset -c $dir python ~/bin/LDPred.py gibbs --cf=madeCoord --ldr=$ldr --f=$f --N=$sampleSize --out=donePred --ldf=None
	done
	
	i=1
        ls *_p[0-9].* | while read pred; do
                numLine=`cat storeRecord | fgrep ${baseName}.${score}.${chr}.${i}.gz | wc -l`
                if [ $numLine -eq 0 ]; then
                        Rscript makeLDPredSet.R $pred

                        plink --threads 1 --bfile ../new.${chr} --score newSummStat 2 4 8 sum header
                        if [ -f plink.profile ]; then
                                sed 's/ \+/\t/g' plink.profile | cut -f7 > ../store${dir}/${baseName}.${score}.${chr}.${i}
                                gzip ../store${dir}/${baseName}.${score}.${chr}.${i}
                                mv newSummStat ../sets/chr${chr}/${baseName}.${score}.${chr}.${i}
                        fi
                fi
                let i=i+1
        done
	fi

elif [ $score == "stackCT" ]; then
	author=`echo $file | cut -f1 -d'.'`
        checkFile=`cat storeRecord | fgrep ${baseName}.${score}.${chr} | wc -l`
        if [ $checkFile -lt 3 ]; then
        cp /home/kulmsc/athena/workDir/extraFiles/stackCT.R .

        Rscript stackCT.R $author $chr
        for i in {1..3};do
                plink --memory 4000 --threads 1 --bfile ../new.${chr}  --score summStat$i 2 4 8 sum
                if [ -f plink.profile ]; then
                        sed 's/ \+/\t/g' plink.profile | cut -f7 > ../store${dir}/${baseName}.${score}.${chr}.${i}
                        gzip ../store${dir}/${baseName}.${score}.${chr}.${i}
                fi
                mv summStat$i ../sets/chr${chr}/${baseName}.${score}.${chr}.${i}
        done

        fi


fi
rm *

# END SCORING ##################################################################################
################################################################################################


#FINISH UP ######################################
cd ..
echo $dir >> possDirs
echo done >> dones.$chr
##################################################

