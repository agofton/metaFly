#!/bin/bash

####
# usage: 7-mopup-host-reads.sh \
# 				-i {in dir} \ 											<- Input reads default = /bowtie2/sorted
# 				-b6 {stitched .b6out dir} \								<- Output from 4_stitch_b6out.sh
# 				-t {tax_to_filt.txt (or other user created list)} \ 	<- User generated taxa list
# 				-o {out dir} 											<- output will be sample_n_host-filtered_R0/R1/R2.fasta
#
# This scrip reads in taxa names from metaFly/tax_to_filt.txt
# created by the user. tax_to_filter.txt should be a single list
# of taxonomic genus taken from taxa_list.txt generated during 
# stitch_b6out.sh
#
# Use an interactive pearcey shell for this!
####

# set params and help
help_message="Runs a series of usearch 9.2 scripts to filter out taxa specified in -t {tax_to_filt.txt} - a user generated list of genera to exclude.
Writes filtered .fasta files to -o {output dir}"

usage="Usage: $(basename "$0") 
{-i /path/to/.fasta/files} 
{-b6 /path/to/stitched/.b6out/files} 
{-t user generated taxa_list.txt to filt (./QC-host-filter/tax-files/tax_to_filt.txt)} 
{-o /all/output/goes/here}
[-h print this message]"

while getopts hi:o:b:t: option; do
	case "${option}" in
		h) echo "$help_message"
		   echo ""
		   echo "$usage"
		   exit;;
		i) in_dir=$OPTARG;;
	    b) b6_dir=$OPTARG;;
		t) tax_list=$OPTARG;;
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

#set vars
r2filt="${out_dir}/reads_to_filt"

# set dirs
mkdir -p ${out_dir}
mkdir -p ${r2filt}

# R0 files
echo ""
echo "========================================"
echo "Extracting host reads from R0 files"
echo "========================================"
echo ""

# generate list of R0 reads from all samples
	# for all R0 files, loop through and find the genus names in tax_list, and extract the corresponding seqIDs into a new file 

for x in ${b6_dir}/*R0.b6out
do
	echo ""
	echo "Finding host seqs in $(basename "$x")"
	echo "-------------------------------------------------------------"

		while IFS= read -r var; do
			cat ${x} | grep "^${var}" | awk -F "\t" '{print $4}' | sort -u >> ${r2filt}/R0_reads_to_filt.txt	
		done < ${tax_list}
done

# filtering host reads from R0 files

for x in ${in_dir}/*R0.fasta
do
	echo ""
	echo  "Filtering host reads from $(basename "$x")"
	echo "---------------------------------------------------------------"
	
	outname="$(basename $"x"_unmapped_R0.fasta)_host-filtered_R0.fasta"

	bin/usearch9.2 \
		-fastx_getseqs ${x} \
		-labels ${r2filt}/R0_reads_to_filt.txt \
		-notmatched ${out_dir}/${outname} 
	
	[ $? -eq 0 ] || echo "Usearch failed to filter host reads from $(basename "$x")"
done

echo ""
echo "=================================================="
echo "Extracting host reads from R1 & R2 files"
echo "=================================================="
echo ""

# generate a list of R1 reads from all samples that hit taxa to filt (taxa_to_filt.txt)
	# for all R1 files, loop through and find the genus names in tax_list, and extract the corresponding seqIDs into a new file 
for x in ${b6_dir}/*R1.b6out
do
	echo ""
	echo  "Finding host seqs in  $(basename "$x")"
	echo "-----------------------------------------------------------"

		while IFS= read -r var; do
			cat ${x} | grep "^${var}" | awk -F "\t" '{print $4}' | sort -u >> ${r2filt}/R1_reads_to_filt.txt	
		done < ${tax_list}
done

# generate list of R2 reads that hit taxa to filt
	# for all R2 files, loop through and find the genus names in tax_list, and extract the corresponding seqIDs into a new file 
for x in ${b6_dir}/*R2.b6out
do
	echo ""
	echo  "Finding host seqs in $(basename "$x")"
	echo "--------------------------------------------------------------------"

		while IFS= read -r var; do
			cat ${x} | grep "^${var}" | awk -F "\t" '{print $4}' | sort -u >> ${r2filt}/R2_reads_to_filt.txt	
		done < ${tax_list}
done

# filtering R1 and R2 seqs from R1 reads
echo ""
	#R1
echo "Creating ${r2filt}/R1_2filt.txt"
echo "-----------------------------------------"
	cat ${r2filt}/R1_reads_to_filt.txt ${r2filt}/R2_reads_to_filt.txt | sed -e 's/R2/R1/g' | sort -u > ${r2filt}/R1_2filt.txt
echo "done"
	
	#R2
echo "Creating ${r2filt}/R2_2filt.txt"
echo "-----------------------------------------"
	cat ${r2filt}/R1_reads_to_filt.txt ${r2filt}/R2_reads_to_filt.txt | sed -e 's/R1/R2/g' | sort -u > ${r2filt}/R2_2filt.txt
echo "done"

# Filtering host reads from R1 files
for x in ${in_dir}/*R1.fasta
do
	echo ""
	echo  "Filtering $(basename "$x")"
	echo "-------------------------------------"

	outname="$(basename "$x" _unmapped_R1.fasta)_host-filtered_R1.fasta"

	bin/usearch9.2 \
		-fastx_getseqs ${x} \
		-labels ${r2filt}/R1_2filt.txt \
		-notmatched ${out_dir}/${outname}

	[ $? -eq 0 ] || echo "Usearch failed to filter host reads from $(basename "$x")"
done

# filtering host reads from R1 files
for x in ${in_dir}/*R2.fasta
do
	echo ""
	echo  "Filtering $(basename "$x")"
	echo "--------------------------------------"

	outname="$(basename "$x" _unmapped_R2.fasta)_host-filtered_R2.fasta"

	bin/usearch9.2 \
		-fastx_getseqs ${x} \
		-labels ${r2filt}/R2_2filt.txt \
		-notmatched ${out_dir}/${outname} 

	[ $? -eq 0 ] || echo "Usearch failed to filter host reads from $(basename "$x")"
done

