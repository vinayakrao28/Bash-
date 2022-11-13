#!bin/bash
#####################################################################################################################################################
#This script is to curate dbSNP Build database 
#Scripted by Vinayak Rao
#Date:09-04-2022
#Version: 1.0
################################################################################### 
echo " "
echo " "
pwd=$(pwd)
time=$(date)
echo -n "Enter version Number : \t"
read text
INPUT="$1"
	echo "                                     
					──╔╦╗─╔═══╦═╗─╔╦═══╗
					──║║║─║╔═╗║║╚╗║║╔═╗║
					╔═╝║╚═╣╚══╣╔╗╚╝║╚═╝║
					║╔╗║╔╗╠══╗║║╚╗║║╔══╝
					║╚╝║╚╝║╚═╝║║─║║║║
					╚══╩══╩═══╩╝─╚═╩╝                                         "
echo ""
echo "########################## SIT BACK AND TAKE CHILL PILL THIS ONE WILL TAKE TIME ¯\_◉‿◉_/¯ #################################"
echo ""
echo ""
############################Pre-Process dbSNP Built file ############################
	#/opt/installers_DGL/bcftools-1.9/bcftools norm -m  '-'  $1 > Bcftools_normalized.vcf ##if this is not working on 52 do this on local system and # out this
	#bcftools norm -m  '-'  $1 > Bcftools_normalized.vcf
echo "#################All multi-allelic mutation are normalized################"
echo ""
echo ""
	#LANG=C grep -v "#" Bcftools_normalized.vcf | grep "NC_0000*" > Only_NC_chrom.vcf
echo "#################### filtering unwanted data ###################################"
echo ""
echo ""

	#sed 's/NC_000001.*/chr1/g' Only_NC_chrom.vcf | sed 's/NC_000002.*/chr2/g' | sed 's/NC_000003.*/chr3/g' | sed 's/NC_000004.*/chr4/g' | sed 's/NC_000005.*/chr5/g' | sed 's/NC_000006.*/chr6/g' | sed 's/NC_000007.*/chr7/g' | sed 's/NC_000008.*/chr8/g' | sed 's/NC_000009.*/chr9/g' | sed 's/NC_000010.*/chr10/g' | sed 's/NC_000011.*/chr11/g' | sed 's/NC_000012.*/chr12/g' | sed 's/NC_000013.*/chr13/g' | sed 's/NC_000014.*/chr14/g' | sed 's/NC_000015.*/chr15/g' | sed 's/NC_000016.*/chr16/g' | sed 's/NC_000017.*/chr17/g' | sed 's/NC_000018.*/chr18/g' | sed 's/NC_000019.*/chr19/g' | sed 's/NC_000020.*/chr20/g' | sed 's/NC_000021.*/chr21/g' | sed 's/NC_000022.*/chr22/g' | sed 's/NC_000023.*/chrX/g' | sed 's/NC_000024.*/chrY/g' > Only_Chrm.txt

echo "####################### Naming all the chromosome number ##########################"
echo ""
echo ""
	#paste Only_Chrm.txt Only_NC_chrom.vcf | sed 's/ \+/\t/g' | cut -f1,3,4,5,6,7,8,9 | awk '{print $1, $2, $3, $4, $5, $6, $7, $8}' | sed 's/ \+/\t/g' > File_for_Bcftools.vcf

	

#echo -n "Enter version Number : \t"
#read text

echo ""
echo ""
#echo "					 DCGL In-House dbSNP Version Number: $text  			"

echo "Getting PSEUDOGENEINFO genes"
echo ""

LANG=C  grep  NC_0000* Bcftools_normalized.vcf | grep -w "PSEUDOGENEINFO=*"  | cut -f1,2,3,4,5,8 > Only_With_PSEUDOGENES.txt

sed 's/NC_000001.*/chr1/g' Only_With_PSEUDOGENES.txt | sed 's/NC_000002.*/chr2/g' | sed 's/NC_000003.*/chr3/g' | sed 's/NC_000004.*/chr4/g' | sed 's/NC_000005.*/chr5/g' | sed 's/NC_000006.*/chr6/g' | sed 's/NC_000007.*/chr7/g' | sed 's/NC_000008.*/chr8/g' | sed 's/NC_000009.*/chr9/g' | sed 's/NC_000010.*/chr10/g' | sed 's/NC_000011.*/chr11/g' | sed 's/NC_000012.*/chr12/g' | sed 's/NC_000013.*/chr13/g' | sed 's/NC_000014.*/chr14/g' | sed 's/NC_000015.*/chr15/g' | sed 's/NC_000016.*/chr16/g' | sed 's/NC_000017.*/chr17/g' | sed 's/NC_000018.*/chr18/g' | sed 's/NC_000019.*/chr19/g' | sed 's/NC_000020.*/chr20/g' | sed 's/NC_000021.*/chr21/g' | sed 's/NC_000022.*/chr22/g' | sed 's/NC_000023.*/chrX/g' | sed 's/NC_000024.*/chrY/g' > Only_With_PSEUDOGENES_removed_Chr.txt
#cut -f1,2,4,5,6,9 $1 >  cut_Columns_2-6_PSEDO.txt 

LANG=C grep -oh "\PSEUDOGENEINFO=\w*" Only_With_PSEUDOGENES.txt | sed 's/PSEUDOGENEINFO=//g' > PSEUDO_GENES.txt

paste -d ' ' Only_With_PSEUDOGENES_removed_Chr.txt Only_With_PSEUDOGENES.txt PSEUDO_GENES.txt | sed 's/ \+/\t/g' | cut -f1,3,4,5,6,8 | sed 's/ \+/\t/g' > For_PSEUDO.txt

echo ""
echo "Getting GENEINFO genes"
LANG=C grep  NC_0000* Bcftools_normalized.vcf | grep -w -E  "GENEINFO=*" | grep -v -w -E "PSEUDOGENEINFO=*" | cut -f1,2,3,4,5,8 > Only_With_GENEINFO.txt

sed 's/NC_000001.*/chr1/g' Only_With_GENEINFO.txt | sed 's/NC_000002.*/chr2/g' | sed 's/NC_000003.*/chr3/g' | sed 's/NC_000004.*/chr4/g' | sed 's/NC_000005.*/chr5/g' | sed 's/NC_000006.*/chr6/g' | sed 's/NC_000007.*/chr7/g' | sed 's/NC_000008.*/chr8/g' | sed 's/NC_000009.*/chr9/g' | sed 's/NC_000010.*/chr10/g' | sed 's/NC_000011.*/chr11/g' | sed 's/NC_000012.*/chr12/g' | sed 's/NC_000013.*/chr13/g' | sed 's/NC_000014.*/chr14/g' | sed 's/NC_000015.*/chr15/g' | sed 's/NC_000016.*/chr16/g' | sed 's/NC_000017.*/chr17/g' | sed 's/NC_000018.*/chr18/g' | sed 's/NC_000019.*/chr19/g' | sed 's/NC_000020.*/chr20/g' | sed 's/NC_000021.*/chr21/g' | sed 's/NC_000022.*/chr22/g' | sed 's/NC_000023.*/chrX/g' | sed 's/NC_000024.*/chrY/g' > Only_With_GENEINFO_removed_Chr.txt

LANG=C grep -oh "\GENEINFO=\w*" Only_With_GENEINFO.txt | sed 's/GENEINFO=//g' > GENEINFO_GENES.txt

paste -d ' ' Only_With_GENEINFO_removed_Chr.txt Only_With_GENEINFO.txt GENEINFO_GENES.txt | sed 's/ \+/\t/g' | cut -f1,3,4,5,6,8 | sed 's/ \+/\t/g' > For_GENEINFO.txt

cat For_PSEUDO.txt For_GENEINFO.txt > Final_Combined_GENE.txt


#LANG=C grep -oh "\PSEUDOGENEINFO=\w*" Only_With_PSEUDOGENES.txt  | sed 's/PSEUDOGENEINFO=//g' > PSEUDO_GENES.txt


#LANG=C grep -oh "\PSEUDOGENEINFO=\w*" $1 | sed 's/PSEUDOGENEINFO=//g' >  Gene_Info.txt

awk '{ print length($4) }' Final_Combined_GENE.txt > length_Ref.txt

awk '{ print length($5) }' Final_Combined_GENE.txt > length_Alt.txt


paste -d ' '  Final_Combined_GENE.txt length_Ref.txt length_Alt.txt | sed 's/ \+/\t/g' > Combine_dbSNP_With_Length_Ref_Alt.txt

echo "######################## This will take ages (˘_˘٥) #####################"
#rm Only_With_PSEUDOGENES.txt PSEUDO_GENES.txt For_PSEUDO.txt Only_With_GENEINFO.txt GENEINFO_GENES.txt For_GENEINFO.txt Final_Combined_GENE.txt length_Ref.txt length_Alt.txt Bcftools_normalized.vcf Only_NC_chrom.vcf Only_Chrm.txt File_for_Bcftools.vcf
############################ Postion 

echo "DELETION Anchor Base Variants"

awk '{if ($7>1 && $8==1) print ("Del");else print("Not_Del");}' Combine_dbSNP_With_Length_Ref_Alt.txt > Del.txt

paste Combine_dbSNP_With_Length_Ref_Alt.txt Del.txt | sed 's/ \+/\t/g' > Combined_Del.txt 

LANG=C grep -w "Del" Combined_Del.txt > Del_grep.txt

cut -f4 Del_grep.txt | cut -c 1 >  Anchore_Base_Del_Ref.txt
cut -f5 Del_grep.txt | cut -c 1 > Anchore_Base_Del_Alt.txt

paste Del_grep.txt Anchore_Base_Del_Ref.txt Anchore_Base_Del_Alt.txt | sed 's/ \+/\t/g' > Combined_Anchore_Base_Ref_Alt.txt

awk '{if ($10==$11) print ("Same");else print("Remove");}' Combined_Anchore_Base_Ref_Alt.txt > Combined_Anchore_Base_Ref_Alt_Comment.txt

paste Combined_Anchore_Base_Ref_Alt.txt Combined_Anchore_Base_Ref_Alt_Comment.txt | sed 's/ \+/\t/g' > Final_Combined_Anchore_Base_Ref_Alt_Comment.txt

LANG=C grep -w "Same" Final_Combined_Anchore_Base_Ref_Alt_Comment.txt > For_Del_Same.txt

LANG=C grep -w "Remove" Final_Combined_Anchore_Base_Ref_Alt_Comment.txt | cut -f1-6 > For_Del_Remove.txt

cut -f4 For_Del_Same.txt | sed 's/^.//' > Del_Ref_WA.txt

cat For_Del_Same.txt | cut -f5 | sed -e 's/./---/g' > Del_Alt_WA.txt

awk '{a=($2+1);print $0,a;}' For_Del_Same.txt | sed 's/ \+/\t/g' | cut -f13 > DEL_New_POS.txt

paste For_Del_Same.txt Del_Ref_WA.txt Del_Alt_WA.txt DEL_New_POS.txt | sed 's/ \+/\t/g' > Final_Del.txt

awk '{print $1, $15, $3, $13, $14, $6 }' Final_Del.txt | sed 's/ \+/\t/g' | sed 's/---//g' | sed 's/ \+/\t/g' > Final_Del_v1.txt

#rm Del.txt Combined_Del.txt Del_grep.txt Anchore_Base_Del_Ref.txt Anchore_Base_Del_Alt.txt Combined_Anchore_Base_Ref_Alt.txt Combined_Anchore_Base_Ref_Alt_Comment.txt Final_Combined_Anchore_Base_Ref_Alt_Comment.txt For_Del_Same.txt Del_Ref_WA.txt Del_Alt_WA.txt DEL_New_POS.txt Final_Del.txt 

##############################################################
echo ""

echo "Insertion Anchor Base"

awk '{if ($8>1 && $7==1) print ("Ins");else print("0");}' Combine_dbSNP_With_Length_Ref_Alt.txt > Ins.txt

		paste Combine_dbSNP_With_Length_Ref_Alt.txt Ins.txt | sed 's/ \+/\t/g' > cout_Ins.txt 

		LANG=C grep -w "Ins" cout_Ins.txt > Ins_grep.txt

        cut -f4 Ins_grep.txt | cut -c 1 > Anchor_Base_Ins_Ref.txt

        cut -f5 Ins_grep.txt | cut -c 1 > Anchor_Base_Ins_Alt.txt 

        paste Ins_grep.txt Anchor_Base_Ins_Ref.txt Anchor_Base_Ins_Alt.txt | sed 's/ \+/\t/g' > Combined_Anchor_Base_Ins_Ref_Alt.txt

        awk '{if ($10==$11) print ("Same");else print("Remove");}' Combined_Anchor_Base_Ins_Ref_Alt.txt > Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt

        paste Combined_Anchor_Base_Ins_Ref_Alt.txt Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt | sed 's/ \+/\t/g' > Final_Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt

        LANG=C grep -w "Same" Final_Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt > For_Same.txt

        LANG=C grep -w "Remove" Final_Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt | cut -f1-6 > For_Remove_Ind.txt

		cut -f5 For_Same.txt | sed 's/^.//' > Ins_Alt_WA.txt

		cat For_Same.txt | cut -f4| sed -e 's/./---/g' > Ins_Ref_WA.txt

		awk '{a=($2+1);print $0,a;}' For_Same.txt | sed 's/ \+/\t/g' > Ins_Pos_plus.txt

		cut -f13 Ins_Pos_plus.txt > Ins_New_Pos.txt

		paste For_Same.txt Ins_Ref_WA.txt Ins_Alt_WA.txt Ins_New_Pos.txt | sed 's/ \+/\t/g' > Final_Ins.txt

		awk '{print $1, $15, $3, $13, $14, $6 }' Final_Ins.txt | sed 's/ \+/\t/g' | sed 's/---//g' | sed 's/ \+/\t/g' > Final_Ins_v1.txt

	rm Ins.txt cout_Ins.txt Ins_grep.txt Ins_Alt_WA.txt Ins_Ref_WA.txt Ins_Pos_plus.txt Ins_New_Pos.txt Final_Ins.txt Anchor_Base_Ins_Ref.txt Anchor_Base_Ins_Alt.txt Combined_Anchor_Base_Ins_Ref_Alt.txt Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt Final_Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt  For_Same.txt
echo ""


echo "SNV Variants"
echo ""

	################### SNV positions ####################################

		awk '{if ($7==1 && $8==1) print ("SNV");else print("0");}' Combine_dbSNP_With_Length_Ref_Alt.txt > Snv.txt

		paste Combine_dbSNP_With_Length_Ref_Alt.txt Snv.txt | sed 's/ \+/\t/g' > count_Snv.txt

		LANG=C grep -w "SNV" count_Snv.txt > Snv_grep.txt

		cut -f1-6 Snv_grep.txt > Final_Snv_v1.txt

	rm Snv.txt count_Snv.txt Snv_grep.txt 


echo ""
echo "MNP Variants  | Okay this is last ◉‿◉"
	############## MNP Positions ######################################

		awk '{if ($7>1 && $8>1) print ("MNP");else print("0");}' Combine_dbSNP_With_Length_Ref_Alt.txt > Mnp.txt

		paste Combine_dbSNP_With_Length_Ref_Alt.txt Mnp.txt | sed 's/ \+/\t/g' > count_Mnp.txt

		LANG=C grep -w "MNP" count_Mnp.txt > Mnp_grep.txt

		awk '{if ($7<=$8) print ("Smaller");else print("Bigger");}' Mnp_grep.txt > MNP_Smaller_Bigger_Ref.txt

		paste Mnp_grep.txt MNP_Smaller_Bigger_Ref.txt | sed 's/ \+/\t/g' > MNP_Small_Big_Combined.txt

		LANG=C grep -w "Smaller" MNP_Small_Big_Combined.txt > MNP_Smaller.txt

		LANG=C grep -w "Bigger" MNP_Small_Big_Combined.txt > MNP_Bigger.txt

##################For Small
		###################### For MNP Same
		awk '{if ($7==$8) print ("Equal");else print("Not_Equal");}' MNP_Smaller.txt > Equal_MNP.txt
		paste MNP_Smaller.txt Equal_MNP.txt | sed 's/ \+/\t/g' > MNP_Smaller_Equal.txt
		grep -w "Equal" MNP_Smaller_Equal.txt > Only_Smaller_Equal.txt
		awk '{print substr($4, 0, 1)}' Only_Smaller_Equal.txt > MNP_Equal_Ref.txt
		awk '{print substr($5, 0, 1)}' Only_Smaller_Equal.txt > MNP_Equal_Alt.txt
		paste Only_Smaller_Equal.txt MNP_Equal_Ref.txt MNP_Equal_Alt.txt | sed 's/ \+/\t/g' > Only_Equal_With_New_Ref_Alt.txt
		awk '{if ($12==$13)print ("Same");else print("Not_same");}' Only_Equal_With_New_Ref_Alt.txt > Only_Equal_Same_Not_Same.txt
		paste Only_Equal_With_New_Ref_Alt.txt Only_Equal_Same_Not_Same.txt | sed 's/ \+/\t/g' > Combine_Equal_Same.txt
		grep -w "Same" Combine_Equal_Same.txt > With_Same_Alt_Ref_Equal.txt
		awk '{print substr($4, 2)}' With_Same_Alt_Ref_Equal.txt > Same_New_Ref.txt
		awk '{print substr($5, 2)}' With_Same_Alt_Ref_Equal.txt > Same_New_Alt.txt
		paste With_Same_Alt_Ref_Equal.txt Same_New_Ref.txt Same_New_Alt.txt | sed 's/ \+/\t/g' | awk '{a=($2+1);print $0,a;}' | sed 's/ \+/\t/g' | awk '{print $1, $17, $3, $15, $16, $6}' | sed 's/ \+/\t/g' > Final_v1_For_Same_MNP.txt

		rm Equal_MNP.txt MNP_Smaller_Equal.txt Only_Smaller_Equal.txt MNP_Equal_Ref.txt MNP_Equal_Alt.txt Only_Equal_With_New_Ref_Alt.txt Only_Equal_Same_Not_Same.txt Combine_Equal_Same.txt With_Same_Alt_Ref_Equal.txt Same_New_Ref.txt Same_New_Alt.txt 

		cat MNP_Smaller.txt | awk '{print substr($5, 0, $7)}' > MNP_Smaller_Alt.txt
		paste MNP_Smaller.txt MNP_Smaller_Alt.txt | sed 's/ \+/\t/g' > MNP_Smaller_Alot_com.txt
		awk '{if ($4==$14) print ("Same");else print ("Different");}' MNP_Smaller_Alot_com.txt > MNP_Small_Same_Diff.txt
		paste MNP_Smaller_Alot_com.txt MNP_Small_Same_Diff.txt > MNP_Smaller_same_diff_comb.txt
		LANG=C grep -w "Different" MNP_Smaller_same_diff_comb.txt | cut -f1-6 > MNP_Smaller_Diff_Final.txt
		LANG=C grep -w "Same" MNP_Smaller_same_diff_comb.txt > MNP_Smaller_Same.txt
		cut -f1-6 MNP_Smaller_Same.txt > MNP_Smaller_Without_Removed_Anchor.txt
		awk '{a=($8-$7);print $0,a;}' MNP_Smaller_Same.txt | sed 's/ \+/\t/g' > MNP_Smaller_Same_Avg.txt
		cut -f5 MNP_Smaller_Same_Avg.txt | rev > MNP_Smaller_Same_Avg_rev_Alt.txt
		paste MNP_Smaller_Same_Avg.txt MNP_Smaller_Same_Avg_rev_Alt.txt | sed 's/ \+/\t/g' > MNP_Smaller_Same_Avg_rev_Alt_Comb.txt
		awk '{print substr($14, 0, $13)}' MNP_Smaller_Same_Avg_rev_Alt_Comb.txt | rev > MNP_Smaller_New_Alt.txt
		paste MNP_Smaller_Same_Avg_rev_Alt_Comb.txt MNP_Smaller_New_Alt.txt | sed 's/ \+/\t/g' > MNP_Smaller_New_Alt_Combined.txt
		awk '{a=($2+$7);print $0,a;}' MNP_Smaller_New_Alt_Combined.txt | sed 's/ \+/\t/g' > MNP_Smaller_New_Pos.txt
		cat MNP_Smaller_New_Pos.txt | cut -f1 | sed 's/./---/g' > MNP_Smaller_New_Ins.txt
		paste MNP_Smaller_New_Pos.txt MNP_Smaller_New_Ins.txt | sed 's/ \+/\t/g' > MNP_Smaller_Final_v1_Combined.txt
		awk '{print $1, $16, $3, $17, $15, $6}' MNP_Smaller_Final_v1_Combined.txt | sed 's/ \+/\t/g' | sed 's/---//g' | sed 's/ \+/\t/g' > MNP_Smaller_Same_Final.txt
		
		rm MNP_Smaller_Alt.txt MNP_Smaller_Alot_com.txt MNP_Small_Same_Diff.txt MNP_Smaller_same_diff_comb.txt MNP_Smaller_Same.txt MNP_Smaller_Same_Avg.txt MNP_Smaller_Same_Avg_rev_Alt.txt MNP_Smaller_Same_Avg_rev_Alt_Comb.txt MNP_Smaller_New_Alt.txt MNP_Smaller_New_Alt_Combined.txt MNP_Smaller_New_Pos.txt MNP_Smaller_New_Ins.txt MNP_Smaller_Final_v1_Combined.txt count_Mnp.txt Mnp.txt

#################For Bigger
		cat MNP_Bigger.txt | awk '{print substr($4, 0, $8)}' > MNP_Bigger_Ref.txt
		paste MNP_Bigger.txt MNP_Bigger_Ref.txt | sed 's/ \+/\t/g' > MNP_Bigger_Ref_com.txt
		awk '{if ($5==$14) print ("Same");else print ("Different");}' MNP_Bigger_Ref_com.txt > MNP_Bigger_Same_Diff.txt
		paste MNP_Bigger_Ref_com.txt MNP_Bigger_Same_Diff.txt > MNP_Bigger_same_diff_comb.txt
		LANG=C grep -w "Different" MNP_Bigger_same_diff_comb.txt | cut -f1-6 > MNP_Bigger_Diff_Final.txt
		LANG=C grep -w "Same" MNP_Bigger_same_diff_comb.txt > MNP_Bigger_Same.txt
		cut -f1-6 MNP_Bigger_Same.txt > MNP_Bigger_Without_Removed_Anchor.txt
		awk '{a=($7-$8);print $0,a;}' MNP_Bigger_Same.txt | sed 's/ \+/\t/g' > MNP_Bigger_Same_Avg.txt
		cut -f4 MNP_Bigger_Same_Avg.txt | rev > Big_Ref_rev.txt
		paste MNP_Bigger_Same_Avg.txt Big_Ref_rev.txt | sed 's/ \+/\t/g' > MNP_Bigger_Same_Avg_rev.txt
		awk '{print substr($14, 0, $13)}' MNP_Bigger_Same_Avg_rev.txt | rev > MNP_Bigger_New_Ref.txt
		cat MNP_Bigger_Same_Avg_rev.txt | cut -f1 | sed 's/./---/g' > MNP_Bigger_New_Alt.txt
		paste MNP_Bigger_Same_Avg_rev.txt  MNP_Bigger_New_Ref.txt MNP_Bigger_New_Alt.txt | sed 's/ \+/\t/g' > MNP_Bigger_Same_Avg_rev_New_ref.txt
		awk '{a=($2+$8);print $0,a;}' MNP_Bigger_Same_Avg_rev_New_ref.txt | sed 's/ \+/\t/g' > MNP_Bigger_Same_Avg_rev_New_ref_AND_Pos.txt
		awk '{print $1, $17, $3, $15, $16, $6 }' MNP_Bigger_Same_Avg_rev_New_ref_AND_Pos.txt | sed 's/ \+/\t/g' | sed 's/---//g' | sed 's/ \+/\t/g' > MNP_Bigger_Same_Final.txt
	
		rm MNP_Bigger_Ref.txt MNP_Bigger_Ref_com.txt MNP_Bigger_Same_Diff.txt MNP_Bigger_same_diff_comb.txt MNP_Bigger_Same.txt MNP_Bigger_Same_Avg.txt Big_Ref_rev.txt MNP_Bigger_Same_Avg_rev.txt MNP_Bigger_New_Ref.txt MNP_Bigger_New_Alt.txt MNP_Bigger_Same_Avg_rev_New_ref.txt MNP_Bigger_Same_Avg_rev_New_ref_AND_Pos.txt
		

cat Final_Snv_v1.txt Final_Del_v1.txt Final_Ins_v1.txt For_Del_Remove.txt For_Remove_Ind.txt MNP_Smaller_Diff_Final.txt MNP_Bigger_Diff_Final.txt MNP_Smaller_Same_Final.txt MNP_Bigger_Same_Final.txt MNP_Smaller_Without_Removed_Anchor.txt MNP_Bigger_Without_Removed_Anchor.txt Final_v1_For_Same_MNP.txt | sed 's/ \+/\t/g' > Final_dbSNP.txt

awk 'BEGIN {FS="\t"; OFS="\t"}; {print $1 "_" $2 "_" $4 "_" $5}' Final_dbSNP.txt > concate.txt

paste concate.txt Final_dbSNP.txt  | sed 's/ \+/\t/g' > DCGL_dbSNP_$text.txt

rm Final_Snv_v1.txt  Final_Ins_v1.txt Final_Del_v1.txt Combine_dbSNP_With_Length_Ref_Alt.txt For_Del_Remove.txt For_Remove_Ind.txt  MNP_Smaller_Diff_Final.txt MNP_Bigger_Diff_Final.txt MNP_Smaller_Same_Final.txt MNP_Bigger_Same_Final.txt MNP_Bigger.txt Mnp_grep.txt MNP_Small_Big_Combined.txt MNP_Smaller_Bigger_Ref.txt MNP_Smaller_Without_Removed_Anchor.txt MNP_Bigger_Without_Removed_Anchor.txt Final_dbSNP.txt concate.txt MNP_Smaller.txt Final_v1_For_Same_MNP.txt








