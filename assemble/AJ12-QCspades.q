#!/bin/bash

#SBATCH -J Mvet_AJ12_QCspades_coassembly_noEC
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH -e /flush1/gof005/AJ12_QCspades_noEC_%A.err
#SBATCH -o /flush1/gof005/AJ12_QCspades_noEC_%A.out
#SBATCH --mem=128GB

module load spades

#spades.py \
#	-1 /flush1/gof005/M_vet_QC_1B/QC_out/AJ12_CGATGT_R1.fasta \
#	-2 /flush1/gof005/M_vet_QC_1B/QC_out/AJ12_CGATGT_R2.fasta \
#	-s /flush1/gof005/M_vet_QC_1B/QC_out/AJ12_CGATGT_R0.fasta \
#	--only-assembler \
#	-t 20 \
#	-m 128 \
#	--tmp-dir /flush1/gof005/M_vet_AJ12_QCspades-128-noEC-tmp-cont \
#	-o /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/AJ12-QCspades-128-noEC-out \
#	--continue

spades.py \
	--continue \
	-o /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/AJ12-QCspades-128-noEC-out

