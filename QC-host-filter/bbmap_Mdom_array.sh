#!/bin/bash

####
#
#
####

# set args & help
help_message=""

usage=""

while getopts hd:i:o:j:n:c:t: option; do
	case "${option}" in
		h) echo "$hmessage"
		   echo "$usage"
		   exit;;
		d) database=$OPTARG;;
		i) in_dir=$OPTARG;;
		o) out_dir=$OPTARG;;
		j) job_name=$OPTARG;;
		n) njobs=$OPTARG;;
		c) njobs_at_once=$OPTARG;;
		t) maxtime=$OPTARG;;
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
slurm_script="./slurm-submission-scripts/bbmap-slurm-${job_name}.q"

# set dirs
mkdir -p $out_dir

# R1 index
R1index=`for x in ${in_dir}/*R1.fasta; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
	R1index="(${R1index});"
		R1index=`sec -E 's@""@ \\\\\\n"@g' <<< ${R1index}`
# R2 index
R2index=`for x in ${in_dir}/*R2.fasta; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
	R2index="(${R2index});"
		R2index=`sec -E 's@""@ \\\\\\n"@g' <<< ${R2index}`
# R2 index
R0index=`for x in ${in_dir}/*R0.fasta; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
	R0index="(${R0index});"
		R0index=`sec -E 's@""@ \\\\\\n"@g' <<< ${R0index}`

# set index vars
R1i='${R1[$i]}'
R2i='${R2[$i]}'
R0i='${R0[$i]}'

# write PE slurm script

R1=${R1index}
R2=${R2index}

module load bbmap

bbmap.sh \
in=${in_dir}/${R1i} \
in2=${in_dir}/${R2i} \
ref= ${database} \
threads=20 \
outu=${out_dir}



