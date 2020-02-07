for chr in {1..22}; do
	plink --bfile ~/athena/ukbiobank/calls/ukbb.${chr} --keep-fam ~/athena/prepUKData/scottTotalPhase --make-bed --out forGwas
	cat forGwas.fam | cut -f1-5 -d' ' > mainFam
	paste -d' ' mainFam ~/athena/prepUKData/scott.hyper > forGwas.fam
	plink --bfile forGwas --logistic
	cat plink.assoc.logistic | tail -n +2 >> ss.scott.hyper
	rm plink*
	rm forGwas*
done
