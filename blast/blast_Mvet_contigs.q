#!/bin/bash

#SBATCH -J blast_Mvet_contigs
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --mem=128GB
#SBATCH --time=01:00:00

module load blast+
module load bioref

blastn \
	-task megablast \
	-query /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/512_AJ44_QCspades_noEC_out/scaffolds.fasta \
	-db /data/bioref/blast/ncbi/nt \
	-strand both \
	-num_threads 20 \
	-max_target_seqs 10 \
	-max_hsps 10 \
	-outfmt '6 ssciname scomname staxid qseqid saccver pident length mismatch gapopen evalue bitscore' \
	-out /flush1/gof005/blast_Mvet_contigs.b6out

