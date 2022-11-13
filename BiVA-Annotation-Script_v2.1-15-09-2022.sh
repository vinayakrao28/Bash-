#!/bin/bash
#####################################################################################################################################################
#This script is to make BiVA for CCP, OCAv3 and OCAPlus samples
#Scripted by Vinayak Rao
#Date:15-09-2022
#Version: 2.1
################################################################################### 
#set -uex
echo " "
echo " "
time=$(date)
Input=$1
pwd=$(pwd)
DATABASE="/bioinfo-data/Vinayak/Databases/Ing_Databases" #Please enter the database path 
echo -n "Enter project name : "
read project_name

echo " $time"
echo " "
echo " "
echo " $pwd"
echo ""
echo ""
echo "Input file used $1   "
echo ""
echo ""
echo -n " IS this OCAPlus Sample..?? (y/n):	"
    #read p "IS this OCAPlus Sample..?? (Y/N): " yorn && [ $yorn == [yY] || $yorn == [yY][eE][sS] ] || exit 1
     #if [ "$yorn" = y ] || [ "$yorn" = Y ] || [ "$yorn" = Yes ] || [ "$yorn" = No ]; then
read yorn
	
	if [ "$yorn" = y ] || [ "$yorn" = Y ]; then
            echo "This is yes for OCAPlus"
mkdir Process_$project_name
cp $1 $pwd/Process_$project_name
cd $pwd/Process_$project_name
mkdir $project_name
unzip $1 -d $pwd/Process_$project_name/$project_name-for_zip

cd $pwd/Process_$project_name/$project_name-for_zip
find . -iname '*Non-Filtered*.tsv' -type f -exec cp {} $pwd/Process_$project_name/$project_name-for_zip \;
grep "POS" *.tsv | sed 's/"/ /g' | cut -f10,11 | sed 's/chr/ /g' | tail -n +2 > Chr_Pos.xls
awk '{a=($2-10);print $0,a;}' Chr_Pos.xls > Chr_Pos_Plus.xls
awk '{a=($2+10);print $0,a;}' Chr_Pos_Plus.xls > Chr_Pos_Plus_minus.xls
sed 's/ \+/\t/g' Chr_Pos_Plus_minus.xls > Chr_Pos_Plus_minus_v1.xls
cut -f2,6,7 Chr_Pos_Plus_minus_v1.xls > Input_$project_name.bed
mv Input_$project_name.bed $pwd
cd $pwd
echo "First Intersection:"
echo ""
echo ""
bedtools intersect -a Input_$project_name.bed -b $DATABASE/OCAPlus_Split_1.bed -wo | cut -f4-56 > First_out.vcf
echo "Second Intersection:"
echo ""
bedtools intersect -a Input_$project_name.bed -b $DATABASE/OCAPlus_Split_2.bed -wo | cut -f4-56 > Second_out.vcf
echo "Third Intersection"
bedtools intersect -a Input_$project_name.bed -b $DATABASE/OCAPlus_Split_3.bed -wo | cut -f4-56 > Third_out.vcf
echo ""
echo "Fourth Intersection"
bedtools intersect -a Input_$project_name.bed -b $DATABASE/OCAPlus_Split_4.bed -wo | cut -f4-56 > Fourth_out.vcf
echo ""
echo "Fifth Intersection"
bedtools intersect -a Input_$project_name.bed -b $DATABASE/OCAPlus_Split_5.bed -wo | cut -f4-56 > Fifth_out.vcf
echo ""
echo "Sixth Intersection"
bedtools intersect -a Input_$project_name.bed -b $DATABASE/OCAPlus_Split_6.bed -wo | cut -f4-56 > Sixth_out.vcf
echo ""

cp $DATABASE/head.txt $pwd

cat head.txt  Sixth_out.vcf Fifth_out.vcf Fourth_out.vcf Third_out.vcf Second_out.vcf First_out.vcf      > $project_name-BiVA.tsv

rm First_out.vcf Input_$project_name.bed head.txt Second_out.vcf Third_out.vcf Fourth_out.vcf Fifth_out.vcf Sixth_out.vcf
rm -r Process_$project_name
            
        elif [ "$yorn" = n ] || [ "$yorn" = N ]; then

            echo -n "Is this CCP-cfTNA in which changes is required..?? (y/n): "
                read yorn_1
                    
                    if [ "$yorn_1" = y ] || [ "$yorn_1" = Y ]; then
echo ""
echo ""
                        echo "Type in values "
echo ""
echo -n "		Original Coverage (500) : "
read Original_Coverage
echo -n "		Frequency (0.5) : "
read Freq
echo -n "		Allele Coverage (7) : "
read AC
echo ""
echo "	Original Coverage > $Original_Coverage && Frequency > $Freq && Allele Coverage > $AC"
tail -n +2 $1 | sed -r "s/^/$Original_Coverage?/g" | sed -r "s/^/$Freq?/g" | sed -r "s/^/$AC?/g" | sed 's/?/\t/g' > aaa.xls
awk '{if ($1<$29) print ("Greater");else print "Smaller"}' aaa.xls > all_Count.xls
awk '{if ($2<$10) print ("Greater");else print "Smaller"}' aaa.xls > Frq.xls
awk '{if ($3<$22) print ("Greater");else print "Smaller"}' aaa.xls > Ori_Cover.xls
#paste -d ' ' aaa.xls all_Count.xls | sed 's/?/\t/g' > Cut_Off_all_Count.xls
#paste -d ' ' aaa.xls Frq.xls | sed 's/?/\t/g' > Cut_Off_Frq.xls
#paste -d ' ' aaa.xls Ori_Cover.xls | sed 's/?/\t/g' > Cut_Off_Ori_Cover.xls

paste -d ' ' all_Count.xls Frq.xls Ori_Cover.xls | sed 's/ \+/\t/g' > Areee.xls
paste -d ' ' Areee.xls aaa.xls | awk '$1 == "Greater" && $2 == "Greater" && $3 == "Greater" {printf "%s\t%s\n", $0,"Do_Substration" ; } ' | sed 's/chr0/chr/g' | cut -f6-56 > Final.xls

head -1 $1 > head.xls

cat head.xls Final.xls > $project_name-alleles_new.xls

rm all_Count.xls Frq.xls Ori_Cover.xls head.xls Final.xls Areee.xls aaa.xls

mkdir Process_$project_name
cp $project_name-alleles_new.xls $pwd/Process_$project_name
cd $pwd/Process_$project_name
echo "xxxxxxxxxxxxxxxxx Input file processing XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
echo ""
echo ""
grep -w "Heterozygous\|Homozygous" $project_name-alleles_new.xls > Input.txt
cut -f1,2 Input.txt > Input_v1.txt
awk '{a=($2-10);print $0,a;}' Input_v1.txt > Input_v2.txt
awk '{a=($2+10);print $0,a;}' Input_v2.txt > Input_v3.txt
sed 's/ \+/\t/g' Input_v3.txt > Input_v4.xls
cut -f1,3,4 Input_v4.xls | tail -n +2 > Input_v5.bed
sed 's/chr//g' Input_v5.bed > Input_v6.bed
echo ""
echo ""
echo ""
#Intersecting the input file with bedtools
echo "First Intersection:                   "
#echo "XXXXXXXXXXXXXXXXXX First intersection XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
bedtools intersect -a Input_v6.bed -b $DATABASE/CCP_v1_Split.bed -wo | cut -f4-56 > First_output.vcf

echo ""
echo ""
echo "Second Intersection:                   "
#echo "XXXXXXXXXXXXXXXXX Second intersection XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
bedtools intersect -a Input_v6.bed -b $DATABASE/CCP_v2_Split.bed -wo | cut -f4-56 > Second_output.vcf


echo ""
echo ""
echo "Third Intersection:                   "
#echo "XXXXXXXXXXXXXXXXX Third intersection XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
bedtools intersect -a Input_v6.bed -b $DATABASE/CCP_v3_Split.bed -wo | cut -f4-56 > Third_output.vcf

echo ""
echo ""
echo "Fourth Intersection:                   "
bedtools intersect -a Input_v6.bed -b $DATABASE/CCP_v4_Split.bed -wo | cut -f4-56 > Fourth_output.vcf
echo ""
echo ""

echo "Fifth Intersection:                   "
echo ""
echo ""

bedtools intersect -a Input_v6.bed -b $DATABASE/CCP_v5_Split.bed -wo | cut -f4-56 > Fifth_output.vcf

echo "Sixth Intersection:                   "
bedtools intersect -a Input_v6.bed -b $DATABASE/CCP_v6_Split.bed -wo | cut -f4-56 > Sixth_output.vcf

#Merge all file
echo ""
echo ""
echo ""
echo "XXXXXXXXXXXXXX All file merging XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
cp $DATABASE/head.txt $pwd/Process_$project_name
cat head.txt Sixth_output.vcf First_output.vcf Second_output.vcf Third_output.vcf Fourth_output.vcf Fifth_output.vcf > $project_name-BiVA.tsv
mv $project_name-BiVA.tsv $pwd
cd $pwd
rm -r Process_$project_name

echo ""
echo ""
echo "           Filtered alleles file is created $project_name-alleles_new.xls"
echo ""
echo ""

echo ""
echo ""
echo "######## BiVA file is created $project_name-BiVA.tsv   $time###################################"
                    else 
                        echo "This is not CCP nor OCAPlus"

mkdir Process_$project_name
cp $1 $pwd/Process_$project_name
cd $pwd/Process_$project_name
if [ $1 = *.xls ]; then
echo "xxxxxxxxxxxxxxxxx Input file processing XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
echo ""
echo ""
grep -w "Heterozygous\|Homozygous" $1 > Input.txt
cut -f1,2 Input.txt > Input_v1.txt
awk '{a=($2-10);print $0,a;}' Input_v1.txt > Input_v2.txt
awk '{a=($2+10);print $0,a;}' Input_v2.txt > Input_v3.txt
sed 's/ \+/\t/g' Input_v3.txt > Input_v4.xls
cut -f1,3,4 Input_v4.xls | tail -n +2 > Input_v5.bed
sed 's/chr//g' Input_v5.bed > Input_v6.bed
echo ""
echo ""
echo ""
#Intersecting the input file with bedtools
echo "First Intersection:                   "
#echo "XXXXXXXXXXXXXXXXXX First intersection XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
bedtools intersect -a Input_v6.bed -b $DATABASE/CCP_v1_Split.bed -wo | cut -f4-56 > First_output.vcf

echo ""
echo ""
echo "Second Intersection:                   "
#echo "XXXXXXXXXXXXXXXXX Second intersection XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
bedtools intersect -a Input_v6.bed -b $DATABASE/CCP_v2_Split.bed -wo | cut -f4-56 > Second_output.vcf


echo ""
echo ""
echo "Third Intersection:                   "
#echo "XXXXXXXXXXXXXXXXX Third intersection XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
bedtools intersect -a Input_v6.bed -b $DATABASE/CCP_v3_Split.bed -wo | cut -f4-56 > Third_output.vcf

echo ""
echo ""
echo "Fourth Intersection:                   "
bedtools intersect -a Input_v6.bed -b $DATABASE/CCP_v4_Split.bed -wo | cut -f4-56 > Fourth_output.vcf
echo ""
echo ""

echo "Fifth Intersection:                   "
echo ""
echo ""

bedtools intersect -a Input_v6.bed -b $DATABASE/CCP_v5_Split.bed -wo | cut -f4-56 > Fifth_output.vcf

echo "Sixth Intersection:                   "
bedtools intersect -a Input_v6.bed -b $DATABASE/CCP_v6_Split.bed -wo | cut -f4-56 > Sixth_output.vcf

#Merge all file
echo ""
echo ""
echo ""
echo "XXXXXXXXXXXXXX All file merging XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
cp $DATABASE/head.txt $pwd/Process_$project_name
cat head.txt Sixth_output.vcf First_output.vcf Second_output.vcf Third_output.vcf Fourth_output.vcf Fifth_output.vcf > $project_name-BiVA.tsv
mv $project_name-BiVA.tsv $pwd
cd $pwd
rm -r Process_$project_name


echo ""
echo ""
echo ""

echo ""
echo ""
echo "######## BiVA file is created $project_name-BiVA.tsv   $time###################################"
#rm head.txt Input.txt Input_v2.txt Input_v3.txt Input_v4.xls Input_v5.bed Input_v6.bed First_output.vcf Second_output.vcf Third_output.vcf Fourth_output.vcf Fifth_output.vcf Sixth_output.vcf Input_v1.txt

elif [ $1 = *.zip ]; then

echo "xxxxxxxxxxxxxxxxx Input file processing XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
echo ""
echo ""

mkdir $project_name
unzip $1 -d $pwd/Process_$project_name/$project_name-for_zip

cd $pwd/Process_$project_name/$project_name-for_zip
find . -iname '*Non-Filtered*.tsv' -type f -exec cp {} $pwd/Process_$project_name/$project_name-for_zip \;
grep "POS" *.tsv | sed 's/"/ /g' | cut -f10,11 | sed 's/chr/ /g' | tail -n +2 > Chr_Pos.xls
awk '{a=($2-10);print $0,a;}' Chr_Pos.xls > Chr_Pos_Plus.xls
awk '{a=($2+10);print $0,a;}' Chr_Pos_Plus.xls > Chr_Pos_Plus_minus.xls
sed 's/ \+/\t/g' Chr_Pos_Plus_minus.xls > Chr_Pos_Plus_minus_v1.xls
cut -f2,6,7 Chr_Pos_Plus_minus_v1.xls > Input_$project_name.bed
mv Input_$project_name.bed $pwd
cd $pwd

echo "First Intersection:                   "
echo ""
echo ""
bedtools intersect -a Input_$project_name.bed -b $DATABASE/CCP_v6_Split.bed -wo | cut -f4-56 > First_out.vcf
echo "Second Intersection:                  "
bedtools intersect -a Input_$project_name.bed -b $DATABASE/OCAv3_bed_Database.bed -wo | cut -f4-56 > second_out.vcf
echo ""
echo ""
cp $DATABASE/head.txt $pwd
cat head.txt First_out.vcf second_out.vcf > $project_name-BiVA.tsv

rm First_out.vcf second_out.vcf Input_$project_name.bed head.txt
rm -r Process_$project_name 
fi
                           
                    fi
       # else 
        #        echo "Not a valid answer"
        #exit 1
     fi              
