#!/bin/bash

####
# usage: 4_stitch_b6out.sh \
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

# set params and help
hmessage="Simple BASH script that will stitch together chunked .b6out files. Will also generate a list of identified genera in ${out_dir}/tax_list.txt. Users can use tax_list.txt to decide which taxa to filter or keep in the next step."
usage="Usage: $(basename "$0") -i {input dir - containing chunked .b6out files} -s {seqs dir - containing files before they were chunked} -o {output dir} -h [print this message]"

while getopts hi:o:j:n:d:t: option; do
	case "${option}" in
		h) echo "$hmessage"
		   echo "$usage"
		   exit;;
		i) in_dir=$OPTARG;;
		s) orig_seqs_dir=$OPTARG;;
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

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# set dirs
mkdir -p ${out_dir}

# use loop to cat chunks from each sample together
for x in ${orig_seqs_dir}/*.fasta
  do
	
	ids="${in_dir}/$(basename "$x" .fasta)_*.b6out"
	out="${out_dir}/$(basename "$x" .fasta).b6out"
	
	cat ${ids} > ${out}
	
  done

# make genus level taxa list
cat ${out_dir}/*.b6out | awk {print $1}' | sort -u > ${out_dir}/tax_list.txt

