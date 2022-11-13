#!/usr/bin/bash
############################################################
#Script to merge bam files 
#Scripted by Vinayak Rao
#Date:21-12-2021
#Version: 2.0
##############################################################


echo "**************Script to merge bam file*********************"
echo ""
echo | date
echo ""
echo -n "Please enter Project name : "
read text
echo  ""
INPUT="$1"
INPUT_2="$2"

VAR1=`samtools view -H $1 | grep '^@RG' | sed "s/.*SM:\([^\t]*\).*/\1/g" | uniq`

echo "$1 Sample ID is ***$VAR1***"
echo ""

VAR2=`samtools view -H $2 | grep '^@RG' | sed "s/.*SM:\([^\t]*\).*/\1/g" | uniq`

echo "$2 Sample ID is ***$VAR2***"
echo""

if [ $VAR1 = $VAR2 ]; then
	
	echo "######## $1 and $2 sample ID's **matches** no need to change #############"
echo ""
samtools view -H $1 > $1.header.sam

echo "First bam header extrated" 
echo ""

samtools view -H $2 > $2.header.sam

echo "Second bam header extracted" 
echo ""
java -Xmx8g -jar /rawdata/opt/picard/picard-tools-current/picard.jar MergeSamFiles I=$1.header.sam I=$2.header.sam O=$text.Merged.header.sam VERBOSITY=WARNING QUIET=true VALIDATION_STRINGENCY=SILENT

echo "Merge sam file created"
echo ""
samtools merge -l1 -@8 $text.Merged.sam $1 $2 -h $text.Merged.header.sam
echo "Header merge" 
samtools view -S -b $text.Merged.sam > $text.Merged.bam

echo "Converting SAM to BAM" 
echo ""
samtools index $text.Merged.bam
echo "Indexing BAM file"

rm $text.Merged.sam $text.Merged.header.sam $2.header.sam $1.header.sam

echo | date

else 
	echo "####### $1 and $2 Sample ID **don't match** need to change ###########"
echo 


	

read -r -p "                        Changing Sample ID in FIRST BAM.....???     [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
 echo "You Choose = Yes"

echo "                        Changing sample ID  in First BAM               "
echo ""
echo -n "Plese enter sample ID : "

read sample_ID

samtools view -H $1  | sed "s/SM:[^\t]*/SM:$sample_ID/g" | samtools reheader - $1 > $1_SM_Changed.bam

samtools index $1_SM_Changed.bam


samtools view -H $1_SM_Changed.bam > $1.header.sam

echo "First bam header extrated" 
echo ""

samtools view -H $2 > $2.header.sam

echo "Second bam header extracted" 
echo ""
java -Xmx8g -jar /rawdata/opt/picard/picard-tools-current/picard.jar MergeSamFiles I=$1.header.sam I=$2.header.sam O=$text.Merged.header.sam VERBOSITY=WARNING QUIET=true VALIDATION_STRINGENCY=SILENT

echo "Merge sam file created" 
echo ""
samtools merge -l1 -@8 $text.Merged.sam $1_SM_Changed.bam $2 -h $text.Merged.header.sam
echo "Header merge" 
samtools view -S -b $text.Merged.sam > $text.Merged.bam

echo "Converting SAM to BAM" 
echo ""
samtools index $text.Merged.bam
echo "Indexing BAM file"

rm $text.Merged.sam $text.Merged.header.sam $2.header.sam $1.header.sam

echo | date
;;
  [nN][oO]|[nN])
 echo "You choose = No"

echo "                        Changing sample ID  in second BAM               "
echo ""
echo -n "Plese enter sample ID : "

read sample_ID

samtools view -H $2  | sed "s/SM:[^\t]*/SM:$sample_ID/g" | samtools reheader - $2 > $2_SM_Changed.bam

samtools index $2_SM_Changed.bam

samtools view -H $1 > $1.header.sam

echo "First bam header extrated" 
echo ""

samtools view -H $2_SM_Changed.bam > $2.header.sam

echo "Second bam header extracted" 
echo ""
java -Xmx8g -jar /rawdata/opt/picard/picard-tools-current/picard.jar MergeSamFiles I=$1.header.sam I=$2.header.sam O=$text.Merged.header.sam VERBOSITY=WARNING QUIET=true VALIDATION_STRINGENCY=SILENT

echo "Merge sam file created" 
echo ""
samtools merge -l1 -@8 $text.Merged.sam $1 $2_SM_Changed.bam -h $text.Merged.header.sam
echo "Header merge" 
samtools view -S -b $text.Merged.sam > $text.Merged.bam

echo "Converting SAM to BAM" 
echo ""
samtools index $text.Merged.bam
echo "Indexing BAM file"

rm $text.Merged.sam $text.Merged.header.sam $2.header.sam $1.header.sam
echo ""
echo | date

;;
    *)
 echo "Invalid input..."
 exit 1
 ;;
esac
fi
