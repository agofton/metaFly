#!/bin/bash
####
# usage: 2_clean_bt2_output.sh \
#			-i {input dir} \ 							<- master output dir from bowtie2
#			-p {subdirectory name prefix to match} \ 	<- default from bt2_map_to_ref_array.sh is: sample_
#			-o {output dir}
#
# Written by Alexander Gofton, 2018, ANIC, CSIRO
# alexander.gofton@gmail.com; alexander.gofton@csiro.au
####

# set params & help
hmessage="Simple BASH script that moves bowtie2 output into more managable file structure, and renames files to normal nomenclature eg. sample_n_R1/R2/R0.fasta"
usage="Usage: $(basename "$0") -i {master output dir from bowtie2} -p {sub directory common prefix eg. sample_} -o {output dir}"

while getopts hi:p:o: option; do
	case "${option}" in
		h) echo "$hmessage"
		   echo "$usage"
		   exit;;
		i) in_dir=$OPTARG;;
		p) subdir_prefix=$OPTARG;;
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
work_dir="`pwd`"

# looping through folders, renameing files and moving to parent dri
for x in ${in_dir}/${subdir_prefix}* ;do

	prefix="$(basename "$x")" 						# def sampleID
	cd ${x} 										# move into subdir
	mv un-conc-mate.1 ${out_dir}/${prefix}_R1.fasta # rename pe fwd reads
	mv un-conc-mate.2 ${out_dir}/${prefix}_R2.fasta # rename pe rev reads
 	mv al-seqs ${out_dir}/${prefix}_R0.fasta 		# rename se reads
	cd ${work_dir} 									# return to working dir

done

cd ${work_dir}

# removing empty folders
#rm -r ${in_dir}/${subdir_prefix}*





