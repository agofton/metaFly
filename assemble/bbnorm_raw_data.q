#!/bin/bash

#SBATCH -J bbnorm
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time=4-00:00:00
#SBATCH -e /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/raw_data_bbnorm_100x/err
#SBATCH -o /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/raw_data_bbnorm_100x/out
#SBATCH -p m3tb

module load bbmap/38.00

bbnorm.sh \
	in=../M_vetustissima_AC/raw_data/all_R1.labeled.fastq \
	in2=../M_vetustissima_AC/raw_data/all_R2.labeled.fastq \
	out=../M_vetustissima_AC/raw_data_bbnorm_100/all_R1_norm_100x.fastq \
	out2=../M_vetustissima_AC/raw_data_bbnorm_100/all_R2_norm_100x.fastq \
	outt=../M_vetustissima_AC/raw_data_bbnorm_100/excluded_reads.fastq \
	k=21 threads=18 target=100 \
	hist=../M_vetustissima_AC/raw_data_bbnorm_100/input.hist \
	histout=../M_vetustissima_AC/raw_data_bbnorm_100/output.hist 	




