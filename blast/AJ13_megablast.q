#!/bin/bash

#SBATCH -J AJ12mb
#SBATCH --time 02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH -o /flush1/gof005/AJ12_splits_%A_%a.out
#SBATCH -e /flush1/gof005/AJ12_splits_%A_%a.err
#SBATCH --array=1-201

module load blast+/2.7.1

blastn \
	-task megablast \
	-query ../M_vetustissima_AC/bowtie2_newindex_vfast-local/unmapped_R1_2_0_concat/AJ12_split/AJ12_chunk_${SLURM_ARRAY_TASK_ID}.fasta \
	-db /data/bioref/blast/ncbi.2018-11-12T19:05:01Z/nt \
	-strand both \
	-num_threads 20 \
	-max_target_seqs 10 \
	-max_hsps 10 \
	-outfmt 11 \
	-out ../M_vetustissima_AC/megablast_splits_out/AJ12_unmapped/AJ12_chunk_${SLURM_ARRAY_TASK_ID}.ANS.1




