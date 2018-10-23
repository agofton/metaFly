#!/bin/bash

#SBATCH -J kraken-std-db-build
#SBATCH --nodes=1
#SBATCH --mem=128GB
#SBATCH --ntasks-per-node=20
#SBATCH --time=04:00:00

module load kraken

kraken-build --standard --threads 20 --db /OSM/CBR/NCMI_AGOF/work/kraken-std-db --download-taxonomy --clean
