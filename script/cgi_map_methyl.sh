#!/usr/bin/env bash
#SBATCH --job-name=CGI_methylation
#SBATCH -o /home/xuyanbo/logs/%A_%a_%x.log
#SBATCH -e /home/xuyanbo/logs/%A_%a_%x.log
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --array=0-8%9

set -euo pipefail

module load bedtools/2.31.0

project_dir=/home/xuyanbo/project/MOF_TAPS
bins=${project_dir}/analysis/fig_factory/fig/Fig5/cgi/hg38_cpgIslandExt.profile_bins.bed
bg_dir=${project_dir}/analysis/HeLa_gDNA/result/05methy_call/filter_taps_bedGraph
outdir=${project_dir}/analysis/fig_factory/fig/Fig5/cgi/methylation_bins
mkdir -p ${outdir}

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
bg=${bg_dir}/${sample}.minTotal3.filter_taps.bedGraph

tmpdir=${outdir}/tmp_${sample}_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}
mkdir -p ${tmpdir}

sorted_bg=${tmpdir}/${sample}.sorted.bedGraph

sort -k1,1 -k2,2n ${bg} > ${sorted_bg}

# bins columns:
# 1 chrom
# 2 start
# 3 end
# 4 cgi_id
# 5 cgi_name
# 6 region
# 7 bin_index
# 8 profile_bin
#
# bedGraph columns:
# 1 CHROM
# 2 START
# 3 END
# 4 TAPS_READOUT_PCT
# 5 TAPS_POSITIVE_COUNT
# 6 TOTAL_INFORMATIVE_COUNT
#
# Output adds:
# mean_pct, sum_positive, sum_total, cpg_count
bedtools map \
  -a ${bins} \
  -b ${sorted_bg} \
  -c 4,5,6,4 \
  -o mean,sum,sum,count \
  -null . \
  -sorted \
> ${outdir}/${sample}.CGI_bins.methylation.tsv

rm -rf ${tmpdir}
echo "[DONE] ${outdir}/${sample}.CGI_bins.methylation.tsv"