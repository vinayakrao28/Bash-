echo " "
echo "***********************************************************************************************************************************"
echo "********************************* Script Developed by Anuja Mishra For Standalone Variant Calling *********************************"
echo "***********************************************************************************************************************************"
echo " "
cat samples_details.txt | while read file_name; do
	SID=$(echo $file_name | cut -d";" -f1)
	echo "Sample ID is : $SID"
	echo " "
	SID2=$(echo $file_name | cut -d";" -f2)
	echo "Path given is : $SID2"
	echo " "
	ii=$(echo $SID2 | cut -d"/" -f2)
	#echo $ii
	if [ $ii = 'torrentsuite' ]
	then
		SID3=$(echo $SID2 | cut -d"/" -f5)
		#echo $SID3
	else
		SID3=$(echo $SID2 | cut -d"/" -f6)
		 #echo $SID3
	fi
	SID4=$(echo $SID3 | sed 's/\.bam//')
	#echo $SID4
	SID5=$(echo $SID4 | sed 's/\_rawlib//')
	#echo $SID5
	SID6=$(echo $file_name |  cut -d";" -f3)
	echo "Panel for which standalone variant calling is to be done : $SID6"
	echo " "
	SID7=$(echo $file_name | cut -d";" -f4)
	echo "Sample type which standalone variant calling is to be done : $SID7"
	echo " "
	SS9=$(echo $file_name | cut -d";" -f5)
	#SS9=`awk -F';' '{print $5}' samples_details.txt`
	echo "Run Number is : $SS9"
	echo " "
	if [ "$SID7" = "gDNA" ]
	then
		SID8='germline_low_stringency_5.10_p1_parameters.json'
	elif [ "$SID7" = "cfTNA" ]
	then
		SID8='DCGL_cfDNA_local_parameters_07_09_2018.json'
	elif [ "$SID7" = "tissue" ]
	then
		SID8='CCP.20141112.somatic_lowstringency_550_TS_V5.14_parameters.json'
	elif [ "$SID6" = "CCP" ] && [ "$SID7" = "tissue" ]
	then
		SID8='CCP.20141112.somatic_lowstringency_550_TS_V5.14_parameters.json'
	fi
	echo "Paramter file used is  : $SID8"
	echo " "
	mkdir $SID
	tmap mapall -f /results/referenceLibrary/tmap-f3/hg19/hg19.fasta -r $SID2 -o 2 -n 16 -i bam -u -v --do-realign --prefix-exclude 5 -Y -J 25 --end-repair 15 --do-repeat-clip --context stage1 map4 | samtools sort -m 1000M -l1 -@12 - /rawdata/Standalone_variant_calling/$SID/$SID4.realigned
	samtools index /rawdata/Standalone_variant_calling/$SID/*.realigned.bam
	cd /rawdata/Standalone_variant_calling/Panel_BED_Files/$SID6/Designed/hg19/unmerged/detail/
	#ls
	des_unm_det=`ls | grep -i ".bed"`
	#echo $des_unm_det
	cd /rawdata/Standalone_variant_calling/Panel_BED_Files/$SID6/Hotspot/hg19/unmerged/detail/
	hot_unm_det=`ls | grep -i ".bed"`
	cd /rawdata/Standalone_variant_calling/Panel_BED_Files/$SID6/Designed/hg19/merged/plain/
	des_mer_pla=`ls | grep -i ".bed"`
	cd /rawdata/Standalone_variant_calling/Panel_BED_Files/$SID6/Hotspot/hg19/merged/plain/
	hot_mer_pla=`ls | grep -i ".bed"`
	cd /rawdata/Standalone_variant_calling/
	/results/plugins/variantCaller/bin/tvcutils prepare_hotspots  --input-bed "/rawdata/Standalone_variant_calling/Panel_BED_Files/$SID6/Hotspot/hg19/unmerged/detail/$hot_unm_det"  --reference "/results/referenceLibrary/tmap-f3/hg19/hg19.fasta"  --left-alignment on  --allow-block-substitutions on  --output-bed "/rawdata/Standalone_variant_calling/$SID/$SID6.20170621.hotspots.left.bed"  --output-vcf "/rawdata/Standalone_variant_calling/$SID/$SID6.20170621.hotspots.hotspot.vcf"  --unmerged-bed "/rawdata/Standalone_variant_calling/Panel_BED_Files/$SID6/Designed/hg19/unmerged/detail/$des_unm_det"
	/results/plugins/variantCaller/bin/variant_caller_pipeline.py  --input-bam "/rawdata/Standalone_variant_calling/$SID/$SID4.realigned.bam"  --region-bed "/rawdata/Standalone_variant_calling/Panel_BED_Files/$SID6/Designed/hg19/merged/plain/$des_mer_pla"  --primer-trim-bed "/rawdata/Standalone_variant_calling/Panel_BED_Files/$SID6/Designed/hg19/unmerged/detail/$des_unm_det"  --generate-gvcf on  --postprocessed-bam "/rawdata/Standalone_variant_calling/$SID/$SID4.realigned_processed.bam"  --reference-fasta "/results/referenceLibrary/tmap-f3/hg19/hg19.fasta"  --output-dir "/rawdata/Standalone_variant_calling/$SID/"  --parameters-file "/rawdata/Standalone_variant_calling/Parameter_Files/$SID8"  --bin-dir "/results/plugins/variantCaller/bin"  --error-motifs-dir "/results/plugins/variantCaller/share/TVC/sse"  --hotspot-vcf "/rawdata/Standalone_variant_calling/$SID/$SID6.20170621.hotspots.hotspot.vcf"
	samtools mpileup -BQ0 -d1000000 -f "/results/referenceLibrary/tmap-f3/hg19/hg19.fasta" -l /rawdata/Standalone_variant_calling/Panel_BED_Files/$SID6/Hotspot/hg19/merged/plain/$hot_mer_pla /rawdata/Standalone_variant_calling/$SID/$SID4.realigned_processed.bam | /results/plugins/variantCaller/scripts/allele_count_mpileup_stdin.py > /rawdata/Standalone_variant_calling/$SID/allele_counts.txt
	/results/plugins/variantCaller/scripts/print_allele_counts.py /rawdata/Standalone_variant_calling/$SID/allele_counts.txt /rawdata/Standalone_variant_calling/$SID/allele_counts.xls "/rawdata/Standalone_variant_calling/$SID/$SID6.20170621.hotspots.left.bed" "/rawdata/Standalone_variant_calling/Panel_BED_Files/$SID6/Hotspot/hg19/unmerged/detail/$hot_unm_det"
	/results/plugins/variantCaller/scripts/generate_variant_tables.py  --suppress-no-calls on  --input-vcf /rawdata/Standalone_variant_calling/$SID/TSVC_variants.vcf  --region-bed "/rawdata/Standalone_variant_calling/Panel_BED_Files/$SID6/Designed/hg19/unmerged/detail/$des_unm_det"  --hotspots  --output-xls /rawdata/Standalone_variant_calling/$SID/variants.xls  --alleles2-xls /rawdata/Standalone_variant_calling/$SID/alleles.xls  --summary-json /rawdata/Standalone_variant_calling/$SID/variant_summary.json  --scatter-png /rawdata/Standalone_variant_calling/$SID/scatter.png  --barcode $SID5  --concatenated-xls "/rawdata/Standalone_variant_calling/$SID/R_2021_02_19_19_41_42_user_DGL-01-202-$9.xls"  --run-name "R_2021_02_19_19_41_42_user_DGL-01-202-$SS9"  --library-type "AmpliSeq"
	/results/plugins/variantCaller/bin/tvcutils prepare_hotspots --reference "/results/referenceLibrary/tmap-f3/hg19/hg19.fasta" --input-vcf "/rawdata/Standalone_variant_calling/$SID/TSVC_variants.vcf" --output-bed "/rawdata/Standalone_variant_calling/$SID/TSVC_variants.bed"
	samtools mpileup -BQ0 -d1000000 -f "/results/referenceLibrary/tmap-f3/hg19/hg19.fasta" -l /rawdata/Standalone_variant_calling/$SID/TSVC_variants.bed /rawdata/Standalone_variant_calling/$SID/$SID4.realigned_processed.bam | /results/plugins/variantCaller/scripts/allele_count_mpileup_stdin.py > /rawdata/Standalone_variant_calling/$SID/TSVC_variants_allele_counts.txt
	/results/plugins/variantCaller/scripts/print_variant_allele_counts.py $SID5 '$SID' /rawdata/Standalone_variant_calling/$SID/TSVC_variants.vcf /rawdata/Standalone_variant_calling/$SID/TSVC_variants_allele_counts.txt /rawdata/Standalone_variant_calling/$SID/variant_allele_counts.xls

	echo "************************************* Variant calling completed for Sample ID : $SID **********************************************"
	echo " "
done
