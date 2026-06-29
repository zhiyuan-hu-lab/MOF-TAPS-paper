#!/bin/bash
#SBATCH --job-name=cpg_cutoff_curve_hela
#SBATCH -o /home/xuyanbo/logs/%A_%a_%x.log
#SBATCH -e /home/xuyanbo/logs/%A_%a_%x.log
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mail-type=END
#SBATCH --array=0-8%9

set -euo pipefail

project_dir=/home/xuyanbo/project/MOF_TAPS
result_dir=${project_dir}/analysis/HeLa_gDNA/result
bedgraph_dir=${result_dir}/05methy_call/raw_bedGraph

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

input_candidates=(
    "${bedgraph_dir}/${sample}.dedup.mergeContext_CpG.bedGraph"
    "${bedgraph_dir}/${sample}.dedup.mergeContext_CpG.bedGraph.gz"
)

input_file=""
for f in "${input_candidates[@]}"; do
    if [[ -f "${f}" ]]; then
        input_file="${f}"
        break
    fi
done

if [[ -z "${input_file}" ]]; then
    echo "Missing MethylDackel raw bedGraph for ${sample}" >&2
    exit 1
fi

outdir=${project_dir}/analysis/fig_factory/fig/FigSI/hela_cpg_cutoff_curve
mkdir -p "${outdir}"

# MethylDackel raw mergeContext CpG bedGraph:
# $5 = MD_METH, $6 = MD_UNMETH
# informative depth = $5 + $6
#
# Output:
# sample  cutoff  covered_cpgs
zcat -f "${input_file}" |
awk -F'\t' -v OFS='\t' -v sample="${sample}" -v MAX=20 '
    $1 ~ /^(track|browser|#)/ { next }

    {
        depth = int(($5 + $6) + 0)

        if (depth < 1) next
        if (depth > MAX) depth = MAX

        depth_count[depth]++
    }

    END {
        cumulative = 0

        for (cutoff = MAX; cutoff >= 1; cutoff--) {
            cumulative += depth_count[cutoff] + 0
            count_at_cutoff[cutoff] = cumulative
        }

        for (cutoff = 1; cutoff <= MAX; cutoff++) {
            print sample, cutoff, count_at_cutoff[cutoff] + 0
        }
    }
' > "${outdir}/${sample}.cpg_depth_1_20x.tsv"