#!bin/bash
#####################################################################################################################################################
#This script is to curate COSMIC Build database 
#Scripted by Vinayak Rao
#Date:07-09-2022
#Version: 1.0
################################################################################### 
echo " "
echo " "
pwd=$(pwd)
time=$(date)
echo -n "Enter version Number : \t"
read text
INPUT="$1"

echo "				匚ㄖ丂爪丨匚	"
echo ""
echo ""
echo "######################## This will take ages (˘_˘٥) #####################"
LANG=C grep -v "^#" $1 | cut -f1,2,3,4,5,8 | sed 's/^/chr/g' | sed 's/ \+/\t/g' > COSMIC_Only_Columns.txt

LANG=C grep -oh "\GENE=*\w*" COSMIC_Only_Columns.txt | sed 's/\_ENST.*//g' > Genes.txt
LANG=C grep -oh "\LEGACY_ID=*\w*" COSMIC_Only_Columns.txt > Legacy_ID.txt
LANG=C grep -oh "\CNT=*\w*" COSMIC_Only_Columns.txt > Count.txt

paste COSMIC_Only_Columns.txt Genes.txt Legacy_ID.txt Count.txt | sed 's/ \+/\t/g' | cut -f1,2,3,4,5,7,8,9 | sed 's/ \+/\t/g' | sed 's/GENE=//g' | sed 's/LEGACY_ID=//g' | sed 's/CNT=//g' > Combined_With_All_File.txt

awk 'BEGIN {FS="\t"; OFS="\t"}; {print $1 "_" $2 "_" $4 "_" $5}' Combined_With_All_File.txt  > concate.txt

paste concate.txt Combined_With_All_File.txt | sed 's/ \+/\t/g' | sort -u -k1,1 > Combined_With_Concate.txt

awk '{ print length($5) }' Combined_With_Concate.txt > length_Ref.txt

awk '{ print length($6) }' Combined_With_Concate.txt > length_Alt.txt


paste -d ' ' Combined_With_Concate.txt length_Ref.txt length_Alt.txt | sed 's/ \+/\t/g' > Combine_COSMIC_With_Length_Ref_Alt.txt


rm concate.txt Genes.txt Legacy_ID.txt Count.txt COSMIC_Only_Columns.txt length_Ref.txt length_Alt.txt Combined_With_All_File.txt Combined_With_Concate.txt #Bcftools_normalized.vcf Only_NC_chrom.vcf Only_Chrm.txt File_for_Bcftools.vcf 
############################ Postion 

echo "DELETION Anchor Base Variants"

awk '{if ($10>1 && $11==1) print ("Del");else print("Not_Del");}' Combine_COSMIC_With_Length_Ref_Alt.txt > Del.txt

paste Combine_COSMIC_With_Length_Ref_Alt.txt Del.txt | sed 's/ \+/\t/g' > Combined_Del.txt 

LANG=C grep -w "Del" Combined_Del.txt > Del_grep.txt

cut -f5 Del_grep.txt | cut -c 1 >  Anchore_Base_Del_Ref.txt
cut -f6 Del_grep.txt | cut -c 1 > Anchore_Base_Del_Alt.txt

paste Del_grep.txt Anchore_Base_Del_Ref.txt Anchore_Base_Del_Alt.txt | sed 's/ \+/\t/g' > Combined_Anchore_Base_Ref_Alt.txt

awk '{if ($13==$14) print ("Same");else print("Remove");}' Combined_Anchore_Base_Ref_Alt.txt > Combined_Anchore_Base_Ref_Alt_Comment.txt

paste Combined_Anchore_Base_Ref_Alt.txt Combined_Anchore_Base_Ref_Alt_Comment.txt | sed 's/ \+/\t/g' > Final_Combined_Anchore_Base_Ref_Alt_Comment.txt

LANG=C grep -w "Same" Final_Combined_Anchore_Base_Ref_Alt_Comment.txt > For_Del_Same.txt

LANG=C grep -w "Remove" Final_Combined_Anchore_Base_Ref_Alt_Comment.txt | cut -f2-9 > For_Del_Remove.txt

cut -f5 For_Del_Same.txt | sed 's/^.//' > Del_Ref_WA.txt

cat For_Del_Same.txt | cut -f6 | sed -e 's/./---/g' > Del_Alt_WA.txt

awk '{a=($3+1);print $0,a;}' For_Del_Same.txt | sed 's/ \+/\t/g' > DEL_New_POS.txt

paste Del_Ref_WA.txt Del_Alt_WA.txt DEL_New_POS.txt | sed 's/ \+/\t/g' > Final_Del.txt

awk '{print $4, $5, $6, $7, $8, $9, $10, $11 }' Final_Del.txt | sed 's/ \+/\t/g' > Final_Del_v2.txt

awk '{print $4, $18, $6, $1, $2, $9, $10, $11 }' Final_Del.txt | sed 's/ \+/\t/g' | sed 's/---//g' | sed 's/ \+/\t/g' > Final_Del_v1.txt

rm Del.txt Combined_Del.txt Del_grep.txt Anchore_Base_Del_Ref.txt Anchore_Base_Del_Alt.txt Combined_Anchore_Base_Ref_Alt.txt Combined_Anchore_Base_Ref_Alt_Comment.txt Final_Combined_Anchore_Base_Ref_Alt_Comment.txt For_Del_Same.txt Del_Ref_WA.txt Del_Alt_WA.txt DEL_New_POS.txt Final_Del.txt 

##############################################################
echo ""

echo "Insertion Anchor Base"

awk '{if ($11>1 && $10==1) print ("Ins");else print("0");}' Combine_COSMIC_With_Length_Ref_Alt.txt > Ins.txt

		paste Combine_COSMIC_With_Length_Ref_Alt.txt Ins.txt | sed 's/ \+/\t/g' > cout_Ins.txt 

		LANG=C grep -w "Ins" cout_Ins.txt > Ins_grep.txt

        cut -f5 Ins_grep.txt | cut -c 1 > Anchor_Base_Ins_Ref.txt
        cut -f6 Ins_grep.txt | cut -c 1 > Anchor_Base_Ins_Alt.txt 

        paste Ins_grep.txt Anchor_Base_Ins_Ref.txt Anchor_Base_Ins_Alt.txt | sed 's/ \+/\t/g' > Combined_Anchor_Base_Ins_Ref_Alt.txt

        awk '{if ($13==$14) print ("Same");else print("Remove");}' Combined_Anchor_Base_Ins_Ref_Alt.txt > Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt

        paste Combined_Anchor_Base_Ins_Ref_Alt.txt Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt | sed 's/ \+/\t/g' > Final_Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt

        LANG=C grep -w "Same" Final_Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt > For_Same.txt

        LANG=C grep -w "Remove" Final_Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt | cut -f2-9 > For_Remove_Ind.txt

		cut -f6 For_Same.txt | sed 's/^.//' > Ins_Alt_WA.txt

		cat For_Same.txt | cut -f5 | sed -e 's/./---/g' > Ins_Ref_WA.txt

		awk '{a=($3+1);print $0,a;}' For_Same.txt | sed 's/ \+/\t/g' > Ins_Pos_plus.txt

		#cut -f13 Ins_Pos_plus.txt > Ins_New_Pos.txt

		paste Ins_Pos_plus.txt Ins_Ref_WA.txt Ins_Alt_WA.txt | sed 's/ \+/\t/g' > Final_Ins.txt
		
		awk '{print $2, $3, $4, $5, $6, $7, $8, $9 }' Final_Ins.txt | sed 's/ \+/\t/g' > Final_Ins_v2.txt

		awk '{print $2, $16, $4, $17, $18, $7, $8, $9 }' Final_Ins.txt | sed 's/ \+/\t/g' | sed 's/---//g' | sed 's/ \+/\t/g' > Final_Ins_v1.txt

	rm Ins.txt cout_Ins.txt Ins_grep.txt Ins_Alt_WA.txt Ins_Ref_WA.txt Ins_Pos_plus.txt Final_Ins.txt Anchor_Base_Ins_Ref.txt Anchor_Base_Ins_Alt.txt Combined_Anchor_Base_Ins_Ref_Alt.txt Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt Final_Combined_Anchor_Base_Ins_Ref_Alt_Comment.txt  For_Same.txt
echo ""


echo "SNV Variants"
echo ""

	################### SNV positions ####################################

		awk '{if ($10==1 && $11==1) print ("SNV");else print("0");}' Combine_COSMIC_With_Length_Ref_Alt.txt > Snv.txt

		paste Combine_COSMIC_With_Length_Ref_Alt.txt Snv.txt | sed 's/ \+/\t/g' > count_Snv.txt

		LANG=C grep -w "SNV" count_Snv.txt > Snv_grep.txt

        awk '{print $2, $3, $4, $5, $6, $7, $8, $9}' Snv_grep.txt | sed 's/ \+/\t/g' > Final_Snv_v1.txt


	rm Snv.txt count_Snv.txt Snv_grep.txt 


echo ""
echo "MNP Variants  | Okay this is last ◉‿◉"
	############## MNP Positions ######################################

		awk '{if ($10>1 && $11>1) print ("MNP");else print("0");}' Combine_COSMIC_With_Length_Ref_Alt.txt > Mnp.txt

		paste Combine_COSMIC_With_Length_Ref_Alt.txt Mnp.txt | sed 's/ \+/\t/g' > count_Mnp.txt

		LANG=C grep -w "MNP" count_Mnp.txt > Mnp_grep.txt

		awk '{if ($10<=$11) print ("Smaller");else print("Bigger");}' Mnp_grep.txt > MNP_Smaller_Bigger_Ref.txt

		paste Mnp_grep.txt MNP_Smaller_Bigger_Ref.txt | sed 's/ \+/\t/g' > MNP_Small_Big_Combined.txt

		LANG=C grep -w "Smaller" MNP_Small_Big_Combined.txt > MNP_Smaller.txt

		LANG=C grep -w "Bigger" MNP_Small_Big_Combined.txt > MNP_Bigger.txt

##################For Small
			######Same MNP
		awk '{if ($10==$11) print ("Equal");else print("Not_Equal");}' MNP_Smaller.txt > Equal_MNP.txt
		paste MNP_Smaller.txt Equal_MNP.txt | sed 's/ \+/\t/g' > MNP_Smaller_Equal.txt
		grep -w "Equal" MNP_Smaller_Equal.txt > Only_Smaller_Equal.txt
		awk '{print substr($5, 0, 1)}' Only_Smaller_Equal.txt > MNP_Equal_Ref.txt
		awk '{print substr($6, 0, 1)}' Only_Smaller_Equal.txt > MNP_Equal_Alt.txt
		paste Only_Smaller_Equal.txt MNP_Equal_Ref.txt MNP_Equal_Alt.txt | sed 's/ \+/\t/g' > Only_Equal_With_New_Ref_Alt.txt
		awk '{if ($15==$16)print ("Same");else print("Not_same");}' Only_Equal_With_New_Ref_Alt.txt > Only_Equal_Same_Not_Same.txt
		paste Only_Equal_With_New_Ref_Alt.txt Only_Equal_Same_Not_Same.txt | sed 's/ \+/\t/g' > Combine_Equal_Same.txt
		grep -w "Same" Combine_Equal_Same.txt > With_Same_Alt_Ref_Equal.txt
		awk '{print substr($5, 2)}' With_Same_Alt_Ref_Equal.txt > Same_New_Ref.txt
		awk '{print substr($6, 2)}' With_Same_Alt_Ref_Equal.txt > Same_New_Alt.txt
		paste With_Same_Alt_Ref_Equal.txt Same_New_Ref.txt Same_New_Alt.txt | sed 's/ \+/\t/g' | awk '{a=($3+1);print $0,a;}' | sed 's/ \+/\t/g' | awk '{print $2, $20, $4, $18, $19, $7, $8, $9}' | sed 's/ \+/\t/g' > Final_v1_For_Same_MNP.txt

		rm Equal_MNP.txt MNP_Smaller_Equal.txt Only_Smaller_Equal.txt MNP_Equal_Ref.txt MNP_Equal_Alt.txt Only_Equal_With_New_Ref_Alt.txt Only_Equal_Same_Not_Same.txt Combine_Equal_Same.txt With_Same_Alt_Ref_Equal.txt Same_New_Ref.txt Same_New_Alt.txt 
		
		cat MNP_Smaller.txt | awk '{print substr($6, 0, $10)}' > MNP_Smaller_Alt.txt
		paste MNP_Smaller.txt MNP_Smaller_Alt.txt | sed 's/ \+/\t/g' > MNP_Smaller_Alot_com.txt
		awk '{if ($5==$14) print ("Same");else print ("Different");}' MNP_Smaller_Alot_com.txt > MNP_Small_Same_Diff.txt
		paste MNP_Smaller_Alot_com.txt MNP_Small_Same_Diff.txt > MNP_Smaller_same_diff_comb.txt
		LANG=C grep -w "Different" MNP_Smaller_same_diff_comb.txt | cut -f2-9 > MNP_Smaller_Diff_Final.txt
		LANG=C grep -w "Same" MNP_Smaller_same_diff_comb.txt > MNP_Smaller_Same.txt
		#cut -f2-9 MNP_Smaller_Same.txt > MNP_Smaller_Without_Removed_Anchor.txt
		awk '{a=($11-$10);print $0,a;}' MNP_Smaller_Same.txt | sed 's/ \+/\t/g' > MNP_Smaller_Same_Avg.txt
		cut -f6 MNP_Smaller_Same_Avg.txt | rev > MNP_Smaller_Same_Avg_rev_Alt.txt
		paste MNP_Smaller_Same_Avg.txt MNP_Smaller_Same_Avg_rev_Alt.txt | sed 's/ \+/\t/g' > MNP_Smaller_Same_Avg_rev_Alt_Comb.txt
		awk '{print substr($17, 0, $16)}' MNP_Smaller_Same_Avg_rev_Alt_Comb.txt | rev > MNP_Smaller_New_Alt.txt
		paste MNP_Smaller_Same_Avg_rev_Alt_Comb.txt MNP_Smaller_New_Alt.txt | sed 's/ \+/\t/g' > MNP_Smaller_New_Alt_Combined.txt
		awk '{a=($3+$10);print $0,a;}' MNP_Smaller_New_Alt_Combined.txt | sed 's/ \+/\t/g' > MNP_Smaller_New_Pos.txt
		cat MNP_Smaller_New_Pos.txt | cut -f9 | sed 's/./---/g' > MNP_Smaller_New_Ins.txt
		paste MNP_Smaller_New_Pos.txt MNP_Smaller_New_Ins.txt | sed 's/ \+/\t/g' > MNP_Smaller_Final_v1_Combined.txt
		awk '{print $2, $3, $4, $5, $6, $7, $8, $9}' MNP_Smaller_Final_v1_Combined.txt | sed 's/ \+/\t/g' > MNP_Smaller_Same_Final_v1.txt
		awk '{print $2, $19, $4, $20, $18, $7, $8, $9}' MNP_Smaller_Final_v1_Combined.txt | sed 's/ \+/\t/g' | sed 's/---//g' | sed 's/ \+/\t/g' > MNP_Smaller_Same_Final.txt
		
		rm MNP_Smaller_Alt.txt MNP_Smaller_Alot_com.txt MNP_Small_Same_Diff.txt MNP_Smaller_same_diff_comb.txt MNP_Smaller_Same.txt MNP_Smaller_Same_Avg.txt MNP_Smaller_Same_Avg_rev_Alt.txt MNP_Smaller_Same_Avg_rev_Alt_Comb.txt MNP_Smaller_New_Alt.txt MNP_Smaller_New_Alt_Combined.txt MNP_Smaller_New_Pos.txt MNP_Smaller_New_Ins.txt MNP_Smaller_Final_v1_Combined.txt count_Mnp.txt Mnp.txt MNP_Smaller.txt MNP_Small_Big_Combined.txt

#################For Bigger
		cat MNP_Bigger.txt | awk '{print substr($5, 0, $11)}' > MNP_Bigger_Ref.txt
		paste MNP_Bigger.txt MNP_Bigger_Ref.txt | sed 's/ \+/\t/g' > MNP_Bigger_Ref_com.txt
		awk '{if ($6==$14) print ("Same");else print ("Different");}' MNP_Bigger_Ref_com.txt > MNP_Bigger_Same_Diff.txt
		paste MNP_Bigger_Ref_com.txt MNP_Bigger_Same_Diff.txt > MNP_Bigger_same_diff_comb.txt
		LANG=C grep -w "Different" MNP_Bigger_same_diff_comb.txt | cut -f2-9 > MNP_Bigger_Diff_Final.txt
		LANG=C grep -w "Same" MNP_Bigger_same_diff_comb.txt > MNP_Bigger_Same.txt
		#cut -f1-6 MNP_Bigger_Same.txt > MNP_Bigger_Without_Removed_Anchor.txt
		awk '{a=($10-$11);print $0,a;}' MNP_Bigger_Same.txt | sed 's/ \+/\t/g' > MNP_Bigger_Same_Avg.txt
		cut -f5 MNP_Bigger_Same_Avg.txt | rev > Big_Ref_rev.txt
		paste MNP_Bigger_Same_Avg.txt Big_Ref_rev.txt | sed 's/ \+/\t/g' > MNP_Bigger_Same_Avg_rev.txt
		awk '{print substr($17, 0, $16)}' MNP_Bigger_Same_Avg_rev.txt | rev > MNP_Bigger_New_Ref.txt
		cat MNP_Bigger_Same_Avg_rev.txt | cut -f9 | sed 's/./---/g' > MNP_Bigger_New_Alt.txt
		paste MNP_Bigger_Same_Avg_rev.txt  MNP_Bigger_New_Ref.txt MNP_Bigger_New_Alt.txt | sed 's/ \+/\t/g' > MNP_Bigger_Same_Avg_rev_New_ref.txt
		awk '{a=($3+$11);print $0,a;}' MNP_Bigger_Same_Avg_rev_New_ref.txt | sed 's/ \+/\t/g' > MNP_Bigger_Same_Avg_rev_New_ref_AND_Pos.txt
		awk '{print $2, $3, $4, $5, $6, $7, $8, $9}' MNP_Bigger_Same_Avg_rev_New_ref_AND_Pos.txt | sed 's/ \+/\t/g' > MNP_Bigger_Same_Final_v1.txt
		awk '{print $2, $20, $4, $18, $19, $7, $8, $9}' MNP_Bigger_Same_Avg_rev_New_ref_AND_Pos.txt | sed 's/ \+/\t/g' | sed 's/---//g' | sed 's/ \+/\t/g' > MNP_Bigger_Same_Final.txt
	
		rm MNP_Bigger_Ref.txt MNP_Bigger_Ref_com.txt MNP_Bigger_Same_Diff.txt MNP_Bigger_same_diff_comb.txt MNP_Bigger_Same.txt MNP_Bigger_Same_Avg.txt Big_Ref_rev.txt MNP_Bigger_Same_Avg_rev.txt MNP_Bigger_New_Ref.txt MNP_Bigger_New_Alt.txt MNP_Bigger_Same_Avg_rev_New_ref.txt MNP_Bigger_Same_Avg_rev_New_ref_AND_Pos.txt
		




cat Final_Snv_v1.txt Final_Del_v1.txt Final_Ins_v1.txt For_Del_Remove.txt For_Remove_Ind.txt MNP_Smaller_Diff_Final.txt MNP_Bigger_Diff_Final.txt MNP_Smaller_Same_Final.txt MNP_Bigger_Same_Final.txt Final_Del_v2.txt Final_Ins_v2.txt MNP_Smaller_Same_Final_v1.txt MNP_Bigger_Same_Final_v1.txt Final_v1_For_Same_MNP.txt | sed 's/ \+/\t/g' > Final_COSMIC.txt

awk 'BEGIN {FS="\t"; OFS="\t"}; {print $1 "_" $2 "_" $4 "_" $5}'  Final_COSMIC.txt > Concate.txt

paste Concate.txt Final_COSMIC.txt | sed 's/ \+/\t/g' > DCGL_COSMIC_$text.txt

rm Final_Snv_v1.txt  Final_Ins_v1.txt Final_Del_v1.txt Combine_COSMIC_With_Length_Ref_Alt.txt  For_Del_Remove.txt For_Remove_Ind.txt MNP_Smaller_Bigger_Ref.txt MNP_Smaller_Same_Final.txt MNP_Bigger_Same_Final.txt MNP_Bigger_Diff_Final.txt MNP_Smaller_Diff_Final.txt Concate.txt Final_COSMIC.txt Final_Del_v2.txt Final_Ins_v2.txt MNP_Smaller_Same_Final_v1.txt MNP_Bigger_Same_Final_v1.txt Final_v1_For_Same_MNP.txt MNP_Bigger.txt Mnp_grep.txt

echo ""
echo ""
echo "****************COSMIC file created DCGL_COSMIC_$text.txt*************************"

echo ""
########################## Adding Header To the filr ##############################








