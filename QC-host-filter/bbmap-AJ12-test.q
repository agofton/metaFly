#!/bin/bash

#SBATCH -J bbmap-AJ12-test
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time=00:30:00
#SBATCH -e /flush1/gof005/bbmap-AJ12-test.err
#SBATCH -o /flush1/gof005/bbmap-AJ12-test.out

module load bbmap

# M. domestica indexed reference genome is in metaFly/ref/, which is the default location

bbmap.sh \
	in=/OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/QC_out/AJ12_CGATGT_R1.fasta \
	in2=/OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/QC/QC_out/AJ12_CGATGT_R2.fasta 
	path=/flush1/gof005
	threads=20 \
	outu=/flush1/gof005/bbmap-unmapped-AJ12-test \
	outm=/flush1/gof005/bbmap-mapped-AJ12-test \
	minid=0.76 \
	local=t



	
