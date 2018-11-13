#!/bin/bash

#SBATCH -J k2-std-build
#SBATCH --nodes=1
#SBATCH --time=04:00:00
#SBATCH --ntasks-per-node=20
#SBATCH --mem=128GB
#SBATCH --qos=express

module load blast+

/OSM/CBR/NCMI_AGOF/work/metaFly/bin/kraken_2/kraken2-build --standard --threads 20 --db /OSM/CBR/NCMI_AGOF/work/k2-std-index
