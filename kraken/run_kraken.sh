#!/bin/bash

####
#
#
# Written by Alexander Gofton, ANIC, CSIRO, 2018
# alexander.gofton@gmail.com; alexander.gofton@csiro.au
####

# set params and help/usage message
help_message=""
usage=""

while getopts hd:i:o:t:j:n:c: option
do
	case "${option}"
	in
		h) echo "$help_message"
		   echo "$usage"
	       exit;;
		d) db=$OPTARG;; 
		i) in_dir=$OPTARG;; 
		o) out_dir=$OPTARG;;
		t) time=$OPTARG;;
		j) job_name=$OPTARG;;
		n) nsamples=$OPTARG;;
		c) narrays_at_once=$OPTARG;;	
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
db="/apps/kraken/db/standard/database"
unclass="${out_dir}/unclassified_seqs"
class="${out_dir}/classified_seqs"
satid='"$SLURM_ARRAY_TASK_ID"'
satid2='${SLURM_ARRAY_TASK_ID}'
# set dirs

# R1 index
r1=`for z in ${in_dir}/*R1.fasta; do
				echo -n '"'
				echo -n $(basename "$z")
				echo -n '"'
				done`
	r1="(${r1});"
		r1=`sed -E 's@""@" \\\\\n"@g' <<< ${r1}`
        	R1='${R1index[$i]}'

# R2 index 
r2=`for z in ${in_dir}/*R1.fasta; do
				echo -n '"'
				echo -n $(basename "$z" R1.fasta)R2.fasta
				echo -n '"'
				done`
	r2="(${r2});"
		r1=`sed -E 's@""@" \\\\\n"@g' <<< ${r2}`
        	R2='${R2index[$i]}'

# unclassified index
uc=`for z in ${in_dir}/*R1.fasta; do
				echo -n '"'
				echo -n $(basename "$z" _R1.fasta)
				echo -n '"'
				done`
	uc="(${uc});"
		uc=`sed -E 's@""@" \\\\\n"@g' <<< ${uc}`
        	UC='${UCindex[$i]}'

# classified index
cl=`for z in ${in_dir}/*R1.fasta; do
				echo -n '"'
				echo -n $(basename "$z" _R1.fasta)
				echo -n '"'
				done`
	cl="(${cl});"
		cl=`sed -E 's@""@" \\\\\n"@g' <<< ${cl}`
        	CL='${CLindex[$i]}'

# write slurm script

echo """#!/bin/bash

#SBATCH -J
#SBATCH -t
#SBATCH -e
#SBATCH -o
#SBATCH --nodes=1
#SBATCH --mem=128GB
#SBATCH --ntasks-per-node=20
#SBATCH --array=

module load kraken

if [ ! -z ${satid} ]
then
i=${satid2}

kraken \
--db ${db}
--threads 20 \
--fasta-input \
--unclassified-out ${unclass}/${UC} \
--classified-out ${class}/${UC} \
--out-fmt paired \
--paired ${in_dir}/${R1} ${in_dir}/${R2}

else
	echo "Error: missing array index as SLURM_ARRAY_TASK_ID"
fi
""" > ${slurm_script}
:



