#!/bin/bash
#SBATCH --job-name=md5
#SBATCH -o /home/xuyanbo/logs/%j_%x.log 
#SBATCH -e /home/xuyanbo/logs/%j_%x.log 
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --array=0-26%27

# Yanbo Xu
# 2026-06-16

set -euo pipefail

TSV="/home/xuyanbo/project/MOF_TAPS/raw_data/GEO_files.tsv"
OUTDIR="/home/xuyanbo/project/MOF_TAPS/raw_data/md5_parts"

mkdir -p "$OUTDIR"

line="$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$TSV")"
file="$(printf "%s\n" "$line" | cut -f1)"

md5sum "$file" > "$OUTDIR/md5_${SLURM_ARRAY_TASK_ID}.txt"