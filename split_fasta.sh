#!/bin/bash


####
# Written by Alexander Gofton, ANIC, CSIRO, 2019
# alexander.gofton@gmail.com; alexander.gofton@csiro.au
####

# set params & help
hmessage="Splits a fasta file into chunks with n sequences per chunk"
usage="Usage: $(basename "$0")
{-i input file}
{-o output file prefix eg. sample_1.fasta = sample_1.fasta.1, sample_1.fasta.10001, sample_1.fasta.20001} 
{-n number of seqs in each chunk - 1000 in above example}
[-h show with help message]"

while getopts hi:o:j:t:n:c:f: option
do
	case "${option}"
	in
		h) echo "$hmessage"
		   echo "$usage"
		   exit;;
		i) input_file=$OPTARG;;
		o) output_files=$OPTARG;;
		n) n_seqs_per_chunk=$OPTARG;;
		:) printf "missing argument for  -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
	  	   exit 1;;
	   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
		   exit 1;;
	esac
done
shift $((OPTIND - 1))

awk -v size=${n_seqs_per_chunk} -v pre=${output_files} -v pad=1 '/^>/ { n++; if (n % size == 1) { close(fname); fname = sprintf("%s.%0" pad "d", pre, n) } } { print >> fname }' ${input_file}
