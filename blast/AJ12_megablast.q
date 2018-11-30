#!/bin/bash

#SBATCH -J b2hr
#SBATCH --time 7-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH -p m3tb
#SBATCH -o /flush1/gof005/AJ12_splits_7d_%A.out
#SBATCH -e /flush1/gof005/AJ12_splits_7d_%A.err

module load blast+/2.7.1
module load bioref

echo `date`

blastn \
	-task megablast \
	-query ../M_vetustissima_AC/bowtie2_vfast_local/unmapped_R1_2_0_concat/AJ12.fasta \
	-db /data/bioref/blast/ncbi/nt \
	-strand both \
	-num_threads 20 \
	-max_target_seqs 10 \
	-outfmt '6 ssciname scomname staxid qseqid saccver pident length mismatch gapopen evalue bitscore' \
	-out ../M_vetustissima_AC/blast_out/AJ12_chunk_${SLURM_ARRAY_TASK_ID}.b6out

echo `date`

