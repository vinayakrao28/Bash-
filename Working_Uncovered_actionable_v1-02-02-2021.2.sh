#!/usr/bin/bash
####################################################################################
####################################################################################
#Welcome to the script which is used to find Pathogenic and Likely Pathogenic variants from Uncovered
#Scripted by Vinayak Rao
#Date:02-02-2021
#Version: 1.0
###################################################################################
echo '\nScript to find uncovered\n'
echo | date 
echo 
echo -n "Please give the project name : \t"
read text
echo 
#python /bioinfo-data/Vinayak/Script/Python.py
DATABASE="/bioinfo-data/Vinayak/Databases"
INPUT="$1"
sed 's/chr//g' $INPUT > input.bed
#cut -f1-3 input.bed > input_v1.bed
bedtools intersect -a input.bed -b $DATABASE/clinvar_*.vcf -wao > intersect.txt #intersect with given bed file 

############################################## Filtering column started ####################################################################
grep -vwE "CLNREVSTAT=no_assertion_criteria_provided" intersect.txt > Fintersect.txt
grep -iw "RS" Fintersect.txt > RS.txt #grep with RS_id only
grep -i "CLNSIG=Pathogenic;" RS.txt > P.txt #grep patho
grep -i "CLNSIG=Likely_pathogenic;" RS.txt > LP.txt #grep Likely Patho
grep -i "CLNSIG=Pathogenic/Likely_pathogenic;" RS.txt > PLP.txt #grep path & Likely Patho

awk '{print $12}' P.txt LP.txt PLP.txt > Onliner_for_RS.txt #comman 11th colum for rs_id
sed -n 's/^.*RS/RS/p' Onliner_for_RS.txt > RS_Comman.txt #only rs_id
sed  's/;.*//' RS_Comman.txt > RS_final.txt #Final_rs_id

awk '{print $1, $2, $3, $4, $5,  $6, $8, $9, $12}' P.txt > P1.txt #extract 3 column 
awk '{print $1, $2, $3, $4, $5,  $6, $8, $9, $12}' LP.txt > LP1.txt
awk '{print $1, $2, $3, $4, $5,  $6, $8, $9, $12}' PLP.txt > PLP1.txt  

sed 's/^/Pathogenic &/g' P1.txt > annotation_patho.txt
sed 's/^/Likely_pathogenic &/g' LP1.txt > annotation_likely.txt
sed 's/^/Pathogenic_Likely_pathogenic &/g' PLP1.txt > annotation_plp.txt


cat annotation_patho.txt annotation_likely.txt annotation_plp.txt > merged_anotation.txt 
grep -oh "\w*GENEINFO=*\w*" Onliner_for_RS.txt > Geneinfo.txt #extrating Gene name
tr ';' '\n' < Onliner_for_RS.txt > pre_clinsig.txt 
grep "CLNDN=" pre_clinsig.txt > Clinsig.txt
#grep -oh "\w*CLNDN=*\w*" Onliner_for_RS.txt > Clinsig.txt #extrating Clinical_Condition 

paste -d ' ' merged_anotation.txt RS_final.txt Geneinfo.txt Clinsig.txt > Uncovered_Actionable.xls

awk '{print $2, $3, $4, $5, $7, $8, $9, $11, $12, $1, $13}' Uncovered_Actionable.xls > Uncovered_Actionable_2.xls
sed 's/^/chr/' Uncovered_Actionable_2.xls > aa.xls
#cp aa.xls xx.bed
#sed 's/ \+/\t/g' xx.bed > yy.bed
#bedtools intersect -a yy.bed -b $INPUT -wo > Amplicon_id.txt
#awk '{print $14}' Amplicon_id.txt > amplicon_column.txt
#paste -d ' ' aa.xls amplicon_column.txt > all_column.xls

############################################## Columnn extrating END #######################################################################

############################################## Preparing header file START #############################################################################
echo chrom > chrom.txt
echo Amplicon_START > amplicon_start.txt
echo Amplicon_END > amplicon_end.txt
echo POS > pos.txt 
echo REF > ref.txt
echo ALT > alt.txt
echo db_SNP_ID > rs_id.txt
echo Gene > gene.txt
echo Clinical_Classification > Clinical_Classification.txt
echo Clinical_Condition > Clinical_Condition.txt
echo Amplicon_id > Amplicon_id.txt
paste -d ' ' chrom.txt amplicon_start.txt amplicon_end.txt Amplicon_id.txt pos.txt ref.txt alt.txt rs_id.txt gene.txt Clinical_Classification.txt Clinical_Condition.txt  > head.vcf

############################################# Header file END ############################################################################################


############################################ Combining main file and header file ######################################################################
cat head.vcf aa.xls > UNNNN.xls

sed 's/RS=/rs/g' UNNNN.xls > aaa.xls

sed 's/GENEINFO=//g' aaa.xls > bbb.xls
sed 's/CLNDN=//g' bbb.xls > Final_Uncovered_1.xls

#awk '{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12}' Final_Uncovered_1.xls > seprate.xls

sed 's/ \+/\t/g' Final_Uncovered_1.xls > $text.xls

############################################ Combining END ############################################################################################
cat $text.xls
echo
echo '################## Uncovered finding is done ##########################'

########################################### Removing Extra file ####################################################################################
rm RS.txt P.txt LP.txt PLP.txt Onliner_for_RS.txt RS_Comman.txt P1.txt LP1.txt PLP1.txt annotation_patho.txt annotation_likely.txt annotation_plp.txt merged_anotation.txt RS_final.txt intersect.txt Uncovered_Actionable.xls UNNNN.xls Fintersect.txt Geneinfo.txt Clinsig.txt aaa.xls bbb.xls Uncovered_Actionable_2.xls Amplicon_id.txt input.bed chrom.txt amplicon_start.txt amplicon_end.txt pos.txt ref.txt alt.txt rs_id.txt gene.txt Clinical_Classification.txt Clinical_Condition.txt head.vcf pre_clinsig.txt Final_Uncovered_1.xls aa.xls

########################################## End removing file #########################################################################################

