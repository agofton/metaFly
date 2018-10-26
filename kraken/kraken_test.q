#!/bin/bash

#SBATCH -J krak-test
#SBATCH --nodes=1
#SBATCH --time=00:10:00
#SBATCH --mem=512GB
#SBATCH --ntasks-per-node=20

module load kraken

kraken \
--db /apps/kraken/db/standard \
--threads 20 \
--fastq-input \
--unclassified-out /OSM/CBR/NCMI_AGOF/work/metaFly_test/kraken_test/uc \
--classified-out /OSM/CBR/NCMI_AGOF/work/metaFly_test/kraken_test/cl \
--output /OSM/CBR/NCMI_AGOF/work/metaFly_test/kraken_test/out \
/OSM/CBR/NCMI_AGOF/work/metaFly_test/raw_data/sample_1_R1.fastq