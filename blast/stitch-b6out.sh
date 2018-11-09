#!/bin/bash

####
# usage: 6_stitch_b6out.sh \
#			-i {split b6out files dir} \ 	<- default = blast_out/splits
#			-s {original seqs dir} \ 		<- default = bowite2/sorted
#			-o {stitched output dir}  		<- default = blast_out/stitched
#
# If using this after bowtie2_array.sh & sort_bt2_output.sh
# then -s will be bt2_out_files "sample_n_unmapped_R1.fasta"
#
# Will also create a list a taxa found in all samples
#
# Written by Alexander Gofton, ANIC, CSIRO, 2018
# aleander.gofton@csiro.au; alexander.gofton@gmail.com
#####

# set args and help
help_message="Simple BASH script that will stitch together chunked .b6out files from split-n-blast-array.sh.
Will also generate a list of identified genera in ./QC-host-filter/tax_files/tax-list.txt.
Users can use tax_list.txt to decide which taxa to filter or keep in the next step."

usage="Usage: $(basename "$0") 
{-i /path/to/chunked/.b6out/files} 
{-s /path/to/original/.fasta/files (before they were split)} 
{-o /all/ouput/goes/here} 
[-h print this message]"

while getopts hi:o:s: option; do
	case "${option}" in
		h) echo "$help_message"
		   echo ""
		   echo "$usage"
		   exit;;
		i) in_dir=$OPTARG;;
		s) seqs_dir=$OPTARG;;
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
mkdir -p ${out_dir}
mkdir -p ./QC-host-filter/tax-files

# for each original file, concatenate .b6out chunks together
for x in ${seqs_dir}/*.fasta
do
	in="${in_dir}/$(basename "$x" .fasta)_*.b6out"
	out="${out_dir}/$(basename "$x" .fasta).b6out"
	
	cat ${in} > ${out}	
done

# make ./QC-host-filter/tax-list.txt
cat ${out_dir}/*.b6out | awk '{print $1}' | sort -u > ./QC-host-filter/tax-files/tax-list.txt

