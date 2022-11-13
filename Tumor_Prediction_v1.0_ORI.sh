#!/bin/bash
date1=$(date +'%m-%d-%Y')
time1=$(date +'%r')
for tissue_sample in 210606756-CCP-FFPE_DNA-IonCode_0430-DGL_2664-58-cholangiocarcinoma-M67
do
	#exec > >(tee -i /results/bioinfo-data-vol1/cnv_analysis_ONCOCNV/CNVkit_CCP_tissue/$tissue_sample/$tissue_sample.log)
	#exec 2>&1
	echo -e "*********************************************************************************************************************************"
	echo -e "*\tScript\t\t:\tTumor Prediction for CCP paired Sample\t\t\t\t\t\t\t\t*"
	echo -e "*\tDeveloped by\t:\tRam Sai\t\t\t\t\t\t\t\t\t\t\t\t*"
	echo -e "*\tVersion\t\t:\tv1.0\t\t\t\t\t\t\t\t\t\t\t\t*"
	echo -e "*********************************************************************************************************************************"
	echo -e "\nDate\t:\t$date1\tTime\t:\t$time1"


	if [ -d "/results/bioinfo-data-vol1/cnv_analysis_ONCOCNV/CNVkit_CCP_tissue/$tissue_sample" ]; then rm -rf /results/bioinfo-data-vol1/cnv_analysis_ONCOCNV/CNVkit_CCP_tissue/$tissue_sample; fi

	mkdir /results/bioinfo-data-vol1/cnv_analysis_ONCOCNV/CNVkit_CCP_tissue/$tissue_sample
	echo -e "\nCreated output dirctory : $tissue_sample\n"
	cd /results/bioinfo-data-vol1/cnv_analysis_ONCOCNV/CNVkit_CCP_tissue/$tissue_sample

	for gDNA_sample in 210606756-CCP-gDNA-IonCode_0411-DGL_2661-58-cholangiocarcinoma-M67

		do
			IFS='-' arr=(${gDNA_sample})
				IFS=$'\n'

			gDNA_path=$(pwd)

			gDNA_run_names=( $(ls /torrentsuite/172.16.3.${arr[5]}/ | grep "${arr[4]}" | grep -v "_tn_") )
			if [ ${#gDNA_run_names[@]} -gt 1 ]; then
			echo -e "\n\nMultiple gDNA run found :\n"
			for I in ${gDNA_run_names[@]}; do echo -e "$I\n"; done
			read -p "Enter run name:    " gdna_run
			gdna_run="${gdna_run%\\n}"
			gDNA_run_names[0]=$gdna_run
			fi

			echo -e "\ngDNA Run:\"${gDNA_run_names[0]}\""
			####### Copy raw bam file from Torrent Suite server #######

			echo -e "\nCreating symbolic link of gDNA raw bam file from /torrentsuite folder...\n"
			ln -s  /torrentsuite/172.16.3.${arr[5]}/${gDNA_run_names[0]}/${arr[3]}_rawlib.bam $gDNA_sample.bam
			ln -s  /torrentsuite/172.16.3.${arr[5]}/${gDNA_run_names[0]}/${arr[3]}_rawlib.bam.bai $gDNA_sample.bam.bai

			############ Finding for right vcf file and copying it to the folder ################
			gdna_vcf_folder=( $(find /torrentsuite/172.16.3.${arr[5]}/${gDNA_run_names[0]}/plugin_out -name "CCP.20131001.designed.bed" | grep -E "variantCaller_out.*${arr[3]}" | xargs dirname | xargs dirname) )

			if grep -q -F "germline_lowstringency_" ${gdna_vcf_folder[0]}/*parameters*.json; then
  			echo -e "gDNA vcf folder: ${gdna_vcf_folder[0]}"
			cp -r ${gdna_vcf_folder[0]}/${arr[3]}/TSVC_variants.vcf.gz ${gdna_vcf_folder[0]}/${arr[3]}/TSVC_variants.vcf.gz.tbi ./

			elif grep -q -F "germline_lowstringency_" ${gdna_vcf_folder[1]}/*parameters*.json; then
  			echo -e "gDNA vcf folder: ${gdna_vcf_folder[1]}"
			cp -r ${gdna_vcf_folder[1]}/${arr[3]}/TSVC_variants.vcf.gz ${gdna_vcf_folder[1]}/${arr[3]}/TSVC_variants.vcf.gz.tbi ./

			elif grep -q -F "germline_lowstringency_" ${gdna_vcf_folder[2]}/*parameters*.json; then
  			echo -e "gDNA vcf folder: ${gdna_vcf_folder[2]}"
			cp -r ${gdna_vcf_folder[2]}/${arr[3]}/TSVC_variants.vcf.gz ${gdna_vcf_folder[2]}/${arr[3]}/TSVC_variants.vcf.gz.tbi ./

			elif grep -q -F "germline_lowstringency_" ${gdna_vcf_folder[3]}/*parameters*.json; then
  			echo -e "gDNA vcf folder: ${gdna_vcf_folder[3]}"
			cp -r ${gdna_vcf_folder[3]}/${arr[3]}/TSVC_variants.vcf.gz ${gdna_vcf_folder[3]}/${arr[3]}/TSVC_variants.vcf.gz.tbi ./

			elif grep -q -F "germline_lowstringency_" ${gdna_vcf_folder[4]}/*parameters*.json; then
		  	echo -e "gDNA vcf folder: ${gdna_vcf_folder[4]}"
			cp -r ${gdna_vcf_folder[4]}/${arr[3]}/TSVC_variants.vcf.gz ${gdna_vcf_folder[4]}/${arr[3]}/TSVC_variants.vcf.gz.tbi ./
			fi

			mv TSVC_variants.vcf.gz $gDNA_sample.vcf.gz
			mv TSVC_variants.vcf.gz.tbi $gDNA_sample.vcf.gz.tbi

		done

	IFS='-' arr=(${tissue_sample})
		IFS=$'\n'

	tissue_path=$(pwd)

	tissue_run_names=( $(ls /torrentsuite/172.16.3.${arr[5]}/ | grep "${arr[4]}" | grep -v "_tn_") )
	if [ ${#tissue_run_names[@]} -gt 1 ]; then
        echo -e "\n\nMultiple tissue run found :\n"
	for I in ${tissue_run_names[@]}; do echo -e "$I\n"; done
        read -p "Enter run name:    " tissue_run
	tissue_run="${tissue_run%\\n}"
        tissue_run_names[0]=$tissue_run
        fi

	echo -e "\nTissue Run:\"${tissue_run_names[0]}\""

####### Copy raw bam file from Torrent Suite server #######

	echo -e "\nCreating symbolic link of tissue DNA raw bam file from /torrentsuite folder...\n"
	ln -s  /torrentsuite/172.16.3.${arr[5]}/${tissue_run_names[0]}/${arr[3]}_rawlib.bam $tissue_sample.bam
	ln -s  /torrentsuite/172.16.3.${arr[5]}/${tissue_run_names[0]}/${arr[3]}_rawlib.bam.bai $tissue_sample.bam.bai

	############ Finding for right vcf file and copying it to the folder ################
	tissue_vcf_folder=( $(find /torrentsuite/172.16.3.${arr[5]}/${tissue_run_names[0]}/plugin_out -name "CCP.20131001.designed.bed" | grep -E "variantCaller_out.*${arr[3]}" | xargs dirname | xargs dirname) )
	if grep -q -F "CCP.20141112.somatic_lowstringency_" ${tissue_vcf_folder[0]}/*parameters*.json; then
        echo  -e "Tissue DNA vcf folder: ${tissue_vcf_folder[0]}"
	cp -r ${tissue_vcf_folder[0]}/${arr[3]}/TSVC_variants.vcf.gz ${tissue_vcf_folder[0]}/${arr[3]}/TSVC_variants.vcf.gz.tbi ./

        elif grep -q -F "CCP.20141112.somatic_lowstringency_" ${tissue_vcf_folder[1]}/*parameters*.json; then
        echo "Tissue DNA vcf folder: ${tissue_vcf_folder[1]}"
        cp -r ${tissue_vcf_folder[1]}/${arr[3]}/TSVC_variants.vcf.gz ${tissue_vcf_folder[1]}/${arr[3]}/TSVC_variants.vcf.gz.tbi ./

      	elif grep -q -F "CCP.20141112.somatic_lowstringency_" ${tissue_vcf_folder[2]}/*parameters*.json; then
        echo "Tissue DNA vcf folder: ${tissue_vcf_folder[2]}"
	cp -r ${tissue_vcf_folder[2]}/${arr[3]}/TSVC_variants.vcf.gz ${tissue_vcf_folder[2]}/${arr[3]}/TSVC_variants.vcf.gz.tbi ./

        elif grep -q -F "CCP.20141112.somatic_lowstringency_" ${tissue_vcf_folder[3]}/*parameters*.json; then
        echo "Tissue DNA vcf folder: ${tissue_vcf_folder[3]}"
        cp -r ${tissue_vcf_folder[3]}/${arr[3]}/TSVC_variants.vcf.gz ${tissue_vcf_folder[3]}/${arr[3]}/TSVC_variants.vcf.gz.tbi ./

        elif grep -q -F "CCP.20141112.somatic_lowstringency_" ${tissue_vcf_folder[4]}/*parameters*.json; then
        echo "Tissue DNA vcf folder: ${tissue_vcf_folder[4]}"
        cp -r ${tissue_vcf_folder[4]}/${arr[3]}/TSVC_variants.vcf.gz ${tissue_vcf_folder[4]}/${arr[3]}/TSVC_variants.vcf.gz.tbi ./
        fi

	mv TSVC_variants.vcf.gz $tissue_sample.vcf.gz
	mv TSVC_variants.vcf.gz.tbi $tissue_sample.vcf.gz.tbi

done

# Tumor Prediction
targets='/results/bioinfo-data-vol1/cnv_analysis_ONCOCNV/CNVkit_CCP_tissue/CCP.20131001.designed_MERGED_CNVkit.bed'
annotate='/results/bioinfo-data-vol1/cnv_analysis_ONCOCNV/CNVkit_CCP_tissue/refFlat.txt'
fasta='/results/referenceLibrary/tmap-f3/hg19/hg19.fasta'
access='/results/bioinfo-data-vol1/cnv_analysis_ONCOCNV/CNVkit_CCP_tissue/access-5k-mappable.hg19.bed'

export NO_AT_BRIDGE=1
export PYTHONPATH="${PYTHONPATH}:/opt/installers_DGL/bnpy-dev"

if [ ${arr[7]} == "M" ]
then
	echo -e "\nIt is a Male Sample"

	cnvkit.py batch $tissue_sample.bam --normal $gDNA_sample.bam --targets $targets --annotate $annotate --fasta $fasta --access $access --output-reference ${arr[0]}_CCP_${arr[2]}_gDNA.cnn --output-dir cnvkit_Results_${arr[0]}_CCP_${arr[2]}_gDNA_paired --diagram --scatter -p 24 --drop-low-coverage --male-reference

else
	echo -e "It is a Female Sample"
	cnvkit.py batch $tissue_sample.bam --normal $gDNA_sample.bam --targets $targets --annotate $annotate  --fasta $fasta --access $access --output-reference ${arr[0]}_CCP_${arr[2]}_gDNA.cnn --output-dir cnvkit_Results_${arr[0]}_CCP_${arr[2]}_gDNA_paired --diagram --scatter -p 24 --drop-low-coverage
fi

# moving cnn file to the to the results folder
mv ${arr[0]}_CCP_${arr[2]}_gDNA.cnn cnvkit_Results_${arr[0]}_CCP_${arr[2]}_gDNA_paired

cd cnvkit_Results_${arr[0]}_CCP_${arr[2]}_gDNA_paired

#copying vcf files in the folder
cp -r /results/bioinfo-data-vol1/cnv_analysis_ONCOCNV/CNVkit_CCP_tissue/$tissue_sample/*vcf* ./

#merging vcf files
vcf-merge $tissue_sample.vcf.gz $gDNA_sample.vcf.gz > $tissue_sample.gDNA_MERGED.vcf

sample_id_vcf=$(LANG=C grep -F "#CHROM" $tissue_sample.gDNA_MERGED.vcf | cut -f10)
normal_id_vcf=$(LANG=C grep -F "#CHROM" $tissue_sample.gDNA_MERGED.vcf | cut -f11)

#checking cns file and creating it if it is not present
if [ -e $tissue_sample.cns ]
then
    echo -e "\n$tissue_sample.cns exits"
else
    cnvkit.py segment $tissue_sample.cnr -o $tissue_sample.cns
fi

cnvkit.py export theta $tissue_sample.cns -r ${arr[0]}_CCP_${arr[2]}_gDNA.cnn -v $tissue_sample.gDNA_MERGED.vcf --sample-id $sample_id_vcf --normal-id $normal_id_vcf

#Run Theta
/opt/installers_DGL/THetA/bin/RunTHetA $tissue_sample.interval_count --TUMOR_FILE $tissue_sample.tumor.snp_formatted.txt --NORMAL_FILE $tissue_sample.normal.snp_formatted.txt --FORCE --BAF --NUM_PROCESSES 4

#checking if n2.graph.pdf exits or no

if [ -e $tissue_sample.n2.graph.pdf ]
then
    echo -e "\n$tissue_sample.n2.graph.pdf exists"
else
	echo -e "\n$tissue_sample.n2.graph.pdf does not exist\nRunning THetA analysis with --NO_CLUSTERING Parameter"
    /opt/installers_DGL/THetA/bin/RunTHetA $tissue_sample.interval_count --TUMOR_FILE $tissue_sample.tumor.snp_formatted.txt --NORMAL_FILE $tissue_sample.normal.snp_formatted.txt --FORCE --BAF --NUM_PROCESSES 4 --NO_CLUSTERING
fi

tumor_content=$(pdfgrep Tumor1 $tissue_sample.n2.graph.pdf | sed 's/\s//g' | sed 's/%/\t/g' | cut -f2 | sed 's/Tumor1://g')
echo "Tumor Content is $tumor_content %"
