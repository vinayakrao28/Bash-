#!/usr/bin/perl –w

use Spreadsheet::WriteExcel;
use Spreadsheet::ParseExcel;
use Getopt::Long;
use Cwd;
use FindBin '$Bin';
use POSIX qw(strftime);
use List::MoreUtils qw(first_index);
use Math::Round;
binmode STDOUT, ":utf8";
use utf8;
use JSON;

# System credentials
$user = "bioinfo";
$ip = "172.16.3.63";
$pass = 'Br@@1234';

# Ion Server credentials
$ionusr = "vinayak";
$ionpass = 'Vr@@1234';

#Script Version
$version="v9.4.2 (27/09/2022)"; 
#Updates
# 1 - Added checklist logic
# 2 - StrandBias after blacklisted remark for gDNA
# 3 - OCAv3-cf analysis compatible
# 4 - BRCA designed file changed
# 5 - DGL/DCG Run plans accepted
#Analyst
$Analyst = "Vinayak Rao";

# Annotation Databases path (Update this to the path of databases on your system)
$db_path = "/bioinfo-data/Vinayak/Databases/";

# Annotation Databases (Download latest version from 172.16.3.52:/rawdata/Databases/Annotation_Databases_and_Scripts).
$Genomes1000=$db_path."1000Genomes.txt";
$PredictSNPdb =$db_path."PredictSNP2.txt";
$VarSeqdb=$db_path."VarSeq.tsv";
$blacklistdb=$db_path."DCGL_blacklisted_variants.txt";
$uncovereddb=$db_path."DCGL_panel_amplicons_gene_exon_codons.txt";
$germlinedb=$db_path."probable_germline_variants.txt";
$ingenuity_pre_processing=$db_path."Ingenuity_pre_processing.txt";
$COSMIC_SNP_Flag=$db_path."SNP_Flag_in_COSMIC.txt";
$actionable=$db_path."actionable_variants_db.txt";
$clinvar_db=$db_path."DCGL_ClinVar.txt";
$checklist_db=$db_path."DCGL_Checklist_07072022.txt";

# Target Region Files (designed.bed)
%target_files = ('CHP' =>  'CHP2.20131001.designed', 'CCP' =>  'CCP.20131001.designed', 'LBS1' =>  'IAD78744_151_Designed', 'LBS2' =>  'IAD79425_170_Designed', 'LBS' =>  'LBS_HotSpot-missing_Designed_with_genes_R2', 'LBS_384' =>  'LBS_384_IAD95291_151_Designed_With_Genes', 'BRCA' =>  'BRCA1_2.20131001.designed_WITH_POOL_info', 'IDP' =>  'IDP.20131001.designed', 'FHD' =>  'FHD_IAD34879_124_Designed', 'Marfan' =>  'Marfan_IAD53329_124_Designed', 'CVS' =>  'NEW_Cardiovascular_panel_Designed', 'CP2' =>  'CP2-MLH1_targets_Designed', 'WP' =>  'NEW_Women_panel_IAD53544_124_Designed', 'AML' =>  'AML_mutation_IAD81960_236_Designed', 'MODY' =>  'MODY_IAD133507_241_Designed', 'HPP' =>  'Pancreatitis_IAD105426_182_Designed', 'Hypercholesterolemia' =>  'IAD66973_197_Designed', 'Exome' =>  'AmpliSeqExome.20141113.designed', 'PGE_A' =>  'PGE_A_IAD116905_181_Designed_364_SNPs', 'PGE_B' =>  'PGE_B_IAD116916_199_Designed_16_SNPs', 'PGE_C' =>  'PGE_C_IAD124852_196_Designed_31_SNPs', 'PGE_AB' =>  'PGE_Combined_Designed_380_SNPs', 'PGE' =>  'PGE_A_B_C_Combined_Designed', 'CHP5' =>  'Lung_5_genes_CHP2.20131001.designed', 'GBM' =>  'GBM_193_amplicons_12_Jan_17_IAD95291_151_Designed_With_Genes', 'CCP1' => 'ONLY_pool-1_CCP.20131001.designed', 'CCP2' => 'ONLY_pool-2_CCP.20131001.designed', 'CCP3' => 'ONLY_pool-3_CCP.20131001.designed', 'CCP4' => 'ONLY_pool-4_CCP.20131001.designed', 'OCAv3' => 'OCAv3.20170110.designed', 'MLH1' => 'MLH1_targets_Designed', 'HBOC' => 'HBOC_IAD151105_241_Designed', 'MHCP' => 'MHCP_IAD152173_241_Designed', 'MMR' => 'MMR.desinged', 'PCP' => 'Proxosome_IAD143027_152_Designed_withGenes');

# Number of Genes in Panel
%panel_genes = ('CHP' => '50 Genes', 'CCP' => '409 Genes', 'LBS1' => '', 'LBS2' => '', 'LBS' => '61 Genes', 'LBS_384' => '68 Genes', 'BRCA' => '2 Genes', 'IDP' => '325 Genes', 'FHD' => '80 Genes', 'Marfan' => '10 Genes', 'CVS' => '209 SNPs', 'CP2' => '23 Genes, 96 SNPs', 'WP' => '14 Genes, 92SNPs', 'AML' => '22 Genes', 'MODY' => '6 Genes', 'HPP' => '4 Genes', 'Hypercholesterolemia' => '2 Genes, 1 SNP', 'Exome' => '18835 Genes', 'CHP5' => '5 Genes', 'GBM' => '53 Genes', 'CCP1' => '409 Genes', 'CCP2' => '409 Genes', 'CCP3' => '409 Genes', 'CCP4' => '409 Genes', 'OCAv3' => '161 Genes', 'MLH1' => '1 Gene', 'HBOC' => '25 Genes', 'MHCP' => '30 Genes', 'MMR' => '6 Genes', 'PCP' => '26 Genes');

#checklist_options
%checklist_options = ('1'=>'Non-Small Cell Lung (NSCLC)','2'=>'Breast','3'=>'Ampullary Adenocarcinoma/ Pancreatic Adenocarcinoma','4'=>'Central Nervous System (CNS)','5'=>'Colon (Appendiceal Adenocarcinoma)/ Rectal (CRC)','6'=>'Gastrointestinal Stromal Tumors (GIST)','7'=>'Prostate/ Ovarian/ Fallopian Tube/ Primary Peritoneal','8'=>'Thyroid Carcinoma','9'=>'Salivary gland tumors','10'=>'Bone','11'=>'Kidney','12'=>'Uterine Sarcoma','13'=>'Hepatobiliary','14'=>'Melanoma-Cutaneous','15'=>'Malignant Pleural Mesothelioma/ Malignant Peritoneal Mesothelioma','16'=>'Endometrial Carcinoma','17'=>'Head and Neck/ Esophageal and Esophagogastric Junction/ Gastric','18'=>'Bladder  (urothelial)','19'=>'Melanoma-Uveal','20'=>'Small Bowel Adenocarcinoma','21'=>'Others (Anal Carcinoma/ Cervical/ Neuroendocrine and Adrenal Tumors/ Occult Primary (unknown primary)/ Small Cell Lung/ Soft Tissue Sarcoma/ Thymomas and Thymic Carcinomas/ Vulvar Cancer)');
#Commandline variables
my ($help);

#### get options
GetOptions(
                "h\|help"   => \$help
          );

usage() and exit(1) if $help;

$fname=$ARGV[0];

usage() and exit(1) unless $fname;

my $cwd = cwd();
$foldername=`basename $cwd `;
chomp $foldername;

@foldername2= split('-',$foldername);

chomp $foldername2[5];

###################  Software/Pipeline Versions ##################################
$BiVA_version = "BiVA_v1.0 (Bioinformatics Variant Annotation database)"; # BiVA version
#$dbSNP_version = "dbSNP build 153"; # QCIT/Ingenuity provided dbSNP version
#$Clinvar_version = "Clinvar 2020-09-15"; # QCIT/Ingenuity provided Clinvar version
#$COSMIC_version =  "COSMIC v92"; # QCIT/Ingenuity provided COSMIC version
#$HGMD_version =  "HGMD 2020.3"; # QCIT/Ingenuity provided HGMD version
$ONCOCNV_version =  "ONCOCNV v6.9"; #ONCO CNV - Somatic SNV, Indel & CNV
#Paramaters
$soft_param_germline = "Germline low stringency"; # SOFTWARE PARAMETERS - Germline SNV & Indel
$soft_param_somatic_cf = "Somatic Custom Stringency"; # SOFTWARE PARAMETERS - Somatic SNV & Indel
$soft_param_somatic_tissue = "Somatic low stringency"; # SOFTWARE PARAMETERS - Somatic SNV, Indel, CNV
#pipelines
if ($foldername2[5] == 51 || $foldername2[5] == 53) # for 51 server Ion PROTON
{
$TMAP_version = "TMAP v5.14"; # ALIGNER version
$TVC_version = "TVC v5.14"; # Torrent VARIANT CALLER version
$pipeline_germline = "DCGL NGS Bioinformatics Pipeline vP2.12"; # NGS Pipeline version Germline SNV & Indel
$pipeline_somatic = "DCGL NGS Bioinformatics Pipeline vP3.16"; # NGS Pipeline version Somatic SNV & Indel
$pipeline_somatic_with_CNA = "DCGL NGS Bioinformatics Pipeline vP7.11"; # NGS Pipeline version - Somatic SNV, Indel & CNV
}
else # Ion CHEF
{
$TMAP_version = "TMAP v5.16"; # ALIGNER version
$TVC_version = "TVC v5.16"; # Torrent VARIANT CALLER version
$pipeline_germline = "DCGL NGS Bioinformatics Pipeline vS2.13"; # NGS Pipeline version Germline SNV & Indel
$pipeline_somatic = "DCGL NGS Bioinformatics Pipeline vS3.17"; # NGS Pipeline version Somatic SNV & Indel
$pipeline_somatic_with_CNA = "DCGL NGS Bioinformatics Pipeline vS7.12"; # NGS Pipeline version - Somatic SNV, Indel & CNV
}
#CNA_baselines
$CNA_baseline_cf = "CCP409_CNA_pool4_5_cfDNA_NegCtr"; # CCP-cf[DT]NA CNA Baseline
$CNA_baseline_cf_OCAv3 = "OCAv3_161_genes_CNA"; # OCAv3-cf[DT]NA CNA Baseline
$CNA_baseline_tumor_paired = "CCP Tumor-Normal pair"; # CCP-Tissue paired CNA Baseline
$CNA_baseline_tumor_unpaired = "CCP409_CNA_16_gDNA_Baseline";# CCP-Tissue unpaired CNA Baseline

###################  Software/Pipeline Versions END ##################################

print "Sample sequenced in? (IND/UK)\t\t:";
$site = <STDIN>;
chomp $site;
if ($site ne "IND" && $site ne "UK")
{print "We don't sequence samples in $site, Please put a valid site code\n";
exit;
}
print "\nWhat is the Cancer Type? select checklist CODE for Cancer Type of this sample...\n0 : No Checklist\n1 : Non-Small Cell Lung (NSCLC)\n2 : Breast\n3 : Ampullary Adenocarcinoma/ Pancreatic Adenocarcinoma\n4 : Central Nervous System (CNS)\n5 : Colon (Appendiceal Adenocarcinoma)/ Rectal (CRC)\n6 : Gastrointestinal Stromal Tumors (GIST)\n7 : Prostate/ Ovarian/ Fallopian Tube/ Primary Peritoneal\n8 : Thyroid Carcinoma\n9 : Salivary gland tumors\n10 : Bone\n11 : Kidney\n12 : Uterine Sarcoma\n13 : Hepatobiliary\n14 : Melanoma-Cutaneous\n15 : Malignant Pleural Mesothelioma/ Malignant Peritoneal Mesothelioma\n16 : Endometrial Carcinoma\n17 : Head and Neck/ Esophageal and Esophagogastric Junction/ Gastric\n18 : Bladder  (urothelial)\n19 : Melanoma-Uveal\n20 : Small Bowel Adenocarcinoma\n21 : Others (Anal Carcinoma/ Cervical/ Neuroendocrine and Adrenal Tumors/ Occult Primary (unknown primary)/ Small Cell Lung/ Soft Tissue Sarcoma/ Thymomas and Thymic Carcinomas/ Vulvar Cancer)\nCode : ";
$cancer_type = <STDIN>;
chomp $cancer_type;


unless(open(I,$fname)){
print "\n\nCan't open file $fname";
}

@data=<I>;

close(I);

$TSheader = $data[0];
chomp $TSheader;

close(P);

unless(open(GG,$Genomes1000)){
print "\n\nCan't open file $Genomes1000\n\n";
}

@G1000=<GG>;

close(GG);

unless(open(GL,$germlinedb)){
print "\n\nCan't open file $germlinedb\n\n";
}

@germline=<GL>;

close(GL);

unless(open(IP,$ingenuity_pre_processing)){
print "\n\nCan't open file $ingenuity_pre_processing\n\n";
}

@IngenuityP=<IP>;

close(IP);

unless(open(O,">$foldername-BiVA_TS.txt")){
print "\n\nCan't write file $foldername-BiVA_TS.txt\n\n";
}

unless(open(R,">$foldername-BiVA_rearranged.txt")){
print "\n\nCan't write file $foldername-BiVA_rearranged.txt\n\n";
}

unless(open(CLINVAR,$clinvar_db)){
print "\n\nCan't open file $clinvar_db\n\n";
}

@ClinVar_data=<CLINVAR>;

close(CLINVAR);

#Usage of software
sub usage {
        print <<EOF;

###################################################################################################################
###################################################################################################################
   														 
	Annotation	: Variant Annotation Script								
	Version		: $version									
														
	This script is developed by Vipul Todarwal for annotation of somatic samples in DCGL, maintained by Harshal Darokar.	 
														 
	NOTE: Kinly install required perl modules used at top of the script and update databases section with 
          local system path.
														 
###################################################################################################################
###################################################################################################################


Usage: perl PATH/TO/SCRIPT.pl input_alleles.xls


EOF
 
}


#Current date

$date = strftime "%d-%m-%Y", localtime;
$time = strftime "%I:%M %p", localtime;



# Remove if log file already exist

if (-f "$foldername-log.txt") {
    `rm $foldername-log.txt`;
}

unless(open(IN,"$foldername-BiVA.tsv")){
print "\n\nCan't open file $foldername-BiVA.tsv\n\n";
}

@IngenuityORI=<IN>;

close(IN);

$INheader=shift@IngenuityORI;

print O $TSheader."\t".$INheader;

open (STDOUT, "| tee -ai $foldername-log.txt");

print <<EOF;

########################################################################################################################################################
											
   Annotation	: Variant Annotation Script
   Version	: $version
   Location	: $Bin

########################################################################################################################################################

Analyst: $Analyst			Date : $date			Time: $time
EOF


# Get ethnicity of the patient from user
print "\n\nList of available ethnicities\t:\n\t\t\t\t\tEAS\n\t\t\t\t\tSAS\n\t\t\t\t\tAFR\n\t\t\t\t\tEUR\n\t\t\t\t\tAMR\n";
print "\nSelect the ethnicity from above\t:\t";
$ethnicity = <STDIN>;
chomp $ethnicity;

print "\nYou selected ethnicity\t\t:\t$ethnicity\n";

if (lc $ethnicity ne lc 'EAS' && lc $ethnicity ne lc 'SAS' && lc $ethnicity ne lc 'AFR' && lc $ethnicity ne lc 'EUR' && lc $ethnicity ne lc 'AMR')
{
    print "\n\nEthnicity is not correct.\n\n";
    exit();
}

print "\n\nCurrent working directory\t:\t$cwd\n";

print "\n\t\t\t\t\tSample ID\t:\t$foldername2[0]";
print "\n\t\t\t\t\tPanel\t\t:\t$foldername2[1]";
print "\n\t\t\t\t\tSample Type\t:\t$foldername2[2]";
print "\n\t\t\t\t\tBarcode\t\t:\t$foldername2[3]";
print "\n\t\t\t\t\tRun\t\t:\t$foldername2[4]";
print "\n\t\t\t\t\tServer\t\t:\t$foldername2[5]";

@ls=`ls -1 `;

#Analysis Type choice
if ($foldername2[1] =~ m/CCP/ && $foldername2[2] =~ m/_[DT]NA/)
{
print "\nAnalysis Type? [Type 1 for Paired; 2 for Unpaired]\t\t:";
$paired_analysis_choice = <STDIN>;
	if ($paired_analysis_choice == 1)
	{
		print "\nYou have selected Paired analysis\n";
	
	}
	elsif ($paired_analysis_choice == 2)
	{
		print "\nYou have selected Unpaired analysis\n";
	}
	else
	{
		print "\nWrong Analysis choice - try again !!!\n";
		exit;
	}
}
# Check file name of alleles.xls file

if ($fname ne "$foldername-alleles.xls")
{
	print "\n\n\nInput excel file is not correct\n\n";
	exit;
}


if (! -e "$foldername-TSVC_variants.vcf.gz")
{
	if (! -e "$foldername-TSVC_variants.vcf")
	{
		print "\n\n\n$foldername-TSVC_variants.vcf.gz or $foldername-TSVC_variants.vcf file is not exist or incorrectly spelled\n\n";
		exit;
	}
}

# Check Sample ID, Barcode and Run in alleles.xls file

@excel_line=split('\t',$data[1]);

$excel_line[48] =~ /(DCG_\d+)/;
$excel_line[48] =~ /(DGL_\d+)/;

$alleles_xls_run = $1;

print "\n\n\nInput excel file\t\t:\t$fname\n";

print "\n\t\t\t\t\tSample ID\t:\t$excel_line[46]";
print "\n\t\t\t\t\tBarcode\t\t:\t$excel_line[47]";
print "\n\t\t\t\t\tRun\t\t:\t$alleles_xls_run\n";
 

if ($foldername2[0] =~ m/$excel_line[46]/ && $foldername2[3] eq $excel_line[47] && $foldername2[4] eq $alleles_xls_run)
{
	print "\n\n\t\t\t\t\tSample ID, Barcode and Run matched in input excel file.\n";
}
else
{
	print "\n\n\t\t\t\t\tSample ID, Barcode and Run N0T MATCHED in input excel file. Either folder name or alleles.xls file is incorrect.\n\n";
	exit;
}



#########################################################################  Server Data Retrival Start  #######################################################################
if ($site eq "IND")
{
print "\n\nServer data retrival\t\t:\t";


@run_names=`sshpass -p '$ionpass' ssh $ionusr\@172.16.3.52 "ls /torrentsuite/172.16.3.$foldername2[5] | grep "$foldername2[4]" | grep -v "_tn_"" `;

if (scalar@run_names > 1){
print scalar@run_names," runs found\n\n";

for ($r=0; $r<scalar@run_names; $r++){
print $r+1," : $run_names[$r]";
}
print "\nEnter 1 run name from above\t\t:\t";
$run_choice = <STDIN>;
chomp $run_choice;
$run_name=$run_choice;

print "\nYou entered\t\t\t:\t$run_name\n\nServer data retrival\t\t:\t";
}
else{
$run_name=$run_names[0];
}

chomp $run_name;

`sshpass -p '$ionpass' ssh $ionusr\@172.16.3.52 sshpass -p '$pass' rsync -r --exclude={*bam*,*auxiliary*} /torrentsuite/172.16.3.$foldername2[5]/$run_name/basecaller_results/datasets_basecaller.json /torrentsuite/172.16.3.$foldername2[5]/$run_name/$foldername2[3]_rawlib.ionstats_alignment.json /torrentsuite/172.16.3.$foldername2[5]/$run_name/plugin_out/coverageAnalysis_out*/$foldername2[3] /torrentsuite/172.16.3.$foldername2[5]/$run_name/plugin_out/coverageAnalysis_out*/*bc_summary.xls $user\@$ip:$cwd `;

`sshpass -p '$ionpass' ssh $ionusr\@172.16.3.52 test -f "/torrentsuite/172.16.3.$foldername2[5]/$run_name/plugin_out/sampleID_out*/$foldername2[3]/read_stats.txt && sshpass -p '$pass' rsync -r /torrentsuite/172.16.3.$foldername2[5]/$run_name/plugin_out/sampleID_out*/$foldername2[3]/read_stats.txt" $user\@$ip:$cwd `;

# Remove if coverageAnalysisReport folder already exist

if (-d "$foldername-coverageAnalysisReport") {
    `rm -r $foldername-coverageAnalysisReport`;
}

`mv $foldername2[3] $foldername-coverageAnalysisReport `;
`mv *bc_summary.xls $foldername-coverageAnalysisReport `;

`test -f "read_stats.txt" && mv read_stats.txt $foldername-coverageAnalysisReport/$foldername-read_stats.txt`;
`mv datasets_basecaller.json $foldername-coverageAnalysisReport/$foldername-datasets_basecaller.json`;
`mv $foldername2[3]_rawlib.ionstats_alignment.json $foldername-coverageAnalysisReport/$foldername-rawlib.ionstats_alignment.json`;

} #switch end
# Server raw data
$id=`grep -E "$foldername2[3]\\".*{" $foldername-coverageAnalysisReport/$foldername-datasets_basecaller.json | sed 's/\\s//g' | sed 's/\\..*//g' | sed 's/"//g'`;
chomp$id;

my $json;
{
  local $/; #Enable 'slurp' mode
  open my $fh, "<", "$foldername-coverageAnalysisReport/$foldername-datasets_basecaller.json";
  $json = <$fh>;
  close $fh;
}

my$data = decode_json($json);

$total_bases = $data->{'read_groups'}->{"$id.$foldername2[3]"}->{'total_bases'};
chomp$total_bases;
$read_count = $data->{'read_groups'}->{"$id.$foldername2[3]"}->{'read_count'};
chomp$read_count;
$Q20_bases = $data->{'read_groups'}->{"$id.$foldername2[3]"}->{'Q20_bases'};
chomp$Q20_bases;


# mean read length
my $json;
{
  local $/; #Enable 'slurp' mode
  open my $fh, "<", "$foldername-coverageAnalysisReport/$foldername-rawlib.ionstats_alignment.json";
  $json = <$fh>;
  close $fh;
}

my$data = decode_json($json);
$mean_read_len = $data->{'full'}->{'mean_read_length'};

#SampleID (Unique Identification)

$uniqueID=`grep "Sample ID:" $foldername-coverageAnalysisReport/$foldername-read_stats.txt`;

$uniqueID =~ s/Sample ID:\s+//g;
chomp$uniqueID;

$bc_summary=`grep '$foldername2[3]' $foldername-coverageAnalysisReport/*bc_summary.xls`;

@coverage_stat=split('\t',$bc_summary);

$mean_depth=sprintf "%.0f",$coverage_stat[4];


#Amplicon coverage
$wc=undef;
$total_amplicons=undef;
$wc=`wc $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
$total_amplicons=$wc-1;

#Amplicons with at least 10 reads
$reads_10=`awk '\$10 >= 10 { count++ } END { print count-1 }' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
$per_10=($reads_10/$total_amplicons)*100;
$per_10_2dec=sprintf "%.2f%%", $per_10;
@uncovered_10=`awk '\$10 < 10' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;

#Amplicons with at least 20 reads
$reads_20=`awk '\$10 >= 20 { count++ } END { print count-1 }' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
$per_20=($reads_20/$total_amplicons)*100;
$per_20_2dec=sprintf "%.2f%%", $per_20;

@uncovered_20=`awk '\$10 < 20' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;

#Amplicons with at least 30 reads
$reads_30=`awk '\$10 >= 30 { count++ } END { print count-1 }' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
$per_30=($reads_30/$total_amplicons)*100;
$per_30_2dec=sprintf "%.2f%%", $per_30;


#Amplicons with at least 100 reads
$reads_100=`awk '\$10 >= 100 { count++ } END { print count-1 }' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
$per_100=($reads_100/$total_amplicons)*100;
$per_100_2dec=sprintf "%.2f%%", $per_100;

#Amplicons with at least 500 reads
$reads_500=`awk '\$10 >= 500 { count++ } END { print count-1 }' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
$per_500=($reads_500/$total_amplicons)*100;
$per_500_2dec=sprintf "%.2f%%", $per_500;

#Amplicons with at least 600 reads
$reads_600=`awk '\$10 >= 600 { count++ } END { print count-1 }' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
$per_600=($reads_600/$total_amplicons)*100;
$per_600_2dec=sprintf "%.2f%%", $per_600;

@uncovered_600=`awk '\$10 < 600' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;


#Target regions
$Target_regions=`grep "Target Regions: " $foldername-coverageAnalysisReport/$foldername2[3]*.stats.cov.txt`;
$Target_regions=~s/Target Regions: //g;
$Target_regions=~ s/\n//g;

# On Target (%)
$On_Target=`grep "Percent reads on target:        " $foldername-coverageAnalysisReport/$foldername2[3]*.stats.cov.txt`;
$On_Target=~s/Percent reads on target:        //g;
$On_Target=~ s/\n//g;

# Uniformity (%)
$Uniformity=`grep "Uniformity of base coverage:       " $foldername-coverageAnalysisReport/$foldername2[3]*.stats.cov.txt`;
$Uniformity=~s/Uniformity of base coverage:       //g;
$Uniformity=~ s/\n//g;


print "Completed\n\n";

print "\nUnique Identification\t\t:\t$uniqueID\n\n";

print "\nCoverage Analysis\t\t:\tTarget region file used: $Target_regions\n\n";

if ($Target_regions ne $target_files{$foldername2[1]}){
print "\nTARGET REGION FILE IS WRONG. It Should be $target_files{$foldername2[1]}. Do you want to proceed? (y/n) : ";
$choice = <STDIN>;
chomp $choice;

if ($choice =~ /n/i){
exit;
}}

# TVC Parameters

@parametersName =`zgrep "##parametersName" $foldername-TSVC_variants.vcf*`;
@parametersDetails =`zgrep "##parametersDetails" $foldername-TSVC_variants.vcf*`;

print "\nTorrent Variant Caller (TVC)\t:\t$parametersName[0]\t\t\t\t\t$parametersDetails[0]";

if ($foldername2[2] =~ m/cf[DT]NA/ && $parametersName[0] !~ m/cfDNA/ && $parametersDetails[0] !~ m/cfDNA/) 
{
    print "\nTVC PARAMETER FILE IS WRONG. It should be cfDNA or cfTNA specific.\n\n";
    exit;
}

if ($foldername2[2] =~ m/gDNA/ && $foldername2[1] !~ m/AML/ && $parametersName[0] !~ m/germline/i && $parametersName[0] !~ m/Germ Line/i && $parametersDetails[0] !~ m/germline/i && $parametersDetails[0] !~ m/Germ Line/i)
{
    print "\nTVC PARAMETER FILE IS WRONG. It should be germline specific.\n\n";
    exit;
}

##########################################################################  Server Data Retrival End  ########################################################################



#############################################################################  Annotation Start  #############################################################################

print "\n\nAnnotation\t\t\t:\t";

$fname_out=$foldername."-My_Work.xls";
$row_all=0, $row_all2=0, $row_filtered=0, $row_filtered2=0,$row_filtered3=0, $row_filtered4=0, $SNVs=0, $Indels=0, $target="";


# Rename *My_Work.xls if already exist

if (-e "$foldername-My_Work.xls") {
    `mv $foldername-My_Work.xls $foldername-My_Work.xls.old`;
}

# Create a new Excel file

my $workbook = Spreadsheet::WriteExcel->new($fname_out);

# Set Format

$bold = $workbook->add_format(bold => 1);
$bold->set_font('Arial');
$bold->set_size(11);

$redbold = $workbook->add_format();
$redbold->set_bold();
$redbold->set_color('red');
$redbold->set_font('Arial');
$redbold->set_size(11);

$greenbold = $workbook->add_format();
$greenbold->set_bold();
$greenbold->set_color('green');
$greenbold->set_font('Arial');
$greenbold->set_size(11);

$yellowbold = $workbook->add_format(bg_color => 13, font=> 'Arial', size=>11);

$left = $workbook->add_format();
$left->set_align('left');
$left->set_font('Arial');
$left->set_size(11);

$center = $workbook->add_format();
$center->set_align('center');
$center->set_font('Arial');
$center->set_size(11);
$center->set_bold();

# Add worksheets
my $worksheet1 = $workbook->add_worksheet('All');
my $worksheet2 = $workbook->add_worksheet('Filtered');
my $worksheet3 = $workbook->add_worksheet('BiVA');
my $worksheet4 = $workbook->add_worksheet('gnomAD or 1000Genomes <=5%');

if ($foldername2[2] eq 'gDNA')
{
	 $worksheet5 = $workbook->add_worksheet('dbSNP_ID_Only');
}
else
{
	 $worksheet5 = $workbook->add_worksheet('COSMIC_ID_Only');
}

my $worksheet6 = $workbook->add_worksheet('SNV_Info');
my $worksheet7 = $workbook->add_worksheet('Uncovered');
my $worksheet8 = $workbook->add_worksheet('Limitations');
my $worksheet9 = $workbook->add_worksheet('CNA_Filtered');
my $worksheet10 = $workbook->add_worksheet('CNA_Report');
my $worksheet11 = $workbook->add_worksheet('Worksheet');


#------------------------------------------------------------------------ Ingenuity Pre-Processing Start ------------------------------------------------------------------------
foreach $IngenuityPline (@IngenuityP)
{
    chomp$IngenuityPline;
    @IngenuityPline_elements = split('\t',$IngenuityPline);
    $Idbcordi1 = $IngenuityPline_elements[0]."\t".$IngenuityPline_elements[1];
    $Idbcordi = $IngenuityPline_elements[4]."\t".$IngenuityPline_elements[5];
    $Idbvar = $IngenuityPline_elements[6]."\t".$IngenuityPline_elements[7];

    $target=first_index { $_ =~ m/$Idbcordi1\t/ } @IngenuityORI;
    $ILP = $IngenuityORI[$target];

    chomp$ILP;
    @IlineP=split('\t',$ILP);

    $Icordi = $IlineP[0]."\t".$IlineP[1];
    $Ivar = $IlineP[4]."\t".$IlineP[5];

    if ($IngenuityPline_elements[0] eq $IlineP[0] && $IngenuityPline_elements[1] == $IlineP[1] && $IngenuityPline_elements[2] eq $IlineP[4] && $IngenuityPline_elements[3] eq $IlineP[5])
    {
        $addline = $ILP;
        $addline =~ s/$Icordi/$Idbcordi/g;
        $addline =~ s/$Ivar/$Idbvar/g;
        push @IngenuityORI, $addline;
    }
}


#------------------------------------------------------------------------- Ingenuity Pre-Processing End -------------------------------------------------------------------------

foreach $line (@data)
{
chomp $line;

@element=split('\t',$line);

# 1st Worksheet : All

	for ($i=0;$i<scalar@element;$i++) 
		{
			$worksheet1->write($row_all, $i, $element[$i], $left);
			$worksheet1->freeze_panes(1, 4);
		}
	$row_all++;


# 2nd Worksheet : Filtered

	if ($line =~ m/Chrom|Heterozygous|Homozygous/)
	{
        $element[2]=~s/-//g;
        $element[3]=~s/-//g;
		$join=$element[0]."_".$element[1]."_".$element[2]."_".$element[3];

		$join_vcf=$element[0]."_".$element[15]."_".$element[16]."_".$element[17];
		$join_vcf=~s/-//g;

		$combined=$combined.$join."\n".$join_vcf."\n";
		$worksheet2->write($row_filtered, 1, $join);

		$element[4] =~ s/Heterozygous/HET/g;
		$element[4] =~ s/Homozygous/HOM/g;




#--------------------------------------------------------------------------- Combined File Start ----------------------------------------------------------------------------
        if ($element[4] !~ m/Allele Call/)
        {
            print O "\n".$line."\t";

            foreach $IL (@IngenuityORI)
            {
                chomp$IL;
                @Iline=split('\t',$IL);
                $Iline[0]="chr". $Iline[0];

                if ($element[0] eq $Iline[0] && $element[1] == $Iline[1] && $element[2] eq $Iline[4] && $element[3] eq $Iline[5])
                {
                    print O $IL;
                    last;
                }

                elsif ($element[0] eq $Iline[0] && $element[1] == $Iline[2] && $element[2] eq $Iline[4] && $element[3] eq $Iline[5])
                {
                    print O $IL;
                    last;
                }
            }
        }

#--------------------------------------------------------------------------- Combined File End ----------------------------------------------------------------------------


		for ($j=2,$i=0;$i<=scalar@element;$j++,$i++) 
			{
				
				$worksheet2->write($row_filtered, $j, $element[$i], $left);
				$worksheet2->freeze_panes(1, 2);
			}

		$row_filtered++;
	}

}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Ingenuity txt file

close (O);

unless(open(INR,"$foldername-BiVA_TS.txt")){
print "\n\nCan't open file $foldername-BiVA_TS.txt\n\n";
}

@IngenuityTS=<INR>;

close(INR);

@rawheaderelements3=split('\t',$IngenuityTS[0]);
$rawheadersize3=scalar@rawheaderelements3;

$INRCHROM=first_index { $_ eq 'Chrom' } @rawheaderelements3;
$INROPOS=first_index { $_ eq 'Position' } @rawheaderelements3;
$INROREF=first_index { $_ eq 'Ref' } @rawheaderelements3;
$INROALT=first_index { $_ eq 'Variant' } @rawheaderelements3;
$INRGT=first_index { $_ eq 'Allele Call' } @rawheaderelements3;
$INRAF=first_index { $_ eq 'Frequency' } @rawheaderelements3;
$INRQUAL=first_index { $_ eq 'Quality' } @rawheaderelements3;
$INROCov=first_index { $_ eq 'Original Coverage' } @rawheaderelements3;
$INRCov=first_index { $_ eq 'Coverage' } @rawheaderelements3;
$INRACov=first_index { $_ eq 'Allele Cov' } @rawheaderelements3;
$INRACovPos=first_index { $_ eq 'Allele Cov+' } @rawheaderelements3;
$INRACovNeg=first_index { $_ eq 'Allele Cov-' } @rawheaderelements3;
$INRGENE=first_index { $_ eq 'Gene ID' } @rawheaderelements3;
$INRTRANSCRIPT=first_index { $_ eq 'Transcript ID' } @rawheaderelements3;
$INRcDNA=first_index { $_ eq 'Transcript Variant' } @rawheaderelements3;
$INRPROTEIN=first_index { $_ eq 'Protein Variant' } @rawheaderelements3;
$Inferred_Activity=first_index { $_ =~ m/Inferred Activity/ } @rawheaderelements3;
$INRClassification=first_index { $_ eq 'Classification' } @rawheaderelements3;
$INRdbSNPID=first_index { $_ eq 'dbSNP ID' } @rawheaderelements3;
#$INRGenomes1000=first_index { $_ eq '1000 Genomes Frequency' } @rawheaderelements3;
#$INRExAC_EAS=first_index { $_ eq 'ExAC East Asian Frequency' } @rawheaderelements3;
#$INRExAC_SAS=first_index { $_ eq 'ExAC South Asian Frequency' } @rawheaderelements3;
#$INRExAC_AFR=first_index { $_ eq 'ExAC African Frequency' } @rawheaderelements3;
#$INRExAC_EUR=first_index { $_ eq 'ExAC European Frequency' } @rawheaderelements3;
#$INRExAC_AMR=first_index { $_ eq 'ExAC Latino Frequency' } @rawheaderelements3;
#$INRgnomAD_PAN=first_index { $_ eq 'gnomAD Frequency' } @rawheaderelements3;
#$INRHGMD=first_index { $_ eq 'HGMD' } @rawheaderelements3;
$INRCOSMIC=first_index { $_ eq 'COSMIC ID' } @rawheaderelements3;
$INRCOSMIC1=$COSMIC+2;


print R "Category"."\t"."Chrom"."\t"."Position"."\t"."Ref"."\t"."Variant"."\t"."Zygosity"."\t"."Frequency"."\t"."Quality"."\t"."Original Coverage"."\t"."Downsample Coverage"."\t"."Downsample Allele Cov"."\t"."Downsample Allele Cov+"."\t"."Downsample Allele Cov-"."\t"."Gene Symbol"."\t"."Transcript ID"."\t"."Exon No"."\t"."cDNA Change"."\t"."Protein Change"."\t"."COSMIC ID"."\t"."Variant Category"."\t"."Inferred Activity"."\t"."Variant Classification"."\t"."dbSNP ID"."\t"."1000 genomes Frequency"."\t"."gnomAD Frequency"."\t"."Remarks"."\n";

splice @IngenuityTS, 0,2;

foreach $INRline (@IngenuityTS)
{
    @INRlineelements = split('\t',$INRline);


    if ($ethnicity =~ m/EAS/i)
    {
        $INRlineelements[$INROREF] =~ s/-//g;
        $INRlineelements[$INROALT] =~ s/-//g;

        print R $INRlineelements[$INRCHROM]."_".$INRlineelements[$INROPOS]."_".$INRlineelements[$INROREF]."_".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRCHROM]."\t".$INRlineelements[$INROPOS]."\t".$INRlineelements[$INROREF]."\t".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRGT]."\t".$INRlineelements[$INRAF]."\t".$INRlineelements[$INRQUAL]."\t".$INRlineelements[$INROCov]."\t".$INRlineelements[$INRCov]."\t".$INRlineelements[$INRACov]."\t".$INRlineelements[$INRACovPos]."\t".$INRlineelements[$INRACovNeg]."\t".$INRlineelements[$INRGENE]."\t".$INRlineelements[$INRTRANSCRIPT]."\t\t".$INRlineelements[$INRcDNA]."\t".$INRlineelements[$INRPROTEIN]."\t".$INRlineelements[$INRCOSMIC]."\t"."\t".$INRlineelements[$Inferred_Activity]."\t".$INRlineelements[$INRClassification]."\t".$INRlineelements[$INRdbSNPID]."\t"."---"."\t"."---"."\t"."---"."\n";
    }

    if ($ethnicity =~ m/SAS/i)
    {
        $INRlineelements[$INROREF] =~ s/-//g;
        $INRlineelements[$INROALT] =~ s/-//g;

        print R $INRlineelements[$INRCHROM]."_".$INRlineelements[$INROPOS]."_".$INRlineelements[$INROREF]."_".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRCHROM]."\t".$INRlineelements[$INROPOS]."\t".$INRlineelements[$INROREF]."\t".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRGT]."\t".$INRlineelements[$INRAF]."\t".$INRlineelements[$INRQUAL]."\t".$INRlineelements[$INROCov]."\t".$INRlineelements[$INRCov]."\t".$INRlineelements[$INRACov]."\t".$INRlineelements[$INRACovPos]."\t".$INRlineelements[$INRACovNeg]."\t".$INRlineelements[$INRGENE]."\t".$INRlineelements[$INRTRANSCRIPT]."\t\t".$INRlineelements[$INRcDNA]."\t".$INRlineelements[$INRPROTEIN]."\t".$INRlineelements[$INRCOSMIC]."\t"."\t".$INRlineelements[$Inferred_Activity]."\t".$INRlineelements[$INRClassification]."\t".$INRlineelements[$INRdbSNPID]."\t"."---"."\t"."---"."\t"."---"."\n";
    }

    if ($ethnicity =~ m/AFR/i)
    {
        $INRlineelements[$INROREF] =~ s/-//g;
        $INRlineelements[$INROALT] =~ s/-//g;

        print R $INRlineelements[$INRCHROM]."_".$INRlineelements[$INROPOS]."_".$INRlineelements[$INROREF]."_".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRCHROM]."\t".$INRlineelements[$INROPOS]."\t".$INRlineelements[$INROREF]."\t".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRGT]."\t".$INRlineelements[$INRAF]."\t".$INRlineelements[$INRQUAL]."\t".$INRlineelements[$INROCov]."\t".$INRlineelements[$INRCov]."\t".$INRlineelements[$INRACov]."\t".$INRlineelements[$INRACovPos]."\t".$INRlineelements[$INRACovNeg]."\t".$INRlineelements[$INRGENE]."\t".$INRlineelements[$INRTRANSCRIPT]."\t\t".$INRlineelements[$INRcDNA]."\t".$INRlineelements[$INRPROTEIN]."\t".$INRlineelements[$INRCOSMIC]."\t"."\t".$INRlineelements[$Inferred_Activity]."\t".$INRlineelements[$INRClassification]."\t".$INRlineelements[$INRdbSNPID]."\t"."---"."\t"."---"."\t"."---"."\n";
        }

    if ($ethnicity =~ m/EUR/i)
    {
        $INRlineelements[$INROREF] =~ s/-//g;
        $INRlineelements[$INROALT] =~ s/-//g;

        print R $INRlineelements[$INRCHROM]."_".$INRlineelements[$INROPOS]."_".$INRlineelements[$INROREF]."_".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRCHROM]."\t".$INRlineelements[$INROPOS]."\t".$INRlineelements[$INROREF]."\t".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRGT]."\t".$INRlineelements[$INRAF]."\t".$INRlineelements[$INRQUAL]."\t".$INRlineelements[$INROCov]."\t".$INRlineelements[$INRCov]."\t".$INRlineelements[$INRACov]."\t".$INRlineelements[$INRACovPos]."\t".$INRlineelements[$INRACovNeg]."\t".$INRlineelements[$INRGENE]."\t".$INRlineelements[$INRTRANSCRIPT]."\t\t".$INRlineelements[$INRcDNA]."\t".$INRlineelements[$INRPROTEIN]."\t".$INRlineelements[$INRCOSMIC]."\t"."\t".$INRlineelements[$Inferred_Activity]."\t".$INRlineelements[$INRClassification]."\t".$INRlineelements[$INRdbSNPID]."\t"."---"."\t"."---"."\t"."---"."\n";
    }

    if ($ethnicity =~ m/AMR/i)
    {
        $INRlineelements[$INROREF] =~ s/-//g;
        $INRlineelements[$INROALT] =~ s/-//g;

        print R $INRlineelements[$INRCHROM]."_".$INRlineelements[$INROPOS]."_".$INRlineelements[$INROREF]."_".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRCHROM]."\t".$INRlineelements[$INROPOS]."\t".$INRlineelements[$INROREF]."\t".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRGT]."\t".$INRlineelements[$INRAF]."\t".$INRlineelements[$INRQUAL]."\t".$INRlineelements[$INROCov]."\t".$INRlineelements[$INRCov]."\t".$INRlineelements[$INRACov]."\t".$INRlineelements[$INRACovPos]."\t".$INRlineelements[$INRACovNeg]."\t".$INRlineelements[$INRGENE]."\t".$INRlineelements[$INRTRANSCRIPT]."\t\t".$INRlineelements[$INRcDNA]."\t".$INRlineelements[$INRPROTEIN]."\t".$INRlineelements[$INRCOSMIC]."\t"."\t".$INRlineelements[$Inferred_Activity]."\t".$INRlineelements[$INRClassification]."\t".$INRlineelements[$INRdbSNPID]."\t"."---"."\t"."---"."\t"."---"."\n";
    }
    if ($ethnicity =~ m/PAN/i)
    {
        $INRlineelements[$INROREF] =~ s/-//g;
        $INRlineelements[$INROALT] =~ s/-//g;

        print R $INRlineelements[$INRCHROM]."_".$INRlineelements[$INROPOS]."_".$INRlineelements[$INROREF]."_".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRCHROM]."\t".$INRlineelements[$INROPOS]."\t".$INRlineelements[$INROREF]."\t".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRGT]."\t".$INRlineelements[$INRAF]."\t".$INRlineelements[$INRQUAL]."\t".$INRlineelements[$INROCov]."\t".$INRlineelements[$INRCov]."\t".$INRlineelements[$INRACov]."\t".$INRlineelements[$INRACovPos]."\t".$INRlineelements[$INRACovNeg]."\t".$INRlineelements[$INRGENE]."\t".$INRlineelements[$INRTRANSCRIPT]."\t\t".$INRlineelements[$INRcDNA]."\t".$INRlineelements[$INRPROTEIN]."\t".$INRlineelements[$INRCOSMIC]."\t"."\t".$INRlineelements[$Inferred_Activity]."\t".$INRlineelements[$INRClassification]."\t".$INRlineelements[$INRdbSNPID]."\t"."---"."\t"."---"."\t"."---"."\n";
    }
}

close (R);

   
unless(open(G,"$foldername-BiVA_rearranged.txt"))
{
	print "\n\nCan't open file $foldername-BiVA_rearranged.txt";
}

@Ingenuity=<G>;

close(G);

$element2_pos=0;

foreach $line2 (@Ingenuity)
{
    @element2=split('\t',$line2);

    chomp $element2[25];

    $diff = $element2[2]-$element2_pos;
    
    @element2_copy = split('\t',$line2);
    $element2_pos = $element2_copy[2];


#Formatting
		
    $element2[5] =~ s/Heterozygous/HET/g;
    $element2[5] =~ s/Homozygous/HOM/g;

    if ($element2[3] eq "")
    {
        $element2[3] = "-";
    }

    if ($element2[4] eq "")
    {
	    $element2[4] = "-";
    }
			
    if ($element2[17] ne "Protein Change") 
    {
        $singleLetterAA = $element2[17];
        $element2[19]="---";
    }

    if ($element2[17] =~ m/p\.*/)
    {

        $element2[17] =~ s/A/Ala/g; $element2[17] =~ s/R/Arg/g; $element2[17] =~ s/N/Asn/g; $element2[17] =~ s/D/Asp/g; $element2[17] =~ s/B/Asx/g; $element2[17] =~ s/C/Cys/g; $element2[17] =~ s/G/Gly/g; $element2[17] =~ s/E/Glu/g; $element2[17] =~ s/Q/Gln/g; $element2[17] =~ s/Z/Glx/g; $element2[17] =~ s/H/His/g; $element2[17] =~ s/I/Ile/g; $element2[17] =~ s/L/Leu/g; $element2[17] =~ s/K/Lys/g; $element2[17] =~ s/M/Met/g; $element2[17] =~ s/P/Pro/g; $element2[17] =~ s/F/Phe/g; $element2[17] =~ s/S/Ser/g; $element2[17] =~ s/T/Thr/g; $element2[17] =~ s/W/Trp/g; $element2[17] =~ s/Y/Tyr/g; $element2[17] =~ s/V/Val/g; $element2[17] =~ s/\*/Ter/g; $element2[17] =~ s/p\./p\.\(/g; $element2[17] =~ s/\;/\)\;/g; $element2[17]="; ".$element2[17].")";

    }

    $COSM_IDs = $element2[18];

    if ($element2[18] != "") 
    {
        $element2[18] = "COSM".$element2[18];
    }

    $element2[18] =~ s/; /; COSM/g; 

    $germ=first_index {$_ =~ m/$element2[0]\t/} @germline; #Germline Variants

# ---------------------------------------------------------------------- 1000 Genomes Start ----------------------------------------------------------------------
#print "\n\n1000 Genome Annotation\t\t\t:\t";

        $g1=first_index {$_ =~ m/$element2[0]\t/} @G1000;

        if ($g1>=0)
        {
            @G10002=split ('\t',$G1000[$g1]);
            chomp$G10002[11];

            if ($ethnicity =~ m/EAS/i)
            {
                $element2[23]=$G10002[7];
            }

            if ($ethnicity =~ m/SAS/i)
            {
                $element2[23]=$G10002[8];
            }

            if ($ethnicity =~ m/AFR/i)
            {
                $element2[23]=$G10002[9];
            }

            if ($ethnicity =~ m/EUR/i)
            {
                $element2[23]=$G10002[10];
            }

            if ($ethnicity =~ m/AMR/i)
            {
                $element2[23]=$G10002[11];
            }
			if ($ethnicity =~ m/PAN/i)
            {
                $element2[23]=$G10002[6];
            }
        }
# ---------------------------------------------------------------------- gnomAD DB Start -------------------------------------------------------------------------
#print "\n\nExAC Annotation\t\t\t:\t";
	$ExAC_DB=$db_path."DCGL_gnomAD.txt";
	unless(open(EX,$ExAC_DB))
		{
		print "\n\nCan't open file $ExAC_DB\n\n";
		}

@ExAC=<EX>;
close(EX);
$ex1=first_index {$_ =~ m/$element2[0]\t/} @ExAC;

        if ($ex1>=0)
        {
            @ExAC1=split ('\t',$ExAC[$ex1]);
            @ExAC2 = grep(~s/\s*$//g, @ExAC1);

            if ($ethnicity =~ m/AFR/i)
            {
                $element2[24]=$ExAC2[9];
            }

            if ($ethnicity =~ m/AMR/i)
            {
                $element2[24]=$ExAC2[11];
            }

            if ($ethnicity =~ m/EAS/i)
            {
                $element2[24]=$ExAC2[7];
            }

            if ($ethnicity =~ m/EUR/i)
            {
                $element2[24]=$ExAC2[10];
            }

            if ($ethnicity =~ m/SAS/i)
            {
                $element2[24]=$ExAC2[8];
            }
	    
			if ($ethnicity =~ m/PAN/i)
            {
                $element2[24]=$ExAC2[6];
            }	
        }


# ---------------------------------------------------------------------- gnomAD DB end ---------------------------------------------------------------------------
# ------------------------------------------------------------------------ PredictSNP Start ------------------------------------------------------------------------
#print "\n\nPredictSNP Annotation\t\t\t:\t";
    $predictSNP_vc=`LANG=C grep -wF '$element2[0]' $PredictSNPdb`;


    if ($predictSNP_vc ne "")
    {
        @predictSNP2=split ('\t',$predictSNP_vc);
        chomp$predictSNP2[5];

        if (($element2[23] >=0.1 ||  $element2[24] >=0.1 || $germ >=0 || $foldername2[2] eq "gDNA" ) && ($element2[6]>=10))
        {
            $predictSNP2[5] =~ s/Driver/Deleterious/g;
            $predictSNP2[5] =~ s/Passenger/Neutral/g;
        }

        $element2[19] = $predictSNP2[5];

    }
# ------------------------------------------------------------------------ PredictSNP End -------------------------------------------------------------------------


# ----------------------------------------------------------------------- 1000 Genomes End -----------------------------------------------------------------------

    if ($element2[20] eq "") 
    {
        $element2[20] = "---";
    }

    $element2[21] =~ s/Uncertain Significance/VUS/g;

    $dbSNPIDs = $element2[22];
			
    if ($element2[22] != "") 
    {
        $element2[22] = "rs".$element2[22];
    }

    if ($element2[22] eq "") 
    {
        $element2[22] = "---";
    }

    if ($element2[23] eq "") 
    {
        $element2[23] = "---";
    }

    if ($element2[24] eq "") 
    {
        $element2[24] = "---";
    }

    if ($element2[25] eq "") 
    {
        $element2[25] = "---";
    }


# 3rd Worksheet : Ingenuity

	for ($i=0;$i<scalar@element2;$i++) 
	{
		if ($i==17)
			{
				$worksheet3->write($row_all2, $i, $singleLetterAA.$element2[$i], $left);
			}
		else
			{
				$worksheet3->write($row_all2, $i, $element2[$i], $left);
				$worksheet3->freeze_panes(1, 1);
			}
	}
		$row_all2++;


	if ($COSM_IDs != "") 
	{
		$COSM_IDs =~ s/\s//g;
		@COSMIC_ID = split(';',$COSM_IDs);
		@COSMIC_ID = sort {$a <=> $b} @COSMIC_ID;
		$element2[18] = $COSMIC_ID[0];
		$element2[18] = "COSM".$element2[18];
	}

	if ($dbSNPIDs != "") 
	{
		$dbSNPIDs =~ s/\s//g;
		@dbSNP_ID = split(';',$dbSNPIDs);
		$element2[22] = "rs".$dbSNP_ID[0];
	}

# 4th Worksheet : ExAC <=5%

	if (($element2[23] <= 5 && $element2[24] <= 5) || ($element2[0] eq 'Category')) 
	{




		$element2[17]=$singleLetterAA.$element2[17];

#--------------------------------------------------------------------- VarSeq Annotation Start---------------------------------------------------------------------
#print "\n\nVar Annotation\t\t\t:\t";
		$varseq = `grep -F -w  '$element2[0]' $VarSeqdb`;
		chomp $varseq;

		@varseqelements = split('\t',$varseq);
	
		if ($varseqelements[1] ne "")
		{
			$element2[14] = $varseqelements[1];
		}
		
		if ($varseqelements[3] ne "")
		{
			$element2[16] = $varseqelements[3];
		}

		if ($varseqelements[3] =~ m/\+/ || $varseqelements[3] =~ m/\-/)
		{
			$element2[15] = "---";
			$element2[17] = "---";
		}
		else
		{
			if ($varseqelements[2] ne "")
			{
				$element2[15] = $varseqelements[2];
			}
			if ($varseqelements[4] ne "" && $varseqelements[4] ne "p=")
			{
				$element2[17] = $varseqelements[4];
			}
		}
#--------------------------------------------------------------------- VarSeq Annotation End ---------------------------------------------------------------------
			$action=`LANG=C grep -F '$element2[0]' $actionable`; 
			@action2=split('\t',$action);
			chomp $action2[0];

		
for ($j=0,$i=0;$i<=scalar@element2;$j++,$i++) 
        {	

				if($element2[0] eq $action2[0])
				{
					 $worksheet4->write($row_filtered2, $j, $element2[$i], $yellowbold);
				}
				else
				{					
		    			$worksheet4->write($row_filtered2, $j, $element2[$i], $left);
		  		}  
		$worksheet4->freeze_panes(1, 1);
	    }
$worksheet4->write(0, 26, "ClinVar_Class", $left);

        if ($element2[0] ne 'Category' && $element2[10] ne "0")
        {
            $strandPos = ($element2[11]/$element2[10])*100;
            $strandNeg = ($element2[12]/$element2[10])*100;
        }

        $black_variant=`LANG=C grep -wF '$element2[0]' $blacklistdb`; # Blacklisted Variants

        if ($element2[22] !~ m/dbSNP ID/)
        {
            # Passenger/Neutral variant Remarks
            if (($element2[19] =~ m/Passenger/ || $element2[19] =~ m/Neutral/) && ($element2[19] !~ "---") && ($element2[19] !~ ""))
            {
                $worksheet4->write($row_filtered2, 25, $element2[19], $left);
            }

            # Synonymous Variants Remarks
            $input=$element2[17];
            $input =~ s/p.//g;

            @processed=split (';', $input);
            $processed[0] =~ s/\d//g;
            @aa=split('',$processed[0]);

            if ($aa[0] eq $aa[1] && scalar@aa == 2)
            {
                $worksheet4->write($row_filtered2, 25, "2.Synonymous", $left);
            }

            # Intronic Variants Remarks
            if (($element2[17] eq "---") || ($element2[17] eq "" && $element2[16] =~ m/\+/) || ($element2[17] eq "" && $element2[16] =~ m/\-/))
            {
                $worksheet4->write($row_filtered2, 25, "3.Intronic", $left);
            }

            # Adjacent Location Variants Remarks
            if ($diff >= -5 && $diff <= 5)
            {
                $worksheet4->write($row_filtered2, 25, "1.Adjacent Location - check hotspot or novel and pathogenicity before filteration", $left);
            }

            # Probable Germline Remarks
            if (($element2[23] >= 0.1 || $element2[24] >= 0.1 || $germ >=0 || $element2[6]==100) && ($element2[22] !~ m/dbSNP ID/) && ($foldername2[2] !~ m/gDNA/))
            {
                $worksheet4->write($row_filtered2, 25, "4.Probable Germline", $left);
            }
            # Strand Bias Remarks
            if ($strandPos > 80 || $strandPos < 20)
            {
                $worksheet4->write($row_filtered2, 25, "7.Strand Bias", $redbold);
            }
            # Variant Coverage Remarks
            if (($foldername2[2] !~ m/gDNA/ && $element2[10] < 20) || ($foldername2[2] =~ m/gDNA/ && $element2[10] < 10))
            {
                $worksheet4->write($row_filtered2, 25, "6.Low Variant Coverage", $redbold);
            }

            # Variant Frequency (LOD) Remarks
            if (($foldername2[1] =~ m/CCP/ && $foldername2[2] =~ m/cfTNA/ && $element2[6] < 1) || ($foldername2[1] !~ m/CCP/ && $foldername2[2] =~ m/cfTNA/ && $element2[6] < 0.5) || ($foldername2[2] =~ m/FT_DNA/ && $element2[6] < 5) || ($foldername2[2] =~ m/FFPE_DNA/ && $element2[6] < 5))
            {
                $worksheet4->write($row_filtered2, 25, "5.Below LOD", $redbold);
            }



            # Blacklisted Remarks
            if ($black_variant =~ m/$foldername2[1]/ || $black_variant =~ m/All/)
            {
                @black_remarks=split('\t',$black_variant);
                chomp$black_remarks[4];
                $worksheet4->write($row_filtered2, 25, "8.Blacklisted - $black_remarks[4]", $redbold);
            }

            # COSMIC SNP Flag
            if ($foldername2[2] ne "gDNA")
            {
                $snp_flag=`LANG=C grep -wF '$element2[0]' $COSMIC_SNP_Flag`; 
                @snp_flag2=split('\t',$snp_flag);
                chomp$snp_flag2[1];
                if ($snp_flag2[0] eq $element2[0])
                {
                    $worksheet4->write($row_filtered2, 25, "9.$snp_flag2[1]", $redbold);
                }
            }
			#ClinVar Classification
			$clin_line=first_index {$_ =~ m/$element2[0]\t/} @ClinVar_data;
			if ($clin_line>=0)
			{
				@Clin_line_split=split ('\t',$ClinVar_data[$clin_line]);
				$clin_class = $Clin_line_split[6];
				chomp $clin_class ; 
				if ($clin_class eq $element2[20])
				{
				$worksheet4->write($row_filtered2, 26, $clin_class, $left);
				}
				else
				{
				$worksheet4->write($row_filtered2, 26, $clin_class, $redbold);
				}
			}
			# Strand Bias Remarks for gDNA
            if (($foldername2[2] =~ m/gDNA/) && ($strandPos > 80 || $strandPos < 20))
            {
                $worksheet4->write($row_filtered2, 25, "7.Strand Bias", $redbold);
            }
			
        }

		$row_filtered2++;


# 5th Worksheet : COSMIC_ID_Only or dbSNP_ID_Only



        if (($foldername2[2] ne "gDNA" && $element2[18] ne "") || ($foldername2[2] ne "gDNA" && $element2[18] eq "COSMIC ID") || ($foldername2[2] eq "gDNA" && $element2[22] ne "---") || ($foldername2[2] eq "gDNA" && $element2[22] eq "dbSNP ID") || ($element2[21] =~ m/Pathogenic/) || ($element2[21] =~ m/VUS/ && $element2[19] =~ m/Driver/) || ($element2[21] =~ m/VUS/ && $element2[19] =~ m/Deleterious/) || ($element2[0] eq $action2[0]) || (($element2[13] eq "EGFR") && ($element2[15] == 19)))
        {
            if ($element2[18] eq "")
            {
                $element2[18] = "---";
            }
	
	
		    for ($j=0,$i=0;$i<=scalar@element2;$j++,$i++) 
		    {
			if(($element2[0] eq $action2[0]) || (($element2[13] eq "EGFR") && ($element2[15] == 19)))
						{
						    $worksheet5->write($row_filtered3, $j, $element2[$i], $yellowbold);
						}
						else
						{
						    $worksheet5->write($row_filtered3, $j, $element2[$i], $left);
						}
			   
			    $worksheet5->freeze_panes(1, 1);
		    }
$worksheet5->write(0, 26, "ClinVar_Class", $left);
            if ($element2[22] !~ m/dbSNP ID/)
            {
                # Passenger/Neutral variant Remarks
                if (($element2[19] =~ m/Passenger/ || $element2[19] =~ m/Neutral/) && ($element2[19] !~ "---") && ($element2[19] !~ ""))
                {
                    $worksheet4->write($row_filtered3, 25, $element2[19], $left);
					$element2[25] = $element2[19];
                }

                # Synonymous Variants Remarks
                if ($aa[0] eq $aa[1] && scalar@aa == 2)
                {
                    $worksheet5->write($row_filtered3, 25, "2.Synonymous", $left);
					$element2[25] = "2.Synonymous";
                }

                # Intronic Variants Remarks
                if (($element2[17] eq "---") || ($element2[17] eq "" && $element2[16] =~ m/\+/) || ($element2[17] eq "" && $element2[16] =~ m/\-/))
                {
                    $worksheet5->write($row_filtered3, 25, "3.Intronic", $left);
					$element2[25] = "3.Intronic";
                }

                # Adjacent Location Variants Remarks
                if ($diff >= -5 && $diff <= 5)
                {
                    $worksheet5->write($row_filtered3, 25, "1.Adjacent Location - check hotspot or novel and pathogenicity before filteration", $left);
                }

                # Probable Germline Remarks
                if (($element2[23] >= 0.1 || $element2[24] >= 0.1 || $germ >=0 || $element2[6]==100) && ($element2[22] !~ m/dbSNP ID/) && ($foldername2[2] !~ m/gDNA/))
                {
                    $worksheet5->write($row_filtered3, 25, "4.Probable Germline", $left);
					$element2[25] = "4.Probable Germline";
                }
                # Strand Bias Remarks
                if ($strandPos > 80 || $strandPos < 20)
                {
                    $worksheet5->write($row_filtered3, 25, "7.Strand Bias", $redbold);
					$element2[25] = "7.Strand Bias";
                }
                # Variant Coverage Remarks
                if ($foldername2[2] !~ m/gDNA/ && $element2[10] < 20)
                {
                    $worksheet5->write($row_filtered3, 25, "6.Low Variant Coverage", $redbold);
					$element2[25] = "6.Low Variant Coverage";
                }

                # Variant Frequency (LOD) Remarks
                if (($foldername2[1] =~ m/CCP/ && $foldername2[2] =~ m/cfTNA/ && $element2[6] < 1) || ($foldername2[1] !~ m/CCP/ && $foldername2[2] =~ m/cfTNA/ && $element2[6] < 0.5) || ($foldername2[1] =~ m/CCP/ && $foldername2[2] =~ m/FT_DNA/ && $element2[6] < 5) || ($foldername2[1] =~ m/CCP/ && $foldername2[2] =~ m/FFPE_DNA/ && $element2[6] < 5) || ($foldername2[2] =~ m/FT_DNA/ && $element2[6] < 5) || ($foldername2[2] =~ m/FFPE_DNA/ && $element2[6] < 5))
                {
                    $worksheet5->write($row_filtered3, 25, "5.Below LOD", $redbold);
					$element2[25] = "5.Below LOD";
                }



                # Blacklisted Remarks
                if ($black_variant =~ m/$foldername2[1]/ || $black_variant =~ m/All/)
                {
                    $worksheet5->write($row_filtered3, 25, "8.Blacklisted - $black_remarks[4]", $redbold);
					$element2[25] = "8.Blacklisted - $black_remarks[4]";
                }

                # COSMIC SNP Flag
                if ($foldername2[2] ne "gDNA" && $snp_flag2[0] eq $element2[0])
                {
                    $worksheet5->write($row_filtered3, 25, "9.$snp_flag2[1]", $redbold);
					$element2[25] = "9.$snp_flag2[1]";
                }
				#ClinVar Classification
				$clin_line=first_index {$_ =~ m/$element2[0]\t/} @ClinVar_data;
				if ($clin_line>=0)
				{
					@Clin_line_split=split ('\t',$ClinVar_data[$clin_line]);
					$clin_class = $Clin_line_split[6];
					chomp $clin_class ; 
				if ($clin_class eq $element2[20])
					{
					$worksheet5->write($row_filtered3, 26, $clin_class, $left);
					}
				else
					{
					$worksheet5->write($row_filtered3, 26, $clin_class, $redbold);
					}
				}
				 # Strand Bias Remarks for gDNA
                if (($foldername2[2] =~ m/gDNA/) && ($strandPos > 80 || $strandPos < 20))
                {
                    $worksheet5->write($row_filtered3, 25, "7.Strand Bias", $redbold);
					$element2[25] = "7.Strand Bias";
                }
            }

	        $row_filtered3++;


# 6th Worksheet : SNV_Info

            if (($black_variant !~ m/$foldername2[1]/ && $black_variant !~ m/All/ && $black_variant !~ m/unknown/ && $element2[13] ne "0" && $element2[10] ne "0") || ($element2[0] eq $action2[0]) || (($element2[13] eq "EGFR") && ($element2[15] == 19)))
            {
				$concat=$element2[1]."_".$element2[2]."_".$element2[3]."_".$element2[4];
				$concat =~ s/-//;

                if ($element2[0] ne 'Category')
                {
                    if ($foldername2[2] =~ m/gDNA/)
                    {
                        $element2[0] = "Germline";
                    }

                    elsif (($element2[23] >= 0.1 || $element2[24] >= 0.1 || $germ >=0 || $element2[6]==100) && ($element2[6]>=10))
                    {
                        $element2[0] = "Probable Germline";
                    }

                    elsif ($foldername2[2] =~ m/cf[DT]NA/ && $element2[6] >=40 && $element2[21] =~ m/Benign/i)
                    {
                        $element2[0] = "Probable Germline";
                    }

                    else
                    {
                        $element2[0] = "Probable Somatic";
                    }
                }

                if ($foldername2[2] =~ m/cf[DT]NA/)
                {
				if (($element2[1] =~ m/Chrom/) || ($foldername2[1] ne "CCP" && $element2[6] >= 0.5 && $element2[10] >=20 && $strandPos <= 80 && $strandPos >= 20 && $snp_flag eq "") || ($foldername2[1] eq "CCP" && $element2[6] >= 1 && $element2[10] >=20 && $strandPos <= 80 && $strandPos >= 20 && $snp_flag eq "" ) || ($concat eq $action2[0]) || (($element2[13] eq "EGFR") && ($element2[15] == 19)))
                    {
                        for ($s=0,$t=0;$s<=scalar@element2;$s++,$t++) 
			            {
                            if ($t==11)
                            {
                                $s=10;
                                $t++;
                                next;
                            }

					if (($concat eq $action2[0]) || (($element2[13] eq "EGFR") && ($element2[15] == 19)))
						{
							$worksheet6->write($row_filtered4, $s, $element2[$t], $yellowbold);
						}
					else
						{
							$worksheet6->write($row_filtered4, $s, $element2[$t], $left);
						}                            
						$worksheet6->freeze_panes(1, 1);
							}

                        # Adjacent Location Variants Remarks
                        if ($diff >= -5 && $diff <= 5 && $element2[22] !~ m/dbSNP ID/)
                        {
                            $worksheet6->write($row_filtered4, 23, "Adjacent Location - check hotspot or novel and pathogenicity before filteration", $left);
                        }

                        $row_filtered4++;

                        $reflen = length($element2[3]);
                        $altlen = length($element2[4]);
                                        
                        if ($reflen == 1 && $altlen == 1 && $element2[3] ne "-" && $element2[4] ne "-")
                        {
                            $SNVs++;
                        }
                    }
                }

                elsif ($foldername2[2] =~ m/FT_DNA/ || $foldername2[2] =~ m/FFPE_DNA/ || $foldername2[2] =~ m/DNA_Cells/ || $foldername2[1] =~ m/AML/)
                {

 		     if (($element2[0] eq 'Category') || ($foldername2[1] !~ m/CCP/ && $element2[6] >= 5 && $element2[10] >=20 && $strandPos <= 80 && $strandPos >= 20 && $snp_flag eq "") || ($foldername2[1] =~ m/CCP/ && $element2[6] >= 5 && $element2[10] >=20 && $strandPos <= 80 && $strandPos >= 20 && $snp_flag eq "") || ($concat eq $action2[0]) || (($element2[13] eq "EGFR") && ($element2[15] == 19)))
                    {
                        for ($s=0,$t=0;$s<=scalar@element2;$s++,$t++) 
			            {
                            if ($t==11)
                            {
                                $s=10;
                                $t++;
                                next;
                            }
					if (($concat eq $action2[0]) || (($element2[13] eq "EGFR") && ($element2[15] == 19)))
						{
							$worksheet6->write($row_filtered4, $s, $element2[$t], $yellowbold);
						}
					else
						{
							 $worksheet6->write($row_filtered4, $s, $element2[$t], $left);
						}  

                    $worksheet6->freeze_panes(1, 1);
                        }

                        # Adjacent Location Variants Remarks
                        if ($diff >= -5 && $diff <= 5 && $element2[22] !~ m/dbSNP ID/)
                        {
                            $worksheet6->write($row_filtered4, 23, "Adjacent Location - check hotspot or novel and pathogenicity before filteration", $left);
                        }

                        $row_filtered4++;

                        $reflen = length($element2[3]);
                        $altlen = length($element2[4]);
                                        
                        if ($reflen == 1 && $altlen == 1 && $element2[3] ne "-" && $element2[4] ne "-")
                        {
                            $SNVs++;
                        }
                    }
                }

                elsif ($foldername2[2] =~ m/gDNA/)
                {
                    if (($element2[0] eq 'Category') || ($element2[6] >= 10 && $element2[10] >=10 && $strandPos <= 80 && $strandPos >= 20) || ($concat eq $action2[0]) || (($element2[13] eq "EGFR") && ($element2[15] == 19)))
                    {
                        for ($s=0,$t=0;$s<=scalar@element2;$s++,$t++) 
			            {
                            if ($t==11)
                            {
                                $s=10;
                                $t++;
                                next;
                            }

					if (($concat eq $action2[0]) || (($element2[13] eq "EGFR") && ($element2[15] == 19)))
						{
							$worksheet6->write($row_filtered4, $s, $element2[$t], $yellowbold);
						}
					else
						{
							$worksheet6->write($row_filtered4, $s, $element2[$t], $left);
						}  

						$worksheet6->freeze_panes(1, 1);
                        }

                        # Adjacent Location Variants Remarks
                        if ($diff >= -5 && $diff <= 5 && $element2[22] !~ m/dbSNP ID/)
                        {
                            $worksheet6->write($row_filtered4, 23, "Adjacent Location - check hotspot or novel and pathogenicity before filteration", $left);
                        }
                        
                        $row_filtered4++;

                        $reflen = length($element2[3]);
                        $altlen = length($element2[4]);
                                        
                        if ($reflen == 1 && $altlen == 1 && $element2[3] ne "-" && $element2[4] ne "-")
                        {
                            $SNVs++;
                        }
                    }
                }
             }	   
  	    }
    }
}

$ReportedVariants=$row_filtered4-1;
$Indels=$ReportedVariants-$SNVs;

if ($ReportedVariants == 0)
{
    $worksheet6->write(1, 0, "No variant detected",$redbold);
}

# 10th Worksheet : CNA_Report

@cnaheader=("SN", "Markers", "Cytoband", "Copy Number", "CNA Ratio", "chr", "Start", "End");

for ($ch=0;$ch<scalar@cnaheader;$ch++) 
{
		if ($foldername2[2] =~ m/FT_/ || $foldername2[2] =~ m/FFPE_/)
		{
		$cnaheader[$ch]=~m/(\d+) \(Gain/;
		$copy_number = $1;
		if($ch == 3 && $1 >= 6 )
		{
		$worksheet10->write(0, $ch, $copy_number." (Amplification)", $center);
		}
		else
		{
		$worksheet10->write(0, $ch, $cnaheader[$ch], $center);
		}
		}
		else
		{
		$worksheet10->write(0, $ch, $cnaheader[$ch], $center);
		}
		$worksheet10->freeze_panes(1, 0);
}

# Set the active worksheet

$worksheet6->activate();

print "Completed\n";


##############################################################################  Annotation End  ##############################################################################


#############################################################################  Uncovered Start  ##############################################################################

# 7th Worksheet : Uncovered

print "\n\nUncovered regions ";


unless(open(U,$uncovereddb))
{
    print "\n\nCan't open file $uncovereddb";
}

@uncoverd=<U>;

close(U);

$urow_10=1, $urow_20=1, $urow_600=1;

@uncoveredheader=("contig_id", "contig_srt", "contig_end", "region_id", "attributes", "gc_count", "overlaps", "fwd_e2e", "rev_e2e", "total_reads", "fwd_reads", "rev_reads", "cov20x", "cov100x", "cov500x", "Gene, Exon, Codons");

for ($i=0;$i<scalar@uncoveredheader;$i++) 
		{
			$worksheet7->write(0, $i, $uncoveredheader[$i], $center);
			$worksheet7->freeze_panes(1, 5);
		}

if ($foldername2[2] =~ m/cf[DT]NA/)
{

    print "<600 reads\t:\t";

	foreach $uline_600 (@uncovered_600)
	{

		@uelement_600 = split ('\t',$uline_600);

		for ($u=0;$u<scalar@uelement_600;$u++) 
		{
			$worksheet7->write($urow_600, $u, $uelement_600[$u], $left);
		}


		foreach $uncovered_ampl (@uncoverd) 
		{
			@uncovered_ampl_elements = split ('\t',$uncovered_ampl);
			chomp$uncovered_ampl_elements[5];

			if (($foldername2[1] !~ m/AML/ && $uncovered_ampl_elements[3] eq $uelement_600[3] && $uncovered_ampl_elements[6] =~ m/cf[DT]NA/i) || ($foldername2[1] =~ m/AML/ && $uncovered_ampl_elements[3] eq $uelement_20[3] && $uncovered_ampl_elements[6] !~ m/gDNA/i))
			{
				$worksheet7->write($urow_600, 15, $uncovered_ampl_elements[5], $left);
                $limitations= $limitations.$uncovered_ampl_elements[5]."; ";
			}
		}
		$urow_600++;
	}
}

if ($foldername2[2] =~ m/gDNA/)
{

    print "<10 reads\t:\t";

	foreach $uline_10 (@uncovered_10)
	{

		@uelement_10 = split ('\t',$uline_10);

		for ($u=0;$u<scalar@uelement_10;$u++) 
		{
			$worksheet7->write($urow_10, $u, $uelement_10[$u], $left);
		}


		foreach $uncovered_ampl (@uncoverd) 
		{
			@uncovered_ampl_elements = split ('\t',$uncovered_ampl);
			chomp$uncovered_ampl_elements[5];
		    if (($foldername2[1] !~ m/AML/ && $uncovered_ampl_elements[3] eq $uelement_10[3] && $uncovered_ampl_elements[6] =~ m/$foldername2[2]/i) || ($foldername2[1] =~ m/AML/ && $uncovered_ampl_elements[3] eq $uelement_10[3] && $uncovered_ampl_elements[6] !~ m/gDNA/i))
		    {
				$worksheet7->write($urow_10, 15, $uncovered_ampl_elements[5], $left);
                $limitations= $limitations.$uncovered_ampl_elements[5]."; ";
			}
		}
		$urow_10++;
	}
}
else
{

print "<20 reads\t:\t";

	foreach $uline_20 (@uncovered_20)
	{
		@uelement_20 = split ('\t',$uline_20);

		for ($u=0;$u<scalar@uelement_20;$u++) 
		{
			$worksheet7->write($urow_20, $u, $uelement_20[$u], $left);
		}

        foreach $uncovered_ampl (@uncoverd) 
        {
		    @uncovered_ampl_elements = split ('\t',$uncovered_ampl);
		    chomp$uncovered_ampl_elements[5];

		    if (($foldername2[1] !~ m/AML/ && $uncovered_ampl_elements[3] eq $uelement_20[3] && $uncovered_ampl_elements[6] =~ m/$foldername2[2]/i) || ($foldername2[1] =~ m/AML/ && $uncovered_ampl_elements[3] eq $uelement_20[3] && $uncovered_ampl_elements[6] !~ m/gDNA/i))
		    {
			    $worksheet7->write($urow_20, 15, $uncovered_ampl_elements[5], $left);
                $limitations= $limitations."; ".$uncovered_ampl_elements[5];
		    }
	    }

		$urow_20++;
	}
}

$limitations =~ s/;\s$//;
$limitations =~ s/^;\s//;

	@limitations = split (";", $limitations);
	sort (@limitations);

	$pre_gene = "";
	$limitations_formatted = "";
	foreach $limitations_ (@limitations)
	{
#	$limitations_ =~m/(.*\],)(.*)/;
	$limitations_ =~m/(.*)\[/;
	$gene = $1;
	chomp $gene;
	$exon_codons = $2;

		if ($gene eq $pre_gene)
		{
	#	$limitations_formatted = $limitations_formatted."; ".$exon_codons;
		chomp $limitations_formatted;
	#	next;
		}
		else
		{
	#	$limitations_formatted = $limitations_formatted." | ".$limitations_;
		$limitations_formatted = $limitations_formatted.", ".$gene;
		chomp $limitations_formatted;
		}
	$pre_gene = $gene;
	}
	#$limitations_formatted =~ s/^\s\|\s//;
	$limitations_formatted =~ s/^,\s//;
	chomp $limitations_formatted;
	
# 8th Worksheet : Limitations

if ($limitations_formatted eq "")
{
    $worksheet8->write(0, 0, "NA", $left);
}

else
{
    $worksheet8->write(0, 0, $limitations_formatted, $left);
}

print "Completed\n";

##############################################################################  Uncovered End  ###############################################################################



############################################################################  LIMS Worksheet Start  ##########################################################################

print "\n\nWorksheet filling\t\t:\t";

@Worksheetheader=("SAMPLE ID", "TESTCODE", "ADAPTOR AND BARCODE DEAILS", "RUN", "SERVER", "SAMPLE TYPE", "AMPLISEQ PANEL DETAILS", "NUMBER OF GENES/SNPs", "DATE", "TOTAL NUMBER OF READS", "MEAN READ LENGTH (bp)", "TOTAL NO. OF BASES (Without MB)", "TOTAL NO. OF BASES >Q20 (Without MB)", "AMPLICONS WITH ATLEAST 10 READS", "AMPLICONS WITH ATLEAST 20 READS", "AMPLICONS WITH ATLEAST 30 READS", "AMPLICONS WITH ATLEAST 100 READS", "AMPLICONS WITH ATLEAST 500 READS", "AMPLICONS WITH ATLEAST 600 READS", "MEAN DEPTH (x)", "MAPPED READS", "Mapped Fusion Panel Reads", "Mapped Fusion Molecular Count", "Median Read Coverage", "Median Molecular Coverage", "On Target (%)", "Uniformity (%)", "MAPD", "QC CRITERIA", "QC COMM", "ALIGNER", "VARIANT CALLER", "SOFTWARE PARAMETERS", "ADDITIONAL ANALYSIS SOFTWARE", "DETAILS OF DATABASES", "NGS Pipeline", "CNA Baseline", "Predicted Tumor Content (Tumor-Normal Paired Analysis)", "TOTAL VARIANTS", "REPORTED VARIANTS", "SNV", "INDEL", "CNV", "Fusion", "Expression Controls Positive", "Total 5'/3' Assay Present", "Sanger", "ddPCR", "Comment", "PERFORMED BY", "CHECKED BY", "Unique Identification", "TMB","MSI Status","MSI Score","LOH");

for ($i=0;$i<scalar@Worksheetheader;$i++) 
		{

			$worksheet11->write(0, $i, $Worksheetheader[$i], $center);
			$worksheet11->freeze_panes(1, 1);

		}

$sample_type = $foldername2[2] ;
$sample_type =~  s/_/ /g;

$worksheet11->write(1, 0, $foldername2[0], $left); # SAMPLE ID
$worksheet11->write(1, 2, $foldername2[3], $left); # ADAPTOR AND BARCODE DEAILS
$worksheet11->write(1, 3, $foldername2[4], $left); # RUN
$worksheet11->write(1, 4, $foldername2[5], $left); # SERVER
$worksheet11->write(1, 5, $sample_type, $left); # SAMPLE TYPE
$worksheet11->write(1, 6, $foldername2[1], $left); # AMPLISEQ PANEL DETAILS
$worksheet11->write(1, 7, $panel_genes{$foldername2[1]}, $left); # NUMBER OF GENES/SNPs
$worksheet11->write(1, 8, $date, $left); # DATE
$worksheet11->write(1, 9, $read_count, $left); # TOTAL NUMBER OF READS
$worksheet11->write(1, 10, $mean_read_len, $left); # MEAN READ LENGTH
$worksheet11->write(1, 11, $total_bases, $left); # TOTAL NO. OF BASES (Without MB)
$worksheet11->write(1, 12, $Q20_bases, $left); # TOTAL NO. OF BASES >Q20 (Without MB)
$worksheet11->write(1, 13, $per_10_2dec, $left); # AMPLICONS WITH ATLEAST 10 READS
$worksheet11->write(1, 14, $per_20_2dec, $left); # AMPLICONS WITH ATLEAST 20 READS
$worksheet11->write(1, 15, $per_30_2dec, $left); # AMPLICONS WITH ATLEAST 30 READS
$worksheet11->write(1, 16, $per_100_2dec, $left); # AMPLICONS WITH ATLEAST 100 READS
$worksheet11->write(1, 17, $per_500_2dec, $left); # AMPLICONS WITH ATLEAST 500 READS
$worksheet11->write(1, 18, $per_600_2dec, $left); # AMPLICONS WITH ATLEAST 600 READS
$worksheet11->write(1, 19, $mean_depth, $left); # MEAN DEPTH
$worksheet11->write(1, 20, $coverage_stat[2], $left); # MAPPED READS
$worksheet11->write(1, 21, "NA"); # Mapped Fusion Panel Reads
$worksheet11->write(1, 22, "NA"); # Mapped Fusion Molecular Count
$worksheet11->write(1, 23, "NA"); # Median Read Coverage
$worksheet11->write(1, 24, "NA"); # Median Molecular Coverage
$worksheet11->write(1, 25, $On_Target, $left); # On Target (%)
$worksheet11->write(1, 26, $Uniformity, $left); # Uniformity (%)
$worksheet11->write(1, 27, "NA"); # MAPD
$worksheet11->write(1, 28, "Pass"); # QC CRITERIA
$worksheet11->write(1, 29, "-"); # QC COMM
$worksheet11->write(1, 30, $TMAP_version); # ALIGNER version
$worksheet11->write(1, 31, $TVC_version); # VARIANT CALLER version
$worksheet11->write(1, 36, ""); # CNA Baseline

if ($ethnicity =~ m/EAS/i)
{
  #  $worksheet11->write(1, 34, "$dbSNP_version, 1000 genomes frequency (EAS) phase 3v5b, ExAC (EAS) Release 1.0, $Clinvar_version, $COSMIC_version"); # DETAILS OF DATABASES - EAS - Somatic
	 $worksheet11->write(1, 34, "1000 genomes frequency (EAS) phase 3v5b, gnomAD (EAS) Release 2.1.1"); # DETAILS OF DATABASES - EAS - Somatic
}

elsif ($ethnicity =~ m/SAS/i)
{
   #  $worksheet11->write(1, 34, "$dbSNP_version, 1000 genomes frequency (EAS) phase 3v5b, ExAC (EAS) Release 1.0, $Clinvar_version, $COSMIC_version"); # DETAILS OF DATABASES - EAS - Somatic
	  $worksheet11->write(1, 34, "1000 genomes frequency (SAS) phase 3v5b, gnomAD (SAS) Release 2.1.1"); # DETAILS OF DATABASES - EAS - Somatic
}

elsif ($ethnicity =~ m/AFR/i)
{
   #  $worksheet11->write(1, 34, "$dbSNP_version, 1000 genomes frequency (EAS) phase 3v5b, ExAC (EAS) Release 1.0, $Clinvar_version, $COSMIC_version"); # DETAILS OF DATABASES - EAS - Somatic
	  $worksheet11->write(1, 34, "1000 genomes frequency (AFR) phase 3v5b, gnomAD (AFR) Release 2.1.1"); # DETAILS OF DATABASES - EAS - Somatic
}

elsif ($ethnicity =~ m/EUR/i)
{
  #  $worksheet11->write(1, 34, "$dbSNP_version, 1000 genomes frequency (EUR) phase 3v5b, ExAC (EUR) Release 1.0, $Clinvar_version, $COSMIC_version"); # DETAILS OF DATABASES - EUR - Somatic
	$worksheet11->write(1, 34, "1000 genomes frequency (EUR) phase 3v5b, gnomAD (EUR) Release 2.1.1"); # DETAILS OF DATABASES - EUR - Somatic
}

elsif ($ethnicity =~ m/AMR/i)
{
   # $worksheet11->write(1, 34, "$dbSNP_version, 1000 genomes frequency (AMR) phase 3v5b, ExAC (AMR) Release 1.0, $Clinvar_version, $COSMIC_version"); # DETAILS OF DATABASES - AMR - Somatic
	$worksheet11->write(1, 34, "1000 genomes frequency (AMR) phase 3v5b, gnomAD (AMR) Release 2.1.1"); # DETAILS OF DATABASES - AMR - Somatic
}

elsif ($ethnicity =~ m/PAN/i)
{
   # $worksheet11->write(1, 34, "$dbSNP_version, 1000 genomes frequency (AMR) phase 3v5b, ExAC (AMR) Release 1.0, $Clinvar_version, $COSMIC_version"); # DETAILS OF DATABASES - AMR - Somatic
	$worksheet11->write(1, 34, "1000 genomes frequency phase 3v5b, gnomAD Release 2.1.1"); # DETAILS OF DATABASES - AMR - Somatic
}
if ($foldername2[2] eq 'gDNA')
{
	$worksheet11->write(1, 32, $soft_param_germline); # SOFTWARE PARAMETERS - Germline SNV & Indel
	$worksheet11->write(1, 33, $BiVA_version); # ADDITIONAL ANALYSIS SOFTWARE - Germline SNV & Indel
#   $worksheet11->write(1, 33, "---"); # ADDITIONAL ANALYSIS SOFTWARE - Germline SNV & Indel

    if ($ethnicity =~ m/EAS/i)
    {
	   # $worksheet11->write(1, 34, "$dbSNP_version, 1000 genomes frequency (EAS) phase 3v5b, ExAC (EAS) Release 1.0, $Clinvar_version, $HGMD_version"); # DETAILS OF DATABASES - EAS - germline
		$worksheet11->write(1, 34, "1000 genomes frequency (EAS) phase 3v5b, gnomAD (EAS) Release 2.1.1"); # DETAILS OF DATABASES - EAS - germline
	}
  
    elsif ($ethnicity =~ m/SAS/i)
    {
	   # $worksheet11->write(1, 34, "$dbSNP_version, 1000 genomes frequency (SAS) phase 3v5b, ExAC (SAS) Release 1.0, $Clinvar_version, $HGMD_version"); # DETAILS OF DATABASES - SAS - germline
		$worksheet11->write(1, 34, "1000 genomes frequency (SAS) phase 3v5b, gnomAD (SAS) Release 2.1.1"); # DETAILS OF DATABASES - SAS - germline

	}

    elsif ($ethnicity =~ m/AFR/i)
    {
	   # $worksheet11->write(1, 34, "$dbSNP_version, 1000 genomes frequency (AFR) phase 3v5b, ExAC (AFR) Release 1.0, $Clinvar_version, $HGMD_version"); # DETAILS OF DATABASES - AFR - germline
		$worksheet11->write(1, 34, "1000 genomes frequency (AFR) phase 3v5b, gnomAD (AFR) Release 2.1.1"); # DETAILS OF DATABASES - AFR - germline
	}

    elsif ($ethnicity =~ m/EUR/i)
    {
	    #$worksheet11->write(1, 34, "$dbSNP_version, 1000 genomes frequency (EUR) phase 3v5b, ExAC (EUR) Release 1.0, $Clinvar_version, $HGMD_version"); # DETAILS OF DATABASES - EUR - germline
		$worksheet11->write(1, 34, "1000 genomes frequency (EUR) phase 3v5b, gnomAD (EUR) Release 2.1.1"); # DETAILS OF DATABASES - EUR - germline
	}

    elsif ($ethnicity =~ m/AMR/i)
    {
	    #$worksheet11->write(1, 34, "$dbSNP_version, 1000 genomes frequency (AMR) phase 3v5b, ExAC (AMR) Release 1.0, $Clinvar_version, $HGMD_version"); # DETAILS OF DATABASES - AMR - germline
		$worksheet11->write(1, 34, "1000 genomes frequency (AMR) phase 3v5b, gnomAD (AMR) Release 2.1.1"); # DETAILS OF DATABASES - AMR - germline
	}

	elsif ($ethnicity =~ m/PAN/i)
    {
	    #$worksheet11->write(1, 34, "$dbSNP_version, 1000 genomes frequency (AMR) phase 3v5b, ExAC (AMR) Release 1.0, $Clinvar_version, $HGMD_version"); # DETAILS OF DATABASES - AMR - germline
		$worksheet11->write(1, 34, "1000 genomes frequency phase 3v5b, gnomAD Release 2.1.1"); # DETAILS OF DATABASES - AMR - germline
	}
    $worksheet11->write(1, 35, $pipeline_germline); # NGS Pipeline version Germline SNV & Indel
    $worksheet11->write(1, 36, "NA"); # CNA Baseline
	$worksheet11->write(1, 42, "NA"); # CNA
}
elsif ($foldername2[2] =~ m/cf[DT]NA/ && $foldername2[1] !~ m/CCP/)
{
	$worksheet11->write(1, 32, $soft_param_somatic_cf); # SOFTWARE PARAMETERS - Somatic SNV & Indel
	$worksheet11->write(1, 33, $BiVA_version);# ADDITIONAL ANALYSIS SOFTWARE - Somatic SNV & Indel
#	$worksheet11->write(1, 33, "---"); # ADDITIONAL ANALYSIS SOFTWARE - Somatic SNV & Indel
	$worksheet11->write(1, 35, $pipeline_somatic); # NGS Pipeline version Somatic SNV & Indel
	$worksheet11->write(1, 42, "NA"); # CNA
    $worksheet11->write(1, 36, "NA"); # CNA Baseline
}
elsif (($foldername2[1] eq 'CHP' || $foldername2[1] eq 'BRCA') && ($foldername2[2] =~ m/FT_/ || $foldername2[2] =~ m/FFPE_/))
{
	$worksheet11->write(1, 32, $soft_param_somatic_tissue); # SOFTWARE PARAMETERS - Somatic SNV & Indel
	$worksheet11->write(1, 33, $BiVA_version); # ADDITIONAL ANALYSIS SOFTWARE - Somatic SNV & Indel
#	$worksheet11->write(1, 33, "---"); # ADDITIONAL ANALYSIS SOFTWARE - Somatic SNV & Indel
	$worksheet11->write(1, 35, $pipeline_somatic); # NGS Pipeline version Somatic SNV & Indel
	$worksheet11->write(1, 42, "NA"); # CNA
    $worksheet11->write(1, 36, "NA"); # CNA Baseline
}
elsif ($foldername2[2] =~ m/cf[DT]NA/ && ($foldername2[1] =~ m/CCP/ || $foldername2[1] =~ m/OCAv3/))
{
	$worksheet11->write(1, 32, $soft_param_somatic_cf); # SOFTWARE PARAMETERS - Somatic SNV, Indel & CNV
	$worksheet11->write(1, 33, "$BiVA_version, $ONCOCNV_version"); # ADDITIONAL ANALYSIS SOFTWARE - Somatic SNV, Indel & CNV
#	$worksheet11->write(1, 33, "$ONCOCNV_version"); # ADDITIONAL ANALYSIS SOFTWARE - Somatic SNV, Indel & CNV
	$worksheet11->write(1, 35, $pipeline_somatic_with_CNA); # NGS Pipeline version - Somatic SNV, Indel & CNV
}

else
{
	$worksheet11->write(1, 32, $soft_param_somatic_tissue); # SOFTWARE PARAMETERS - Somatic SNV, Indel & CNV
	$worksheet11->write(1, 33, "$BiVA_version, $ONCOCNV_version"); # ADDITIONAL ANALYSIS SOFTWARE - Somatic SNV, Indel & CNV
#	$worksheet11->write(1, 33, "$ONCOCNV_version"); # ADDITIONAL ANALYSIS SOFTWARE - Somatic SNV, Indel & CNV

	$worksheet11->write(1, 35, $pipeline_somatic_with_CNA); # NGS Pipeline version - Somatic SNV, Indel & CNV
}

if ($foldername2[1] =~ m/CCP/ && $foldername2[2] =~ m/cf[DT]NA/)
{
    $worksheet11->write(1, 36, $CNA_baseline_cf); # CCP-cf[DT]NA CNA Baseline
}
if ($foldername2[1] =~ m/OCAv3/ && $foldername2[2] =~ m/cf[DT]NA/)
{
    $worksheet11->write(1, 36, $CNA_baseline_cf_OCAv3); # OCAv3-cf[DT]NA CNA Baseline
}
if ($foldername2[1] =~ m/CCP/ && $foldername2[2] =~ m/_[DT]NA/)
{
if ($paired_analysis_choice == 1)
	{
    $worksheet11->write(1, 36, $CNA_baseline_tumor_paired); # CCP-Tissue paired CNA Baseline
	}
	else
	{
    $worksheet11->write(1, 36, $CNA_baseline_tumor_unpaired); # CCP-Tissue unpaired CNA Baseline
	}
}

$worksheet11->write(1, 37, "NA"); # Predicted Tumor Content (Tumor-Normal Paired Analysis)
$worksheet11->write(1, 38, $row_filtered-1); # TOTAL VARIANTS
$worksheet11->write(1, 39, $ReportedVariants); # REPORTED VARIANTS
$worksheet11->write(1, 40, $SNVs); # SNV
$worksheet11->write(1, 41, $Indels); # INDEL
$worksheet11->write(1, 43, "NA"); # Fusion
$worksheet11->write(1, 44, "NA"); # Expression Controls Positive
$worksheet11->write(1, 45, "NA"); # Total 5'/3' Assay Present
$worksheet11->write(1, 46, "NA"); # Sanger
$worksheet11->write(1, 47, "NA"); # ddPCR
$worksheet11->write(1, 48, "---"); # Comment
$worksheet11->write(1, 49, $Analyst); # Analyst
$worksheet11->write(1, 50, "Harshal Darokar"); # Reviewer
$worksheet11->write(1, 51, $uniqueID); # Unique Identification

if ($foldername2[1] eq 'CCP' && $foldername2[2] !~ m/gDNA/ && $foldername2[2] !~ m/cfTNA/)
{
    $worksheet11->write(1, 52, ""); # TMB
}

else
{
    $worksheet11->write(1, 52, "NA"); # TMB
}

$worksheet11->write(1, 53, "NA"); # MSI Status
$worksheet11->write(1, 54, "NA"); # MSI Score
$worksheet11->write(1, 55, "NA"); # LOH

		

print "Completed\n";

###########################################################################  LIMS Worksheet End  #########################################################################
###########################################################################  Checklist START  #########################################################################
if ($cancer_type > 0)
	{
		my $worksheet12 = $workbook->add_worksheet('CheckList');
		unless(open(CL,$checklist_db)){
		print "\n\nCan't open file $checklist_db";
		}
		@cl_db=<CL>;
		close(CL);
		$checklist_row_count=2;
		$worksheet12->write(0, 0,"chr_pos_ref_alt",$left);
		$worksheet12->write(0, 1,"Gene Symbol",$left);
		$worksheet12->write(0, 2,"Protein change",$left);
		$worksheet12->write(0, 3,"Cosmic ID",$left);
		$worksheet12->write(0, 4,"Allele Cov",$left);
		$worksheet12->write(0, 5,"Total Cov",$left);
		$worksheet12->write(0, 6,"Raw Freq",$left);
		$worksheet12->write(0, 7,"Remark",$left);
		$worksheet12->write(0, 8,$checklist_options{$cancer_type},$bold);
		@can_specific_var = '';
		@non_specific_var = '';
		$tmp_floor = '';
		$tmp_celing = '';
		$tmp_non_floor = '';
		$tmp_non_celing = '';
		foreach $cl_db (@cl_db)
		{
			chomp $cl_db;
			@cl_db_line=split('\t',$cl_db);
			
			foreach $data_for_cl (@data)
			{
				@data_for_cl_line=split('\t',$data_for_cl);
				$data_for_cl_line[2]=~s/-//g;
				$data_for_cl_line[3]=~s/-//g;
				if (($cl_db_line[9] =~m/:$cancer_type:/))
				{
						if (($data_for_cl_line[0] eq $cl_db_line[2]) && ($data_for_cl_line[1] eq $cl_db_line[3]) && ($data_for_cl_line[2] eq $cl_db_line[4]) && ($data_for_cl_line[3] eq $cl_db_line[5]))
							{
								$cl_var_pos = $cl_db_line[0]."\t".$cl_db_line[1]."\t".$cl_db_line[7]."\t".$cl_db_line[8];
								if ($data_for_cl_line[25] <= $tmp_floor)
								{
								push (@can_specific_var,$cl_var_pos."\t".$data_for_cl_line[25]."\t".$data_for_cl_line[19]."\t".sprintf ("%.2f",($data_for_cl_line[25]/$data_for_cl_line[19])*100));
								$tmp_floor = $data_for_cl_line[25];
								}
								elsif ($data_for_cl_line[25] > $tmp_celing)
								{
								unshift (@can_specific_var,$cl_var_pos."\t".$data_for_cl_line[25]."\t".$data_for_cl_line[19]."\t".sprintf ("%.2f",($data_for_cl_line[25]/$data_for_cl_line[19])*100));
								$tmp_celing = $data_for_cl_line[25];
								}

							}

				}
				else
				{
					if (($data_for_cl_line[0] eq $cl_db_line[2]) && ($data_for_cl_line[1] eq $cl_db_line[3]) && ($data_for_cl_line[2] eq $cl_db_line[4]) && ($data_for_cl_line[3] eq $cl_db_line[5]))
							{
								$cl_var_pos = $cl_db_line[0]."\t".$cl_db_line[1]."\t".$cl_db_line[7]."\t".$cl_db_line[8];
								if ($data_for_cl_line[25] <= $tmp_non_floor)
								{
								push (@non_specific_var,$cl_var_pos."\t".$data_for_cl_line[25]."\t".$data_for_cl_line[19]."\t".sprintf ("%.2f",($data_for_cl_line[25]/$data_for_cl_line[19])*100));
								$tmp_non_floor = $data_for_cl_line[25];
								}
								elsif ($data_for_cl_line[25] > $tmp_non_celing)
								{
								unshift (@non_specific_var,$cl_var_pos."\t".$data_for_cl_line[25]."\t".$data_for_cl_line[19]."\t".sprintf ("%.2f",($data_for_cl_line[25]/$data_for_cl_line[19])*100));
								$tmp_non_celing = $data_for_cl_line[25];
								}
							}
				}
			}
			
		}
	$worksheet12->write($checklist_row_count-1, 0, "Cancer Specific Variants",$left); #Type of variant
	@can_specific_var = grep($_, @can_specific_var);
		foreach $can_specific_var (@can_specific_var)
			{
			@can_specific_var_line=split('\t',$can_specific_var);
			$worksheet12->write($checklist_row_count, 0, $can_specific_var_line[0],$left);
			$worksheet12->write($checklist_row_count, 1, $can_specific_var_line[1],$left);
			$worksheet12->write($checklist_row_count, 2, $can_specific_var_line[2],$left);
			$worksheet12->write($checklist_row_count, 3, $can_specific_var_line[3],$left);
								if (($foldername2[2] =~ m/cfTNA/) && ($can_specific_var_line[4] > 5) && ($can_specific_var_line[4] < 20) && (($can_specific_var_line[4]/$can_specific_var_line[5])*100 > 0.5))
								{
								$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4],$redbold);
								$worksheet12->write($checklist_row_count, 5, $can_specific_var_line[5],$redbold);
								$worksheet12->write($checklist_row_count, 6, $can_specific_var_line[6],$redbold);
								$worksheet12->write($checklist_row_count, 7, "Alert if ddPCR assay available",$redbold);

								}
								elsif (($foldername2[2] =~ m/FT_DNA/ || $foldername2[2] =~ m/FFPE_DNA/) && ($can_specific_var_line[4] > 5) && ($can_specific_var_line[4] < 20) && (($can_specific_var_line[4]/$can_specific_var_line[5])*100 > 2.5))
								{
								$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4],$redbold);
								$worksheet12->write($checklist_row_count, 5, $can_specific_var_line[5],$redbold);
								$worksheet12->write($checklist_row_count, 6, $can_specific_var_line[6],$redbold);
								$worksheet12->write($checklist_row_count, 7, "Alert if ddPCR assay available",$left);
								}
								elsif (($foldername2[2] =~ m/cfTNA/) && ($can_specific_var_line[4] >=20) && (($can_specific_var_line[4]/$can_specific_var_line[5])*100 >=1))
								{
								$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4],$greenbold);
								$worksheet12->write($checklist_row_count, 5, $can_specific_var_line[5],$greenbold);
								$worksheet12->write($checklist_row_count, 6, $can_specific_var_line[6],$greenbold);
								$worksheet12->write($checklist_row_count, 7, "Detected?",$greenbold);
								}
								elsif (($foldername2[2] =~ m/FT_DNA/ || $foldername2[2] =~ m/FFPE_DNA/) && ($can_specific_var_line[4] >=20) && (($can_specific_var_line[4]/$can_specific_var_line[5])*100 >=5))
								{
								$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4],$greenbold);
								$worksheet12->write($checklist_row_count, 5, $can_specific_var_line[5],$greenbold);
								$worksheet12->write($checklist_row_count, 6, $can_specific_var_line[6],$greenbold);
								$worksheet12->write($checklist_row_count, 7, "Detected?",$greenbold);
								}
								else
								{
								$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4],$left);
								$worksheet12->write($checklist_row_count, 5, $can_specific_var_line[5],$left);
								$worksheet12->write($checklist_row_count, 6, $can_specific_var_line[6],$left);
								$worksheet12->write($checklist_row_count, 7, "---",$left);
								}
								$checklist_row_count = $checklist_row_count+1;
			}
	$non_checklist_row_count = scalar@can_specific_var+4;
	$worksheet12->write($non_checklist_row_count-1, 0, "Non-Cancer Specific Variants",$left); #Type of variant
	@non_specific_var = grep($_, @non_specific_var);
		foreach $non_specific_var (@non_specific_var)
			{
			@non_specific_var_line=split('\t',$non_specific_var);
			$worksheet12->write($non_checklist_row_count, 0, $non_specific_var_line[0],$left);
			$worksheet12->write($non_checklist_row_count, 1, $non_specific_var_line[1],$left);
			$worksheet12->write($non_checklist_row_count, 2, $non_specific_var_line[2],$left);
			$worksheet12->write($non_checklist_row_count, 3, $non_specific_var_line[3],$left);
								if (($foldername2[2] =~ m/cfTNA/) && ($non_specific_var_line[4] > 5) && ($non_specific_var_line[4] < 20) && (($non_specific_var_line[4]/$non_specific_var_line[5])*100 > 0.5))
								{
								$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4],$redbold);
								$worksheet12->write($non_checklist_row_count, 5, $non_specific_var_line[5],$redbold);
								$worksheet12->write($non_checklist_row_count, 6, $non_specific_var_line[6],$redbold);
								$worksheet12->write($non_checklist_row_count, 7, "Alert if ddPCR assay available",$redbold);

								}
								elsif (($foldername2[2] =~ m/FT_DNA/ || $foldername2[2] =~ m/FFPE_DNA/) && ($non_specific_var_line[4] > 5) && ($non_specific_var_line[4] < 20) && (($non_specific_var_line[4]/$non_specific_var_line[5])*100 > 2.5))
								{
								$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4],$redbold);
								$worksheet12->write($non_checklist_row_count, 5, $non_specific_var_line[5],$redbold);
								$worksheet12->write($non_checklist_row_count, 6, $non_specific_var_line[6],$redbold);
								$worksheet12->write($non_checklist_row_count, 7, "Alert if ddPCR assay available",$left);
								}
								elsif (($foldername2[2] =~ m/cfTNA/) && ($non_specific_var_line[4] >=20) && (($non_specific_var_line[4]/$non_specific_var_line[5])*100 >=1))
								{
								$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4],$greenbold);
								$worksheet12->write($non_checklist_row_count, 5, $non_specific_var_line[5],$greenbold);
								$worksheet12->write($non_checklist_row_count, 6, $non_specific_var_line[6],$greenbold);
								$worksheet12->write($non_checklist_row_count, 7, "Detected?",$greenbold);
								}
								elsif (($foldername2[2] =~ m/FT_DNA/ || $foldername2[2] =~ m/FFPE_DNA/) && ($non_specific_var_line[4] >=20) && (($non_specific_var_line[4]/$non_specific_var_line[5])*100 >=5))
								{
								$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4],$greenbold);
								$worksheet12->write($non_checklist_row_count, 5, $non_specific_var_line[5],$greenbold);
								$worksheet12->write($non_checklist_row_count, 6, $non_specific_var_line[6],$greenbold);
								$worksheet12->write($non_checklist_row_count, 7, "Detected?",$greenbold);
								}
								else
								{
								$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4],$left);
								$worksheet12->write($non_checklist_row_count, 5, $non_specific_var_line[5],$left);
								$worksheet12->write($non_checklist_row_count, 6, $non_specific_var_line[6],$left);
								$worksheet12->write($non_checklist_row_count, 7, "---",$left);
								}
								$non_checklist_row_count = $non_checklist_row_count+1;
			
			}
		
		
		
	}


###########################################################################  Checklist END  #########################################################################







$endtime = strftime "%I:%M %p", localtime;

print "\n\n\n***************** Sample Analysis Completed on $date at $endtime *****************\n\n";

close (STDOUT);
exit;
