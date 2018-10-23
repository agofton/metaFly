#!/bin/bash

####
# usage phix_filter.sh \
# 			-i {input directory containing .fastq files} 	# output from trimmomatic 
# 			-o {output dir} 								# all output will go here
#
# Run this in an interactive pearcey session.
#
# Default trimmomatic output will be 4 .fastq files per 1 pe input sample
# 		sample_x_1P.fastq
# 		sample_x_2P.fastq
# 		sample_x_1U.fastq
# 		sample_x_rev_up.fastq
#
# This script will:
# 	1) filter phiX reads from pe files - maintaining pe structure
# 	2) filter phiX reads from se files
# 	3) rename reads will simpler seqIDs: sample_x_R1.seq_num; sample_x_R2.seq_num; sample_x.seq_num
# 	4) converts. fastq to .fasta - QC is now complete so .fastq not needed
#
# Written by Alexander Gofton, ANIC, CSIRO, 2018
# alexander.gofton@csiro.au; alexander.gofton@gmail.com
####

# set params & help
help_message="Runs several usearch v9.2 scripts to clean up trimmomatic output including: renames files, filters phiX seqs, 
concatenated fwd-unpaired and rev-unpaired files, and relabels seqIDs to:
'filename_prefix'_'read designation'.'unique num identifier' (eg sample_n_R1.1)"

usage="Usage: $(basename "$0") 
{-i /input/dir} 
{-o /output/dir}"

while getopts hi:o: option; do
	case "${option}"
	in
		h) echo "$help_message"
		   echo ""
		   echo "$usage"
		   exit;;
		i) in_dir=$OPTARG;;
		o) out_dir=$OPTARG;;
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
mkdir -p ${out_dir}/tmp
mkdir -p ${out_dir}/tmp2

# looping over pe files and filtering phiX
for x in ${in_dir}/*1P.fastq
do
	rev="${in_dir}/$(basename "$x" 1P.fastq)2P.fastq"
	t1="${out_dir}/tmp/$(basename "$x" 1P.fastq)R1.fastq"
	t2="${out_dir}/tmp/$(basename "$rev" 2P.fastq)R2.fastq"

	echo ""
	echo "===================================="
	echo "phiX filtering pe reads: ${x}"
	echo "===================================="
	echo ""
	
	bin/usearch9.2 \
		-filter_phix ${x} \
		-reverse ${rev}\
		-output ${t1}\
		-output2 ${t2} 
done

# looping through se files and filtering phiX				
for y in ${in_dir}/*1U.fastq
do
	rev_up="${in_dir}/$(basename "$y" 1U.fastq)2U.fastq"
	ca="$(basename "$y" 1U.fastq)R0.fastq"
	
	echo ${ca}
	echo ""
	echo "=========================================="
	echo "Concatenating ${y} and ${rev_up}"
	echo "=========================================="
	echo ""
	
	cat ${y} ${rev_up} > ${out_dir}/tmp2/${ca}
done

for x in ${out_dir}/tmp2/*R0.fastq
do
	echo ""
	echo "=========================================="
	echo "Filtering phiX reads from ${x}"
	echo "=========================================="
	echo ""
	
	bin/usearch9.2 \
		-filter_phix ${x} \
		-output "${out_dir}/tmp/$(basename "$x")" 
done

rm -r -f "${out_dir}/tmp2"

# converting from .fastq to .fasta and renaming seqIDs
for x in ${out_dir}/tmp/*.fastq
do
	
	echo ""
	echo "==============================================="
	echo "Converting .fastq to .fasta & renaming seqIDs: ${x}"
	echo "=============================================="
	echo ""

	seq_label_prefix="$(basename "$x" .fastq)"

	bin/usearch9.2 \
		-fastq_filter ${x} \
		-fastaout "${out_dir}/$(basename "$x" .fastq).fasta" \
		-relabel "${seq_label_prefix}."
done

rm -r -f "${out_dir}/tmp"
	
