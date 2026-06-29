#!/bin/bash
#SBATCH --job-name=smk_cfDNA
#SBATCH -o /home/xuyanbo/logs/%j_%x.log 
#SBATCH -e /home/xuyanbo/logs/%j_%x.log 
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2

# Yanbo Xu
# 2026-06-22

eval "$(conda shell.bash hook)"
conda activate run_snakemake

cd /home/xuyanbo/project/MOF_TAPS/analysis/cfDNA/script

snakemake --jobs 200 --cores 64 \
    --default-resources mem_mb=8000 \
    --cluster "sbatch --partition=cpu --cpus-per-task={threads} --mem={resources.mem_mb}M -o /home/xuyanbo/logs/%j_%x.log -e /home/xuyanbo/logs/%j_%x.log" \
    --latency-wait 10 \
    --keep-going \
    --rerun-incomplete \
    --printshellcmds