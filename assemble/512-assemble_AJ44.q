#!/bin/bash

#SBATCH -J spades_AJALL_QCspades_noEC
#SBATCH --time=72:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH -e /flush1/gof005/spades_all_Mvet_%A.err
#SBATCH -o /flush1/gof005/spades_all_Mvet_%A.out
#SBATCH -p m3tb

module load spades

spades.py \
	--pe1-1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ12_R1.fastq \
	--pe2-1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ13_R1.fastq \
	--pe3-1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ14_R1.fastq \
	--pe4-1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ15_R1.fastq \
	--pe5-1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ16_R1.fastq \
	--pe6-1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ17_R1.fastq \
	--pe7-1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ18_R1.fastq \
	--pe8-1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ19_R1.fastq \
	--pe9-1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ20_R1.fastq \
	--pe1-2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ12_R2.fastq \
	--pe2-2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ13_R2.fastq \
	--pe3-2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ14_R2.fastq \
	--pe4-2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ15_R2.fastq \
	--pe5-2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ16_R2.fastq \
	--pe6-2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ17_R2.fastq \
	--pe7-2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ18_R2.fastq \
	--pe8-2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ19_R2.fastq \
	--pe9-2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ20_R2.fastq \
	--s1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ12_R0.fastq \
	--s2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ13_R0.fastq \
	--s3 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ14_R0.fastq \
	--s4 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ15_R0.fastq \
	--s5 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ16_R0.fastq \
	--s6 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ17_R0.fastq \
	--s7 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ18_R0.fastq \
	--s8 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ19_R0.fastq \
	--s9 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/AJ20_R0.fastq \
	--trusted-contigs /OSM/CBR/NCMI_AGOF/work/M_vet_bt2_index/M_vet_512_scafolds.fasta \
	--only-assembler \
	-t 20 \
	-m 512 \
	--tmp-dir /flush1/gof005/spades_AJALL_512_48hr_tmp \
	-o /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/spades_AJall
	


