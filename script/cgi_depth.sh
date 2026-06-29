#!/usr/bin/env bash
#SBATCH --job-name=bam_count
#SBATCH -o /home/xuyanbo/logs/%A_%a_%x.log
#SBATCH -e /home/xuyanbo/logs/%A_%a_%x.log
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --array=0-8%9

set -euo pipefail

module load samtools/1.18

project_dir=/home/xuyanbo/project/MOF_TAPS

bam_dir=${project_dir}/analysis/HeLa_gDNA/result/04dedup
outdir=${project_dir}/analysis/fig_factory/fig/Fig5/cgi/bam_counts
mkdir -p ${outdir}

bins=${project_dir}/analysis/fig_factory/fig/Fig5/cgi/hg38_cpgIslandExt.profile_bins.bed

ref_fai=/home/xuyanbo/ref/methy_seq/148bp_unmodified_spikein_plus_5fc_5hmc_5cac.fa.fai
autosome_bed=${outdir}/hg38.chr1_22.bed

if [[ ! -s ${autosome_bed} ]]; then
  awk 'BEGIN{OFS="\t"} $1 ~ /^chr([1-9]|1[0-9]|2[0-2])$/ {print $1,0,$2}' \
    ${ref_fai} \
  > ${autosome_bed}
fi

samples=(
  fym260106_S01
  fym260106_S02
  fym260106_S03
  fym260106_S04
  fym260106_S05
  fym260106_S06
  fym260124_S04
  fym260124_S05
  fym260124_S06
)

sample=${samples[$SLURM_ARRAY_TASK_ID]}
bam=${bam_dir}/${sample}.dedup.bam
out=${outdir}/${sample}.bam_count.tsv

all_records=$(samtools view -c ${bam})

depth_eligible_all=$(samtools view -c -F 1796 ${bam})

depth_eligible_chr1_22=$(samtools view -c -F 1796 -L ${autosome_bed} ${bam})

depth_eligible_CGI_bins=$(samtools view -c -F 1796 -L ${bins} ${bam})

proper_pair_R1_depth_eligible_all=$(samtools view -c -f 66 -F 1796 ${bam})

proper_pair_R1_depth_eligible_chr1_22=$(samtools view -c -f 66 -F 1796 -L ${autosome_bed} ${bam})

echo -e "sample\tall_records\tdepth_eligible_all\tdepth_eligible_chr1_22\tdepth_eligible_CGI_bins\tproper_pair_R1_depth_eligible_all\tproper_pair_R1_depth_eligible_chr1_22" > ${out}

echo -e "${sample}\t${all_records}\t${depth_eligible_all}\t${depth_eligible_chr1_22}\t${depth_eligible_CGI_bins}\t${proper_pair_R1_depth_eligible_all}\t${proper_pair_R1_depth_eligible_chr1_22}" >> ${out}

echo "[DONE] ${out}"