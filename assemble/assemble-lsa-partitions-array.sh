#!/bin/bash

####
# Wirtten by Alexander Gofton, ANIC, CSIRO, 2018
# alexaner.gofton@gmail.com; alexander.gofton@csiro.au
####

# set args and help
help_message=""

usage="Usage: $(basename "$0")
{-i /path/to/lsa/read_partitions}
{-o /all/output/will/go/here}
{-t max time per assembly hh:mm:ss}
{-j job_name}
{-p /tmp/files/will/go/here}"

while getopts hi:o:t:j:p: option
do
	case "${option}"
	in
		h) echo "$help_message"
		    echo ""
		    echo "$usage"
			exit;;
		i) read_partitions=${OPTARG};;
		o) out_dir=${OPTARG};;
		t) max_time=${OPTARG};;
		j) job_name=${OPTARG};;
		p) tmp_dir=${OPTARG};;
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
slurm_script_dir="./slurm-submission-scripts/assemble-partitions/${job_name}"
home_dir="`pwd`"
logs=${out_dir}/logs
satid='"$SLURM_ARRAY_TASK_ID"'
satid2='${SLURM_ARRAY_TASK_ID}'

# set dirs
mkdir -p ${out_dir}
mkdir -p ${slurm_script_dir}
mkdir -p ${tmp_dir}
mkdir -p ${logs}

# write slurm script
for x in ${read_partitions}/*/
	
    do
		index=`for z in ${x}/*.fastq; do
				echo -n '"'
				echo -n $(basename "$z")
				echo -n '"'
				done`
		index="(${index});"
		index=`sed -E 's@""@" \\\\\n"@g' <<< ${index}`
        INDEX='${index[$i]}'
    
        outdex=`for z in ${x}/*.fastq; do
				echo -n '"'
				echo -n $(basename "$z" .fastq)
				echo -n '"'
				done`
		outdex="(${outdex});"
		outdex=`sed -E 's@""@" \\\\\n"@g' <<< ${outdex}`
        OUTDEX='${outdex[$i]}'

		nsamples=`ls -1 ${x} | wc -l`
		narrays=$(($nsamples-1))

# array name eg. "partition_36"
jname="partition_$(basename "$x")_array"
pname="partition_$(basename "$x")" 

echo """#!/bin/bash
#SBATCH -J ${jname}
#SBATCH -t ${max_time}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH -e ${logs}/${jname}_%A.err
#SBATCH -o ${logs}/${jname}_%A.out
#SBATCH --mem=128GB
#SBATCH --array=0-${narrays}

# load modules
module load spades

# array indexes
index=${index}
outdex=${outdex}

# run spades
if [ ! -z ${satid} ]
then
i=${satid2}

mkdir ${out_dir}/${pname}
mkdir ${tmp_dir}/${pname}

spades.py \
--only-assembler \
-t 20 \
-m 128 \
--12 ${INDEX} \
-o ${out_dir}/${pname}/${OUTDEX}_out \
-tmp-dir ${tmp_dir}/${pname}/${OUTDEX}_tmp

else
	echo "Error: missing array index as SLURM_ARRAY_TASK_ID"
fi
""" > ${slurm_script_dir}/${jname}.q
done

# send scripts to slurm
#for job in ${slurm_script_dir}/*.q
#do  	
#	echo ""
#	echo "========================="
#	echo "Pushing ${job} to slurm"
# 	sbatch ${job}
#  	sleep 1
#done

