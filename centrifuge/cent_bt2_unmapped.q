#!/bin/bash

#SBATCH -J cent_vfast-loc
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=10:00:00
#SBATCH --mem=300gb
#SBATCH -p m512gb
#SBATCH -o /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/centrifuge-nt-out/cent_%A.out
#SBATCH -e /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/centrifuge-nt-out/cent_%A.err

for x in /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_newindex_vfast-local/unmapped/*R0_unmapped.fastq
do
	R1="$(basename "$x" R0_unmapped.fastq)R1_unmapped.fastq"
	R2="$(basename "$x" R0_unmapped.fastq)R2_unmapped.fastq"
	R0="$(basename "$x")"
	cent="$(basename "$x" _R0_unmapped.fastq).cent"
	rep="$(basename "$x" _R0_unmapped.fastq).rep"
	krep="$(basename "$x" _R0_unmapped.fastq).krep"


	/OSM/CBR/NCMI_AGOF/work/metaFly/bin/centrifuge/centrifuge \
		--verbose \
		-q \
		-t \
		-x /OSM/CBR/NCMI_AGOF/work/centrifuge-index/nt \
		-1 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_vfast-local/unmapped/${R1} \
		-2 /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_vfast-local/unmapped/${R2} \
		-U /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/bowtie2_vfast-local/unmapped/${R0} \
		-p 1 \
		-S /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/centrifuge-nt-out/${cent} \
		--report-file /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/centrifuge-nt-out/${rep}

#kraken style report
	/OSM/CBR/NCMI_AGOF/work/metaFly/bin/centrifuge/centrifuge-kreport \
		-x /OSM/CBR/NCMI_AGOF/work/centrifuge-index/nt \
		/OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/centrifuge-nt-out/${cent} > /OSM/CBR/NCMI_AGOF/work/M_vetustissima_AC/centrifuge-nt-out/${krep}
done


