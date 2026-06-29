#!/usr/bin/env bash
#SBATCH --job-name=CGI_coverage_raw
#SBATCH -o /home/xuyanbo/logs/%A_%a_%x.log
#SBATCH -e /home/xuyanbo/logs/%A_%a_%x.log
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --array=0-8%9

set -euo pipefail

module load samtools/1.18
module load bedtools/2.31.0

project_dir=/home/xuyanbo/project/MOF_TAPS

bins=${project_dir}/analysis/fig_factory/fig/Fig5/cgi/hg38_cpgIslandExt.profile_bins.bed
bam_dir=${project_dir}/analysis/HeLa_gDNA/result/04dedup
outdir=${project_dir}/analysis/fig_factory/fig/Fig5/cgi/coverage_bins_raw_dedup

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
bam=${bam_dir}/${sample}.dedup.bam

tmpdir=${outdir}/tmp_${sample}_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}
mkdir -p ${tmpdir}

depth_bg=${tmpdir}/${sample}.CGI_bins.per_base_depth.bedGraph

samtools depth \
  -aa \
  -b ${bins} \
  -Q 0 \
  -q 0 \
  ${bam} \
| awk 'BEGIN{OFS="\t"} {print $1,$2-1,$2,$3}' \
| LC_ALL=C sort \
    --parallel=${SLURM_CPUS_PER_TASK} \
    -S 2G \
    -T ${tmpdir} \
    -k1,1 -k2,2n \
> ${depth_bg}

bedtools map \
  -a ${bins} \
  -b ${depth_bg} \
  -c 4 \
  -o mean \
  -null 0 \
  -sorted \
> ${outdir}/${sample}.CGI_bins.coverage.tsv

rm -rf ${tmpdir}

echo "[DONE] ${outdir}/${sample}.CGI_bins.coverage.tsv"