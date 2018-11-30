#!/bin/bash

####
#
####

help_message="Writes and launches a slurm array job sending each sample (file) to its own node to run kraken2. kraken2 db must be build before running this job, and it is recommended that all input seqs from each sample are concatenated together into a single file - unless you only have pe reads, in which case this script can be editied to accept those. Default file types is .fastq, but this cript can be edited to accept .fasta files."

usage="Usage: $(basename "$0")
{-d /path/to/k2/database/folder}
{-i /input/dir}
{-o /output/dir}
{-j job_name}
{-n nfiles}
{-c run_njobs_at_once}
{-t max time (hh:mm:ss format)}
{-q either "express" or "standard"} <- selects the quality of service for slurm priority (default=standard, max time for express is 06:00:00)
[-h show this help message]
"

while getopts hd:i:o:j:n:c:t:q: option; do
	case "${option}" in
		h) echo "$help_message" 
		   echo ""
		   echo "$usage"
		   exit;;
		d) database=$OPTARG;;
		i) in_dir=$OPTARG;;
		o) out_dir=$OPTARG;;
		j) job_name=$OPTARG;;
		n) n_jobs=$OPTARG;;
		c) n_jobs_at_once=$OPTARG;;
		t) max_time=$OPTARG;;
		q) qos=$OPTARG;;
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
mkdir -p ${out_dir}/out
mkdir -p ${out_dir}/logs
mkdir -p ${out_dir}/class
mkdir -p ${out_dir}/unclass
mkdir -p ${out_dir}/reports

# set vars
slurm_script="slurm-submission-scripts/kraken2_${job_name}_`date -I`"
narrays=$(($n_jobs-1))

# array indexes
# input
in_index="(`for x in ${in_dir}/*.fastq; do
				echo -n '"'
				echo -n $(basename $x)
				echo -n '"'
			done`);"
	in_index=`sed -E 's@""@" \\\\\\n"@g' <<< ${in_index}`
# output
out_index="(`for x in ${in_dir}/*.fastq; do
				echo -n '"'
				echo -n $(basename $x .fastq).k2out
				echo -n '"'
			done`);"
	out_index=`sed -E 's@""@" \\\\\\n"@g' <<< ${out_index}`
# class
class_index="(`for x in ${in_dir}/*.fastq; do
				echo -n '"'
				echo -n $(basename $x .fastq)_class.fastq
				echo -n '"'
			done`);"
	class_index=`sed -E 's@""@" \\\\\\n"@g' <<< ${class_index}`
# unclass
unclass_index="(`for x in ${in_dir}/*.fastq; do
				echo -n '"'
				echo -n $(basename $x .fastq)_unclass.fastq
				echo -n '"'
			done`);"
	unclass_index=`sed -E 's@""@" \\\\\\n"@g' <<< ${unclass_index}`
# report
rep_index="(`for x in ${in_dir}/*.fastq; do
				echo -n '"'
				echo -n $(basename $x .fastq).rep
				echo -n '"'
			done`);"
	rep_index=`sed -E 's@""@" \\\\\\n"@g' <<< ${rep_index}`

# slurm vars
satid1='"$SLURM_ARRAY_TASK_ID"'
satid2='${SLURM_ARRAY_TASK_ID}'
in='${IN_INDEX[$i]}'
out='${OUT_INDEX[$i]}'
class='${CLASS_INDEX[$i]}'
unclass='${UNCLASS_INDEX[$i]}'
rep='${REP_INDEX[$i]}'

# write slurm script

# qos switch
if [[ $qos == "express" ]]; then
		
echo "#!/bin/bash

#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${max_time}
#SBATCH -o ${out_dir}/logs/${job_name}_%A_sample_%a.out
#SBATCH -e ${out_dir}/logs/${job_name}_%A_sample_%a.err
#SBATCH --array=0-${narrays}%${n_jobs_at_once}
#SBATCH --mem=128GB
#SBATCH --qos=express

module load kraken2

IN_INDEX=$in_index
OUT_INDEX=$out_index
CLASS_INDEX=$class_index
UNCALSS_INDEX=$unclass_index
REP_INDEX=$rep_index

if [[ ! -z ${satid1} ]]; then
	i=${satid2}

kraken2 \
--db ${database} \
--classified-out ${out_dir}/class/${class} \
--unclssified-out ${out_dir}/unclass/${unclass} \
--threads 20 \
--output ${out_dir}/out/${out} \
--report ${out_dir}/reports/${rep} \
--use-names \
${in_dir}/${in}

else
	echo "Error: missing array index as SLURM_ARRAY_TASK_ID"
fi
" > $slurm_script
###
else
###
echo "#!/bin/bash

#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${max_time}
#SBATCH -o ${out_dir}/logs/${job_name}_%A_sample_%a.out
#SBATCH -e ${out_dir}/logs/${job_name}_%A_sample_%a.err
#SBATCH --array=0-${narrays}%${n_jobs_at_once}
#SBATCH --mem=128GB

module load kraken2

IN_INDEX=$in_index
OUT_INDEX=$out_index
CLASS_INDEX=$class_index
UNCALSS_INDEX=$unclass_index
REP_INDEX=$rep_index

if [ ! -z ${satid1} ]; then
	i=${satid2}

kraken2 \
--db ${database} \
--classified-out ${out_dir}/class/${class} \
--unclssified-out ${out_dir}/unclass/${unclass} \
--threads 20 \
--output ${out_dir}/out/${out} \
--report ${out_dir}/reports/${rep} \
--use-names \
${in_dir}/${in}

else
	echo "Error: missing array index as SLURM_ARRAY_TASK_ID"
fi
" > $slurm_script

fi

# push job to slurm
sbatch $slurm_script








