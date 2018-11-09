#!/bin/bash

####
#
#
####

# set args & help
help_message="This script takes sample .fasta files (R1, R2, R0) from an input dir & writes and launches a slurm array sending each sample to its own node to be mapped to the M.domestica ref genome with bbmap"

usage="Usage: bbmap_Mdom_array.sh \
{-i path/to/fasta/files} \
{-o out/put/goes/here} \
{-j job_name} \
{-n nsamples} \
{-c narrays at once} \
{-t max_time (hh:mm:ss)}"

while getopts hi:o:j:n:c:t: option; do
	case "${option}" in
		h) echo "$hmessage"
		   echo "$usage"
		   exit;;
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

# indexed M. domestica ref genome is in metaFly/ref by default. This is the default path expected 
# by bbmap so does not need to be specified in the script.

# set vars
database="./ref"
pe_slurm_script="./slurm-submission-scripts/bbmap-pe-${job_name}.q"
se_slurm_script="./slurm-submission-scripts/bbmap-se-${job_name}.q"
narrays=$(($njobs-1))
satid='"$SLURM_ARRAY_TASK_ID"'
satid2='${SLURM_ARRAY_TASK_ID}'

# set dirs
mkdir -p ${out_dir}
mkdir -p ${out_dir}/logs

# R1 index
R1index=`for x in ${in_dir}/*R1.fasta; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
	R1index="(${R1index});"
		R1index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R1index}`
# R2 index
R2index=`for x in ${in_dir}/*R2.fasta; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
	R2index="(${R2index});"
		R2index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R2index}`
# R2 index
R0index=`for x in ${in_dir}/*R0.fasta; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
	R0index="(${R0index});"
		R0index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R0index}`
# pe unmapped out
PEoutUindex=`for x in ${in_dir}/*R1.fasta; do
			echo -n '"'
			echo -n $(basename "$x" _R1.fasta)_unmapped_interleaved.fasta
			echo -n '"'
		done`
	PEoutUindex="(${PEoutUindex});"
		PEoutUindex=`sed -E 's@""@" \\\\\\n"@g' <<< ${PEoutUindex}`
# se unmapped out
SEoutUindex=`for x in ${in_dir}/*R1.fasta; do
			echo -n '"'
			echo -n $(basename "$x" _R1.fasta)_unmapped_R0.fasta
			echo -n '"'
		done`
	SEoutUindex="(${SEoutUindex});"
		SEoutUindex=`sed -E 's@""@" \\\\\\n"@g' <<< ${SEoutUindex}`
##############################################################
# set index vars
R1i='${R1[$i]}'
R2i='${R2[$i]}'
R0i='${R0[$i]}'
PEoutUi='${PEoutu[$i]}'
SEoutUi='${SEoutu[$i]}'
##############################################################
# write PE slurm script
echo """#!/bin/bash

#SBATCH -J ${job_name}_pe
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${maxtime}
#SBATCH -o ${out_dir}/logs/${job_name}_pe_%A_sample_%a.out
#SBATCH -e ${out_dir}/logs/${job_name}_pe_%A_sample_%a.err
#SBATCH --array=0-${narrays}%${njobs_at_once}

# load modules
module load bbmap

# print arrays
R1=${R1index}
R2=${R2index}
PEoutu=${PEoutUindex}

# main script
if [ ! -z ${satid} ]
then
i=${satid2}

bbmap.sh \
in=${in_dir}/${R1i} \
in2=${in_dir}/${R2i} \
threads=20 \
outu=${out_dir}/${PEoutUi} \
minid=0.80 \
local=f

else
	echo "Error: missing array index"
fi
""" > ${pe_slurm_script}
##########################################################
# write SE slurm script
echo """#!/bin/bash

#SBATCH -J ${job_name}_se
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${maxtime}
#SBATCH -o ${out_dir}/logs/${job_name}_se_%A_sample_%a.out
#SBATCH -e ${out_dir}/logs/${job_name}_se_%A_sample_%a.err
#SBATCH --array=0-${narrays}%${njobs_at_once}

# load modules
module load bbmap

# print arrays
R0=${R0index}
SEoutu=${SEoutUindex}

# main script
if [ ! -z ${satid} ]
then
i=${satid2}

bbmap.sh \
in=${in_dir}/${R0i} \
threads=20 \
outu=${out_dir}/${SEoutUi} \
minid=0.80 \
local=f

else
	echo "Error: missing array index"
fi
""" > ${se_slurm_script}
##########################################################
# push scripts to slurm
#sbatch ${pe_slurm_script}
#sbatch ${se_slurm_script}

