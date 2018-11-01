#!/bin/bash

#SBATCH -J bbmap-index-Mdom
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --mem=128GB
#SBATCH -e /flush1/gof005/bbmap-index-Mdom.err
#SBATCH -o /flush1/gof005/bbmap-index-Mdom.out
#SBATCH --time=02:00:00

module load bbmap

bbmap.sh \
	ref=/OSM/CBR/NCMI_AGOF/work/M_domestica_ref_genome/M_domestica_ref_genome.fasta \
	path=/OSM/CBR/NCMI_AGOF/work/M_domestica_ref_genome_bbmap_index2 \
	k=11 \
	t=20

   	
