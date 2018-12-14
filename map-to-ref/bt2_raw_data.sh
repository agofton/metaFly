#!/bin/bash

# set params & help
help_message="Maps seqs to a ref genome with bowtie2 and keep seqs that do not match. Ref genome should already be indexed with bowtie2.
Writes and launches a slurm array sending each sample to its own node for mapping.
Assumes .fasta files, pe reads in separate files, and one unpaired read file - all labeled with the same filename_prefix_R1/R2/R0.fasta - as formatted by 2-clean-trimmomatic-output.sh
Edit lines 114-117 to change mapping params."

usage="Usage: $(basename "$0") 
{-d path/to/indexed/genome(s)/index_prefix} 
{-s /input/dir} 
{-o /output/dir} 
{-j job_name} 
{-n nsamples} 
{-c run_nsamples_at_once} 
{-t max time (hh:mm:ss format)}
{-p nthreads}
{-m mem in GB eg. 128GB}
[-h show this help message]"

while getopts hd:s:o:j:n:c:t:p:m: option; do
	case "${option}" in
		h) echo "$hmessage"
		   echo "$usage"
		   exit;;
		d) database=$OPTARG;;
		s) seqs_dir=$OPTARG;;
		o) output_dir=$OPTARG;;
		j) job_name=$OPTARG;;
		n) n_jobs=$OPTARG;;
		c) n_jobs_at_once=$OPTARG;;
		t) time_per_sample=$OPTARG;;
		p) nthreads=$OPTARG;;
		m) mem=$OPTARG;;
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
slurm_script="./slurm-submission-scripts/bt2_SLURM_${job_name}_`date -I`.q"
work_dir="`pwd`"
satid='${SLRUM_ARRAY_TASK_ID}'  
narrays=$(($n_jobs-1))
satid='${SLURM_ARRAY_TASK_ID}'
satid2='"$SLURM_ARRAY_TASK_ID"'
 
# set dirs
mkdir -p ${output_dir}
mkdir -p ${output_dir}/logs
mkdir -p ${output_dir}/mapped
mkdir -p ${output_dir}/unmapped

# set array indexes
# R1 index
R1index=`for x in ${seqs_dir}/*R1*; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
	R1index="(${R1index});"
		R1index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R1index}`

# R2 index
R2index=`for x in ${seqs_dir}/*R2*; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
	R2index="(${R2index});"
		R2index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R2index}`

# unmapped dir index
UMindex=`for x in ${seqs_dir}/*R1*; do
			echo -n '"'
			echo -n $(basename "$x" R1.labeled.fastq.gz)_R%.labeled.unmapped.fq.gz
			echo -n '"'
		done`
	UMindex="(${UMindex});"
		UMindex=`sed -E 's@""@" \\\\\\n"@g' <<< ${UMindex}`

# index vars
R1I='${R1[$i]}'
R2I='${R2[$i]}'
UMI='${UM[$i]}'

# writing slurm script
echo """#!/bin/bash

#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${time_per_sample}
#SBATCH -o ${output_dir}/logs/${job_name}_%A_sample_%a.out
#SBATCH -e ${output_dir}/logs/${job_name}_%A_sample_%a.err
#SBATCH --array=0-${narrays}%${n_jobs_at_once}
#SBATCH --mem=${mem}

# load modules
module load bowtie/2.2.9

# print arrays
R1=${R1index}
R2=${R2index}
UM=${UMindex}

# main script
if [ ! -z ${satid2} ]
then
i=${satid}

bowtie2 \
-q \
-x ${database} \
-1 ${seqs_dir}/${R1I} \
-2 ${seqs_dir}/${R2I} \
--threads ${nthreads} \
--local -N 1 \
--un-conc-gz ${output_dir}/unmapped/${UMI}

else
	echo "Error: missing array index as SLURM_ARRAY_TASK_ID"
fi
""" > ${slurm_script}


# pushing script to slurm
sbatch ${slurm_script}



