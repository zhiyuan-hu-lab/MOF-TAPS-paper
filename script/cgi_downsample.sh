#!/usr/bin/env bash
#SBATCH --job-name=hela_bam_downsample
#SBATCH -o /home/xuyanbo/logs/%A_%a_%x.log
#SBATCH -e /home/xuyanbo/logs/%A_%a_%x.log
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --array=0-8%9

set -euo pipefail

module load samtools/1.18

project_dir=/home/xuyanbo/project/MOF_TAPS

bam_dir=${project_dir}/analysis/HeLa_gDNA/result/04dedup
cgi_dir=${project_dir}/analysis/fig_factory/fig/Fig5/cgi
plan=${cgi_dir}/bam_counts/HeLa_BAM_downsample_plan.tsv

outdir=${cgi_dir}/downsampled_bam_chr1_22
mkdir -p ${outdir}

ref_fai=/home/xuyanbo/ref/methy_seq/148bp_unmodified_spikein_plus_5fc_5hmc_5cac.fa.fai
autosome_bed=${cgi_dir}/hg38.chr1_22.bed

if [[ ! -s ${autosome_bed} ]]; then
  awk 'BEGIN{OFS="\t"} $1 ~ /^chr([1-9]|1[0-9]|2[0-2])$/ {print $1,0,$2}' \
    ${ref_fai} \
  > ${autosome_bed}
fi

sample=$(awk -v i=$((SLURM_ARRAY_TASK_ID + 2)) 'BEGIN{FS="\t"} NR==i {print $1}' ${plan})
frac=$(awk -v i=$((SLURM_ARRAY_TASK_ID + 2)) 'BEGIN{FS="\t"} NR==i {print $6}' ${plan})

bam=${bam_dir}/${sample}.dedup.bam
out_bam=${outdir}/${sample}.chr1_22.depthEligible.downsampled.bam

tmpdir=${outdir}/tmp_${sample}_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}
mkdir -p ${tmpdir}

seed=$((1000 + SLURM_ARRAY_TASK_ID))

# samtools -s requires INT.FRAC format. If frac=1, keep all.
if awk -v f="${frac}" 'BEGIN{exit !(f >= 0.999999)}'; then
  samtools view \
    -@ ${SLURM_CPUS_PER_TASK} \
    -b \
    -F 1796 \
    -L ${autosome_bed} \
    ${bam} \
  | samtools sort \
      -@ ${SLURM_CPUS_PER_TASK} \
      -T ${tmpdir}/${sample} \
      -o ${out_bam} -
else
  samtools view \
    -@ ${SLURM_CPUS_PER_TASK} \
    -b \
    -F 1796 \
    -L ${autosome_bed} \
    -s ${seed}.${frac#0.} \
    ${bam} \
  | samtools sort \
      -@ ${SLURM_CPUS_PER_TASK} \
      -T ${tmpdir}/${sample} \
      -o ${out_bam} -
fi

samtools index -@ ${SLURM_CPUS_PER_TASK} ${out_bam}

samtools view -c ${out_bam} \
> ${outdir}/${sample}.chr1_22.depthEligible.downsampled.count.txt

rm -rf ${tmpdir}

echo "[DONE] ${out_bam}"