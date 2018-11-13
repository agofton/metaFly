#!/bin/bash

#SBATCH -J spades-coassembly-test
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH -e /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/spades-AJ12-coassembly-test_%A.err
#SBATCH -o /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/spades-AJ12-coassembly-test_%A.out
#SBATCH --mem=128GB
#SBATCH --qos=express

module load spades

spades.py \
	--only-assembler \
	--careful \
	-1 ../M_vetustissima_AC/bowtie2_newindex_vfast-local/unmapped/AJ12_R1_unmapped.fastq \
	-2 ../M_vetustissima_AC/bowtie2_newindex_vfast-local/unmapped/AJ12_R2_unmapped.fastq \
	-s ../M_vetustissima_AC/bowtie2_newindex_vfast-local/unmapped/AJ12_R0_unmapped.fastq \
	-t 20 \
	-m 128 \
	--tmp-dir /flush1/gof005/AJ12-spades-coassembly-test \
	-o ../M_vetustissima_AC/coassembly-test/spades-AJ12

	








