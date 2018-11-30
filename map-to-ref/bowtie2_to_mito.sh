#!/bin/bash

# For use on BowenVM, not Pearcey

# sets args
help_message="Maps each sample (3 files R1, R2, R0) to the M. domestica reference genome, and filters .bam file to only inclde hits"
usage="$(basename $0) -r /path/to/bt2/references/mito/genome -i /path/to/input/reads -o /output/goes/here [-h show this message]"

while getopts hr:i:o: option; do
	case "${option}" in
		h) echo "$hmessage"
		   echo "$usage"
		   exit;;
		r) reference=$OPTARG;;
		i) indir=$OPTARG;;
		o) outdir=$OPTARG;;
		:) printf "missing argument for  -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
	  	   exit 1;;
	   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
		   exit 1;;
	esac
done
shift $((OPTIND - 1))

# set dirs
mkdir -p ${outdir}

# Input reads should be merged and QC'd, and all placed in one folder (-i /path/to/input) as .fastq files.
# Each sample should then have a R0 (merged reads), R1 & R2 .fastq file.
# Mitochondrial genome should already be indexed by bowtie2.

for x in ${indir}/*R0.fastq
do
	sam=$(basename $x _R0.fastq).sam
	mappedsam=$(basename $x _R0.fastq).mapped.sam

	bowtie2 \
	   -x ${reference} \
	   -1 ${indir}/$(basename $x R0.fastq)R1.fastq \
	   -2 ${indir}/$(basename $x R0.fastq)R2.fastq \
	   -U ${x} \
	   -S ${outdir}/${sam} \
	   -q \
	   --local

	samtools view -F 0x04 -b ${outdir}/${sam} > ${outdir}/${mappedsam}

	rm ${outdir}/${sam}

done








