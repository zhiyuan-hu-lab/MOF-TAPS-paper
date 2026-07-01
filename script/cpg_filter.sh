#!/usr/bin/env bash
#SBATCH --job-name=cpg_filter
#SBATCH -o /home/xuyanbo/logs/%A_%a_%x.log
#SBATCH -e /home/xuyanbo/logs/%A_%a_%x.log
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --array=0-11%12

set -euo pipefail

module load bedtools/2.31.0

dbsnp_bed=/home/xuyanbo/ref/hg38/SNP/dbSNP153.BED3.sorted.bed
centromere_bed=/home/xuyanbo/ref/hg38/centromeres/centromeres.hg38.sorted.bed
blacklist_bed=/home/xuyanbo/ref/hg38/blacklist/hg38-blacklist.v2.bed

raw_dir=/home/xuyanbo/project/MOF_TAPS/analysis/cfDNA/result/05methy_call/raw_bedGraph
out_dir=/home/xuyanbo/project/MOF_TAPS/analysis/cfDNA/result/05methy_call/filter_bedGraph

samples=(
  FYM_260410_S01
  FYM_260410_S02
  FYM_260410_S03
  FYM_260410_S04
  FYM_260410_S05
  FYM_260410_S06
  FYM_260410_S07
  FYM_260410_S08
  FYM_260410_S09
  FYM_260410_S10
  FYM_260410_S11
  FYM_260410_S12
)

mkdir -p "${out_dir}"

sample=${samples[$SLURM_ARRAY_TASK_ID]}

raw_bedgraph="${raw_dir}/${sample}.dedup.mergeContext_CpG.bedGraph"
output="${out_dir}/${sample}.dedup.filtered.mergeContext_CpG.bedGraph"

awk 'BEGIN{OFS="\t"}
    $1 !~ /^(track|browser|#)/ &&
    $1 ~ /^chr([1-9]|1[0-9]|2[0-2])$/ {
        print $1,$2,$3,$4,$5,$6
    }' "${raw_bedgraph}" \
    | sort -k1,1 -k2,2n \
    | bedtools intersect \
        -a - \
        -b <(
            cat "${dbsnp_bed}" "${centromere_bed}" "${blacklist_bed}" \
                | awk 'BEGIN{OFS="\t"} $1 ~ /^chr([1-9]|1[0-9]|2[0-2])$/ {print $1,$2,$3}' \
                | sort -k1,1 -k2,2n
        ) \
        -v \
        -sorted \
    > "${output}"