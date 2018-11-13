#!/bin/bash

#SBATCH -J lsa-ST-test
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --mem=128GB
#SBATCH --time=02:00:00
#SBATCH -o /OSM/CBR/NCMI_AGOF/work/metaFly/lsa-slurm/hash-counting-test_%A.out
#SBATCH -e /OSM/CBR/NCMI_AGOF/work/metaFly/lsa-slurm/hash-counting-test_%A.err

module load lsa
module load python/2.7.13

./HashCounting.sh 20 33 22

./KmerSVDClustering.sh 20 22 .8




