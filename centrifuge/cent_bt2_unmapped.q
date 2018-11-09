#!/bin/bash

#SBATCH -J cent_vfast-loc
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:30:00
#SBATCH --mem=200gb
#SBATCH -p m512gb
#SBATCH -o /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_vfast-local/cent2_%A.out
#SBATCH -e /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_vfast-local/cent2_%A.err


module load centrifuge
															
/OSM/CBR/NCMI_AGOF/work/metaFly/bin/centrifuge/centrifuge --verbose -q -t -x /OSM/CBR/NCMI_AGOF/work/centrifuge-index/nt -1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_vfast-local/unmapped/AJ12_R1_unmapped.fastq -2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_vfast-local/unmapped/AJ12_R2_unmapped.fastq -U /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_vfast-local/unmapped/AJ12_R0_unmapped.fastq -p 1 -S /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_vfast-local/AJ12-2.cent --report-file /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_vfast-local/AJ12-2.rep

#kraken style report
/OSM/CBR/NCMI_AGOF/work/metaFly/bin/centrifuge/centrifuge-kreport -x /OSM/CBR/NCMI_AGOF/work/centrifuge-index/nt /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_vfast-local/AJ12-2.cent > /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_vfast-local/AJ12-2.krep


