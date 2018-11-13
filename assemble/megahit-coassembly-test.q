#!/bin/bash

#SBATCH -J megahit-coassembly-test
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH -e /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/megahit-AJ12-coassembly-test_%A.err
#SBATCH -o /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/megahit-AJ12-coassembly-test_%A.out
#SBATCH --mem=128GB
#SBATCH --qos=express

/OSM/CBR/NCMI_AGOF/work/metaFly/bin/megahit/megahit \
	-1 ../M_vetustissima_AC/bowtie2_newindex_vfast-local/unmapped/AJ12_R1.fastq \
	-2 ../M_vetustissima_AC/bowtie2_newindex_vfast-local/unmapped/AJ12_R2.fastq \
	-r ../M_vetustissima_AC/bowtie2_newindex_vfast-local/unmapped/AJ12_R0.fastq \
	-t 20 \
	-o ../M_vetustissima_AC/coassembly-test/megahit-AJ12 \
	--out-prefix megahit_AJ12
	


