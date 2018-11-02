#!/bin/bash

#SBATCH -J spades_AJ44_QCspades_noEC
#SBATCH --time=48:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH -e /flush1/gof005/spades_AJ44_QCspades_noEC_%A.err
#SBATCH -o /flush1/gof005/spades_AJ44_QCspades_noEC_%A.out
#SBATCH --mem=128GB

module load spades

spades.py \
	-1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ44_R1.fastq \
	-2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ44_R2.fastq \
	-s /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ44_R0.fastq \
	--only-assembler \
	-t 20 \
	-m 128 \
	--tmp-dir /flush1/gof005/spades_AJ44_QCspades_noEC_tmp \
	-o /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/spades_AJ44_QCspades_noEC_out \
	


