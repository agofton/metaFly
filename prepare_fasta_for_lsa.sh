#!/bin/bash

####
# usage: prepare_fasta_for_lsa.sh \
#					-i {in dir} \	<- files to rename
#					-o {out dir}	<- renames files go here
# -h for help
# Script will rename files from
# illumina labels: 	sample_n_R1.fastq
# 					sample_n_R2.fastq
# 					sample_n_R0.fastq <-this one is my label = unpaired reads
#
# to lsa labels: 	sample_n.fastq.1
# 					sample_n.fastq.2
# 					sample_n.single.fastq.1
#
# and will convert .fasta to .fastq will all Qscores at 40 (I)
#
# Written by Alexander Gofton, ANIC, CSIRO, 2018
# alexander.gofton@gmail.com; alexander.gofton@csiro.au
####

# set params and help
help_message="BASH script to rename .fasta files for input into LSA and convert to .fastq eg. sample_n_R1.fasta -> sample_n.fastq.1, sample_n_R2.fasta -> sample_n.fastq.2, sample_n_R0.fasta -> sample_n.single.fasta.1 As quality filtering has already been done on these seqs all Qscores are set to 40 (I). fasta to fastq done with perl script metaFly/bin/fasta_to_fastq.pl"
usage="Usage: $(basename "$0") -i {input fasta dir} -o {output dir}"

while getopts hi:o: option
do
	case "$option" in
		h) echo "$help_message"
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

# set vars
tmp="${out_dir}/tmp"

# set dirs
mkdir -p ${out_dir}
mkdir -p ${tmp}

# loop over R1 files changing names
for x in ${in_dir}/*R1.fasta; do

	lsa_name="$(basename "$x" _R1.fasta).fastq.1"

	cp ${x} ${tmp}/${lsa_name}
done

# loop over R2 files changing names
for x in ${in_dir}/*R2.fasta; do

	lsa_name="$(basename "$x" _R2.fasta).fastq.2"

	cp ${x} ${tmp}/${lsa_name}
done

# loop over R0 files changing names
for x in ${in_dir}/*R0.fastq; do

	lsa_name="$(basename "$x" _R0.fasta).single.fastq.1"

	cp ${x} ${tmp}/${lsa_name}
done

# convert .fasta to .fastq with perl command
for x in ${tmp}/*.fastq.?; do

	fastqout=$(basename "$x")

	perl bin/fasta_to_fastq.pl ${x} > "${out_dir}/${fastqout}"
done

# cleanup
rm -r -f ${tmp}

