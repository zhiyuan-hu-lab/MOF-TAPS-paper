#!/bin/bash
#SBATCH --job-name=seqkit
#SBATCH -o /home/xuyanbo/logs/%j_%x.log 
#SBATCH -e /home/xuyanbo/logs/%j_%x.log 
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mail-type=END
#SBATCH --mail-user=yanboxu@whu.edu.cn

# Yanbo Xu
# 2026-02-04

eval "$(conda shell.bash hook)"
conda activate bioinfo

cd /home/xuyanbo/project/MCC/raw_data/20260622
seqkit stats -j 8 */*.fq.gz > fq_stats_summary.txt