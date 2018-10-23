#!/bin/bash

#SBATCH -J lsa-ST-test
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --mem128GB
#SBATCH --time 02:00:00
#SBATCH -o /OSM/CBR/NCMI_AGOF/work/metaFly/lsa-slurm/lsa-ST-test_%A.out
#SBATCH -e /OSM/CBR/NCMI_AGOF/work/metaFly/lsa-slurm/lsa-ST-test_%A.err

./HashCounting.sh 20 33 22

./KmerSVDClustering 20 22 .8

./ReadPartitioning.sh 20


