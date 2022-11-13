#!/bin/bash
# Bash Menu Script Example
#####################################################################################################################################################
#Welcome to the script which is used to find Exon and codons
#Scripted by Vinayak Rao
#Date:02-11-2021
#Version: 1.1 (AmpliconID added)
###################################################################################
#
echo " "
echo " "
time=$(date)
Input=$1
pwd=$(pwd)
DATABASE="/bioinfo-data/Vinayak/Databases" #Please enter the database path 
echo -n "Enter project name : "
read project_name
PS3='Please enter your choice: '
options=("Get info from genes" "Uncovered Exon and Codon" "Quit")
echo " "
echo " "
select opt in "${options[@]}"
do
    case $opt in
        "Get info from genes")
            echo " "
            echo " "
            echo "Seleted option:                   $opt"
            echo " "
            echo " "
            echo "                                      $time"
            echo "                                    "
            echo "Current Location:                     $pwd"
            echo " "
            echo " "
            echo "Input file:                           $Input"
            grep -wf $Input $DATABASE/uncovered_Exon_Codons_final.vcf > aa.xls
            echo Chrom > chrom.txt
            echo Start > start.txt
            echo End > C_end.txt
            echo gene_id > gene_id.txt
            echo Transcript > Transcript.txt
            echo Exon > Exon.txt
            echo Codon_Start > Codons_Start.txt
            echo Codon_END > Codon_END.txt
            echo Gen_Orientation > Gene_Orientation.txt
            echo CDS_start_end > CDS_start_end.txt
            echo Pos_Neg_Strand > Pos_Neg_Strand.txt
            paste -d ' ' chrom.txt start.txt C_end.txt gene_id.txt Transcript.txt Exon.txt Codons_Start.txt Codon_END.txt Gene_Orientation.txt CDS_start_end.txt Pos_Neg_Strand.txt > head.vcf
            grep -w "gene" aa.xls > Gene.xls
            grep -w "CDS" aa.xls > CDS.xls
            cat head.vcf Gene.xls > Gene_v1.xls     
            sed 's/ \+/\t/g' Gene_v1.xls > Gene_$project_name.xls
            cat head.vcf CDS.xls > CDS_v1.xls
            sed 's/ \+/\t/g' CDS_v1.xls > CDS_$project_name.xls
            rm aa.xls chrom.txt start.txt C_end.txt gene_id.txt Transcript.txt Exon.txt Codons_Start.txt Codon_END.txt Gene_Orientation.txt CDS_start_end.txt Pos_Neg_Strand.txt head.vcf Gene.xls CDS.xls Gene_v1.xls CDS_v1.xls
            echo "Output file:                         Gene-$project_name.xls and CDS_$project_name.xls"
            echo " "
            echo " "
            echo "----------------------Genes Information retrieval completed     $time-------------------------------------------------------------------"

            break
            ;;
        "Uncovered Exon and Codon")

echo " "
echo " "
echo "Seleted option:                       $opt"
echo " "
echo " "
echo "                                      $time"
echo "                                    "
echo "Current Location:                     $pwd"
echo " "
echo " "
echo "Input file:                           $Input"
echo " "
bedtools intersect -a $Input -b $DATABASE/uncovered_Exon_Codons_final.vcf -wao > intersect.vcf

grep -w "CDS" intersect.vcf > CDS.txt
grep -w "Plus" CDS.txt > Plus.txt
grep -w "Neg" CDS.txt > Neg.txt
	
echo " "
#If Input start is less then refrence start for Plus
        awk '$6 >= $2 {printf "%s\t%s\n", $0,"Do_Addition" ; }' Plus.txt > Plus_Add.txt
        awk '{a=($16/3);print $0,a;}' Plus_Add.txt > Round_p.txt
        awk '{a=int($18+0.5);print $0,a;}' Round_p.txt > Round_v1_p.txt
        awk '{a=($11+$19);print $0,a;}' Round_v1_p.txt > Round_v2_p.txt
        awk '{print $1, $2, $3, $4, $8, $9, $10, $11, $20}' Round_v2_p.txt > Plus1.xls
       rm Plus_Add.txt Round_v1_p.txt Round_v2_p.txt Round_p.txt 

#If Input Start is greater then refrence start for Plus
        awk '$2 >= $6 && $3 >= $7 {printf "%s\t%s\n", $0,"Do_Substration" ; }' Plus.txt > Plus_sub.txt
        awk '{a=($16/3);print $0,a;}' Plus_sub.txt > Round_v1_p_s.txt
        awk '{a=int($18+0.5);print $0,a;}' Round_v1_p_s.txt > Round_v2_p_s.txt
        awk '{a=($12-$19);print $0,a;}' Round_v2_p_s.txt > Round_v3_p_s.txt
        awk '{print $1, $2, $3, $4, $8, $9, $10, $20, $12}' Round_v3_p_s.txt > Plus2.xls

###If refrence end is greater then input end then this is the new end #############################
        awk '$2 >= $6 && $7 >= $3 {printf "%s\t%s\n", $0,"Do_Substration_v2" ; }' Plus.txt > Plus_sub_v2.txt
        awk '{a=($7-$3);print $0,a;}' Plus_sub_v2.txt > Plus_sub_v2_1.txt
        awk '{a=($18/3);print $0,a;}' Plus_sub_v2_1.txt > Plus_sub_v2_2.txt
        awk '{a=int($19+0.5);print $0,a;}' Plus_sub_v2_2.txt > Plus_sub_v2_3.txt

###################################This End's hear#######################################

###############################New Start start's hear########################################
        awk '{a=($2-$6);print $0,a;}' Plus_sub_v2_3.txt > Plus_sub_v2_4.txt
        awk '{a=($21/3);print $0,a;}' Plus_sub_v2_4.txt > Plus_sub_v2_5.txt
        awk '{a=int($22+0.5);print $0,a;}' Plus_sub_v2_5.txt > Plus_sub_v2_6.txt
        awk '{a=($11+$23);print $0,a;}' Plus_sub_v2_6.txt > Plus_sub_v2_7.txt
        awk '{a=($12-$20);print $0,a;}' Plus_sub_v2_7.txt > Plus_sub_v2_8.txt
        awk '{print $1, $2, $3, $4, $8, $9, $10, $24, $25}' Plus_sub_v2_8.txt > Plus_sub_v2.xls
       rm Plus_sub_v2.txt Plus_sub_v2_1.txt Plus_sub_v2_2.txt Plus_sub_v2_3.txt Plus_sub_v2_4.txt Plus_sub_v2_5.txt Plus_sub_v2_6.txt Plus_sub_v2_7.txt Plus_sub_v2_8.txt Plus_sub.txt Round_v1_p_s.txt Round_v2_p_s.txt Round_v3_p_s.txt
echo " "
###################################Start end's hear ############################################################

        awk '$2 >= $6 && $7 >= $3 {printf "%s\t%s\n", $0,"Do_Sub" ; }' Neg.txt > Neg_sub.txt
        awk '{a=($16/3);print $0,a;}' Neg_sub.txt > Round_v1_n_s.txt
        awk '{a=int($18+0.5);print $0,a;}' Round_v1_n_s.txt > Round_v2_n_s.txt
        awk '{a=($7-$3);print $0,a;}' Round_v2_n_s.txt > Round_v3_n_s.txt
        awk '{a=($20/3);print $0,a;}' Round_v3_n_s.txt > Round_v4_n_s.txt
        awk '{a=int($21+0.5);print $0,a;}' Round_v4_n_s.txt > Round_v5_n_s.txt
        awk '{a=($2-$6);print $0,a;}' Round_v5_n_s.txt > Round_v6_n_s.txt
        awk '{a=($21/3);print $0,a;}' Round_v6_n_s.txt > Round_v7_n_s.txt
        awk '{a=int($22+0.5);print $0,a;}' Round_v7_n_s.txt > Round_v8_n_s.txt
        awk '{a=($11+$22);print $0,a;}' Round_v8_n_s.txt > Round_v9_n_s.txt
        awk '{a=($12-$25);print $0,a;}' Round_v9_n_s.txt > Round_v10_n_s.txt  
        awk '{print $1, $2, $3, $4, $8, $9, $10, $26, $27}' Round_v10_n_s.txt > Neg1_v1.xls
                              
#If Input Start is greater than refrence start for Neg
        awk '$2 >= $6 && $3 >= $7 {printf "%s\t%s\n", $0,"Do_Sub" ; }' Neg.txt > Neg_sub_v11_ns.txt
        awk '{a=($16/3);print $0,a;}' Neg_sub_v11_ns.txt > Neg_sub_v12_ns.txt
        awk '{a=int($18+0.5);print $0,a;}' Neg_sub_v12_ns.txt > Neg_sub_v13_ns.txt
        awk '{a=($11+$19);print $0,a;}' Neg_sub_v13_ns.txt > Neg_sub_v14_ns.txt
        awk '{print $1, $2, $3, $4, $8, $9, $10, $11, $20}' Neg_sub_v14_ns.txt > Neg1_v2.xls
       rm Neg_sub.txt Round_v1_n_s.txt Round_v2_n_s.txt Round_v3_n_s.txt Round_v4_n_s.txt Round_v5_n_s.txt Round_v6_n_s.txt Neg_sub_v11_ns.txt Neg_sub_v12_ns.txt Neg_sub_v13_ns.txt Neg_sub_v14_ns.txt Round_v7_n_s.txt Round_v8_n_s.txt Round_v9_n_s.txt Round_v10_n_s.txt
#If Input Start is less then refrence start for Neg
        awk '$6 >= $2 {printf "%s\t%s\n", $0,"Do_Substration" ; }' Neg.txt > Neg_Add.txt
        awk '{a=($16/3);print $0,a;}' Neg_Add.txt > Round_n_a.txt
        awk '{a=int($18+0.5);print $0,a;}' Round_n_a.txt > Round_v1_n_a.txt
        awk '{a=($12-$19);print $0,a;}' Round_v1_n_a.txt > Round_v2_n_a.txt
        awk '{print $1, $2, $3, $4, $8, $9, $10, $20, $12}' Round_v2_n_a.txt > Neg2.xls
        rm Neg_Add.txt Round_n_a.txt Round_v1_n_a.txt Round_v2_n_a.txt
echo " "
#############Preparation for header file################################
echo Chrom > Chrom.txt
echo Start > start.txt
echo End > end.txt
echo Amplicon_ID > Ampli.txt
echo Gene > gene.txt
echo Transcript_id > transcript.txt
echo Exon > exon.txt
echo Codon_Start > C_start.txt
echo Codon_End > C_end.txt
echo Concate > Concate.txt

paste -d ' ' Chrom.txt start.txt end.txt Ampli.txt gene.txt transcript.txt exon.txt C_start.txt C_end.txt Concate.txt > head.txt

##################END of header file######################################

####Compiling output into excel file###########################
cat Plus1.xls Plus2.xls Plus_sub_v2.xls Neg1_v1.xls Neg1_v2.xls Neg2.xls > Final_Prev.xls

#----------Concatenate last 5 columns-------------------
sed 's/ \+/\t/g' Final_Prev.xls > Final_Prev-v1.xls #Uncovered-$project_name.xls
awk 'BEGIN {FS="\t"; OFS="\t"}; {print $5 "[" $6 "]" "," $7 "," "Codons" $8 "-" $9}' Final_Prev-v1.xls > Final_Prev-v2.xls #Uncovered-$project_name.xls > Final_Vinu.xls
paste -d ' ' Final_Prev-v1.xls Final_Prev-v2.xls > Final_Prev-v3.xls
cat head.txt Final_Prev-v3.xls > Final_Prev-v4.xls
sed 's/ \+/\t/g' Final_Prev-v4.xls > Uncovered-$project_name.xls
rm Final_Prev.xls CDS.txt Plus.txt Neg.txt intersect.vcf head.txt Plus1.xls Neg2.xls Plus2.xls Chrom.txt C_end.txt gene.txt transcript.txt exon.txt start.txt end.txt Plus_sub_v2.xls C_start.txt Neg1_v1.xls Neg1_v2.xls Concate.txt Final_Prev-v1.xls Final_Prev-v2.xls Final_Prev-v3.xls Final_Prev-v4.xls Ampli.txt
 
echo "Output file:                         Uncovered-$project_name.xls"
echo " "
echo " "
echo " "

echo "----------------------Exon codon finding completed    $time-------------------------------------------------------------------"
            break
            ;;

        "Quit")
echo " "
echo " "
echo "Seleted option:                       $opt"
echo " "
echo " "
echo "Process is stopped " 
 
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

