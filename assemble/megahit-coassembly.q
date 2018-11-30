#!/bin/bash

#SBATCH -J mh7d
#SBATCH --time=7-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH -e /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/megahit-all-coassembly-7d_%A.err
#SBATCH -o /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/megahit-all-coassembly-7d_%A.out
#SBATCH -p m3tb

module load megahit

megahit \
	-1 ../M_vetustissima_AC/bowtie2_vfast_local/input_for_metaBAT2/AJ_R1.fastq \
	-2 ../M_vetustissima_AC/bowtie2_vfast_local/input_for_metaBAT2/AJ_R2.fastq \
	-r ../M_vetustissima_AC/bowtie2_vfast_local/input_for_metaBAT2/AJ_R0.fastq \
	-t 20 \
	-o ../M_vetustissima_AC/megahit_assemblies/megahit_AJ_all_7day

	


