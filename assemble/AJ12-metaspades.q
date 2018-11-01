#!/bin/bash

#SBATCH -J metaspades_AJ12_coassembly_noEC
#SBATCH --time=36:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH -e /flush1/gof005/AJ12_metaspades_noEC_%A.err
#SBATCH -o /flush1/gof005/AJ12_metaspades_noEC_%A.out
#SBATCH --mem=128GB

module load spades

spades.py \
	--meta \
	-1 /flush1/gof005/M_vet_raw_data/AJ12_CGATGT_R1.fastq \
	-2 /flush1/gof005/M_vet_raw_data/AJ12_CGATGT_R2.fastq \
	--only-assembler \
	-t 20 \
	-m 128 \
	--tmp-dir /flush1/gof005/M_vet_AJ12_metaspades-128-noEC-tmp \
	-o /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/AJ12-metaspades-128-noEC-out

