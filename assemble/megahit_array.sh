#!/bin/bash

####
# Written by Alexander Gofton, ANIC, CSIRO, 2018
# alexander.gofton@gmail.com; alexander.gofton@csiro.au
####

# set params & help
hmessage="This sript will launch a slurm array sending each sample (consisting of a R1, R2, and R0 .fasta or fastq file)
to its own node for denovo assembly with megahit"
usage="Usage: $(basename "$0")
{-i /input/dir/}
{-o /all/output/goes/here} <- run will fail if output dir already exists
{-j job_name}
{-t max time hh:mm:ss}
{-n n_samples}
{-c run n jobs at once}
{-f input reads are fasta or fastq format - pick one}
[-h show with help message]"

while getopts hi:o:j:t:n:c:f: option
do
	case "${option}"
	in
		h) echo "$hmessage"
		   echo "$usage"
		   exit;;
		i) in_dir=$OPTARG;;
		o) out_dir=$OPTARG;;
		j) job_name=$OPTARG;;
		t) max_time=$OPTARG;;
		n) n_jobs=$OPTARG;;
		c) n_jobs_at_once=$OPTARG;;
		f) fa_fq=$OPTARG;;
		:) printf "missing argument for  -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
	  	   exit 1;;
	   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
		   exit 1;;
	esac
done
shift $((OPTIND - 1))

# fasta/fastq switch
if [ $fa_fq != 'fasta' ] && [ $fa_fq != 'fastq' ]; then
		echo 'Argument error: -f must be either "fasta" or "fastq"'
		exit 1
	elif [ $fa_fq = "fasta" ]; then
		fa_fq=".fasta"
	else
		fa_fq=".fastq"
fi

#set vars
slurm_script=/OSM/CBR/NCMI_AGOF/work/metaFly/slurm-submission-scripts/megahit_array_${job_name}_`date -I`.q
narrays=$(($n_jobs-1))

# make dirs
mkdir -p ${out_dir}
mkdir -p ${out_dir}/logs

# make indexes
# R1 index
R1_index="(`for x in ${in_dir}/*R1*; do
							echo -n '"'
							echo -n $(basename "$x")
							echo -n '"'
					done`);"
R1_index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R1_index}`
# R2 index
R2_index="(`for x in ${in_dir}/*R2*; do
							echo -n '"'
							echo -n $(basename "$x")
							echo -n '"'
					done`);"
R2_index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R2_index}`
# R2 index
R0_index="(`for x in ${in_dir}/*R0*; do
							echo -n '"'
							echo -n $(basename "$x")
							echo -n '"'
					done`);"
R0_index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R0_index}`

outprfx_index="(`for x in ${in_dir}/*R0*; do
							echo -n '"'
							echo -n $(basename "$x" _R0_unmapped.fastq)
							echo -n '"'
					done`);"
outprfx_index=`sed -E 's@""@" \\\\\\n"@g' <<< ${outprfx_index}`

#script vars
satid1='"$SLURM_ARRAY_TASK_ID"'
satid2='${SLURM_ARRAY_TASK_ID}'
R1p='${R1_INDEX[$i]}'
R2p='${R2_INDEX[$i]}'
R0p='${R0_INDEX[$i]}'
outp='${OUTPRFX_INDEX[$i]}'

# write slurm array script
echo "#!/bin/bash

#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${max_time}
#SBATCH -o ${out_dir}/logs/${job_name}_%A_sample_%a.out
#SBATCH -e ${out_dir}/logs/${job_name}_%A_sample_%a.err
#SBATCH --array=0-${narrays}%${n_jobs_at_once}
#SBATCH --mem=128GB

module load megahit

R1_INDEX=$R1_index
R2_INDEX=$R2_index
R0_INDEX=$R0_index
OUTPRFX_INDEX=$outprfx_index

if [ ! -z ${satid1} ]
then
i=${satid2}

megahit \
-1 ${in_dir}/${R1p} \
-2 ${in_dir}/${R2p} \
-r ${in_dir}/${R0p} \
-t 20 \
-o ${out_dir}/${outp}

else
	echo "Error: missing array index as SLURM_ARRAY_TASK_ID"
fi
" > ${slurm_script}

# pushing job to slurm
sbatch ${slurm_script}
