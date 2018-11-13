#!/bin/bash

#SBATCH -J metaspades_AJ12_raw_data_coassembly
#SBATCH --time=48:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH -e /flush1/gof005/AJ12_metaspades_raw_data_coassembly_%A.err
#SBATCH -o /flush1/gof005/AJ12_metaspades_raw_data_coassembly_%A.out
#SBATCH --mem=512GB

module load spades

spades.py \
	--meta \
	-1 ../M_vetustissima_AC/raw_data/AJ12_CGATGT_R1.fastq \
	-2 ../M_vetustissima_AC/raw_data/AJ12_CGATGT_R2.fastq \
	--only-assembler \
	-t 20 \
	-m 512 \
	--tmp-dir /flush1/gof005/M_vet_AJ12_metaspades_raw_data_coassembly-tmp \
	-o ../M_vetustissima_AC/AJ12-metaspades

