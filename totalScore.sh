echo begin scoring

chr=$1
file=$2
score=$3
infoLim=0.3
mafLim=0.01

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
        plim=`cat /home/kulmsc/slurm/input/smallFiles/subsetCLUMP | cut -f1 -d'-' | sort -n | tail -1`
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
	ls /home/kulmsc/athena/forScoring/chr$chr | grep gz$ | grep -v split | while read rsLine; do
                zcat /home/kulmsc/athena/forScoring/chr${chr}/$rsLine | awk -v var="$infoLim" '$7 > var {print $0}' | \
                awk '{ if (!($4=="A" && $5=="T" || $4 =="T" && $5 =="A" || $4 =="C" && $5 =="G" || $4 =="G" && $5 =="C") ) print $0; }' | \
                awk 'length($4) == 1 {print $0}' | awk 'length($5) == 1 {print $0}' | \
                awk '$10 > 0 {print $0}' | fgrep -v NA | cut -f2 | sort | uniq -u >> allRsid.$chr
        done

        bgenix -g /home/kulmsc/athena/ukbiobank/imputed/ukbb.${chr}.bgen -incl-rsids allRsid.$chr > new.${chr}.bgen
        #rm chr${chr}.bgen chr${chr}.bgen.bgi
        plink2 --memory 4000 --bgen new.${chr}.bgen --sample /home/kulmsc/athena/ukbiobank/imputed/ukbb.${chr}.sample --make-bed --out realTemp.$chr --threads 1
	plink --memory 4000 --bfile realTemp.$chr --keep-fam phase.eid --make-bed --out new.temp.${chr} --threads 1
	rm realTemp.${chr}.*
        plink --memory 4000 --bfile new.temp.${chr} --freq --out new.temp.${chr} --threads 1
        sed 's/  */\t/g' new.temp.${chr}.frq  | tail -n +2 | awk '$5 < 0.01 {print $2}' | sort | uniq -u > badRsids.${chr}
        cat new.temp.${chr}.bim | cut -f2 | sort | uniq -d >> badRsids.${chr}
        plink --memory 4000 --bfile new.temp.${chr} --exclude badRsids.${chr} --make-bed --out new.${chr} --threads 1
        cat new.${chr}.bim | cut -f2 > goodRsids.${chr}
        rm new.${chr}.bgen new.temp.${chr}.* chr${chr}.sample

        #for ldpred LDPredFunct annoPred
        #cp /home/cbsumezey/sdk2004/1000genomes/eur.chr${chr}.*  .
        #for grabld
        #if grep -Fxq grabld allScores; then
        #        cat new.${chr}.fam | cut -f1 | sort -R | head -1000 > fam500.${chr}
        #        plink --bfile new.$chr --keep-fam fam500.${chr} --recode A --out forLD.${chr}
        #        cp ~/prsDatabase/ldGrabBLD.R ldGrabBLD.${chr}.R
        #        Rscript ldGrabBLD.${chr}.R $chr
        #        rm forLD.${chr}.raw ldGrabBLD.${chr}.R
        #fi
        #for LDPredFunct
        #if [ ! -d "LDpred-funct" ]; then
        #        cp -r ~/prsDatabase/LDpred-funct .
        #fi
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

echo NOW WE DO THE SCORING
if [ $score == "clump" ]; then
	
        cp /home/kulmsc/slurm/input/smallFiles/fileHeader .
        cp /home/kulmsc/slurm/input/smallFiles/subsetCLUMP .

        plim=`cat subsetCLUMP | cut -f1 -d'-' | sort -n | tail -1`
        zcat /home/kulmsc/athena/forScoring/chr${chr}/$file | awk -v var="$infoLim" '$7 > var {print $0}' | \
                awk '{ if (!($4=="A" && $5=="T" || $4 =="T" && $5 =="A" || $4 =="C" && $5 =="G" || $4 =="G" && $5 =="C") ) print $0; }' | \
                awk 'length($4) == 1 {print $0}' | awk 'length($5) == 1 {print $0}' | \
                awk '$10 > 0 {print $0}' | fgrep -v NA | sort -k2 | rev | uniq -f8 -u | rev > summStat
        fgrep -w -f ../goodRsids.${chr} summStat > temp; mv temp summStat
        cat fileHeader summStat > temp ; mv temp summStat
        baseName="${file::-3}"

        i=1
        cat subsetCLUMP | while read sub; do
                plim=`echo $sub | cut -f1 -d'-'`
                r2lim=`echo $sub | cut -f2 -d'-'`
                plink --memory 4000 --threads 1 --bfile ../new.${chr}  --clump summStat --clump-p1 $plim --clump-r2 $r2lim
                if [ -f plink.clumped ]; then
                        sed -e 's/ [ ]*/\t/g' plink.clumped | sed '/^\s*$/d' | cut -f4 | tail -n +2 > doneRsids
                        fgrep -f doneRsids summStat > doneSummStat
                        plink --threads 1 --bfile ../new.${chr} --score doneSummStat 2 4 8 no-sum
                        mv doneSummStat ../sets/chr${chr}/${baseName}.${score}.${chr}.${i}
                        if [ -f plink.profile ]; then
                                sed 's/ \+/\t/g' plink.profile | cut -f7 > ../store${dir}/${baseName}.${score}.${chr}.${i}
                                gzip ../store${dir}/${baseName}.${score}.${chr}.${i}
                                rm plink.profile
                        fi
                        rm plink.clumped
                fi
                let i=i+1
        done

elif [ $score == "sblup" ]; then  #WARNING - HIGH MEMORY USAGE
        baseName="${file::-3}"
        cp /home/kulmsc/slurm/input/smallFiles/makeMA.R .
        cp /home/kulmsc/slurm/input/smallFiles/pToStat .
        cp /home/kulmsc/slurm/input/smallFiles/metaData .
        cp /home/kulmsc/slurm/input/smallFiles/allH2 .

        author=`echo $file | cut -f1 -d'.'`
        sampSize=`cat metaData | fgrep $author | cut -f2`
        numSnps=`cat metaData | fgrep $author | cut -f3`
        herit=`cat allH2 | fgrep $author | cut -f2 -d' '`
        param=`echo "scale=4; $numSnps * (1/$herit)" | bc`

        zcat /home/kulmsc/athena/forScoring/chr${chr}/$file | awk -v var="$infoLim" '$7 > var {print $0}' | \
                awk '{ if (!($4=="A" && $5=="T" || $4 =="T" && $5 =="A" || $4 =="C" && $5 =="G" || $4 =="G" && $5 =="C") ) print $0; }' | \
                awk 'length($4) == 1 {print $0}' | awk 'length($5) == 1 {print $0}' | \
                awk '$10 > 0 {print $0}' | fgrep -v NA | sort -k2 | rev | uniq -f8 -u | rev > preSummStat
        fgrep -w -f ../goodRsids.${chr} preSummStat > temp; mv temp preSummStat


	cat preSummStat > win.ss
        cat win.ss | cut -f2 > extraRsids
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

        plink --memory 4000 --threads 1 --bfile ../new.${chr}  --score finalSummStat 2 4 8 no-sum
        if [ -f plink.profile ]; then
                sed 's/ \+/\t/g' plink.profile | cut -f7 > ../store${dir}/${baseName}.${score}.${chr}.1
                gzip ../store${dir}/${baseName}.${score}.${chr}.1
        fi
        mv finalSummStat ../sets/chr${chr}/${baseName}.${score}.${chr}.1

	cp sblup.sblup.cojo ../backup/${baseName}.${score}.${chr}.1

elif [ $score == "prsCS" ]; then
	zcat /home/kulmsc/athena/forScoring/chr${chr}/$file | awk -v var="$infoLim" '$7 > var {print $0}' | \
	awk '{ if (!($4=="A" && $5=="T" || $4 =="T" && $5 =="A" || $4 =="C" && $5 =="G" || $4 =="G" && $5 =="C") ) print $0; }' | \
	awk 'length($4) == 1 {print $0}' | awk 'length($5) == 1 {print $0}' | \
	awk '$10 > 0 {print $0}' | fgrep -v NA | sort -k2 | rev | uniq -f8 -u | rev > fullSummStat
        fgrep -w -f ../goodRsids.${chr} fullSummStat > temp; mv temp fullSummStat

        cat fullSummStat | cut -f2,4,5,8,10 > goSummStat

        cat goSummStat | cut -f1 > specificRsids
        plink --threads 1 --bfile ../new.${chr} --extract specificRsids --make-bed --out ss

        name=`echo $file | cut -f1 -d'.'`
        sampSize=`cat ~/prsDatabase/metaData | grep $name | cut -f2`

        cp /home/kulmsc/slurm/input/prscs/* .

	cat summStatHeader goSummStat > smallSummStat
        i=1
	b=0.5
        for phi in 0.000001 0.5; do
                for a in 1 10; do
			taskset -c $dir python PRScs.py --ref_dir=/home/kulmsc/athena --bim_prefix=ss --sst_file=smallSummStat --n_gwas=$sampSize --out_dir=. \
                        	--chrom=$chr --phi=$phi --a=$a --b=$b --n_burnin=100 --n_iter=300
                        cat pst* > fullPst
                        rm pst*

                        pstFile=fullPst
                        cat $pstFile | cut -f2 > prsRsids
                        fgrep -f prsRsids fullSummStat > preSummStat
                        cat preSummStat | cut -f1-7 > preSS1
                        cat preSummStat | cut -f9-10 > preSS2
                        cat $pstFile | cut -f6 > newBeta
                        paste preSS1 newBeta preSS2 > summStat

                        baseName="${file::-3}"
                        plink --bfile ../new.${chr}  --score summStat 2 4 8 no-sum
                        if [ -f plink.profile ]; then
                                sed 's/ \+/\t/g' plink.profile | cut -f7 > ../store${dir}/${baseName}.${score}.${chr}.${i}
                                gzip ../store${dir}/${baseName}.${score}.${chr}.${i}
                        fi
                        mv summStat ../sets/chr${chr}/${baseName}.${score}.${chr}.${i}
                        let i=i+1
                        rm fullPst
                done
        done


fi
rm *

# END SCORING ##################################################################################
################################################################################################


#FINISH UP ######################################
cd ..
echo $dir >> possDirs
echo done >> dones.$chr
##################################################

