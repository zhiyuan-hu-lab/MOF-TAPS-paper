#!/usr/bin/env bash
#SBATCH --job-name=cpg_overlap_venn
#SBATCH -o /home/xuyanbo/logs/%j_%x.log
#SBATCH -e /home/xuyanbo/logs/%j_%x.log
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mail-type=END

set -euo pipefail

project_dir=/home/xuyanbo/project/MOF_TAPS
bedgraph_dir=${project_dir}/analysis/HeLa_gDNA/result/05methy_call/filter_taps_bedGraph
outdir=${project_dir}/analysis/fig_factory/fig/FigSI/hela_venn_3set
mkdir -p ${outdir}

master=${outdir}/HeLa_gDNA.minTotal3.venn3.tsv

run_tags=(10pg 100pg 1ng)
taps_samples=(fym260106_S01 fym260106_S02 fym260106_S03)
tapsplus_samples=(fym260106_S04 fym260106_S05 fym260106_S06)
mof_samples=(fym260124_S04 fym260124_S05 fym260124_S06)

run_one() {
    local i=$1
    local run_tag=${run_tags[$i]}

    local mof=${bedgraph_dir}/${mof_samples[$i]}.minTotal3.filter_taps.bedGraph
    local tapsplus=${bedgraph_dir}/${tapsplus_samples[$i]}.minTotal3.filter_taps.bedGraph
    local taps=${bedgraph_dir}/${taps_samples[$i]}.minTotal3.filter_taps.bedGraph

    local out_one=${outdir}/3way.${run_tag}.minTotal3.venn3.tsv
    local tmpdir=${outdir}/tmp_${run_tag}_${SLURM_JOB_ID}
    mkdir -p ${tmpdir}

    echo -e "run_tag\tcomparison\tk\tset_A\tset_B\tset_C\tA_only\tB_only\tC_only\tAB_only\tAC_only\tBC_only\tABC\tA_total\tB_total\tC_total\tunion" > ${out_one}

    {
        zcat -f ${mof}      | awk 'BEGIN{OFS="\t"} $1 !~ /^(track|browser|#)/ {print $1,$2,$3,1}'
        zcat -f ${tapsplus} | awk 'BEGIN{OFS="\t"} $1 !~ /^(track|browser|#)/ {print $1,$2,$3,2}'
        zcat -f ${taps}     | awk 'BEGIN{OFS="\t"} $1 !~ /^(track|browser|#)/ {print $1,$2,$3,4}'
    } \
    | LC_ALL=C sort \
        --parallel=2 \
        -S 2G \
        -T ${tmpdir} \
        -u -k1,1 -k2,2n -k3,3n -k4,4n \
    | awk -F'\t' -v OFS='\t' \
        -v run_tag=${run_tag} \
        -v comparison=3way \
        -v k=minTotal3 \
        -v A='MOF-TAPS' \
        -v B='TAPS+' \
        -v C='TAPS' '
        function flush() {
            if (key != "") c[mask]++
        }

        {
            this = $1 FS $2 FS $3

            if (key != "" && this != key) {
                flush()
                mask = 0
            }

            key = this
            mask += $4
        }

        END {
            flush()

            A_only  = c[1] + 0
            B_only  = c[2] + 0
            AB_only = c[3] + 0
            C_only  = c[4] + 0
            AC_only = c[5] + 0
            BC_only = c[6] + 0
            ABC     = c[7] + 0

            A_total = A_only + AB_only + AC_only + ABC
            B_total = B_only + AB_only + BC_only + ABC
            C_total = C_only + AC_only + BC_only + ABC
            UNION   = A_only + B_only + C_only + AB_only + AC_only + BC_only + ABC

            print run_tag, comparison, k, A, B, C, A_only, B_only, C_only, AB_only, AC_only, BC_only, ABC, A_total, B_total, C_total, UNION
        }' >> ${out_one}

    rm -rf ${tmpdir}
    echo "[DONE] ${out_one}"
}

run_one 0 &
run_one 1 &
run_one 2 &

wait

head -n 1 ${outdir}/3way.10pg.minTotal3.venn3.tsv > ${master}

for tag in 10pg 100pg 1ng; do
    tail -n +2 ${outdir}/3way.${tag}.minTotal3.venn3.tsv >> ${master}
done

echo "[MERGED] ${master}"