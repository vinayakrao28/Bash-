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
use 5.010;
use Spreadsheet::ParseExcel::SaveParser;

# System credentials
$user = "bioinfo";
$ip = "172.16.3.63";
$pass = 'Vr@@1234';

# Ion Server credentials
$ionusr = "vinayak";
$ionpass = 'Vr@@1234';

# Ion Reporter credentials (Dont change)
$irusr = "sachin";
$irpass = 'Sc@@1234';

# Script Version
$version="v4.4.2 (27/09/2022)";  
#Updates
# 1 - Added checklist logic
# 2 - Gene not in testcode logic added
# 3 - HRR analysis compatible

# Analyst
$Analyst = "Vinayak Rao";
# Annotation Databases path (Update this to the path of databases on your system)
$db_path = "/bioinfo-data/Vinayak/Databases/";

# Annotation Databases files (Download latest version from 172.16.3.52:/rawdata/Databases/Annotation_Databases_and_Scripts).
$Genomes1000=$db_path."1000Genomes.txt"; # Change filename as per version
$PredictSNPdb=$db_path."PredictSNP2.txt"; # Change filename as per version
$blacklistdb=$db_path."DCGL_blacklisted_variants.txt"; # Change filename as per version
$uncovereddb=$db_path."DCGL_panel_amplicons_gene_exon_codons.txt"; # Change filename as per version
$germlinedb=$db_path."probable_germline_variants.txt"; # Change filename as per version
$COSMIC_SNP_Flag=$db_path."SNP_Flag_in_COSMIC.txt"; # Change filename as per version
$actionable=$db_path."actionable_variants_db.txt";
$clinvar_db=$db_path."DCGL_ClinVar.txt";
$checklist_db=$db_path."DCGL_Checklist_07072022.txt";

###################  Ion Reporter Workflow  ##################################
%workflows_cfTNA = ('omPAN' => 'Oncomine TagSeq Pan-Cancer Liquid Biopsy - w2.4 - Single Sample r.0', 'omLUNG' => 'Oncomine TagSeq Lung v2 Liquid Biopsy - w2.4 - Single Sample r.0', 'GBMHD' => 'GBMHD (GlioACT) for Liquid Biopsy w2.1 - DNA - Single Sample r.0');

%workflows_tumor = ('OCAv3' => 'Oncomine Comprehensive v3 - w4.1 DNA and Fusions - Single Sample r.0', 'omPAN' => 'Oncomine TagSeq Pan-Cancer Tumor w2.4 - Single Sample r.0', 'omLUNG' => 'Oncomine TagSeq Lung v2 Tumor - w2. 4 - Single Sample r.0', 'OCAPlus' => 'Oncomine Comprehensive Plus - w2.1 DNA - Single Sample r.0', 'omBRCA' => 'Oncomine BRCA Research Somatic 530 - w3.5 - DNA - Single Sample r.0', 'HRR' => 'HRR Pathway Oncomine - 540 - w4.1 DNA - Single Sample r.0');

%workflows_gDNA = ('omBRCA' => 'Oncomine BRCA Research Germline 530 - w3.5 - DNA - Single Sample r.0');

###################  Ion Reporter Workflow END ##################################
# Target Region Files (designed.bed)
%target_files = ('OCAv3' =>  'OCAv3.20170110.designed', 'omPAN' =>  'Oncomine_PANCAN_cfNA_v5.Designed', 'omLUNG' =>  'Oncomine_Lung_cfNA.08212017.Designed', 'GBMHD' => 'GBMHD_GlioACT_IAH179810_374_Designed', 'OCAPlus' => 'OCAPlus.20191203.designed', 'omBRCA' => 'Oncomine_BRCA_Research_Assay.20160503.Designed', 'HRR' => 'Oncomine_HRR_Pathway_Predesigned.20201229_Designed');

# Number of Genes in Panel
%panel_genes = ('OCAv3' => '161 Genes', 'omPAN' => '52 Genes', 'omLUNG' => '12 Genes', 'GBMHD' => '15 Genes', 'OCAPlus' => '511 Genes','omBRCA' => '2 Genes','HRR' => '28 Genes');

###################  Gene List ##################################
%genelist = ('ABCB1' => '12', 'ABL1' => '12', 'ABL2' => '12', 'ABRAXAS1' => '12', 'ACVR1' => '1', 'ACVR1B' => '12', 'ACVR2A' => '12', 'ADAMTS12' => '12', 'ADAMTS2' => '12', 'AKT1' => '12', 'AKT2' => '12', 'AKT3' => '12', 'ALK' => '12', 'AMER1' => '12', 'APC' => '12', 'AR' => '12', 'ARAF' => '12', 'ARHGAP35' => '12', 'ARID1A' => '12', 'ARID1B' => '12', 'ARID2' => '12', 'ARID5B' => '12', 'ASXL1' => '12', 'ASXL2' => '12', 'ATM' => '12', 'ATP1A1' => '1', 'ATR' => '12', 'ATRX' => '12', 'AURKA' => '12', 'AURKC' => '12', 'AXIN1' => '12', 'AXIN2' => '12', 'AXL' => '12', 'B2M' => '12', 'BAP1' => '12', 'BARD1' => '12', 'BCL2' => '12', 'BCL2L12' => '1', 'BCL6' => '12', 'BCOR' => '12', 'BCR' => '12', 'BLM' => '12', 'BMP5' => '1', 'BMPR2' => '12', 'BRAF' => '12', 'BRCA1' => '12', 'BRCA2' => '12', 'BRIP1' => '12', 'BTK' => '12', 'CACNA1D' => '1', 'CALR' => '12', 'CARD11' => '12', 'CASP8' => '12', 'CBFB' => '12', 'CBL' => '12', 'CCND1' => '12', 'CCND2' => '12', 'CCND3' => '12', 'CCNE1' => '12', 'CD274' => '12', 'CD276' => '12', 'CD79B' => '12', 'CDC73' => '12', 'CDH1' => '12', 'CDH10' => '12', 'CDK12' => '12', 'CDK4' => '12', 'CDK6' => '12', 'CDKN1A' => '12', 'CDKN1B' => '12', 'CDKN2A' => '12', 'CDKN2B' => '12', 'CDKN2C' => '12', 'CHD4' => '1', 'CHEK1' => '12', 'CHEK2' => '12', 'CIC' => '12', 'CIITA' => '12', 'CREBBP' => '12', 'CSF1R' => '12', 'CSMD3' => '12', 'CTCF' => '12', 'CTLA4' => '12', 'CTNNB1' => '12', 'CTNND2' => '12', 'CUL1' => '12', 'CUL3' => '12', 'CUL4A' => '12', 'CUL4B' => '12', 'CYLD' => '12', 'CYP2C9' => '12', 'CYP2D6' => '12', 'CYSLTR2' => '12', 'DAXX' => '12', 'DDR1' => '12', 'DDR2' => '12', 'DDX3X' => '12', 'DGCR8' => '1', 'DICER1' => '12', 'DNMT3A' => '12', 'DOCK3' => '12', 'DPYD' => '12', 'DROSHA' => '1', 'DSC1' => '12', 'DSC3' => '12', 'E2F1' => '1', 'EGFR' => '12', 'EIF1AX' => '1', 'ELF3' => '12', 'EMSY' => '12', 'ENO1' => '12', 'EP300' => '12', 'EPAS1' => '1', 'EPCAM' => '12', 'EPHA2' => '12', 'ERAP1' => '12', 'ERAP2' => '12', 'ERBB2' => '12', 'ERBB3' => '12', 'ERBB4' => '12', 'ERCC2' => '12', 'ERCC4' => '12', 'ERCC5' => '12', 'ERG' => '12', 'ERRFI1' => '12', 'ESR1' => '12', 'ETV1' => '12', 'ETV4' => '12', 'ETV5' => '12', 'ETV6' => '12', 'EZH2' => '12', 'FAM135B' => '12', 'FANCA' => '12', 'FANCC' => '12', 'FANCD2' => '12', 'FANCE' => '12', 'FANCF' => '12', 'FANCG' => '12', 'FANCI' => '12', 'FANCL' => '12', 'FANCM' => '12', 'FAS' => '12', 'FAT1' => '12', 'FBXW7' => '12', 'FGF19' => '12', 'FGF23' => '12', 'FGF3' => '12', 'FGF4' => '12', 'FGF7' => '1', 'FGF9' => '1', 'FGFR1' => '12', 'FGFR2' => '12', 'FGFR3' => '12', 'FGFR4' => '12', 'FGR' => '12', 'FLT3' => '12', 'FLT4' => '12', 'FOXA1' => '12', 'FOXL2' => '12', 'FOXO1' => '12', 'FUBP1' => '12', 'FYN' => '12', 'GATA2' => '12', 'GATA3' => '12', 'GLI1' => '12', 'GLI3' => '12', 'GNA11' => '12', 'GNA13' => '12', 'GNAQ' => '12', 'GNAS' => '12', 'GPS2' => '12', 'H3F3A' => '12', 'H3F3B' => '12', 'HDAC2' => '12', 'HDAC9' => '12', 'HIF1A' => '12', 'HIST1H2BD' => '1', 'HIST1H3B' => '12', 'HLA-A' => '12', 'HLA-B' => '12', 'HNF1A' => '12', 'HRAS' => '12', 'ID3' => '12', 'IDH1' => '12', 'IDH2' => '12', 'IGF1R' => '12', 'IKBKB' => '12', 'IL6ST' => '12', 'IL7R' => '12', 'INPP4B' => '12', 'IRF4' => '12', 'IRS4' => '1', 'JAK1' => '12', 'JAK2' => '12', 'JAK3' => '12', 'KDM5C' => '12', 'KDM6A' => '12', 'KDR' => '12', 'KEAP1' => '12', 'KIT' => '12', 'KLF4' => '1', 'KLF5' => '12', 'KLHL13' => '12', 'KMT2A' => '12', 'KMT2B' => '12', 'KMT2C' => '12', 'KMT2D' => '12', 'KNSTRN' => '12', 'KRAS' => '12', 'LARP4B' => '12', 'LATS1' => '12', 'LATS2' => '12', 'MAGOH' => '12', 'MAP2K1' => '12', 'MAP2K2' => '12', 'MAP2K4' => '12', 'MAP2K7' => '12', 'MAP3K1' => '12', 'MAP3K4' => '12', 'MAPK1' => '12', 'MAPK8' => '12', 'MAX' => '12', 'MCL1' => '12', 'MDM2' => '12', 'MDM4' => '12', 'MECOM' => '12', 'MED12' => '12', 'MEF2B' => '12', 'MEN1' => '12', 'MET' => '12', 'MGA' => '12', 'MITF' => '12', 'MLH1' => '12', 'MLH3' => '12', 'MPL' => '12', 'MRE11' => '12', 'MSH2' => '12', 'MSH3' => '12', 'MSH6' => '12', 'MTAP' => '12', 'MTOR' => '12', 'MTUS2' => '12', 'MUTYH' => '12', 'MYB' => '12', 'MYBL1' => '12', 'MYC' => '12', 'MYCL' => '12', 'MYCN' => '12', 'MYD88' => '12', 'MYOD1' => '1', 'NBN' => '12', 'NCOR1' => '12', 'NF1' => '12', 'NF2' => '12', 'NFE2L2' => '12', 'NOTCH1' => '12', 'NOTCH2' => '12', 'NOTCH3' => '12', 'NOTCH4' => '12', 'NRAS' => '12', 'NRG1' => '12', 'NSD2' => '1', 'NT5C2' => '12', 'NTRK1' => '12', 'NTRK2' => '12', 'NTRK3' => '12', 'NUP93' => '1', 'NUTM1' => '12', 'PALB2' => '12', 'PARP1' => '12', 'PARP2' => '12', 'PARP3' => '12', 'PARP4' => '12', 'PAX5' => '12', 'PBRM1' => '12', 'PCBP1' => '12', 'PDCD1' => '12', 'PDCD1LG2' => '12', 'PDGFRA' => '12', 'PDGFRB' => '12', 'PDIA3' => '12', 'PGD' => '12', 'PHF6' => '12', 'PIK3C2B' => '12', 'PIK3CA' => '12', 'PIK3CB' => '12', 'PIK3CD' => '12', 'PIK3CG' => '12', 'PIK3R1' => '12', 'PIK3R2' => '12', 'PIM1' => '12', 'PLCG1' => '12', 'PMS1' => '12', 'PMS2' => '12', 'POLD1' => '12', 'POLE' => '12', 'POT1' => '12', 'PPARG' => '12', 'PPM1D' => '12', 'PPP2R1A' => '12', 'PPP2R2A' => '12', 'PPP6C' => '1', 'PRDM1' => '12', 'PRDM9' => '12', 'PRKACA' => '12', 'PRKACB' => '12', 'PRKAR1A' => '12', 'PSMB10' => '12', 'PSMB8' => '12', 'PSMB9' => '12', 'PTCH1' => '12', 'PTEN' => '12', 'PTPN11' => '12', 'PTPRD' => '12', 'PTPRT' => '12', 'PXDNL' => '12', 'RAC1' => '12', 'RAD50' => '12', 'RAD51' => '12', 'RAD51B' => '12', 'RAD51C' => '12', 'RAD51D' => '12', 'RAD52' => '12', 'RAD54L' => '12', 'RAF1' => '12', 'RARA' => '12', 'RASA1' => '12', 'RASA2' => '12', 'RB1' => '12', 'RBM10' => '12', 'RECQL4' => '12', 'RELA' => '12', 'RET' => '12', 'RGS7' => '1', 'RHEB' => '12', 'RHOA' => '12', 'RICTOR' => '12', 'RIT1' => '12', 'RNASEH2A' => '12', 'RNASEH2B' => '12', 'RNASEH2C' => '12', 'RNF43' => '12', 'ROS1' => '12', 'RPA1' => '12', 'RPL10' => '1', 'RPL22' => '12', 'RPL5' => '12', 'RPS6KB1' => '12', 'RPTOR' => '12', 'RSPO2' => '12', 'RSPO3' => '12', 'RUNX1' => '12', 'RUNX1T1' => '12', 'SDHA' => '12', 'SDHB' => '12', 'SDHC' => '12', 'SDHD' => '12', 'SETBP1' => '1', 'SETD2' => '12', 'SF3B1' => '12', 'SIX1' => '1', 'SIX2' => '1', 'SLCO1B3' => '12', 'SLX4' => '12', 'SMAD2' => '12', 'SMAD4' => '12', 'SMARCA4' => '12', 'SMARCB1' => '12', 'SMC1A' => '1', 'SMO' => '12', 'SNCAIP' => '12', 'SOCS1' => '12', 'SOS1' => '1', 'SOX2' => '12', 'SOX9' => '12', 'SPEN' => '12', 'SPOP' => '12', 'SRC' => '12', 'SRSF2' => '1', 'STAG2' => '12', 'STAT1' => '12', 'STAT3' => '12', 'STAT5B' => '1', 'STAT6' => '12', 'STK11' => '12', 'SUFU' => '12', 'TAF1' => '12', 'TAP1' => '12', 'TAP2' => '12', 'TBX3' => '12', 'TCF7L2' => '12', 'TERT' => '12', 'TET2' => '12', 'TGFBR1' => '1', 'TGFBR2' => '12', 'TMEM132D' => '12', 'TNFAIP3' => '12', 'TNFRSF14' => '12', 'TOP1' => '12', 'TP53' => '12', 'TP63' => '12', 'TPMT' => '12', 'TPP2' => '12', 'TRRAP' => '12', 'TSC1' => '12', 'TSC2' => '12', 'TSHR' => '12', 'U2AF1' => '12', 'UGT1A1' => '12', 'USP8' => '12', 'USP9X' => '12', 'VHL' => '12', 'WAS' => '12', 'WT1' => '12', 'XPO1' => '12', 'XRCC2' => '12', 'XRCC3' => '12', 'YAP1' => '12', 'YES1' => '12', 'ZBTB20' => '12', 'ZFHX3' => '12', 'ZMYM3' => '12', 'ZNF217' => '12', 'ZNF429' => '12', 'ZRSR2' => '12', 'MRE11A' => '12');
###################  Gene List END ##################################
#checklist_options
%checklist_options = ('1'=>'Non-Small Cell Lung (NSCLC)','2'=>'Breast','3'=>'Ampullary Adenocarcinoma/ Pancreatic Adenocarcinoma','4'=>'Central Nervous System (CNS)','5'=>'Colon (Appendiceal Adenocarcinoma)/ Rectal (CRC)','6'=>'Gastrointestinal Stromal Tumors (GIST)','7'=>'Prostate/ Ovarian/ Fallopian Tube/ Primary Peritoneal','8'=>'Thyroid Carcinoma','9'=>'Salivary gland tumors','10'=>'Bone','11'=>'Kidney','12'=>'Uterine Sarcoma','13'=>'Hepatobiliary','14'=>'Melanoma-Cutaneous','15'=>'Malignant Pleural Mesothelioma/ Malignant Peritoneal Mesothelioma','16'=>'Endometrial Carcinoma','17'=>'Head and Neck/ Esophageal and Esophagogastric Junction/ Gastric','18'=>'Bladder  (urothelial)','19'=>'Melanoma-Uveal','20'=>'Small Bowel Adenocarcinoma','21'=>'Others (Anal Carcinoma/ Cervical/ Neuroendocrine and Adrenal Tumors/ Occult Primary (unknown primary)/ Small Cell Lung/ Soft Tissue Sarcoma/ Thymomas and Thymic Carcinomas/ Vulvar Cancer)');


# Current date

$date = strftime "%d-%m-%Y", localtime;
$time = strftime "%I:%M %p", localtime;

my $cwd = cwd();
$foldername=`basename $cwd `;
chomp $foldername;

@foldername2= split('-',$foldername);

chomp $foldername2[5];

###################  Software/Pipeline Versions ##################################
$IR_version = "Ion Reporter v5.16"; #IonReporter Version
$BiVA_version = "BiVA_v1.0 (Bioinformatics Variant Annotation database)"; # BiVA version
#$dbSNP_version = "dbSNP build 153"; # QCIT/Ingenuity provided dbSNP version
#$Clinvar_version = "Clinvar 2020-09-15"; # QCIT/Ingenuity provided Clinvar version
#$COSMIC_version = "COSMIC v92"; # QCIT/Ingenuity provided COSMIC version
#$HGMD_version =  "HGMD 2020.3"; # QCIT/Ingenuity provided HGMD version
$COSMIC_version_fusion = "COSMIC v84"; # IR provided COSMIC version
#Paramaters
$soft_param_omPAN = "tagseq_pancancer_liquidbiopsy"; # SOFTWARE PARAMETERS - tagseq_pancancer_liquidbiopsy
$soft_param_omLUNG_liquidbiopsy = "tagseq_lung_liquidbiopsy"; # SOFTWARE PARAMETERS - tagseq_lung_liquidbiopsy
$soft_param_omLUNG_tumor = "tagseq_lung_tumor"; # SOFTWARE PARAMETERS - tagseq_lung_tumor
$soft_param_OCAv3 = "OCAv3 Somatic Low Stringency"; # SOFTWARE PARAMETERS - OCAv3
$soft_param_OCAPlus = "Oncomine Comprehensive Plus - w2.1 - DNA - Single Sample"; # SOFTWARE PARAMETERS - OCAPlus
$soft_param_omBRCA_somatic = "Oncomine BRCA Research Somatic - 530 - w3.4 - DNA - Single Sample"; # SOFTWARE PARAMETERS - omBRCA
$soft_param_omBRCA_germline = "Oncomine BRCA Research Germline - 530 - w3.5 - DNA - Single Sample"; # SOFTWARE PARAMETERS - omBRCA
$soft_param_HRR = "HRR Pathway Oncomine - 540 - w4.1 - DNA - Single Sample"; # SOFTWARE PARAMETERS - HRR
#pipelines
if ($foldername2[5] == 51 || $foldername2[5] == 53) # for 51 IND server or 53 UK server
{
$TMAP_version = "TMAP v5.14"; # ALIGNER version
$TVC_version = "TVC v5.14"; # Torrent VARIANT CALLER version
$pipeline_omPAN = "DCGL NGS Bioinformatics Pipeline vP11.9"; # NGS Pipeline - Oncomine TagSeq Pan (omPAN)
$pipeline_omLUNG = "DCGL NGS Bioinformatics Pipeline vP12.9"; # NGS Pipeline Oncomine TagSeq Lung (omLUNG)
$pipeline_DNA_OCAv3 = "DCGL NGS Bioinformatics Pipeline vP9.9"; # NGS Pipeline - OCAv3 DNA
$pipeline_RNA_fusion_OCAv3 = "DCGL NGS Bioinformatics Pipeline vP10.3"; #NGS Pipeline - OCAv3 Fusion
$pipeline_OCAPlus = "DCGL NGS Bioinformatics Pipeline vP15.1"; # NGS Pipeline - OCAPlus
$pipeline_omBRCA_somatic = "DCGL NGS Bioinformatics Pipeline vP16.1"; # NGS Pipeline - omBRCA somatic
$pipeline_omBRCA_germline = "DCGL NGS Bioinformatics Pipeline vP17.1"; # NGS Pipeline - omBRCA germline
$pipeline_HRR = "DCGL NGS Bioinformatics Pipeline vP18.1"; # NGS Pipeline - HRR
}
else
{
$TMAP_version = "TMAP v5.16"; # ALIGNER version
$TVC_version = "TVC v5.16"; # Torrent VARIANT CALLER version
$pipeline_omPAN = "DCGL NGS Bioinformatics Pipeline vP11.10"; # NGS Pipeline - Oncomine TagSeq Pan (omPAN)
$pipeline_omLUNG = "DCGL NGS Bioinformatics Pipeline vP12.10"; # NGS Pipeline Oncomine TagSeq Lung (omLUNG)
$pipeline_DNA_OCAv3 = "DCGL NGS Bioinformatics Pipeline vS9.10"; # NGS Pipeline - OCAv3 DNA
$pipeline_RNA_fusion_OCAv3 = "DCGL NGS Bioinformatics Pipeline vS10.4"; #NGS Pipeline - OCAv3 Fusion
$pipeline_OCAPlus = "DCGL NGS Bioinformatics Pipeline vS15.2"; # NGS Pipeline - OCAPlus
$pipeline_omBRCA_somatic = "DCGL NGS Bioinformatics Pipeline vP16.2"; # NGS Pipeline - omBRCA somatic
$pipeline_omBRCA_germline = "DCGL NGS Bioinformatics Pipeline vP17.2"; # NGS Pipeline - omBRCA germline
$pipeline_HRR = "DCGL NGS Bioinformatics Pipeline vS18.2"; # NGS Pipeline - HRR
}
#CNA_baselines
$CNA_baseline_omPAN = "Oncomine Pan-Cancer Assay Baseline v1.2"; # CNA baseline - omPAN - Somatic
$CNA_baseline_omLUNG = "Oncomine TagSeq Lung v2 Assay Baseline v2.0"; # CNA baseline - omLUNG - Somatic
$CNA_baseline_DNA_OCAv3 = "Oncomine Comprehensive DNA v3 540 Assay Baseline v2.1";# CNA baseline - OCAv3 - Somatic
$CNA_baseline_OCAPlus = "Oncomine Comprehensive Plus DNA 550 Baseline v2.0";# CNA baseline - OCAPlus - Somatic
$CNA_baseline_omBRCA = "Oncomine BRCA DNA Baseline v2.1";# CNA baseline - omBRCA - Somatic/Germline
$CNA_baseline_HRR = "NA";# CNA baseline - HRR
###################  Software/Pipeline Versions END ##################################

print "Sample sequenced in? (IND/UK)\t\t:";
$site = <STDIN>;
chomp $site;
if ($site ne "IND" && $site ne "UK")
{print "We don't sequence samples in $site, Please put a valid site code\n";
exit;
}

if ($foldername2[1] eq "OCAPlus")
	{
		print "Is this a TumorInsight Plus test code DCG-084? (Y/N):";
		$tc = <STDIN>;
			chomp $tc;
		if (($tc eq "Y") || ($tc eq "y") || ($tc eq "2"))
			{
			$Testcode = 2;
			}
		else
			{
			$Testcode = 1;
			}
	}
else
	{
		$Testcode = 0;
	}
print "\nWhat is the Cancer Type? select checklist CODE for Cancer Type of this sample...\n0 : No Checklist\n1 : Non-Small Cell Lung (NSCLC)\n2 : Breast\n3 : Ampullary Adenocarcinoma/ Pancreatic Adenocarcinoma\n4 : Central Nervous System (CNS)\n5 : Colon (Appendiceal Adenocarcinoma)/ Rectal (CRC)\n6 : Gastrointestinal Stromal Tumors (GIST)\n7 : Prostate/ Ovarian/ Fallopian Tube/ Primary Peritoneal\n8 : Thyroid Carcinoma\n9 : Salivary gland tumors\n10 : Bone\n11 : Kidney\n12 : Uterine Sarcoma\n13 : Hepatobiliary\n14 : Melanoma-Cutaneous\n15 : Malignant Pleural Mesothelioma/ Malignant Peritoneal Mesothelioma\n16 : Endometrial Carcinoma\n17 : Head and Neck/ Esophageal and Esophagogastric Junction/ Gastric\n18 : Bladder  (urothelial)\n19 : Melanoma-Uveal\n20 : Small Bowel Adenocarcinoma\n21 : Others (Anal Carcinoma/ Cervical/ Neuroendocrine and Adrenal Tumors/ Occult Primary (unknown primary)/ Small Cell Lung/ Soft Tissue Sarcoma/ Thymomas and Thymic Carcinomas/ Vulvar Cancer)\nCode : ";
$cancer_type = <STDIN>;
chomp $cancer_type;

# Remove if previous folders and files are already exist

if (-f "$foldername-log.txt") {
    `rm -rf $foldername-log.txt`;
}
if($site eq "IND")
{
	if (-d "QC") {
		`rm -rf QC`;
	}

	if (-d "Variants") {
		`rm -rf Variants`;
	}

	if (-d "Workflow_Settings") {
		`rm -rf Workflow_Settings`;
	}

	if (-d "CNV_VCIB") {
		`rm -rf CNV_VCIB`;
	}

	if (-d "$foldername-coverageAnalysisReport") {
		`rm -r $foldername-coverageAnalysisReport`;
	}

	if (-f "fusions_RNAExonVariants_normCounts.png") {
		`rm -r fusions_RNAExonVariants_normCounts.png`;
	}
}

#Usage of software
sub usage {
        print <<EOF;

#############################################################################################################################################
#############################################################################################################################################
   														 
	Annotation	: Variant Annotation Script for Oncomine Panels						 
	Version		: $version									 
														 
	This script is developed by Vipul Todarwal for annotation of somatic samples of Oncomine panels in DCGL, maintained by Harshal Darokar.	

    NOTE: Kinly install required perl modules used at top of the script and update databases section with 
          local system path.
														 
#############################################################################################################################################
#############################################################################################################################################


Usage: perl PATH/TO/SCRIPT.pl input_Ion_Reporter_file_All.zip


EOF
 
}


#Commandline variables
my ($help);

#### get options
GetOptions(
                "h\|help"   => \$help
          );

usage() and exit(1) if $help;

$fname=$ARGV[0];
`unzip $fname`;

usage() and exit(1) unless $fname;



$basename1=`basename Variants/*`;
chomp $basename1;
$basename2=`basename Variants/*/*oncomine.tsv`;
$basename3=`basename Variants/*/*-full.tsv`;

`sed -i 's/"//g' Variants/$basename1/$basename2`;

unless(open(I,"Variants/$basename1/$basename2")){
print "\n\nCan't open file Variants/$basename1/$basename2\n\n";
}

@data=<I>;

close(I);


@IRheader = grep { /rowtype/ } @data;
chomp $IRheader[0];


unless(open(C,"Variants/$basename1/$basename3")){
print "\n\nCan't open file Variants/$basename1/$basename3";
}

@CNVdata=<C>;
shift @CNVdata;

close(C);

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

# Header field index

$header= first_index { $_ =~ m/vcf.rownum/ } @data;

$rawheader=$data[$header];
@rawheaderelements=split('\t',$rawheader);
$rawheadersize=scalar@rawheaderelements;

$rowtype=first_index { $_ eq 'rowtype' } @rawheaderelements;
$filter=first_index { $_ eq 'FILTER' } @rawheaderelements;
$var_id=first_index { $_ eq 'ID' } @rawheaderelements;
$IRchr=first_index {$_ eq 'CHROM'} @rawheaderelements;
$IRpos=first_index {$_ eq 'INFO...OPOS'} @rawheaderelements;
$IRref=first_index {$_ eq 'INFO...OREF'} @rawheaderelements;
$IRalt=first_index {$_ eq 'INFO...OALT'} @rawheaderelements;
$GT=first_index { $_ eq 'FORMAT.1.GT' } @rawheaderelements;
$GT1=$GT+2;
$AF=first_index { $_ eq 'FORMAT.A.AF' } @rawheaderelements;
$AF1=$AF+2;
$LOD=first_index { $_ eq 'INFO.A.LOD' } @rawheaderelements;
$LOD1=$LOD+2;
$MolCount=first_index { $_ eq 'INFO...MOL_COUNT' } @rawheaderelements;
$ID=first_index { $_ eq 'ID' } @rawheaderelements;
$ReadCount=first_index { $_ eq 'INFO...READ_COUNT' } @rawheaderelements;
$IRFDP=first_index { $_ eq 'FORMAT.1.FDP' } @rawheaderelements;
$IRFAO=first_index { $_ eq 'FORMAT.A.FAO' } @rawheaderelements;
$GENE=first_index { $_ eq 'FUNC1.gene' } @rawheaderelements;
$GENE1=$GENE+2;
$PROTEIN=first_index { $_ eq 'FUNC1.protein' } @rawheaderelements;
$PROTEIN1=$PROTEIN+2;
$COSF=first_index { $_ eq 'INFO.1.ANNOTATION' } @rawheaderelements;
$header2= first_index { $_ =~ m/iscn/ } @CNVdata;
$rawheader2=$CNVdata[$header2];
@rawheaderelements2=split('\t',$rawheader2);
$iscn=first_index { $_ eq 'iscn' } @rawheaderelements2;
$filter2=first_index { $_ eq 'filter' } @rawheaderelements2;
$cnv_locus=first_index { $_ eq '# locus' } @rawheaderelements2;
$cnv_length=first_index { $_ eq 'length' } @rawheaderelements2;
$type=first_index { $_ eq 'type' } @rawheaderelements2;
$marker=first_index { $_ eq 'gene' } @rawheaderelements2;
$cnv_st=first_index { $_ eq 'Subtype' } @rawheaderelements2;
$cnv_call=first_index { $_ eq 'Call' } @rawheaderelements2;
$oncomineGeneClass=first_index { $_ =~ m/Oncomine Variant Annotator v/ } @rawheaderelements2;
$no_call_reason=first_index { $_ eq 'no_call_reason' } @rawheaderelements2;


open (STDOUT, "| tee -ai $foldername-log.txt");

print <<EOF;

##############################################################################################################################################################################

   Annotation	: Variant Annotation Script
   Version	: $version
   Location	: $Bin

##############################################################################################################################################################################

Analyst: $Analyst			Date: $date			Time: $time
EOF

print "\n\n\nCurrent location\t\t:\t$cwd\n";

$folder=`basename $cwd`;
chomp$folder;

print "\n\t\t\t\t\tSample ID\t:\t$foldername2[0]";
print "\n\t\t\t\t\tPanel\t\t:\t$foldername2[1]";
print "\n\t\t\t\t\tSample Type\t:\t$foldername2[2]";
print "\n\t\t\t\t\tBarcode\t\t:\t$foldername2[3]";
print "\n\t\t\t\t\tRun\t\t:\t$foldername2[4]";
print "\n\t\t\t\t\tServer\t\t:\t$foldername2[5]";


print "\n\n\nInput IR zip file\t\t:\t$fname\n";


# Check file name of All.zip file

if ($fname ne "$foldername-All.zip")
{
	print "\n\nInput IR zip file name is incorrect\n";
	exit;
}


# Check Sample ID with the file Name:

`mv QC/*_QC.pdf QC/$folder-QC.pdf`;

`pdftotext QC/$folder-QC.pdf`;

$SID=$foldername2[0]."_v";
$BID=$foldername2[3];

$match = `grep "$BID\$" QC/$folder-QC.txt`;
$match2 = `grep "$SID" QC/$folder-QC.txt`;


if (($match eq "") && ($match2 eq ""))
{
print "\n\nSample ID checking\t\t:\tSample Id and Barcode not matching with the downloaded All.Zip file. Do you want to proceed? (y/n) : \n";
		$choice_1 = <STDIN>;
		chomp $choice_1;

			if ($choice_1 =~ /n/i)
			{
				exit;
			}
}
else
{
print "\n\nSample ID checking\t\t:\tSample Id and Barcode match with the downloaded All.Zip file";
}


# Get IR Server IP
print "\n\nEnter IR server (57 | 91 | 92 | 93 | 94)\t:\t";
$IRserver = <STDIN>;

chomp $IRserver;

print "\n\nYou entered Ion Reporter server\t:\t$IRserver";


# Get ethnicity of the patient from user
if ($foldername2[2] =~ m/[DT]NA/)
{
    print "\n\nList of available Ethnicities\t:\n\t\t\t\t\tEAS\n\t\t\t\t\tSAS\n\t\t\t\t\tAFR\n\t\t\t\t\tEUR\n\t\t\t\t\tAMR\n";
    print "\nSelect the Ethnicity from above\t:\t";
    $ethnicity = <STDIN>;
    chomp $ethnicity;

    print "\nYou selected ethnicity\t\t:\t$ethnicity\n";

    if (lc $ethnicity ne lc 'EAS' && lc $ethnicity ne lc 'SAS' && lc $ethnicity ne lc 'AFR' && lc $ethnicity ne lc 'EUR' && lc $ethnicity ne lc 'AMR')
    {
        print "\n\nEthnicity is not correct.\n\n";
        exit();
    }

    unless(open(IN,"$foldername-BiVA.tsv")){
    print "\n\nCan't open file $foldername-BiVA.tsv\n\n";
    exit;
    }

    @IngenuityORI=<IN>;

    close(IN);

    $INheader=shift@IngenuityORI;

}

unless(open(CLINVAR,$clinvar_db)){
print "\n\nCan't open file $clinvar_db\n\n";
}

@ClinVar_data=<CLINVAR>;

close(CLINVAR);

unless(open(O,">$foldername-BiVA_IR.txt")){
print "\n\nCan't write file $foldername-BiVA_IR.txt\n\n";
}

print O $IRheader[0]."\t".$INheader;

unless(open(R,">$foldername-BiVA_rearranged.txt")){
print "\n\nCan't write file $foldername-BiVA_rearranged.txt\n\n";
}
=head
############################################################################ IR Workflow QC Start ############################################################################
#`mv QC/*_QC.pdf QC/$folder-QC.pdf`;

#`pdftotext QC/$folder-QC.pdf`;


$workflow=`grep -A 2 "Workflow" QC/$folder-QC.txt | grep -v "Workflow" | sed -z 's/\\n/ /g'`;
$workflow;

$workflow =~ s/^\s+//;
$workflow =~ s/\s+$//;


print "\n\nIR Oncomine workflow used\t:\t$workflow\n";

if ($foldername2[2] =~ m/cfTNA/)
{
    if ($workflow ne $workflows_cfTNA{$foldername2[1]})
    {
        print "\n\nOncomine workflow is wrong. It Should be - \"$workflows_cfTNA{$foldername2[1]}\"\n\n";

        print "\n\n\n************************************************************** Sample Analysis Failed Due To Wrong IR Workflow **************************************************************\n\n\n";

        exit;
    }
}

elsif ($foldername2[2] =~ m/RNA/)
{

    if ($workflow ne $workflows_tumor{$foldername2[1]})
    {

        if ($workflow ne 'Oncomine Comprehensive v3 - w4.1 Fusions - Single Sample r.0')
        {
        
            print "\n\nOncomine workflow is wrong. It Should be either - $workflows_tumor{$foldername2[1]} \n\n\t\t\t\t\t\t\tOR\n\n\t\t\t\t\t\t\tOncomine Comprehensive v3 - w3.2 Fusions - Single Sample r.0";

            print "\n\n\n************************************************************** Sample Analysis Failed Due To Wrong IR Workflow **************************************************************\n\n\n";

            exit;
        }
    }

}

elsif ($foldername2[1] =~ m/OCAv3/ && $foldername2[2] =~ m/[DT]NA/)
{

    if ($workflow ne $workflows_tumor{$foldername2[1]})
    {
        if ($workflow ne 'Oncomine Comprehensive v3 - w4.1 DNA - Single Sample r.0')
        {
            print "\n\nOncomine workflow is wrong. It Should be either\t:\t$workflows_tumor{$foldername2[1]} \n\n\t\t\t\t\t\t\tOR\n\n\t\t\t\t\t\t\tOncomine Comprehensive v3 - w3.2 DNA - Single Sample r.0";

            print "\n\n\n************************************************************** Sample Analysis Failed Due To Wrong IR Workflow **************************************************************\n\n\n";

            exit;
        }
    }
}

elsif ($foldername2[1] =~ m/omBRCA/ && $foldername2[2] =~ m/gDNA/)
{

    if ($workflow ne $workflows_gDNA{$foldername2[1]})
    {
       # if ($workflow ne 'Oncomine BRCA Research Germline - 530 - w3.5 - DNA - Single Sample r. 0')
        #{
            print "\n\nOncomine workflow is wrong. It Should be either\t:\t$workflows_gDNA{$foldername2[1]} \n\n";

            print "\n\n\n************************************************************** Sample Analysis Failed Due To Wrong IR Workflow **************************************************************\n\n\n";

            exit;
       # }
    }
}


else
{
    if ($workflow ne $workflows_tumor{$foldername2[1]})
    {
        print "\n\nOncomine workflow is wrong. It Should be $workflows_tumor{$foldername2[1]}";

        print "\n\n\n************************************************************** Sample Analysis Failed Due To Wrong IR Workflow **************************************************************\n\n\n";

        exit;
    }
}

############################################################################# IR Workflow QC End #############################################################################
=cut
#########################################################################  Server Data Retrival Start  #######################################################################
if ($site eq "IND")
{
print "\n\nServer data retrival\t\t:\t";


@run_names=`sshpass -p '$ionpass' ssh $ionusr\@172.16.3.52 "ls /torrentsuite/172.16.3.$foldername2[5] | grep "$foldername2[4]" | grep -v "_tn_"" `;


if (scalar@run_names > 1)
{
	print scalar@run_names," runs found\n\n";

	for ($r=0; $r<scalar@run_names; $r++)
	{
	print $r+1," : $run_names[$r]";
	}
	print "\nEnter 1 run name from above\t\t:\t";
	$run_choice = <STDIN>;
	chomp $run_choice;
	$run_name=$run_choice;

	print "\nYou entered run\t\t:\t$run_name\n\nServer data retrival\t\t:\t";
}

else
{
	$run_name=$run_names[0];
}

chomp $run_name;

`sshpass -p '$ionpass' ssh $ionusr\@172.16.3.52 sshpass -p '$pass' rsync -r --exclude={*bam*,*auxiliary*} /torrentsuite/172.16.3.$foldername2[5]/$run_name/basecaller_results/datasets_basecaller.json /torrentsuite/172.16.3.$foldername2[5]/$run_name/$foldername2[3]_rawlib.ionstats_alignment.json $user\@$ip:$cwd `;

`sshpass -p '$ionpass' ssh $ionusr\@172.16.3.52 test -f "/torrentsuite/172.16.3.$foldername2[5]/$run_name/plugin_out/sampleID_out*/$foldername2[3]/read_stats.txt && sshpass -p '$pass' rsync -r /torrentsuite/172.16.3.$foldername2[5]/$run_name/plugin_out/sampleID_out*/$foldername2[3]/read_stats.txt" $user\@$ip:$cwd `;


if (-d "$foldername-coverageAnalysisReport") { # remove "coverageAnalysisReport" folder if already exist
    `rm -r $foldername-coverageAnalysisReport`;
}

if (-d "$foldername-CnvActor") {  # Remove "CnvActor" folder if already exist
    `rm -r $foldername-CnvActor`;
}


if ($foldername2[2] =~ m/[DT]NA/)
{

    $IR_path=`grep "qcmodule.qcprotocol.json.file=" Workflow_Settings/Module_Configuration_Files/secondary/global.ini | xargs dirname | sed 's/qcmodule.qcprotocol.json.file=//' `;
    chomp $IR_path;

    `sshpass -p '$ionpass' ssh $ionusr\@172.16.3.52 sshpass -p '$pass' rsync -r /torrentsuite/172.16.3.$foldername2[5]/$run_name/plugin_out/coverageAnalysis_out*/$foldername2[3] /torrentsuite/172.16.3.$foldername2[5]/$run_name/plugin_out/coverageAnalysis_out*/*bc_summary.xls $user\@$ip:$cwd `;

   `mv $foldername2[3] $foldername-coverageAnalysisReport `;
    `mv *bc_summary.xls $foldername-coverageAnalysisReport `;

   `sshpass -p '$irpass' ssh $irusr\@172.16.3.$IRserver sshpass -p '$pass' rsync -r $IR_path/outputs/CnvActor-00 $user\@$ip:$cwd `;
    `mv CnvActor-00 $foldername-CnvActor `;
  
  if (($foldername2[1] =~m/omPAN/) || ($foldername2[1] =~m/omLUNG/))
   {
   `sshpass -p '$ionpass' ssh $ionusr\@172.16.3.52 sshpass -p '$pass' rsync -r /torrentsuite/172.16.3.$foldername2[5]/$run_name/plugin_out/molecularCoverageAnalysis_out*/results.json $user\@$ip:$cwd `;
   `mv results.json $foldername-coverageAnalysisReport `;
   }
	
}

else
{
   `mkdir $foldername-coverageAnalysisReport`;
}

`test -f "read_stats.txt" && mv read_stats.txt $foldername-coverageAnalysisReport/$foldername-read_stats.txt`;
`mv datasets_basecaller.json $foldername-coverageAnalysisReport/$foldername-datasets_basecaller.json`;
`mv $foldername2[3]_rawlib.ionstats_alignment.json $foldername-coverageAnalysisReport/$foldername-rawlib.ionstats_alignment.json`;

if ($foldername2[2] =~ m/TNA/) # Copy "consensus_metrics.txt" file for median read & median molecular coverage
{
    `sshpass -p '$irpass' ssh $irusr\@172.16.3.$IRserver sshpass -p '$pass' rsync -r $IR_path/outputs/VariantCallerActor-00/consensus_metrics.txt $user\@$ip:$cwd `;
    `mv consensus_metrics.txt $foldername-coverageAnalysisReport/$foldername-consensus_metrics.txt`;
}
}
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

		if (($mean_read_len < 55) && ($foldername2[2] =~ m/cf[DT]NA/))
		{
		print "\nSample QC fail MeanReadLength: $mean_read_len. Do you want to proceed? (y/n) : ";
		$choice = <STDIN>;
		chomp $choice;

			if ($choice =~ /n/i)
			{
				exit;
			}
		}
		if (($mean_read_len < 75) && (($foldername2[2] =~ m/FFPE_[DT]NA/)||($foldername2[2] =~ m/FT_[DT]NA/)))
		{
		print "\nSample QC fail MeanReadLength: $mean_read_len. Do you want to proceed? (y/n) : ";
		$choice = <STDIN>;
		chomp $choice;

			if ($choice =~ /n/i)
			{
				exit;
			}
		}

if (($foldername2[1] =~m/omPAN/) || ($foldername2[1] =~m/omLUNG/))
 {
	# molecular uniformity
	my $json1;
	{
	  local $/; #Enable 'slurp' mode
	  open my $fh, "<", "$foldername-coverageAnalysisReport/results.json";
	  $json1 = <$fh>;
	  close $fh;
	}

my$data = decode_json($json1);
$mol_uniformity = $data->{'barcodes'}->{$foldername2[3]}->{'Fam_uniformity_of_amplicon_coverage'};
}
#print "Fam_uniformity_of_amplicon_coverage:\t$mol_uniformity";
#----------------------------------------------------------- coverageAnalysis Start ----------------------------------------------------------------#
if ($foldername2[2] =~ m/[DT]NA/)
{

# coverageAnalysis

	$bc_summary=`grep '$foldername2[3]' $foldername-coverageAnalysisReport/*bc_summary.xls`;

	@coverage_stat=split('\t',$bc_summary);

	$mean_depth=sprintf "%.0fx",$coverage_stat[4];

# Amplicon coverage
	$wc=undef;
	$total_amplicons=undef;
	$wc=`wc $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
	$total_amplicons=$wc-1;

# Amplicons with at least 10 reads
	$reads_10=`awk '\$10 >= 10 { count++ } END { print count-1 }' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
	$per_10=($reads_10/$total_amplicons)*100;
	$per_10_2dec=sprintf "%.2f%%", $per_10;
@uncovered_10=`awk '\$10 < 10' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;

# Amplicons with at least 20 reads
	$reads_20=`awk '\$10 >= 20 { count++ } END { print count-1 }' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
	$per_20=($reads_20/$total_amplicons)*100;
	$per_20_2dec=sprintf "%.2f%%", $per_20;

	@uncovered_20=`awk '\$10 < 20' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;

# Amplicons with at least 30 reads
	$reads_30=`awk '\$10 >= 30 { count++ } END { print count-1 }' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
	$per_30=($reads_30/$total_amplicons)*100;
	$per_30_2dec=sprintf "%.2f%%", $per_30;


# Amplicons with at least 100 reads
	$reads_100=`awk '\$10 >= 100 { count++ } END { print count-1 }' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
	$per_100=($reads_100/$total_amplicons)*100;
	$per_100_2dec=sprintf "%.2f%%", $per_100;

# Amplicons with at least 500 reads
	$reads_500=`awk '\$10 >= 500 { count++ } END { print count-1 }' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
	$per_500=($reads_500/$total_amplicons)*100;
	$per_500_2dec=sprintf "%.2f%%", $per_500;

# Amplicons with at least 600 reads
	$reads_600=`awk '\$10 >= 600 { count++ } END { print count-1 }' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;
	$per_600=($reads_600/$total_amplicons)*100;
	$per_600_2dec=sprintf "%.2f%%", $per_600;

	@uncovered_600=`awk '\$10 < 600' $foldername-coverageAnalysisReport/$foldername2[3]*amplicon.cov.xls`;

# Target regions
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

# MAPD
	$mapd = `head -1 QC/mapd.txt`;


if ($foldername2[3] =~ m/Tag/)
    {

        $Median_read_cov_ORI = `grep "^Median read coverage:" $foldername-coverageAnalysisReport/$foldername-consensus_metrics.txt | sed 's/Median read coverage://'`;
        $Median_read_cov = round ($Median_read_cov_ORI);

        $Median_mol_cov_ORI = `grep "^Median molecular coverage:" $foldername-coverageAnalysisReport/$foldername-consensus_metrics.txt | sed 's/Median molecular coverage://'`;
        $Median_mol_cov = round ($Median_mol_cov_ORI);
		
		if (($Median_read_cov < 17000) || ($Median_mol_cov < 1250))
		{
		print "\nSample QC fail MRC: $Median_read_cov; MMC : $Median_mol_cov. Do you want to proceed? (y/n) : ";
		$choice = <STDIN>;
		chomp $choice;

			if ($choice =~ /n/i)
			{
				exit;
			}
		}
		
		
		
		
	$Median_LOD_percent_ORI = `grep "^Median LOD percent:" $foldername-coverageAnalysisReport/$foldername-consensus_metrics.txt | sed 's/Median LOD percent://'`;
        $Median_LOD_percent = $Median_LOD_percent_ORI;
		$Median_LOD_percent =~s/\s+//;
		chomp $Median_LOD_percent;
        $Percentile_LOD_percent_ORI = `grep "^80th percentile LOD percent:" $foldername-coverageAnalysisReport/$foldername-consensus_metrics.txt | sed 's/80th percentile LOD percent://'`;
        $Percentile_LOD_percent = $Percentile_LOD_percent_ORI;
		$Percentile_LOD_percent =~s/\s+//;
		chomp $Percentile_LOD_percent;
		$Sample_LOD = "Sample LOD $Median_LOD_percent-$Percentile_LOD_percent";
    }
}

if (-f "QC/TotalMappedFusionPanelReads.txt")
{
# Mapped Fusion Panel Reads
	$TotalMappedFusionPanelReads = `grep "TotalMappedFusionPanelReads=" QC/TotalMappedFusionPanelReads.txt`;
	$TotalMappedFusionPanelReads =~ s/TotalMappedFusionPanelReads=//g;
	$TotalMappedFusionPanelReads =~ s/\n//g;

	$pool1 = `grep "POOL-1=" QC/TotalMappedFusionPanelReads.txt`;
	$pool1 =~ s/POOL-1=/ [POOL-1=/g;
	$pool1 =~ s/\n//g;

	$pool2 = `grep "POOL-2=" QC/TotalMappedFusionPanelReads.txt`;
	$pool2 =~ s/POOL-2=/, POOL-2=/g;
	$pool2 =~ s/\n/]/g;

	$MappedFusionPanelReads = $TotalMappedFusionPanelReads.$pool1.$pool2;

# Mapped Fusion Molecular Count
	$MappedFusionMolCount = `grep "TotalMappedFusionMolecularCount=" QC/TotalMappedFusionPanelReads.txt`;
	$MappedFusionMolCount =~ s/TotalMappedFusionMolecularCount=//g;
	$MappedFusionMolCount =~ s/\n//g;
}

print "completed\n";

if ($foldername2[2] =~ m/[DT]NA/)
{
	print "\n\nCoverage Analysis\t\t:\tTarget region file used: $Target_regions\n";

	if ($Target_regions ne $target_files{$foldername2[1]})
	{
	print "\nTARGET REGION FILE IS WRONG. It Should be $target_files{$foldername2[1]}. Do you want to proceed? (y/n) : ";
	$choice = <STDIN>;
	chomp $choice;

	if ($choice =~ /n/i)
	{
	exit;

	}
	}
}

#------------------------------------------------------------ Coverage Analysis End ------------------------------------------------------------------#


#-------------------------------------------------- SampleID (Unique Identification) Start ----------------------------------------------------------#

if (-e "$foldername-coverageAnalysisReport/$foldername-read_stats.txt")
{
    $uniqueID=`grep "Sample ID:" $foldername-coverageAnalysisReport/$foldername-read_stats.txt`;

    $uniqueID =~ s/Sample ID:\s+//g;
    chomp$uniqueID;
}

else
{
    $uniqueID ="NA";
}


print "\n\nUnique Identification\t\t:\t$uniqueID\n";

#-------------------------------------------------- SampleID (Unique Identification) End -----------------------------------------------------------#

# CNA Sample QC
if ($foldername2[2] =~ m/[DT]NA/ && $mapd >= 0.5)
{
	print "\n\nCNA Sample QC\t\t\t:\tFAIL\n";
}

elsif ($foldername2[3] =~ m/Tag/ && $foldername2[2] =~ m/cf/ && $mapd >= 0.4)
{
	print "\n\nCNA Sample QC\t\t\t:\tFAIL\n";
}
	
# Fusion Sample QC
if ($foldername2[3] =~ m/Tag/ || $foldername2[2] =~ m/RNA/)
{
	$FusionSampleQC = `head -1 QC/RNAQCAndCalls.txt`;
	$FusionSampleQC =~ s/FusionSampleQC=<//g;
	$FusionSampleQC =~ s/]>/]/g;
	
	print "\n\nFusion Sample QC\t\t:\t$FusionSampleQC";
}

##########################################################################  Server Data Retrival End  ########################################################################


#=cut
#############################################################################  Annotation Start  #############################################################################

print "\n\nAnnotation\t\t\t:\t";

$fname_out=$foldername."-My_Work.xls";
$row_all=0, $row_all2=0, $row_filtered=0, $row_filtered2=0, $row_filtered3=0, $row_filtered4=0, $row_cna=0, $row_fusion=0, $coutfusion=0, $RNAExonVariant=0, $ExprControl=0, $row_cnaR=1, $fr_row=1, $SNVs=0, $Indels=0;
@fusions;

# Rename *My_Work.xls if already exist

if (-e "$foldername-My_Work.xls") 
{
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
my $worksheet11 = $workbook->add_worksheet('Fusion_Filtered');
my $worksheet12 = $workbook->add_worksheet('Fusion_Report');
my $worksheet13 = $workbook->add_worksheet('Worksheet');



foreach $line (@data)
{
	chomp $line;

	@element=split('\t',$line);


# 1st Worksheet : All

	for ($i=0;$i<scalar@element;$i++) 
	{
		$worksheet1->write($row_all, $i, $element[$i], $left);
		$worksheet1->freeze_panes(5, 9);
	}
	$row_all++;


# 11th Worksheet : Fusion_Filtered
	if ($foldername2[2] =~ m/RNA/ || $foldername2[3] =~ m/TagSequencing/)
	{

		if ($line =~ m/POS/ && $element[1] =~ m/Fusion/ && $line !~ m/Non-Targeted/)
		{
			$coutfusion++;
            push(@fusions,($line));
		}

		if ($line =~ m/POS/ && $element[1] =~ m/RNAExonVariant/ && $element[$ID] !~ m/WT/ )
		{
			$RNAExonVariant++;
            push(@RNAExonVar,($line));
		}


		if ($line =~ m/POS/ && $element[1] =~ m/ExprControl|ProcControl/)
		{
			$ExprControl++;
		}

		if ($line =~ m/POS/ && $element[1] =~ m/rowtype|Fusion|ExprControl|ProcControl|RNAExonVariant/)
		{
		
			for ($f=0;$f<scalar@element;$f++) 
			{
				$worksheet11->write($row_fusion, $f, $element[$f], $left);
				$worksheet11->freeze_panes(1, 9);
			}
		$row_fusion++;
		
		}

	}


	if ($foldername2[2] =~ m/[DT]NA/)
	{
# 2nd Worksheet : Filtered

		if ($line =~ m/\tPOS\t/ && $element[1] =~ m/rowtype|snp|mnp|ins|del|complex/)
		{

			$join=$element[$IRchr]."_".$element[$IRpos]."_".$element[$IRref]."_".$element[$IRalt];
			$join=~s/-//g;

			$combined=$combined.$join."\n";
			$worksheet2->write($row_filtered, 1, $join, $left);

# Zygosity	
			if ($element[$GT] ne "FORMAT.1.GT")
			{
				@GTaa=split("/",$element[$GT]);

				if ($GTaa[0] eq $GTaa[1])
				{
					$element[$GT] = "HOM";
				}
				else
				{
					$element[$GT] = "HET";
				}
			}


# Allele Frequency
			if ($element[$AF] ne "FORMAT.A.AF")
			{

				$element[$AF] = $element[$AF]*100;

				$element[$AF] = sprintf "%.2f", $element[$AF];
			}

# LOD
			if ($element[$PROTEIN] ne "FUNC1.protein" && $element[$LOD] ne "INFO.A.LOD" && $foldername2[1] ne 'OCAv3' && $foldername2[1] ne 'OCAPlus' && $foldername2[1] ne 'omBRCA' && $foldername2[1] ne 'HRR')

			{

				$element[$LOD] = $element[$LOD]*100;
				$element[$LOD] = sprintf "%.2f", $element[$LOD];
				$element[$PROTEIN] =~ s/Ter/\*/g;
				$filtsingleLetterAA = $element[$PROTEIN];
				$element[$PROTEIN] =~ s/A/Ala/g; $element[$PROTEIN] =~ s/R/Arg/g; $element[$PROTEIN] =~ s/N/Asn/g; $element[$PROTEIN] =~ s/D/Asp/g; $element[$PROTEIN] =~ s/B/Asx/g;
				$element[$PROTEIN] =~ s/C/Cys/g; $element[$PROTEIN] =~ s/G/Gly/g; $element[$PROTEIN] =~ s/E/Glu/g; $element[$PROTEIN] =~ s/Q/Gln/g; $element[$PROTEIN] =~ s/Z/Glx/g;
				$element[$PROTEIN] =~ s/H/His/g; $element[$PROTEIN] =~ s/I/Ile/g; $element[$PROTEIN] =~ s/L/Leu/g; $element[$PROTEIN] =~ s/K/Lys/g; $element[$PROTEIN] =~ s/M/Met/g;
				$element[$PROTEIN] =~ s/P/Pro/g; $element[$PROTEIN] =~ s/F/Phe/g; $element[$PROTEIN] =~ s/S/Ser/g; $element[$PROTEIN] =~ s/T/Thr/g; $element[$PROTEIN] =~ s/W/Trp/g;
				$element[$PROTEIN] =~ s/Y/Tyr/g; $element[$PROTEIN] =~ s/V/Val/g; $element[$PROTEIN] =~ s/\*/Ter/g;
				$element[$PROTEIN] =~ s/p\./p\.\(/g; $element[$PROTEIN] =~ s/\;/\)\;/g; $element[$PROTEIN]="; ".$element[$PROTEIN].")";
			}
	
			elsif ($element[$PROTEIN] ne "FUNC1.protein") 
			{
				$threeLetterAA = $element[$PROTEIN];
				$threeLetterAA =~ s/p\./p\.\(/g;
				$element[$PROTEIN] =~ s/Ala/A/g; $element[$PROTEIN] =~ s/Arg/R/g; $element[$PROTEIN] =~ s/Asn/N/g; $element[$PROTEIN] =~ s/Asp/D/g; $element[$PROTEIN] =~ s/Asx/B/g;
				$element[$PROTEIN] =~ s/Cys/C/g; $element[$PROTEIN] =~ s/Gly/G/g; $element[$PROTEIN] =~ s/Glu/E/g; $element[$PROTEIN] =~ s/Gln/Q/g; $element[$PROTEIN] =~ s/Glx/Z/g;
				$element[$PROTEIN] =~ s/His/H/g; $element[$PROTEIN] =~ s/Ile/I/g; $element[$PROTEIN] =~ s/Leu/L/g; $element[$PROTEIN] =~ s/Lys/K/g; $element[$PROTEIN] =~ s/Met/M/g;
				$element[$PROTEIN] =~ s/Pro/P/g; $element[$PROTEIN] =~ s/Phe/F/g; $element[$PROTEIN] =~ s/Ser/S/g; $element[$PROTEIN] =~ s/Thr/T/g; $element[$PROTEIN] =~ s/Trp/W/g;
				$element[$PROTEIN] =~ s/Tyr/Y/g; $element[$PROTEIN] =~ s/Val/V/g; $element[$PROTEIN] =~ s/Ter/\*/g;
				$element[$PROTEIN] = $element[$PROTEIN]."; ".$threeLetterAA.")";
			}

#---------------------------------------------- Combined File Start -----------------------------------------------------------------------------------------------
            if ($element[1] !~ m/rowtype/)
            {
                print O "\n".$line."\t";

                foreach $IL (@IngenuityORI)
                {
                    chomp$IL;
                    @Iline=split('\t',$IL);
                    $Iline[0]="chr". $Iline[0];
       
                    if ($Iline[4] eq "") 
		            {
			            $Iline[4] = "-";
		            }

		            if ($Iline[5] eq "") 
		            {
			            $Iline[5] = "-";
		            }

                    if ($element[$IRchr] eq $Iline[0] && $element[$IRpos] == $Iline[1] && $element[$IRref] eq $Iline[4] && $element[$IRalt] eq $Iline[5])
                    {
                        print O $IL;
                        last;
                    }

                    elsif ($element[$IRchr] eq $Iline[0] && $element[$IRpos] == $Iline[2] && $element[$IRref] eq $Iline[4] && $element[$IRalt] eq $Iline[5])
                    {
                        print O $IL;
                        last;
                    }
                }
            }
        
#---------------------------------------------- Combined File End -----------------------------------------------------------------------------------------------

			for ($j=2,$i=0;$i<=scalar@element;$j++,$i++) 
			{
				if ($i==$PROTEIN)
				{
					$worksheet2->write($row_filtered, $j, $filtsingleLetterAA.$element[$PROTEIN], $left);
				}
				else
				{
					$worksheet2->write($row_filtered, $j, $element[$i], $left);
					$worksheet2->freeze_panes(1, 2);
				}
			}
			$row_filtered++;
		}


# 9th Worksheet : CNA_Filtered

		if ($element[1] =~ m/rowtype|CNV/ && $element[$filter] =~ m/FILTER|GAIN|LOSS/)
		{
		
			for ($t=0;$t<scalar@element;$t++) 
			{
				$worksheet9->write($row_cna, $t, $element[$t], $left);
				$worksheet9->freeze_panes(1, 9);
			}
		$row_cna++;
		
		}

        if (($line =~ m/PERCENT_ALIGNED_READS<60.0/) || ($foldername2[1] =~ m/OCAv3/ && $mapd >= 0.5) || ($foldername2[1] =~ m/OCAPlus/ && $mapd >= 0.5) || ($foldername2[1] =~ m/omBRCA/ && $mapd >= 0.5) ||($foldername2[3] =~ m/Tag/ && $foldername2[2] =~ m/cf/ && $mapd >= 0.4)||($foldername2[1] =~ m/omLUNG/ && $mapd >= 0.4))
        {
            $CNAqc="Fail";
        }
	
	}
}


if ($foldername2[2] =~ m/RNA/ || $foldername2[1] =~ m/om/)
{

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 12th Worksheet : Fusion_Report
    $fus=0, $total_fusion=0;

    @fusionheader=("SN", "Type", "Gene", "Variant ID", "Detection", "COSMIC ID", "Read Counts", "Molecular Counts");

    for ($fh=0;$fh<scalar@fusionheader;$fh++) 
    {
        $worksheet12->write(0, $fh, $fusionheader[$fh], $center);
        $worksheet12->freeze_panes(1, 0);
    }

    if ($FusionSampleQC =~ m/FAIL/i)
    {
        $worksheet12->write(1, 0, "Fusion QC failed",$redbold);
    }

    elsif ($coutfusion == 0 && $RNAExonVariant == 0)
    {
        $worksheet12->write(1, 0, "No fusion detected",$redbold);
    }

    else
    {
        for ($fr=0;$fr<$coutfusion;$fr=$fr+2)
        {

            @fusline=split('\t',$fusions[$fr]);

            $fusline[$ID] =~ s/_.*//g;
            @gene=split('\.',$fusline[$ID]);

            if ($fusline[$COSF] eq "")
            {
                $fusline[$COSF] = "---";
            }
      
            if ($foldername2[2] =~ m/RNA/ && $fusline[$ReadCount] >=120)
            {
                $worksheet12->write($fr_row, 0, $fr_row,$left);
                $worksheet12->write($fr_row, 1, $fusline[$rowtype],$left);
                $worksheet12->write($fr_row, 2, $gene[0],$left);
                $worksheet12->write($fr_row, 3, $fusline[$ID],$left);
                $worksheet12->write($fr_row, 4, "Present",$left);
                $worksheet12->write($fr_row, 5, $fusline[$COSF],$left);
                $worksheet12->write($fr_row, 6, $fusline[$ReadCount],$left);
                $worksheet12->write($fr_row, 7, "NA",$left);
                $fr_row++;
                $fus++;
            }

            if ($foldername2[3] =~ m/TagSequencing/)
            {
                $worksheet12->write($fr_row, 0, $fr_row,$left);
                $worksheet12->write($fr_row, 1, $fusline[$rowtype],$left);
                $worksheet12->write($fr_row, 2, $gene[0],$left);
                $worksheet12->write($fr_row, 3, $fusline[$ID],$left);
                $worksheet12->write($fr_row, 4, "Present",$left);
                $worksheet12->write($fr_row, 5, $fusline[$COSF],$left);
                $worksheet12->write($fr_row, 6, $fusline[$ReadCount],$left);
                $worksheet12->write($fr_row, 7, $fusline[$MolCount],$left);
                $fr_row++;
                $fus++;
            }

        }
        
        for ($re=0;$re<$RNAExonVariant;$re=$re+2)
        {
            @RNAExonVarline=split('\t',$RNAExonVar[$re]);

            @RNAExonGene=split('\.',$RNAExonVarline[$ID]);
      
            $worksheet12->write($fr_row, 0, $fr_row,$left);
            $worksheet12->write($fr_row, 1, $RNAExonVarline[$rowtype],$left);
            $worksheet12->write($fr_row, 2, $RNAExonGene[0],$left);
            $worksheet12->write($fr_row, 3, $RNAExonVarline[$ID],$left);
            $worksheet12->write($fr_row, 4, "Present",$left);
            $worksheet12->write($fr_row, 5, "---",$left);

            if ($foldername2[3] =~ m/TagSequencing/)
            {
                $worksheet12->write($fr_row, 6, $RNAExonVarline[$ReadCount],$left);
                $worksheet12->write($fr_row, 7, $RNAExonVarline[$MolCount],$left);
                $fr_row++;
            }

            else
            {
                $worksheet12->write($fr_row, 6, $RNAExonVarline[$ReadCount],$left);
                $worksheet12->write($fr_row, 7, "NA",$left);
                $fr_row++;
            }
        $RNAExonVariant_uniq++;
        }
    }
}
$total_fusion=$fus+$RNAExonVariant_uniq;
if ($foldername2[2] =~ m/[DT]NA/)
{
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 10th Worksheet : CNA_Report

   	@cnaheader=("SN", "Markers", "Cytoband", "Copy Number", "CNA Ratio", "chr", "Start", "End");

	for ($ch=0;$ch<scalar@cnaheader;$ch++) 
	{
		$worksheet10->write(0, $ch, $cnaheader[$ch], $center);
		$worksheet10->freeze_panes(1, 0);
	}

	if ($CNAqc eq 'Fail')
	{
        $worksheet10->write(1, 0, "CNA QC failed",$redbold);
	}

	elsif ($row_cna == 1)
	{
		$worksheet10->write(1, 0, "No CNA detected",$redbold);
	}

    else
    {
        foreach $cnvline (@CNVdata)
        {
	        chomp $cnvline;

	        @elementCNV=split('\t',$cnvline);


	        if ($elementCNV[$type] =~ m/CNV/ && $elementCNV[$filter2] =~ m/GAIN|LOSS/ && $elementCNV[$oncomineGeneClass] =~ m/Gain-of-Function/ && $foldername2[1] !~ m/omBRCA/)
	        {

                @elementCNV_CN = split('x',$elementCNV[$iscn]);
				@elementCNV_locus = split(':',$elementCNV[$cnv_locus]);
                $elementCNV_CN[0] =~ s/\(.*//g;
                $cn=round($elementCNV_CN[1]);

                $fd = sprintf "%.2f", $elementCNV_CN[1]/2;

                $elementCNV[$filter2]=~s/([\w']+)/\u\L$1/g;
                $cn=$cn." ($elementCNV[$filter2])";


                $worksheet10->write($row_cnaR, 0, $row_cnaR, $left);
			    $worksheet10->write($row_cnaR, 1, $elementCNV[$marker], $left);
			    $worksheet10->write($row_cnaR, 2, $elementCNV_CN[0], $left);
                $worksheet10->write($row_cnaR, 5, $elementCNV_locus[0], $left);
				$worksheet10->write($row_cnaR, 6, $elementCNV_locus[1], $left);
				$worksheet10->write($row_cnaR, 7, $elementCNV[$cnv_length]+$elementCNV_locus[1], $left);
				if ($Testcode != 0 && $genelist{$elementCNV[$marker]} !~m/$Testcode/)
				{
				$worksheet10->write($row_cnaR, 9, "Gene not in TestCode genelist", $left);
				}
                if ($foldername2[3] =~ m/TagSequencing/ || $foldername2[3] =~ m/IonHDdual/)
                {
			        $worksheet10->write($row_cnaR, 3, "NA", $left);
						if ($foldername2[2] =~ m/FT_/ || $foldername2[2] =~ m/FFPE_/)
						{
							if ($fd >= 6)
							{
							$worksheet10->write($row_cnaR, 4, "$fd (Amplification)", $left);
							}
							else
							{
							$worksheet10->write($row_cnaR, 4, "$fd (Gain)", $left);
							}
						}
						else
						{
						$worksheet10->write($row_cnaR, 4, "$fd (Gain)", $left);
						}
                }
                else
                {
                   
						if ($foldername2[2] =~ m/FT_/ || $foldername2[2] =~ m/FFPE_/)
						{
								$cn=~m/(\d+) \(Gain/;
								$copy_number = $1;
							if ($copy_number >= 6)
							{
							$worksheet10->write($row_cnaR, 3, $copy_number." (Amplification)", $left);
							}
							else
							{
							$worksheet10->write($row_cnaR, 3, $cn, $left);
							}
						}
						else
						{
						$worksheet10->write($row_cnaR, 3, $cn, $left);
						}

			        $worksheet10->write($row_cnaR, 4, "NA", $left);
                }

			    $worksheet10->freeze_panes(1,1);
                $row_cnaR++
		    }
			elsif ($elementCNV[$type] =~ m/CNV/ && $elementCNV[$filter2] =~ m/GAIN|LOSS/ && $foldername2[1] =~ m/omBRCA/ )
			{
				@elementCNV_CN = split('x',$elementCNV[$iscn]);
				@elementCNV_locus = split(':',$elementCNV[$cnv_locus]);
                $elementCNV_CN[0] =~ s/\(.*//g;
                $cn=round($elementCNV_CN[1]);

                $fd = sprintf "%.2f", $elementCNV_CN[1]/2;

                $elementCNV[$filter2]=~s/([\w']+)/\u\L$1/g;
                $cn=$cn." ($elementCNV[$filter2])";
				$worksheet10->write($row_cnaR, 0, $row_cnaR, $left);
			    $worksheet10->write($row_cnaR, 1, $elementCNV[$marker]." - ".$elementCNV[$cnv_call], $left);
			    $worksheet10->write($row_cnaR, 2, $elementCNV_CN[0], $left);
				$worksheet10->write($row_cnaR, 3, $cn, $left);
				$worksheet10->write($row_cnaR, 4, "NA", $left);
				$worksheet10->write($row_cnaR, 5, $elementCNV_locus[0], $left);
				$worksheet10->write($row_cnaR, 6, $elementCNV_locus[1], $left);
				$worksheet10->write($row_cnaR, 7, $elementCNV[$cnv_length]+$elementCNV_locus[1], $left);
				$worksheet10->write($row_cnaR, 8, $elementCNV[$cnv_st], $left);
				$worksheet10->freeze_panes(1,1);
                $row_cnaR++
			}
			
			
			
        }
    }


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Ingenuity txt file

    close (O);

    unless(open(INR,"$foldername-BiVA_IR.txt")){
    print "\n\nCan't open file $foldername-BiVA_IR.txt\n\n";
    }

    @IngenuityIR=<INR>;

    close(INR);

    @rawheaderelements3=split('\t',$IngenuityIR[0]);
    $rawheadersize3=scalar@rawheaderelements3;

    $INRCHROM=first_index { $_ eq 'CHROM' } @rawheaderelements3;
    $INROPOS=first_index { $_ eq 'INFO...OPOS' } @rawheaderelements3;
    $INROREF=first_index { $_ eq 'INFO...OREF' } @rawheaderelements3;
    $INROALT=first_index { $_ eq 'INFO...OALT' } @rawheaderelements3;
    $INRGT=first_index { $_ eq 'FORMAT.1.GT' } @rawheaderelements3;
    $INRAF=first_index { $_ eq 'FORMAT.A.AF' } @rawheaderelements3;
    $INRQUAL=first_index { $_ eq 'QUAL' } @rawheaderelements3;
    $INRLOD=first_index { $_ eq 'INFO.A.LOD' } @rawheaderelements3;
    $INRDP=first_index { $_ eq 'FORMAT.1.DP' } @rawheaderelements3;
    $INRFDP=first_index { $_ eq 'FORMAT.1.FDP' } @rawheaderelements3;
    $INRFAO=first_index { $_ eq 'FORMAT.A.FAO' } @rawheaderelements3;
    $INRID=first_index { $_ eq 'ID' } @rawheaderelements3;
    $INRReadCount=first_index { $_ eq 'INFO...READ_COUNT' } @rawheaderelements3;
    $INRGENE=first_index { $_ eq 'FUNC1.gene' } @rawheaderelements3;
    $INRTRANSCRIPT=first_index { $_ eq 'FUNC1.transcript' } @rawheaderelements3;
    $INREXON=first_index { $_ eq 'FUNC1.exon' } @rawheaderelements3;
    $INRcDNA=first_index { $_ eq 'FUNC1.coding' } @rawheaderelements3;
    $INRPROTEIN=first_index { $_ eq 'FUNC1.protein' } @rawheaderelements3;
    $Inferred_Activity=first_index { $_ =~ m/Inferred Activity/ } @rawheaderelements3;
    $INRClassification=first_index { $_ eq 'Classification' } @rawheaderelements3;
    $INRdbSNPID=first_index { $_ eq 'dbSNP ID' } @rawheaderelements3;
#    $INRGenomes1000=first_index { $_ eq '1000 Genomes Frequency' } @rawheaderelements3;
#    $INRExAC_EAS=first_index { $_ eq 'ExAC East Asian Frequency' } @rawheaderelements3;
#    $INRExAC_SAS=first_index { $_ eq 'ExAC South Asian Frequency' } @rawheaderelements3;
#    $INRExAC_AFR=first_index { $_ eq 'ExAC African Frequency' } @rawheaderelements3;
#    $INRExAC_EUR=first_index { $_ eq 'ExAC European Frequency' } @rawheaderelements3;
#    $INRExAC_AMR=first_index { $_ eq 'ExAC Latino Frequency' } @rawheaderelements3;
#    $INRgnomAD_PAN=first_index { $_ eq 'gnomAD Frequency' } @rawheaderelements3;
#    $INRHGMD=first_index { $_ eq 'HGMD' } @rawheaderelements3;
    $INRCOSMIC=first_index { $_ eq 'COSMIC ID' } @rawheaderelements3;
    $INRCOSMIC1=$COSMIC+2;


    print R "Category"."\t"."Chrom"."\t"."Position"."\t"."Ref"."\t"."Variant"."\t"."Zygosity"."\t"."Frequency"."\t"."Quality"."\t"."LOD"."\t"."Original Coverage"."\t"."Downsample Coverage"."\t"."Downsample Allele Cov"."\t"."Gene Symbol"."\t"."Transcript ID"."\t"."Exon No"."\t"."cDNA Change"."\t"."Protein Change"."\t"."COSMIC ID"."\t"."Variant Category"."\t"."Inferred Activity"."\t"."Variant Classification"."\t"."dbSNP ID"."\t"."1000 genomes Frequency"."\t"."gnomAD Frequency"."\t"."Remarks"."\n";

    foreach $INRline (@IngenuityIR)
    {
        @INRlineelements = split('\t',$INRline);

# Zygosity	
		if ($INRlineelements[$INRGT] ne "FORMAT.1.GT")
		{
		    @GTaa=split("/",$INRlineelements[$INRGT]);

		    if ($GTaa[0] eq $GTaa[1])
		    {
		        $INRlineelements[$INRGT] = "HOM";
		    }
	        else
		    {
			    $INRlineelements[$INRGT] = "HET";
		    }
        }


# Allele Frequency
	    if ($INRlineelements[$INRAF] ne "FORMAT.A.AF")
	    {
		    $INRlineelements[$INRAF] = $INRlineelements[$INRAF]*100;
		    $INRlineelements[$INRAF] = sprintf "%.2f", $INRlineelements[$INRAF];
	    }

# LOD

        if ($foldername2[1] eq 'OCAv3' || $foldername2[1] eq 'OCAPlus' || $foldername2[1] eq 'omBRCA' || $foldername2[1] eq 'HRR' )
        {
            $INRlineelements[$INRLOD]="NA";
        }



		if ($INRlineelements[$INRPROTEIN] ne "FUNC1.protein" && $INRlineelements[$INRLOD] ne "INFO.A.LOD" && $foldername2[1] ne 'OCAv3' && $foldername2[1] ne 'OCAPlus' && $foldername2[1] ne 'omBRCA' && $foldername2[1] ne 'HRR')
		{

			$INRlineelements[$INRLOD] = $INRlineelements[$INRLOD]*100;
			$INRlineelements[$INRLOD] = sprintf "%.2f", $INRlineelements[$INRLOD];
			$INRlineelements[$INRPROTEIN] =~ s/Ter/\*/g;
			$filtsingleLetterAA = $INRlineelements[$INRPROTEIN];
			$INRlineelements[$INRPROTEIN] =~ s/A/Ala/g; $INRlineelements[$INRPROTEIN] =~ s/R/Arg/g; $INRlineelements[$INRPROTEIN] =~ s/N/Asn/g; $INRlineelements[$INRPROTEIN] =~ s/D/Asp/g; 
			$INRlineelements[$INRPROTEIN] =~ s/B/Asx/g; $INRlineelements[$INRPROTEIN] =~ s/C/Cys/g; $INRlineelements[$INRPROTEIN] =~ s/G/Gly/g; $INRlineelements[$INRPROTEIN] =~ s/E/Glu/g; 
			$INRlineelements[$INRPROTEIN] =~ s/Q/Gln/g; $INRlineelements[$INRPROTEIN] =~ s/Z/Glx/g; $INRlineelements[$INRPROTEIN] =~ s/H/His/g; $INRlineelements[$INRPROTEIN] =~ s/I/Ile/g; 
			$INRlineelements[$INRPROTEIN] =~ s/L/Leu/g; $INRlineelements[$INRPROTEIN] =~ s/K/Lys/g; $INRlineelements[$INRPROTEIN] =~ s/M/Met/g; $INRlineelements[$INRPROTEIN] =~ s/P/Pro/g; 
			$INRlineelements[$INRPROTEIN] =~ s/F/Phe/g; $INRlineelements[$INRPROTEIN] =~ s/S/Ser/g; $INRlineelements[$INRPROTEIN] =~ s/T/Thr/g; $INRlineelements[$INRPROTEIN] =~ s/W/Trp/g; 
			$INRlineelements[$INRPROTEIN] =~ s/Y/Tyr/g; $INRlineelements[$INRPROTEIN] =~ s/V/Val/g; $INRlineelements[$INRPROTEIN] =~ s/\*/Ter/g; 
			$INRlineelements[$INRPROTEIN] =~ s/p\./p\.\(/g; $INRlineelements[$INRPROTEIN] =~ s/\;/\)\;/g; $INRlineelements[$INRPROTEIN]=$filtsingleLetterAA."; ".$INRlineelements[$INRPROTEIN].")";
		}

		elsif ($INRlineelements[$INRPROTEIN] ne "FUNC1.protein") 
		{
			$threeLetterAA = $INRlineelements[$INRPROTEIN];
			$threeLetterAA =~ s/p\./p\.\(/g;
			$INRlineelements[$INRPROTEIN] =~ s/Ala/A/g; $INRlineelements[$INRPROTEIN] =~ s/Arg/R/g; $INRlineelements[$INRPROTEIN] =~ s/Asn/N/g; $INRlineelements[$INRPROTEIN] =~ s/Asp/D/g; 
			$INRlineelements[$INRPROTEIN] =~ s/Asx/B/g; $INRlineelements[$INRPROTEIN] =~ s/Cys/C/g; $INRlineelements[$INRPROTEIN] =~ s/Gly/G/g; $INRlineelements[$INRPROTEIN] =~ s/Glu/E/g; 
			$INRlineelements[$INRPROTEIN] =~ s/Gln/Q/g; $INRlineelements[$INRPROTEIN] =~ s/Glx/Z/g; $INRlineelements[$INRPROTEIN] =~ s/His/H/g; $INRlineelements[$INRPROTEIN] =~ s/Ile/I/g; 
			$INRlineelements[$INRPROTEIN] =~ s/Leu/L/g; $INRlineelements[$INRPROTEIN] =~ s/Lys/K/g; $INRlineelements[$INRPROTEIN] =~ s/Met/M/g; $INRlineelements[$INRPROTEIN] =~ s/Pro/P/g; 
			$INRlineelements[$INRPROTEIN] =~ s/Phe/F/g; $INRlineelements[$INRPROTEIN] =~ s/Ser/S/g; $INRlineelements[$INRPROTEIN] =~ s/Thr/T/g; $INRlineelements[$INRPROTEIN] =~ s/Trp/W/g; 
			$INRlineelements[$INRPROTEIN] =~ s/Tyr/Y/g; $INRlineelements[$INRPROTEIN] =~ s/Val/V/g; $INRlineelements[$INRPROTEIN] =~ s/Ter/\*/g; 
			$INRlineelements[$INRPROTEIN] = $INRlineelements[$INRPROTEIN]."; ".$threeLetterAA.")";
		}


        if ($ethnicity =~ m/EAS/i)
        {
            $INRlineelements[$INROREF] =~ s/-//g;
            $INRlineelements[$INROALT] =~ s/-//g;

            print R $INRlineelements[$INRCHROM]."_".$INRlineelements[$INROPOS]."_".$INRlineelements[$INROREF]."_".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRCHROM]."\t".$INRlineelements[$INROPOS]."\t".$INRlineelements[$INROREF]."\t".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRGT]."\t".$INRlineelements[$INRAF]."\t".$INRlineelements[$INRQUAL]."\t".$INRlineelements[$INRLOD]."\t".$INRlineelements[$INRDP]."\t".$INRlineelements[$INRFDP]."\t".$INRlineelements[$INRFAO]."\t".$INRlineelements[$INRGENE]."\t".$INRlineelements[$INRTRANSCRIPT]."\t".$INRlineelements[$INREXON]."\t".$INRlineelements[$INRcDNA]."\t".$INRlineelements[$INRPROTEIN]."\t".$INRlineelements[$INRCOSMIC]."\t"."\t".$INRlineelements[$Inferred_Activity]."\t".$INRlineelements[$INRClassification]."\t".$INRlineelements[$INRdbSNPID]."\t"."---"."\t"."---"."\t"."---"."\n";
        }

        if ($ethnicity =~ m/SAS/i)
        {
            $INRlineelements[$INROREF] =~ s/-//g;
            $INRlineelements[$INROALT] =~ s/-//g;

            print R $INRlineelements[$INRCHROM]."_".$INRlineelements[$INROPOS]."_".$INRlineelements[$INROREF]."_".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRCHROM]."\t".$INRlineelements[$INROPOS]."\t".$INRlineelements[$INROREF]."\t".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRGT]."\t".$INRlineelements[$INRAF]."\t".$INRlineelements[$INRQUAL]."\t".$INRlineelements[$INRLOD]."\t".$INRlineelements[$INRDP]."\t".$INRlineelements[$INRFDP]."\t".$INRlineelements[$INRFAO]."\t".$INRlineelements[$INRGENE]."\t".$INRlineelements[$INRTRANSCRIPT]."\t".$INRlineelements[$INREXON]."\t".$INRlineelements[$INRcDNA]."\t".$INRlineelements[$INRPROTEIN]."\t".$INRlineelements[$INRCOSMIC]."\t"."\t".$INRlineelements[$Inferred_Activity]."\t".$INRlineelements[$INRClassification]."\t".$INRlineelements[$INRdbSNPID]."\t"."---"."\t"."---"."\t"."---"."\n";
        }

        if ($ethnicity =~ m/AFR/i)
        {
            $INRlineelements[$INROREF] =~ s/-//g;
            $INRlineelements[$INROALT] =~ s/-//g;

            print R $INRlineelements[$INRCHROM]."_".$INRlineelements[$INROPOS]."_".$INRlineelements[$INROREF]."_".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRCHROM]."\t".$INRlineelements[$INROPOS]."\t".$INRlineelements[$INROREF]."\t".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRGT]."\t".$INRlineelements[$INRAF]."\t".$INRlineelements[$INRQUAL]."\t".$INRlineelements[$INRLOD]."\t".$INRlineelements[$INRDP]."\t".$INRlineelements[$INRFDP]."\t".$INRlineelements[$INRFAO]."\t".$INRlineelements[$INRGENE]."\t".$INRlineelements[$INRTRANSCRIPT]."\t".$INRlineelements[$INREXON]."\t".$INRlineelements[$INRcDNA]."\t".$INRlineelements[$INRPROTEIN]."\t".$INRlineelements[$INRCOSMIC]."\t"."\t".$INRlineelements[$Inferred_Activity]."\t".$INRlineelements[$INRClassification]."\t".$INRlineelements[$INRdbSNPID]."\t"."---"."\t"."---"."\t"."---"."\n";
        }

        if ($ethnicity =~ m/EUR/i)
        {
            $INRlineelements[$INROREF] =~ s/-//g;
            $INRlineelements[$INROALT] =~ s/-//g;

            print R $INRlineelements[$INRCHROM]."_".$INRlineelements[$INROPOS]."_".$INRlineelements[$INROREF]."_".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRCHROM]."\t".$INRlineelements[$INROPOS]."\t".$INRlineelements[$INROREF]."\t".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRGT]."\t".$INRlineelements[$INRAF]."\t".$INRlineelements[$INRQUAL]."\t".$INRlineelements[$INRLOD]."\t".$INRlineelements[$INRDP]."\t".$INRlineelements[$INRFDP]."\t".$INRlineelements[$INRFAO]."\t".$INRlineelements[$INRGENE]."\t".$INRlineelements[$INRTRANSCRIPT]."\t".$INRlineelements[$INREXON]."\t".$INRlineelements[$INRcDNA]."\t".$INRlineelements[$INRPROTEIN]."\t".$INRlineelements[$INRCOSMIC]."\t"."\t".$INRlineelements[$Inferred_Activity]."\t".$INRlineelements[$INRClassification]."\t".$INRlineelements[$INRdbSNPID]."\t"."---"."\t"."---"."\t"."---"."\n";
        }

        if ($ethnicity =~ m/AMR/i)
        {
            $INRlineelements[$INROREF] =~ s/-//g;
            $INRlineelements[$INROALT] =~ s/-//g;

            print R $INRlineelements[$INRCHROM]."_".$INRlineelements[$INROPOS]."_".$INRlineelements[$INROREF]."_".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRCHROM]."\t".$INRlineelements[$INROPOS]."\t".$INRlineelements[$INROREF]."\t".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRGT]."\t".$INRlineelements[$INRAF]."\t".$INRlineelements[$INRQUAL]."\t".$INRlineelements[$INRLOD]."\t".$INRlineelements[$INRDP]."\t".$INRlineelements[$INRFDP]."\t".$INRlineelements[$INRFAO]."\t".$INRlineelements[$INRGENE]."\t".$INRlineelements[$INRTRANSCRIPT]."\t".$INRlineelements[$INREXON]."\t".$INRlineelements[$INRcDNA]."\t".$INRlineelements[$INRPROTEIN]."\t".$INRlineelements[$INRCOSMIC]."\t"."\t".$INRlineelements[$Inferred_Activity]."\t".$INRlineelements[$INRClassification]."\t".$INRlineelements[$INRdbSNPID]."\t"."---"."\t"."---"."\t"."---"."\n";
        }
        if ($ethnicity =~ m/PAN/i)
        {
            $INRlineelements[$INROREF] =~ s/-//g;
            $INRlineelements[$INROALT] =~ s/-//g;

            print R $INRlineelements[$INRCHROM]."_".$INRlineelements[$INROPOS]."_".$INRlineelements[$INROREF]."_".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRCHROM]."\t".$INRlineelements[$INROPOS]."\t".$INRlineelements[$INROREF]."\t".$INRlineelements[$INROALT]."\t".$INRlineelements[$INRGT]."\t".$INRlineelements[$INRAF]."\t".$INRlineelements[$INRQUAL]."\t".$INRlineelements[$INRLOD]."\t".$INRlineelements[$INRDP]."\t".$INRlineelements[$INRFDP]."\t".$INRlineelements[$INRFAO]."\t".$INRlineelements[$INRGENE]."\t".$INRlineelements[$INRTRANSCRIPT]."\t".$INRlineelements[$INREXON]."\t".$INRlineelements[$INRcDNA]."\t".$INRlineelements[$INRPROTEIN]."\t".$INRlineelements[$INRCOSMIC]."\t"."\t".$INRlineelements[$Inferred_Activity]."\t".$INRlineelements[$INRClassification]."\t".$INRlineelements[$INRdbSNPID]."\t"."---"."\t"."---"."\t"."---"."\n";
        }
    }

    close (R);

	unless(open(G,"$foldername-BiVA_rearranged.txt"))
	{
		print "\n\nCan't open file $foldername-BiVA_rearranged.txt";
	}

	@Ingenuity=<G>;

	close(G);

	splice @Ingenuity, 1,2;
	
    $element2_pos=0;

	foreach $line2 (@Ingenuity)
	{
		@element2=split('\t',$line2);

		chomp $element2[24] ;

        $diff = $element2[2]-$element2_pos;
        
        @element2_copy = split('\t',$line2);
        $element2_pos = $element2_copy[2];

#Formatting

        if ($element2[3] eq "") 
		{
			$element2[3] = "-";
		}

		if ($element2[4] eq "") 
		{
			$element2[4] = "-";
		}

        if ($element2[16] =~ m/\?/)
        {
            $element2[14] = "---";
            $element2[16] = "---";
        }

		$COSM_IDs = $element2[17];
		
		if ($element2[17] != "") 
		{
			$element2[17] = "COSM".$element2[17];
		}

		$element2[17] =~ s/; /; COSM/g; 
	
        $element2[0] =~ s/\)//g;
        $germ=first_index {$_ =~ m/$element2[0]\t/} @germline; #Germline Variants



# ------------------------------------------------------------------------ PredictSNP Start ------------------------------------------------------------------------

        $predictSNP_vc=`LANG=C grep -wF '$element2[0]' $PredictSNPdb`;

        if ($element2[18] ne "Variant Category") 
        {
            $element2[18] = "---";
        }

        if ($predictSNP_vc ne "")
        {
            @predictSNP2=split ('\t',$predictSNP_vc);
            chomp$predictSNP2[5];

            if (($element2[22] >=0.1 || $element2[23] >=0.1 || $germ >=0) && ($element2[6]>=10))
            {
                $predictSNP2[5] =~ s/Driver/Deleterious/g;
                $predictSNP2[5] =~ s/Passenger/Neutral/g;
            }

            $element2[18] = $predictSNP2[5];
        }

# ------------------------------------------------------------------------ PredictSNP End ------------------------------------------------------------------------


# ---------------------------------------------------------------------- 1000 Genomes Start ----------------------------------------------------------------------

            $g1=first_index {$_ =~ m/$element2[0]\t/} @G1000;

            if ($g1>=0)
            {
                @G10002=split ('\t',$G1000[$g1]);
                chomp$G10002[11];

                if ($ethnicity =~ m/EAS/i)
                {
                    $element2[22]=$G10002[7];
                }

                if ($ethnicity =~ m/SAS/i)
                {
                    $element2[22]=$G10002[8];
                }

                if ($ethnicity =~ m/AFR/i)
                {
                    $element2[22]=$G10002[9];
                }

                if ($ethnicity =~ m/EUR/i)
                {
                    $element2[22]=$G10002[10];
                }

                if ($ethnicity =~ m/AMR/i)
                {
                    $element2[22]=$G10002[11];
                }
		if ($ethnicity =~ m/PAN/i)
		{
			$element2[22]=$G10002[6];
		}
            }

        
# ----------------------------------------------------------------------- 1000 Genomes End -----------------------------------------------------------------------
# ---------------------------------------------------------------------- gnomAD DB Start -------------------------------------------------------------------------

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
                $element2[23]=$ExAC2[9];
            }

            if ($ethnicity =~ m/AMR/i)
            {
                $element2[23]=$ExAC2[11];
            }

            if ($ethnicity =~ m/EAS/i)
            {
                $element2[23]=$ExAC2[7];
            }

            if ($ethnicity =~ m/EUR/i)
            {
                $element2[23]=$ExAC2[10];
            }

            if ($ethnicity =~ m/SAS/i)
            {
		
                $element2[23]=$ExAC2[8];
            }
            if ($ethnicity =~ m/PAN/i)
            {
                $element2[23]=$ExAC2[6];
            }
			
        }

# ---------------------------------------------------------------------- gnomAD DB end ---------------------------------------------------------------------------
		if ($element2[19] eq "") 
		{
			$element2[19] = "---";
		}

		$element2[20] =~ s/Uncertain Significance/VUS/g;
			
		if ($element2[21] != "") 
		{
			$element2[21] = "rs".$element2[21];
		}

		if ($element2[21] eq "") 
		{
			$element2[21] = "---";
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


# 3rd Worksheet : Ingenuity

		for ($i=0;$i<scalar@element2;$i++) 
		{

				$worksheet3->write($row_all2, $i, $element2[$i], $left);
				$worksheet3->freeze_panes(1, 1);

		}
		$row_all2++;

		
		if ($COSM_IDs != "") 
		{
			$COSM_IDs =~ s/\s//g;
			@COSMIC_ID = split(';',$COSM_IDs);
			@COSMIC_ID = sort {$a <=> $b} @COSMIC_ID;
			$element2[17] = $COSMIC_ID[0];
			$element2[17] = "COSM".$element2[17];
		}

        if ($element2[17] eq "")
        {
            $element2[17] = "---";
        }


# 4th Worksheet : ExAC <=5%

		if (($element2[22] <= 5 && $element2[23] <= 5) || ($element2[0] eq 'Category'))
		{
		

			$action=`LANG=C grep -F '$element2[0]' $actionable`; 
			#print "$action\n";
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
			$worksheet4->write(0, 25, "ClinVar_Class", $left);
            $black_variant=`LANG=C grep -wF '$element2[0]' $blacklistdb`; # Blacklisted Variants

            if ($element2[21] !~ m/dbSNP ID/)
            {
                # Passenger/Neutral variant Remarks
                if (($element2[18] =~ m/Passenger/ || $element2[18] =~ m/Neutral/) && ($element2[18] !~ "---") && ($element2[18] !~ ""))
                {
                    $worksheet4->write($row_filtered2, 24, $element2[18], $left);
                }

                # Synonymous Variants Remarks
                if ($element2[16] eq "p.(=); p.((=))")
                {
                    $worksheet4->write($row_filtered2, 24, "2.Synonymous", $left);
                }

                # Intronic Variants Remarks
                if (($element2[16] eq "---") || ($element2[16] eq "" && $element2[15] =~ m/\+/) || ($element2[16] eq "" && $element2[15] =~ m/\-/))
                {
                    $worksheet4->write($row_filtered2, 24, "3.Intronic", $left);
                }

                # Adjacent Location Variants Remarks
                if ($diff >= -5 && $diff <= 5)
                {
                    $worksheet4->write($row_filtered2, 24, "1.Adjacent Location - check hotspot or novel and pathogenicity before filteration", $left);
                }

                # Probable Germline Remarks
                if ($element2[22] >= 0.1 || $element2[23] >= 0.1 || $germ >=0 || $element2[6]==100)
                {
                    $worksheet4->write($row_filtered2, 24, "4.Probable Germline", $left);
                }

                # Variant Coverage Remarks
				if (($foldername2[2] !~ m/gDNA/ && $foldername2[2] !~ m/cf[DT]NA/ && $element2[11] < 20) || ($foldername2[2] =~m/cf[DT]NA/ && $element2[11] < 6))
                {
                    $worksheet4->write($row_filtered2, 24, "6.Low Variant Coverage", $redbold);
                }

                # Variant Frequency (LOD) Remarks
                if (($foldername2[1] =~ m/OCAv3/ && $foldername2[2] !~ m/gDNA/ && $foldername2[2] !~ m/cf[DT]NA/ && $element2[6] < 5) || ($foldername2[1] !~ m/OCAv3/ && $foldername2[2] =~ m/cf[DT]NA/ && $element2[6] < 0.1) || ($foldername2[1] !~ m/OCAv3/ && $foldername2[2] !~ m/cf[DT]NA/ && $element2[6] < 5))
                {
                    $worksheet4->write($row_filtered2, 24, "5.Below LOD", $redbold);

                }

                # Blacklisted Remarks
                if ($black_variant =~ m/$foldername2[1]/ || $black_variant =~ m/All/)
                {
                    @black_remarks=split('\t',$black_variant);
                    chomp$black_remarks[4];
                    $worksheet4->write($row_filtered2, 24, "7.Blacklisted - $black_remarks[4]", $redbold);
                }

                # COSMIC SNP Flag
                if ($foldername2[2] ne "gDNA")
                {
                    $snp_flag=`LANG=C grep -F '$element2[0]' $COSMIC_SNP_Flag`; 
                    @snp_flag2=split('\t',$snp_flag);
                    chomp$snp_flag2[1];
                    if ($snp_flag2[0] eq $element2[0])
                    {
                        $worksheet4->write($row_filtered2, 24, "9.$snp_flag2[1]", $redbold);
                    }
                }
				# Gene in list
                 if ($Testcode != 0 && $genelist{$element2[12]} !~m/$Testcode/)
                {
                $worksheet4->write($row_filtered2, 24, "Gene Not in TestCode List", $redbold);
				}
				#ClinVar Classification
				$clin_line=first_index {$_ =~ m/$element2[0]\t/} @ClinVar_data;
				if ($clin_line>=0)
				{
					@Clin_line_split=split ('\t',$ClinVar_data[$clin_line]);
					$clin_class = $Clin_line_split[6];
					chomp $clin_class ; 
				if ($clin_class eq $element2[19])
					{
					$worksheet4->write($row_filtered2, 25, $clin_class, $left);
					}
				else
					{
					$worksheet4->write($row_filtered2, 25, $clin_class, $redbold);
					}
				}

            }

			$row_filtered2++;


# 5th Worksheet : COSMIC_ID_Only

$worksheet5->write(0, 25, "ClinVar_Class", $left);
			if ($foldername2[2] ne "gDNA")	
			{


				if (($element2[17] ne "---" || $element2[17] eq "COSMIC ID" || $element2[20] =~ m/Pathogenic/ || $element2[20] eq "")  || ($element2[20] =~ m/VUS/ && $element2[18] =~ m/Driver/) || ($element2[20] =~ m/VUS/ && $element2[18] =~ m/Deleterious/) || ($element2[0] eq $action2[0]) || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
				{
					for ($j=0,$i=0;$i<=scalar@element2;$j++,$i++) 
					{
						if(($element2[0] eq $action2[0]) || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
						{
						    $worksheet5->write($row_filtered3, $j, $element2[$i], $yellowbold);
						}
						else
						{
						    $worksheet5->write($row_filtered3, $j, $element2[$i], $left);
						}
	
					    $worksheet5->freeze_panes(1, 1);
					}

                    if ($element2[21] !~ m/dbSNP ID/)
                    {
                        # Passenger/Neutral variant Remarks
                        if (($element2[18] =~ m/Passenger/ || $element2[18] =~ m/Neutral/) && ($element2[18] !~ "---") && ($element2[18] !~ ""))
                        {
                            $worksheet5->write($row_filtered3, 24, $element2[18], $left);
							$element2[24] = $element2[18];

                        }

                        # Synonymous Variants Remarks
                        if ($element2[16] eq "p.(=); p.((=))")
                        {
                            $worksheet5->write($row_filtered3, 24, "2.Synonymous", $left);
							$element2[24] = "2.Synonymous";
                        }
        
                        # Intronic Variants Remarks
                        if (($element2[16] eq "---") || ($element2[16] eq "" && $element2[15] =~ m/\+/) || ($element2[16] eq "" && $element2[15] =~ m/\-/))
                        {
                            $worksheet5->write($row_filtered3, 24, "3.Intronic", $left);
							$element2[24] = "3.Intronic";
                        }

                        # Adjacent Location Variants Remarks
                        if ($diff >= -5 && $diff <= 5)
                        {
                            $worksheet5->write($row_filtered3, 24, "1.Adjacent Location - check hotspot or novel and pathogenicity before filteration", $left);
                        }

                        # Probable Germline Remarks
                        if ($element2[22] >= 0.1 || $element2[23] >= 0.1 || $germ >=0 || $element2[6]==100)
                        {
                            $worksheet5->write($row_filtered3, 24, "4.Probable Germline", $left);
							$element2[24] = "4.Probable Germline";
                        }

                        # Variant Coverage Remarks
                        if (($foldername2[2] !~ m/gDNA/ && $foldername2[2] !~ m/cf[DT]NA/ && $element2[11] < 20) || ($foldername2[2] =~ m/cf[DT]NA/ && $element2[11] < 6))
                        {
                            $worksheet5->write($row_filtered3, 24, "6.Low Variant Coverage", $redbold);
							$element2[24] = "6.Low Variant Coverage";
                        }

                        # Variant Frequency (LOD) Remarks
                        if (($foldername2[1] =~ m/OCAv3/ && $foldername2[2] !~ m/gDNA/ && $foldername2[2] !~ m/cf[DT]NA/ && $element2[6] < 5) || ($foldername2[1] !~ m/OCAv3/ && $foldername2[2] =~ m/cf[DT]NA/ && $element2[6] < 0.1) || ($foldername2[1] !~ m/OCAv3/ && $foldername2[2] !~ m/cf[DT]NA/ && $element2[6] < 5))
                        {
                            $worksheet5->write($row_filtered3, 24, "5.Below LOD", $redbold);
							$element2[24] = "5.Below LOD";
                        }

                        # Blacklisted Remarks
                        if ($black_variant =~ m/$foldername2[1]/ || $black_variant =~ m/All/)
                        {
                           $worksheet5->write($row_filtered3, 24, "7.Blacklisted - $black_remarks[4]", $redbold);
							$element2[24] = "7.Blacklisted - $black_remarks[4]";
                        }

                        # COSMIC SNP Flag
                        if ($snp_flag2[0] eq $element2[0])
                        {
                            $worksheet5->write($row_filtered3, 24, "9.$snp_flag2[1]", $redbold);
							$element2[24] = "9.$snp_flag2[1]";
                        }
						# Gene in list
                        if ($Testcode != 0 && $genelist{$element2[12]} !~m/$Testcode/)
                        {
                            $worksheet5->write($row_filtered3, 24, "Gene Not in TestCode List", $redbold);
							$element2[24] = "Gene Not in TestCode List";
                        }
						#ClinVar Classification
						$clin_line=first_index {$_ =~ m/$element2[0]\t/} @ClinVar_data;
						if ($clin_line>=0)
						{
							@Clin_line_split=split ('\t',$ClinVar_data[$clin_line]);
							$clin_class = $Clin_line_split[6];
							chomp $clin_class ; 
						if ($clin_class eq $element2[19])
							{
							$worksheet5->write($row_filtered3, 25, $clin_class, $left);
							}
						else
							{
							$worksheet5->write($row_filtered3, 25, $clin_class, $redbold);
							}
						}
                    }
               

					$row_filtered3++;


# 6th Worksheet : SNV_Info

                    if (($black_variant !~ m/$foldername2[1]/ && $black_variant !~ m/All/ && $element2[20] ne "" && $snp_flag eq "" ) || ($element2[0] eq $action2[0]) || (($element2[12] eq "EGFR") && ($element2[14] == 19)) && ($element2[24] !~m/Gene Not in TestCode List/))
                    {
					$concat=$element2[1]."_".$element2[2]."_".$element2[3]."_".$element2[4];
					$concat =~ s/-//;
			
                        if ($element2[0] ne 'Category')
                        {
                            if (($element2[22] >= 0.1 || $element2[23] >= 0.1 || $germ >=0 || $element2[6]==100) && ($element2[6] >= 10))
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
                            if (($element2[0] eq 'Category') || ($element2[6] >= 0.1 && $element2[11] >=6 && $snp_flag eq "") || ($concat eq $action2[0]) || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
                            {

                                for ($s=0,$t=0;$s<=scalar@element2;$s++,$t++) 
					            {
                                    if ($t==8)
                                    {
                                        $s=7;
                                        next;
                                    }

							if (($concat eq $action2[0])  || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
							{
							$worksheet6->write($row_filtered4, $s, $element2[$t], $yellowbold);
							}
							else{
							$worksheet6->write($row_filtered4, $s, $element2[$t], $left);
							}
							$worksheet6->freeze_panes(1, 1);
					            }

                                # Adjacent Location Variants Remarks
                                if ($diff >= -5 && $diff <= 5 && $element2[21] !~ m/dbSNP ID/)
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

                        elsif ($foldername2[1] =~ m/omLUNG/ && $foldername2[2] !~ m/cf[DT]NA/)
                        {
                            if (($element2[0] eq 'Category') || ($element2[6] >= 5 && $element2[11] >=6 && $snp_flag eq "") || ($concat eq $action2[0]) || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
                            {
                                for ($s=0,$t=0;$s<=scalar@element2;$s++,$t++) 
					            {
                                    if ($t==8)
                                    {
                                        $s=7;
                                        next;
                                    }			

							if (($concat eq $action2[0]) || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
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
                                if ($diff >= -5 && $diff <= 5 && $element2[21] !~ m/dbSNP ID/)
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

                        elsif (($element2[0] eq 'Category') || ((($foldername2[1] =~ m/OCAv3/) || ($foldername2[1] =~ m/OCAPlus/)) && $foldername2[2] !~ m/gDNA/ && $foldername2[2] !~ m/cf[DT]NA/ && $element2[6] >= 5 && $element2[11] >= 20 && $snp_flag eq "") || ($concat eq $action2[0]) || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
                        {
                            for ($s=0,$t=0;$s<=scalar@element2;$s++,$t++) 
					        {
                                if ($t==8)
                                {
                                    $s=7;
                                    next;
                                }

							if (($concat eq $action2[0]) || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
								{
								$worksheet6->write($row_filtered4, $s, $element2[$t], $yellowbold);
								}
								else{
								$worksheet6->write($row_filtered4, $s, $element2[$t], $left);
								}
									
				                $worksheet6->freeze_panes(1, 1);
					        }

                            # Adjacent Location Variants Remarks
                            if ($diff >= -5 && $diff <= 5 && $element2[21] !~ m/dbSNP ID/)
                            {
                                $worksheet6->write($row_filtered4, 23, "Adjacent Location - check hotspot or novel and pathogenicity before filteration", $left);
                            }

					        $row_filtered4++;

                            $element2[3] =~ s/-//g;
                            $element2[4] =~ s/-//g;
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
		
			elsif ($foldername2[2] eq "gDNA")	
			{
					if (($element2[21] ne "---" || $element2[21] eq "dbSNP ID" || $element2[20] =~ m/Pathogenic/ || $element2[20] eq "")  || ($element2[20] =~ m/VUS/ && $element2[18] =~ m/Driver/) || ($element2[20] =~ m/VUS/ && $element2[18] =~ m/Deleterious/) || ($element2[0] eq $action2[0]) || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
				{
					for ($j=0,$i=0;$i<=scalar@element2;$j++,$i++) 
					{
						if(($element2[0] eq $action2[0]) || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
						{
						    $worksheet5->write($row_filtered3, $j, $element2[$i], $yellowbold);
						}
						else
						{
						    $worksheet5->write($row_filtered3, $j, $element2[$i], $left);
						}
	
					    $worksheet5->freeze_panes(1, 1);
					}

                    if ($element2[21] !~ m/dbSNP ID/)
                    {
                        # Passenger/Neutral variant Remarks
                        if (($element2[18] =~ m/Passenger/ || $element2[18] =~ m/Neutral/) && ($element2[18] !~ "---") && ($element2[18] !~ ""))
                        {
                            $worksheet5->write($row_filtered3, 23, $element2[18], $left);
							$element2[23] = $element2[18];

                        }

                        # Synonymous Variants Remarks
                        if ($element2[16] eq "p.(=); p.((=))")
                        {
                            $worksheet5->write($row_filtered3, 23, "2.Synonymous", $left);
							$element2[24] = "2.Synonymous";
                        }
        
                        # Intronic Variants Remarks
                        if (($element2[16] eq "---") || ($element2[16] eq "" && $element2[15] =~ m/\+/) || ($element2[16] eq "" && $element2[15] =~ m/\-/))
                        {
                            $worksheet5->write($row_filtered3, 23, "3.Intronic", $left);
							$element2[23] = "3.Intronic";
                        }

                        # Adjacent Location Variants Remarks
                        if ($diff >= -5 && $diff <= 5)
                        {
                            $worksheet5->write($row_filtered3, 23, "1.Adjacent Location - check hotspot or novel and pathogenicity before filteration", $left);
                        }

                        # Probable Germline Remarks
                        if ($element2[22] >= 0.1 || $element2[23] >= 0.1 || $germ >=0 || $element2[6]==100)
                        {
                            $worksheet5->write($row_filtered3, 23, "4.Probable Germline", $left);
							$element2[23] = "4.Probable Germline";
                        }

                        # Variant Coverage Remarks
                        if ($foldername2[2] =~ m/gDNA/ && $element2[11] < 10)
                        {
                            $worksheet5->write($row_filtered3, 23, "6.Low Variant Coverage", $redbold);
							$element2[23] = "6.Low Variant Coverage";
                        }

                        # Variant Frequency (LOD) Remarks
                        if ($foldername2[2] =~ m/gDNA/ && $element2[6] < 10)
                        {
                            $worksheet5->write($row_filtered3, 23, "5.Below LOD", $redbold);
							$element2[23] = "5.Below LOD";
                        }

                        # Blacklisted Remarks
                        if ($black_variant =~ m/$foldername2[1]/ || $black_variant =~ m/All/)
                        {
                           $worksheet5->write($row_filtered3, 23, "7.Blacklisted - $black_remarks[4]", $redbold);
							$element2[23] = "7.Blacklisted - $black_remarks[4]";
                        }

                  
                    }
               

					$row_filtered3++;


# 6th Worksheet : SNV_Info

                    if (($black_variant !~ m/$foldername2[1]/ && $black_variant !~ m/All/ && $element2[20] ne "" && $snp_flag eq "" ) || ($element2[0] eq $action2[0]) || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
                    {
					$concat=$element2[1]."_".$element2[2]."_".$element2[3]."_".$element2[4];
					$concat =~ s/-//;
			
                        if ($element2[0] ne 'Category')
                        {

                                $element2[0] = "Germline";

                        }

                        if ($foldername2[2] =~ m/gDNA/)
                        {
                            if (($element2[0] eq 'Category') || ($element2[6] >= 10 && $element2[11] >=10 && $snp_flag eq "") || ($concat eq $action2[0]) || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
                            {

                                for ($s=0,$t=0;$s<=scalar@element2;$s++,$t++) 
					            {
                                    if ($t==8)
                                    {
                                        $s=7;
                                        next;
                                    }

							if (($concat eq $action2[0])  || (($element2[12] eq "EGFR") && ($element2[14] == 19)))
							{
							$worksheet6->write($row_filtered4, $s, $element2[$t], $yellowbold);
							}
							else{
							$worksheet6->write($row_filtered4, $s, $element2[$t], $left);
							}
							$worksheet6->freeze_panes(1, 1);
					            }

                                # Adjacent Location Variants Remarks
                                if ($diff >= -5 && $diff <= 5 && $element2[21] !~ m/dbSNP ID/)
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
		
		
			} #gDNA loop ends
		}
	}

    $ReportedVariants=$row_filtered4-1;
    $Indels=$ReportedVariants-$SNVs;

    if ($ReportedVariants == 0)
    {
        $worksheet6->write(1, 0, "No variant detected",$redbold);
    }

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

	$urow_20=1, $urow_600=1;

	@uncoveredheader=("contig_id", "contig_srt", "contig_end", "region_id", "attributes", "gc_count", "overlaps", "fwd_e2e", "rev_e2e", "total_reads", "fwd_reads", "rev_reads", "cov20x", "cov100x", "cov500x", "Gene, Exon, Codons");

	for ($i=0;$i<scalar@uncoveredheader;$i++) 
			{
				$worksheet7->write(0, $i, $uncoveredheader[$i], $center);
				$worksheet7->freeze_panes(1, 5);
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

				if ($uncovered_ampl_elements[3] eq $uelement_10[3])
				{
					$worksheet7->write($urow_10, 15, $uncovered_ampl_elements[5], $left);
					$limitations= $limitations."; ".$uncovered_ampl_elements[5];
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

				if ($uncovered_ampl_elements[3] eq $uelement_20[3])
				{
					$worksheet7->write($urow_20, 15, $uncovered_ampl_elements[5], $left);
					$limitations= $limitations."; ".$uncovered_ampl_elements[5];
				}
			}

			$urow_20++;
		}
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

	if (($gene eq $pre_gene) || ($Testcode != 0 && $genelist{$gene} !~m/$Testcode/))
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
#	$limitations_formatted =~ s/^\s\|\s//;
	$limitations_formatted =~ s/^,\s//;
	$limitations_formatted =~ s/\s+,\s+/, /g;
	chomp $limitations_formatted;
	
# 8th Worksheet : Limitations
if ($foldername2[2] =~ m/cf[DT]NA/ || scalar@uelement_20 == 0)
{
    $worksheet8->write(0, 0, "NA", $left);
}

else
{
    $worksheet8->write(0, 0, $limitations_formatted, $left);
}

print "Completed\n";

#`rm $foldername-Ingenuity_rearranged.txt $foldername-Ingenuity_IR.txt`;

##############################################################################  Uncovered End  ###############################################################################


############################################################################  LIMS Worksheet Start  ##########################################################################

print "\n\nWorksheet filling\t\t:\t";

@Worksheetheader=("SAMPLE ID", "TESTCODE", "ADAPTOR AND BARCODE DEAILS", "RUN", "SERVER", "SAMPLE TYPE", "AMPLISEQ PANEL DETAILS", "NUMBER OF GENES/SNPs", "DATE", "TOTAL NUMBER OF READS", "MEAN READ LENGTH (bp)", "TOTAL NO. OF BASES (Without MB)", "TOTAL NO. OF BASES >Q20 (Without MB)", "AMPLICONS WITH ATLEAST 10 READS", "AMPLICONS WITH ATLEAST 20 READS", "AMPLICONS WITH ATLEAST 30 READS", "AMPLICONS WITH ATLEAST 100 READS", "AMPLICONS WITH ATLEAST 500 READS", "AMPLICONS WITH ATLEAST 600 READS", "MEAN DEPTH (x)", "MAPPED READS", "Mapped Fusion Panel Reads", "Mapped Fusion Molecular Count", "Median Read Coverage", "Median Molecular Coverage", "On Target (%)", "Uniformity (%)", "MAPD", "QC CRITERIA", "QC COMM", "ALIGNER", "VARIANT CALLER", "SOFTWARE PARAMETERS", "ADDITIONAL ANALYSIS SOFTWARE", "DETAILS OF DATABASES", "NGS Pipeline", "CNA Baseline", "Predicted Tumor Content (Tumor-Normal Paired Analysis)", "TOTAL VARIANTS", "REPORTED VARIANTS", "SNV", "INDEL", "CNV", "Fusion", "Expression Controls Positive", "Total 5'/3' Assay Present", "Sanger", "ddPCR", "Comment", "PERFORMED BY", "CHECKED BY", "Unique Identification","TMB","MSI Status","MSI Score","LOH");

for ($i=0;$i<scalar@Worksheetheader;$i++) 
		{

			$worksheet13->write(0, $i, $Worksheetheader[$i], $center);
			$worksheet13->freeze_panes(1, 1);

		}

$sample_type = $foldername2[2] ;
$sample_type =~  s/_/ /g;

$worksheet13->write(1, 0, $foldername2[0], $left); # SAMPLE ID
$worksheet13->write(1, 2, $foldername2[3], $left); # ADAPTOR AND BARCODE DEAILS
$worksheet13->write(1, 3, $foldername2[4], $left); # RUN
$worksheet13->write(1, 4, $foldername2[5], $left); # SERVER
$worksheet13->write(1, 5, $sample_type, $left); # SAMPLE TYPE
$worksheet13->write(1, 6, $foldername2[1], $left); # AMPLISEQ PANEL DETAILS
$worksheet13->write(1, 7, $panel_genes{$foldername2[1]}, $left); # NUMBER OF GENES/SNPs
$worksheet13->write(1, 8, $date, $left); # DATE
$worksheet13->write(1, 9, $read_count, $left); # TOTAL NUMBER OF READS
$worksheet13->write(1, 10, $mean_read_len, $left); # MEAN READ LENGTH
$worksheet13->write(1, 11, $total_bases, $left); # TOTAL NO. OF BASES (Without MB)
$worksheet13->write(1, 12, $Q20_bases, $left); # TOTAL NO. OF BASES >Q20 (Without MB)

if ($foldername2[2] =~ m/[DT]NA/)
{
	$worksheet13->write(1, 13, $per_10_2dec, $left); # AMPLICONS WITH ATLEAST 10 READS
	$worksheet13->write(1, 14, $per_20_2dec, $left); # AMPLICONS WITH ATLEAST 20 READS
	$worksheet13->write(1, 15, $per_30_2dec, $left); # AMPLICONS WITH ATLEAST 30 READS
	$worksheet13->write(1, 16, $per_100_2dec, $left); # AMPLICONS WITH ATLEAST 100 READS
	$worksheet13->write(1, 17, $per_500_2dec, $left); # AMPLICONS WITH ATLEAST 500 READS
	$worksheet13->write(1, 18, $per_600_2dec, $left); # AMPLICONS WITH ATLEAST 600 READS
	$worksheet13->write(1, 19, $mean_depth, $left); # MEAN DEPTH
	$worksheet13->write(1, 20, $coverage_stat[2], $left); # MAPPED READS
	$worksheet13->write(1, 25, $On_Target, $left); # On Target (%)
	$worksheet13->write(1, 26, $mol_uniformity, $left); # Uniformity (%)
	$worksheet13->write(1, 27, $mapd); # MAPD
	$worksheet13->write(1, 31, $TVC_version); # VARIANT CALLER version
	$worksheet13->write(1, 33, "$BiVA_version, $IR_version"); # ADDITIONAL ANALYSIS SOFTWARE - Somatic SNV, Indel & CNV
#	$worksheet13->write(1, 33, "$IR_version"); # ADDITIONAL ANALYSIS SOFTWARE - Somatic SNV, Indel & CNV

    if ($ethnicity =~ m/EAS/i)
    {
     #   $worksheet13->write(1, 34, "$dbSNP_version, 1000 genomes frequency (EAS) phase 3v5b, ExAC (EAS) Release 1.0, $Clinvar_version, $COSMIC_version"); # DETAILS OF DATABASES - EAS - Somatic
		$worksheet13->write(1, 34, "1000 genomes frequency (EAS) phase 3v5b, gnomAD (EAS) Release 2.1.1"); # DETAILS OF DATABASES - EAS - Somatic
    }

    elsif ($ethnicity =~ m/SAS/i)
    {
    #    $worksheet13->write(1, 34, "$dbSNP_version, 1000 genomes frequency (SAS) phase 3v5b, ExAC (SAS) Release 1.0, $Clinvar_version, $COSMIC_version"); # DETAILS OF DATABASES - SAS - Somatic
		$worksheet13->write(1, 34, "1000 genomes frequency (SAS) phase 3v5b, gnomAD (SAS) Release 2.1.1"); # DETAILS OF DATABASES - SAS - Somatic
    }

    elsif ($ethnicity =~ m/AFR/i)
    {
     #   $worksheet13->write(1, 34, "$dbSNP_version, 1000 genomes frequency (AFR) phase 3v5b, ExAC (AFR) Release 1.0, $Clinvar_version, $COSMIC_version"); # DETAILS OF DATABASES - AFR - Somatic
		$worksheet13->write(1, 34, "1000 genomes frequency (AFR) phase 3v5b, gnomAD (AFR) Release 2.1.1"); # DETAILS OF DATABASES - AFR - Somatic
    }

    elsif ($ethnicity =~ m/EUR/i)
    {
     #   $worksheet13->write(1, 34, "$dbSNP_version, 1000 genomes frequency (EUR) phase 3v5b, ExAC (EUR) Release 1.0, $Clinvar_version, $COSMIC_version"); # DETAILS OF DATABASES - EUR - Somatic
		$worksheet13->write(1, 34, "1000 genomes frequency (EUR) phase 3v5b, gnomAD (EUR) Release 2.1.1"); # DETAILS OF DATABASES - EUR - Somatic
    }

    elsif ($ethnicity =~ m/AMR/i)
    {
     #   $worksheet13->write(1, 34, "$dbSNP_version, 1000 genomes frequency (AMR) phase 3v5b, ExAC (AMR) Release 1.0, $Clinvar_version, $COSMIC_version"); # DETAILS OF DATABASES - AMR - Somatic
		$worksheet13->write(1, 34, "1000 genomes frequency (AMR) phase 3v5b, gnomAD (AMR) Release 2.1.1"); # DETAILS OF DATABASES - AMR - Somatic
    }
    elsif ($ethnicity =~ m/PAN/i)
    {
     #   $worksheet13->write(1, 34, "$dbSNP_version, 1000 genomes frequency (AMR) phase 3v5b, ExAC (AMR) Release 1.0, $Clinvar_version, $COSMIC_version"); # DETAILS OF DATABASES - AMR - Somatic
		$worksheet13->write(1, 34, "1000 genomes frequency phase 3v5b, gnomAD Release 2.1.1"); # DETAILS OF DATABASES - AMR - Somatic
    }

	$worksheet13->write(1, 37, "NA"); # Predicted Tumor Content (Tumor-Normal Paired Analysis)

	if ($foldername2[1] eq 'OCAv3')
	{
		$worksheet13->write(1, 21, "NA"); # Mapped Fusion Panel Reads
		$worksheet13->write(1, 22, "NA"); # Mapped Fusion Molecular Count
		$worksheet13->write(1, 23, "NA"); # Median Read Coverage
		$worksheet13->write(1, 24, "NA"); # Median Molecular Coverage
		$worksheet13->write(1, 26, $Uniformity, $left); # Uniformity (%)
		$worksheet13->write(1, 32, $soft_param_OCAv3);# SOFTWARE PARAMETERS - OCAv3
		$worksheet13->write(1, 35, $pipeline_DNA_OCAv3); # NGS Pipeline
		$worksheet13->write(1, 36, $CNA_baseline_DNA_OCAv3);# CNA baseline - OCAv3 - Somatic
		$worksheet13->write(1, 43, "NA");
		$worksheet13->write(1, 44, "NA");
	}
		if ($foldername2[1] eq 'OCAPlus')
	{
		$worksheet13->write(1, 21, "NA"); # Mapped Fusion Panel Reads
		$worksheet13->write(1, 22, "NA"); # Mapped Fusion Molecular Count
		$worksheet13->write(1, 23, "NA"); # Median Read Coverage
		$worksheet13->write(1, 24, "NA"); # Median Molecular Coverage
		$worksheet13->write(1, 26, $Uniformity, $left); # Uniformity (%)
		$worksheet13->write(1, 32, $soft_param_OCAPlus);# SOFTWARE PARAMETERS - OCAPlus
		$worksheet13->write(1, 35, $pipeline_OCAPlus); # NGS Pipeline
		$worksheet13->write(1, 36, $CNA_baseline_OCAPlus);# CNA baseline - OCAPlus - Somatic
		$worksheet13->write(1, 43, "NA");
		$worksheet13->write(1, 44, "NA");
	}
	
		if ($foldername2[1] eq 'omBRCA')
	{
		$worksheet13->write(1, 21, "NA"); # Mapped Fusion Panel Reads
		$worksheet13->write(1, 22, "NA"); # Mapped Fusion Molecular Count
		$worksheet13->write(1, 23, "NA"); # Median Read Coverage
		$worksheet13->write(1, 24, "NA"); # Median Molecular Coverage
		$worksheet13->write(1, 26, $Uniformity, $left); # Uniformity (%)
		$worksheet13->write(1, 32, $soft_param_omBRCA_somatic);# SOFTWARE PARAMETERS - omBRCA
		$worksheet13->write(1, 35, $pipeline_omBRCA_somatic); # NGS Pipeline
		$worksheet13->write(1, 36, $CNA_baseline_omBRCA);# CNA baseline - omBRCA
		$worksheet13->write(1, 44, "NA");
	}
				if ($foldername2[1] eq 'HRR')
	{
		$worksheet13->write(1, 21, "NA"); # Mapped Fusion Panel Reads
		$worksheet13->write(1, 22, "NA"); # Mapped Fusion Molecular Count
		$worksheet13->write(1, 23, "NA"); # Median Read Coverage
		$worksheet13->write(1, 24, "NA"); # Median Molecular Coverage
		$worksheet13->write(1, 26, $Uniformity, $left); # Uniformity (%)
		$worksheet13->write(1, 32, $soft_param_HRR);# SOFTWARE PARAMETERS - HRR
		$worksheet13->write(1, 35, $pipeline_HRR); # NGS Pipeline
		$worksheet13->write(1, 36, $CNA_baseline_HRR);# CNA baseline - HRR
		$worksheet13->write(1, 44, "NA");
	}
}

	if ($foldername2[1] eq 'omBRCA' && $foldername2[2] =~ m/gDNA/)
{
	$worksheet13->write(1, 21, "NA"); # Mapped Fusion Panel Reads
	$worksheet13->write(1, 22, "NA"); # Mapped Fusion Molecular Count
	$worksheet13->write(1, 23, "NA"); # Median Read Coverage
	$worksheet13->write(1, 24, "NA"); # Median Molecular Coverage
	$worksheet13->write(1, 26, $Uniformity, $left); # Uniformity (%)
	$worksheet13->write(1, 32, $soft_param_omBRCA_germline);# SOFTWARE PARAMETERS - omBRCA
	$worksheet13->write(1, 35, $pipeline_omBRCA_germline); # NGS Pipeline
	$worksheet13->write(1, 36, $CNA_baseline_omBRCA);# CNA baseline - omBRCA
	$worksheet13->write(1, 44, "NA");
}

if ($foldername2[1] eq 'omPAN')
{
	$worksheet13->write(1, 21, $MappedFusionPanelReads, $left); # Mapped Fusion Panel Reads
	$worksheet13->write(1, 22, $MappedFusionMolCount, $left); # Mapped Fusion Molecular Count
    $worksheet13->write(1, 23, $Median_read_cov, $left); # Median Read Coverage
    $worksheet13->write(1, 24, $Median_mol_cov, $left); # Median Molecular Coverage
	$worksheet13->write(1, 26, $mol_uniformity, $left); # Molecular Uniformity (%)
	$worksheet13->write(1, 32, $soft_param_omPAN); # SOFTWARE PARAMETERS - tagseq_pancancer_liquidbiopsy
	$worksheet13->write(1, 35, $pipeline_omPAN); # NGS Pipeline - Oncomine TagSeq Pan (omPAN)
	$worksheet13->write(1, 36, $CNA_baseline_omPAN); # CNA baseline - omPAN - Somatic
	$worksheet13->write(1, 43, $total_fusion); # Fusion
	$worksheet13->write(1, 44, "$ExprControl/2"); # Expression Controls
}

elsif ($foldername2[1] eq 'omLUNG' && $foldername2[2] =~ m/cf[DT]NA/)
{
	$worksheet13->write(1, 21, $MappedFusionPanelReads, $left); # Mapped Fusion Panel Reads
	$worksheet13->write(1, 22, $MappedFusionMolCount, $left); # Mapped Fusion Molecular Count
    $worksheet13->write(1, 23, $Median_read_cov, $left); # Median Read Coverage
    $worksheet13->write(1, 24, $Median_mol_cov, $left); # Median Molecular Coverage
	$worksheet13->write(1, 26, $mol_uniformity, $left); # Molecular Uniformity (%)
	$worksheet13->write(1, 32, $soft_param_omLUNG_liquidbiopsy); # SOFTWARE PARAMETERS - tagseq_lung_liquidbiopsy
	$worksheet13->write(1, 35, $pipeline_omLUNG); # NGS Pipeline Oncomine TagSeq Lung (omLUNG)
	$worksheet13->write(1, 36, $CNA_baseline_omLUNG); # CNA baseline - omLUNG - Somatic
	$worksheet13->write(1, 43, $total_fusion); # Fusion
    $worksheet13->write(1, 44, "$ExprControl/2"); # Expression Controls
}

elsif ($foldername2[1] eq 'omLUNG' && $foldername2[2] !~ m/cf[DT]NA/)
{
	$worksheet13->write(1, 21, $MappedFusionPanelReads, $left); # Mapped Fusion Panel Reads
	$worksheet13->write(1, 22, $MappedFusionMolCount, $left); # Mapped Fusion Molecular Count
    $worksheet13->write(1, 23, $Median_read_cov, $left); # Median Read Coverage
    $worksheet13->write(1, 24, $Median_mol_cov, $left); # Median Molecular Coverage
	$worksheet13->write(1, 26, $mol_uniformity, $left); # Molecular Uniformity (%)
	$worksheet13->write(1, 32, $soft_param_omLUNG_tumor); # SOFTWARE PARAMETERS - tagseq_lung_tumor
	$worksheet13->write(1, 35, $pipeline_omLUNG); # NGS Pipeline Oncomine TagSeq Lung (omLUNG)
	$worksheet13->write(1, 36, $CNA_baseline_omLUNG); # CNA baseline - omLUNG - Somatic
	$worksheet13->write(1, 43, $total_fusion); # Fusion
    $worksheet13->write(1, 44, "$ExprControl/2"); # Expression Controls
}

elsif ($foldername2[3] =~ m/IonHDdual/)
{
	$worksheet13->write(1, 21, "NA", $left); # Mapped Fusion Panel Reads
	$worksheet13->write(1, 22, "NA", $left); # Mapped Fusion Molecular Count
    $worksheet13->write(1, 23, $Median_read_cov, $left); # Median Read Coverage
    $worksheet13->write(1, 24, $Median_mol_cov, $left); # Median Molecular Coverage
	$worksheet13->write(1, 26, $mol_uniformity, $left); # Molecular Uniformity (%)
	$worksheet13->write(1, 32, "ampliseq_hd_cfdna"); # SOFTWARE PARAMETERS
	$worksheet13->write(1, 35, $pipeline_DNA_OCAv3); # NGS Pipeline OCAv3 DNA
	$worksheet13->write(1, 36, "NA"); # CNA baseline
	$worksheet13->write(1, 43, "NA"); # Fusion
    $worksheet13->write(1, 44, "NA"); # Expression Controls
}

$worksheet13->write(1, 28, "Pass");
$worksheet13->write(1, 29, "---");
	
if ($CNAqc eq 'Fail')
{
    $worksheet13->write(1, 28, "CNA QC Fail");
    $worksheet13->write(1, 29, "CNA QC Fail");
}

if ($FusionSampleQC =~ m/FAIL/i)

{
    $worksheet13->write(1, 28, "Fusion QC Fail");
    $worksheet13->write(1, 29, "Fusion QC Fail");
}

if ($CNAqc eq 'Fail' && $FusionSampleQC =~ m/FAIL/i)

{
    $worksheet13->write(1, 28, "CNA and Fusion QC Fail");
    $worksheet13->write(1, 29, "CNA and Fusion QC Fail");
}

$worksheet13->write(1, 30, $TMAP_version); # ALIGNER version
$worksheet13->write(1, 38, $row_filtered-1); # TOTAL VARIANTS
$worksheet13->write(1, 39, $ReportedVariants); # REPORTED VARIANTS
$worksheet13->write(1, 40, $SNVs); # SNV
$worksheet13->write(1, 41, $Indels); # INDEL
$worksheet13->write(1, 42, $row_cnaR-1); # CNV
$worksheet13->write(1, 45, "NA"); # Total 5'/3' Assay Present
$worksheet13->write(1, 46, "---"); # Sanger
$worksheet13->write(1, 47, "---"); # ddPCR
#$worksheet13->write(1, 48, "---"); # Comment
if ($foldername2[2] =~ m/TNA/)
    {
	$worksheet13->write(1, 48, $Sample_LOD); # Comment
	}
	else {
		$worksheet13->write(1, 48, "---"); # Comment
		}




if ($foldername2[2] =~ m/RNA/)
{
	$worksheet13->write(1, 13, "NA");
	$worksheet13->write(1, 14, "NA");
	$worksheet13->write(1, 15, "NA");
	$worksheet13->write(1, 16, "NA");
	$worksheet13->write(1, 17, "NA");
	$worksheet13->write(1, 18, "NA");
	$worksheet13->write(1, 19, "NA");
	$worksheet13->write(1, 20, "NA");
	$worksheet13->write(1, 21, $MappedFusionPanelReads); # Mapped Fusion Panel Reads
	$worksheet13->write(1, 22, "NA"); # Mapped Fusion Molecular Count
	$worksheet13->write(1, 23, "NA"); # Median Read Coverage
	$worksheet13->write(1, 24, "NA"); # Median Molecular Coverage
	$worksheet13->write(1, 25, "NA"); # On Target (%)
	$worksheet13->write(1, 26, "NA"); # Uniformity (%)
	$worksheet13->write(1, 27, "NA"); # MAPD
	$worksheet13->write(1, 31, "NA");
	$worksheet13->write(1, 32, "Medium Sensitivity");
	$worksheet13->write(1, 33, $IR_version); # IR version
	$worksheet13->write(1, 34, $COSMIC_version_fusion); #COSMIC version RNA
	$worksheet13->write(1, 35, $pipeline_RNA_fusion_OCAv3); #NGS Pipeline - OCAv3 Fusion
	$worksheet13->write(1, 36, "NA");
	$worksheet13->write(1, 37, "NA");
	$worksheet13->write(1, 38, "NA");
	$worksheet13->write(1, 39, "NA");
	$worksheet13->write(1, 40, "NA");
	$worksheet13->write(1, 41, "NA");
	$worksheet13->write(1, 42, "NA"); # CNA
	$worksheet13->write(1, 43, $total_fusion); # Fusion

    if ($coutfusion == 0)    
    {
        $worksheet13->write(1, 43, "0");
    }

    $worksheet13->write(1, 46, "NA");
	$worksheet13->write(1, 47, "NA");
	$worksheet13->write(1, 44, "$ExprControl/6"); # Fusion controls at-least 2 out of 6
}
$worksheet13->write(1, 49, $Analyst, $left); # PERFORMED BY
$worksheet13->write(1, 50, "Harshal Darokar"); # Reviewer
$worksheet13->write(1, 51, $uniqueID); # Unique Identification

######################### MSI data start
		if ($foldername2[1] eq 'OCAPlus')
		{
$TMB = `grep -- "TMBMutationsPerMb" Variants/$foldername2[0]*/$foldername2[0]*_Non-Filtered_*.vcf | sed 's/##TMBMutationsPerMb=//g'`;
$worksheet13->write(1, 52, round ($TMB)); # TMB
			open my $fh_OCAplus, "<", "MSI/Summary.tsv";
			@msi_data = <$fh_OCAplus>;
			@msi_header = split("\t",$msi_data[0]);

						 for ($msi_count=0;$msi_count <= scalar @msi_header;$msi_count++)
						 {
							 if ($msi_header[$msi_count] eq "MSI Status")
							 {
							 $msi_status_col = $msi_count;
							 }
							 if ($msi_header[$msi_count] eq "MSI Score")
							 {
							 $msi_score_col = $msi_count;
							 }
							
						 }
							@msi_line = split("\t",$msi_data[1]);
							$msi_status = $msi_line[$msi_status_col];
							chomp $msi_status;
							$msi_score = $msi_line[$msi_score_col];
							chomp $msi_score;
			$worksheet13->write(1, 53, $msi_status); # MSI Status
			$worksheet13->write(1, 54, $msi_score); # MSI Score
$LOH =`grep -- "percentLOH" $foldername-CnvActor/TumorFraction/tumor_fraction.json | sed 's/    \"percentLOH\": //g' | sed 's/,/%/'`;
chomp $LOH;
$worksheet13->write(1, 55, $LOH); # LOH
		}
######################### MSI data end
		else
		{
			$worksheet13->write(1, 52, "NA"); # TMB
			$worksheet13->write(1, 53, "NA"); # MSI Status
			$worksheet13->write(1, 54, "NA"); # MSI Score
			$worksheet13->write(1, 55, "NA"); # LOH

		}

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
		$tmp_floor_fusion = '';
		$tmp_celing_fusion = '';
		$tmp_non_floor_fusion = '';
		$tmp_non_celing_fusion = '';
		foreach $cl_db (@cl_db)
		{
			chomp $cl_db;
			@cl_db_line=split('\t',$cl_db);
			
			foreach $data_for_cl (@data)
			{
				@data_for_cl_line=split('\t',$data_for_cl);
				        $data_for_cl_line[$IRref]=~s/-//g;
						$data_for_cl_line[$IRalt]=~s/-//g;
			
					if (($cl_db_line[9] =~m/:$cancer_type:/))
						{
							#for SNV/Indel
							if (($data_for_cl_line[$IRchr] eq $cl_db_line[2]) && ($data_for_cl_line[$IRpos] eq $cl_db_line[3]) && ($data_for_cl_line[$IRref] eq $cl_db_line[4]) && ($data_for_cl_line[$IRalt] eq $cl_db_line[5]))
								{
									$cl_var_pos = $cl_db_line[0]."\t".$cl_db_line[1]."\t".$cl_db_line[7]."\t".$cl_db_line[8];
									if ($data_for_cl_line[$IRFAO] <= $tmp_floor)
									{
									push (@can_specific_var,$cl_var_pos."\t".$data_for_cl_line[$IRFAO]."\t".$data_for_cl_line[$IRFDP]."\t".sprintf ("%.2f",($data_for_cl_line[$IRFAO]/$data_for_cl_line[$IRFDP])*100));
									$tmp_floor = $data_for_cl_line[$IRFAO];
									}
									elsif ($data_for_cl_line[$IRFAO] > $tmp_celing)
									{
									unshift (@can_specific_var,$cl_var_pos."\t".$data_for_cl_line[$IRFAO]."\t".$data_for_cl_line[$IRFDP]."\t".sprintf ("%.2f",($data_for_cl_line[$IRFAO]/$data_for_cl_line[$IRFDP])*100));
									$tmp_celing = $data_for_cl_line[$IRFAO];
									}

								}
							#for Fusion
							elsif (($data_for_cl_line[$GENE] eq $cl_db_line[1]) && ($data_for_cl_line[$rowtype] eq $cl_db_line[0]) && ($data_for_cl_line[$var_id] !~ m/WT/))
								{
									if ($data_for_cl_line[$ReadCount] <= $tmp_floor_fusion)
									{
									push (@can_specific_var,"---"."\t".$cl_db_line[1]."\t".$data_for_cl_line[$var_id]."\t"."---"."\t".$data_for_cl_line[$ReadCount]."\t".$data_for_cl_line[$MolCount]."\t"."---"."\t"."---");
									$tmp_floor_fusion = $data_for_cl_line[$ReadCount];
									}
									elsif ($data_for_cl_line[$ReadCount] > $tmp_celing_fusion)
									{
									unshift (@can_specific_var,"---"."\t".$cl_db_line[1]."\t".$data_for_cl_line[$var_id]."\t"."---"."\t".$data_for_cl_line[$ReadCount]."\t".$data_for_cl_line[$MolCount]."\t"."---"."\t"."---");
									$tmp_celing_fusion = $data_for_cl_line[$ReadCount];
									}

								}
						}
						else
						{	#for SNV/Indel
							if (($data_for_cl_line[$IRchr] eq $cl_db_line[2]) && ($data_for_cl_line[$IRpos] eq $cl_db_line[3]) && ($data_for_cl_line[$IRref] eq $cl_db_line[4]) && ($data_for_cl_line[$IRalt] eq $cl_db_line[5]))
							{
									$cl_var_pos = $cl_db_line[0]."\t".$cl_db_line[1]."\t".$cl_db_line[7]."\t".$cl_db_line[8];
									if ($data_for_cl_line[$IRFAO] <= $tmp_non_floor)
									{
									push (@non_specific_var,$cl_var_pos."\t".$data_for_cl_line[$IRFAO]."\t".$data_for_cl_line[$IRFDP]."\t".sprintf ("%.2f",($data_for_cl_line[$IRFAO]/$data_for_cl_line[$IRFDP])*100));
									$tmp_non_floor = $data_for_cl_line[$IRFAO];
									}
									elsif ($data_for_cl_line[$IRFAO] > $tmp_non_celing)
									{
									unshift (@non_specific_var,$cl_var_pos."\t".$data_for_cl_line[$IRFAO]."\t".$data_for_cl_line[$IRFDP]."\t".sprintf ("%.2f",($data_for_cl_line[$IRFAO]/$data_for_cl_line[$IRFDP])*100));
									$tmp_non_celing = $data_for_cl_line[$IRFAO];
									}
									
							}
								#for Fusion
							elsif (($data_for_cl_line[$GENE] eq $cl_db_line[1]) && ($data_for_cl_line[$rowtype] eq $cl_db_line[0]) && ($data_for_cl_line[$var_id] !~ m/WT/))
							{
								if ($data_for_cl_line[$ReadCount] <= $tmp_non_floor_fusion)
								{
								push (@non_specific_var,"---"."\t".$cl_db_line[1]."\t".$data_for_cl_line[$var_id]."\t"."---"."\t".$data_for_cl_line[$ReadCount]."\t".$data_for_cl_line[$MolCount]."\t"."---"."\t"."---");
								$tmp_non_floor_fusion = $data_for_cl_line[$ReadCount];
								}
								elsif ($data_for_cl_line[$ReadCount] > $tmp_non_celing_fusion)
								{
								unshift (@non_specific_var,"---"."\t".$cl_db_line[1]."\t".$data_for_cl_line[$var_id]."\t"."---"."\t".$data_for_cl_line[$ReadCount]."\t".$data_for_cl_line[$MolCount]."\t"."---"."\t"."---");
								$tmp_non_celing_fusion = $data_for_cl_line[$ReadCount];
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
			$worksheet12->write($checklist_row_count, 5, $can_specific_var_line[5],$left);
						
								if (($foldername2[2] =~ m/cf[DT]NA/) && ($can_specific_var_line[6] < 0.1) && ($can_specific_var_line[6] > 0) && ($can_specific_var_line[4] > 1)&& ($can_specific_var_line[4] < 6))
								{
								$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4],$redbold);
								$worksheet12->write($checklist_row_count, 6, $can_specific_var_line[6],$redbold);
								$worksheet12->write($checklist_row_count, 7, "Alert if ddPCR assay available",$redbold);
								}
								elsif (($foldername2[2] !~ m/cf[DT]NA/) && ($foldername2[1] =~ m/omLUNG/) &&($can_specific_var_line[6] > 2.5) && ($can_specific_var_line[4] > 1) && ($can_specific_var_line[4] < 6))
								{
								$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4],$redbold);
								$worksheet12->write($checklist_row_count, 6, $can_specific_var_line[6],$redbold);
								$worksheet12->write($checklist_row_count, 7, "Unassignable variant",$redbold);
								}
								elsif (($foldername2[2] =~ m/cf[DT]NA/) && ($can_specific_var_line[6] >= 0.1) && ($can_specific_var_line[4] > 5))
								{
								$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4],$greenbold);
								$worksheet12->write($checklist_row_count, 6, $can_specific_var_line[6],$greenbold);
								$worksheet12->write($checklist_row_count, 7, "Detected?",$greenbold);
								}
								elsif (($foldername2[2] !~ m/cf[DT]NA/) && ($foldername2[1] =~ m/OCA/ || $foldername2[1] =~ m/HRR/) &&($can_specific_var_line[6] > 2.5) && ($can_specific_var_line[4] > 5) && ($can_specific_var_line[4] < 20))
								{
								$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4],$redbold);
								$worksheet12->write($checklist_row_count, 6, $can_specific_var_line[6],$redbold);
								$worksheet12->write($checklist_row_count, 7, "Unassignable variant",$redbold);
								}
								elsif (($foldername2[2] !~ m/cf[DT]NA/) && ($foldername2[1] =~ m/omLUNG/) && ($can_specific_var_line[6] >= 5) && ($can_specific_var_line[4] >= 6))
								{
								$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4],$greenbold);
								$worksheet12->write($checklist_row_count, 6, $can_specific_var_line[6],$greenbold);
								$worksheet12->write($checklist_row_count, 7,"Detected?",$left);
								}
								elsif (($foldername2[2] !~ m/cf[DT]NA/) && ($foldername2[1] =~ m/OCA/ || $foldername2[1] =~ m/HRR/) && ($can_specific_var_line[6] >= 5) && ($can_specific_var_line[4] >= 20))
								{
								$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4],$greenbold);
								$worksheet12->write($checklist_row_count, 6, $can_specific_var_line[6],$greenbold);
								$worksheet12->write($checklist_row_count, 7,"Detected?",$left);
								}
								elsif ($can_specific_var_line[0] eq "---")
								{
										if ($can_specific_var_line[5] > 1)
										{
										$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4]." (Read count)",$redbold);
										$worksheet12->write($checklist_row_count, 5, $can_specific_var_line[5]." (Mol count)",$redbold);
										}
										else
										{
										$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4]." (Read count)",$left);
										$worksheet12->write($checklist_row_count, 5, $can_specific_var_line[5]." (Mol count)",$left);									
										}
								}
								else
								{
								$worksheet12->write($checklist_row_count, 4, $can_specific_var_line[4],$left);
								$worksheet12->write($checklist_row_count, 6, $can_specific_var_line[6],$left);
								$worksheet12->write($checklist_row_count, 7,"---",$left);
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
			$worksheet12->write($non_checklist_row_count, 5, $non_specific_var_line[5],$left);
								if (($foldername2[2] =~ m/cf[DT]NA/) && ($non_specific_var_line[6] < 0.1) && ($non_specific_var_line[6] > 0) && ($non_specific_var_line[4] > 1)&& ($non_specific_var_line[4] < 6))
								{
								$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4],$redbold);
								$worksheet12->write($non_checklist_row_count, 6, $non_specific_var_line[6],$redbold);
								$worksheet12->write($non_checklist_row_count, 7, "Alert if ddPCR assay available",$redbold);
								}
								elsif (($foldername2[2] !~ m/cf[DT]NA/) && ($foldername2[1] =~ m/omLUNG/) &&($non_specific_var_line[6] > 2.5) && ($non_specific_var_line[4] > 1) && ($non_specific_var_line[4] < 6))
								{
								$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4],$redbold);
								$worksheet12->write($non_checklist_row_count, 6, $non_specific_var_line[6],$redbold);
								$worksheet12->write($non_checklist_row_count, 7, "Unassignable variant",$redbold);
								}
								elsif (($foldername2[2] =~ m/cf[DT]NA/) && ($non_specific_var_line[6] >= 0.1) && ($non_specific_var_line[4] > 5))
								{
								$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4],$greenbold);
								$worksheet12->write($non_checklist_row_count, 6, $non_specific_var_line[6],$greenbold);
								$worksheet12->write($non_checklist_row_count, 7, "Detected?",$greenbold);
								}
								elsif (($foldername2[2] !~ m/cf[DT]NA/) && ($foldername2[1] =~ m/OCA/ || $foldername2[1] =~ m/HRR/) &&($non_specific_var_line[6] > 2.5) && ($non_specific_var_line[4] > 5) && ($non_specific_var_line[4] < 20))
								{
								$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4],$redbold);
								$worksheet12->write($non_checklist_row_count, 6, $non_specific_var_line[6],$redbold);
								$worksheet12->write($non_checklist_row_count, 7, "Unassignable variant",$redbold);
								}
								elsif (($foldername2[2] !~ m/cf[DT]NA/) && ($foldername2[1] =~ m/omLUNG/) && ($non_specific_var_line[6] >= 5) && ($non_specific_var_line[4] >= 6))
								{
								$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4],$greenbold);
								$worksheet12->write($non_checklist_row_count, 6, $non_specific_var_line[6],$greenbold);
								$worksheet12->write($non_checklist_row_count, 7,"Detected?",$left);
								}
								elsif (($foldername2[2] !~ m/cf[DT]NA/) && ($foldername2[1] =~ m/OCA/ || $foldername2[1] =~ m/HRR/) && ($non_specific_var_line[6] >= 5) && ($non_specific_var_line[4] >= 20))
								{
								$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4],$greenbold);
								$worksheet12->write($non_checklist_row_count, 6, $non_specific_var_line[6],$greenbold);
								$worksheet12->write($non_checklist_row_count, 7,"Detected?",$left);
								}
								elsif ($non_specific_var_line[0] eq "---")
								{
										if ($non_specific_var_line[5] > 1)
										{
										$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4]." (Read count)",$redbold);
										$worksheet12->write($non_checklist_row_count, 5, $non_specific_var_line[5]." (Mol count)",$redbold);
										}
										else
										{
										$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4]." (Read count)",$left);
										$worksheet12->write($non_checklist_row_count, 5, $non_specific_var_line[5]." (Mol count)",$left);									
										}
								}
								else
								{
								$worksheet12->write($non_checklist_row_count, 4, $non_specific_var_line[4],$left);
								$worksheet12->write($non_checklist_row_count, 6, $non_specific_var_line[6],$left);
								$worksheet12->write($non_checklist_row_count, 7,"---",$left);
								}
			$non_checklist_row_count = $non_checklist_row_count+1;
			}
###########################################################################  Checklist END  #########################################################################
}

$endtime = strftime "%I:%M %p", localtime;

print "\n\n\n******************************************************** Sample Analysis Completed on $date at $endtime ********************************************************\n\n\n";

close (STDOUT);

exit;

