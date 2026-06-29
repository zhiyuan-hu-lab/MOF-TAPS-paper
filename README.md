# Interfacial MOF catalysis integrates epigenetic conversion with amplification in low-input DNA methylation sequencing

Yumin Feng<sup>1,†</sup>, Yanbo Xu<sup>2,†</sup>, Zipeng Wang<sup>1,†</sup>, Long Yu<sup>3</sup>, Cong Ding<sup>1</sup>, Mengjun Wang<sup>2</sup>, Shuang Peng<sup>1</sup>, Xiang Zhou<sup>1,* </sup>, Zhiyuan Hu<sup>2,* </sup>, and Yibin Liu<sup>1,* </sup>

<sup>1</sup> State Key Laboratory of Metabolism and Regulation in Complex Organisms, College of Chemistry and Molecular Sciences, Taikang Center for Life and Medical Sciences, Wuhan University, Wuhan 430072, China 

<sup>2</sup> Reproductive Medicine Center, Medical Research Institute, Frontier Science Center for Immunology and Metabolism, Zhongnan Hospital, Wuhan University, Wuhan 430072, China 

<sup>3</sup> Department of Laboratory Medicine, Zhongnan Hospital of Wuhan University, Wuhan 430071, China

<sup>†</sup> These authors contributed equally to this work. 

<sup>* </sup> Correspondence: liuyibin@whu.edu.cn, zhiyuan.hu@whu.edu.cn,xzhou@whu.edu.cn

## Data preprocessing

Containing The pipeline using Snakemake consists steps from QC to methylation calling. Code in `analysis/HeLa_gDNA/script` and `analysis/cfDNA/script`.

1. raw data downsampling
2. trimming & QC
3. mapping to reference genome with spike-in
4. deduplication
5. M-bias profile & methylation calling

## Fig factory

Figures of methylation sequencing part. Processing code in `script`, and notebook in `analysis/fic_factory`.

* HeLa gDNA metrics barplot: `analysis/fic_factory/Fig5_hela_benchmark.qmd`
* HeLa gDNA curve plotof CpG covered in multiple cutoff: `script/count_CpG_depth.sh`, `analysis/fig_factory/FigSI_hela_cpg_cutoff_curve.ipynb`
* HeLa gDNA venn plot of CpGs overlap: `script/cpg_venn.sh`, `analysis/fig_factory/FigSI_hela_venn.ipynb`
* HeLa methylation level and coverage profile in CGI and flanking regions: `script/cgi_profile_bins.R`, `script/cgi_map_coverage_nodown.sh`, `script/cgi_map_methyl.sh`, `analysis/fig_factory/Fig5_cgi_profile.qmd`
* cfDNA correlation scatter plot: `analysis/fig_factory/Fig6_correlation.qmd`
* cfDNA metrics barplot: `analysis/fig_factory/FigSI_cfDNA_metrics.qmd`

