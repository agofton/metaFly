#!/bin/bash

####
#
####

# set params & help
help_message="Creates a SLURM array sending each file in .fasta or .fastq file in {-i input/dir} to its own pearcey node to pefrorm diamond blastx to the nt database.
Results will be places in {-o /output/dir} in diamond archive format (100 - can be converted into any other format and read by MEGAN), and tabular format (6 - for easy seq parsing).
For easier downstream analysis it is recomended to concatedate paired (R1 and R2) and unpaired (R0) reads into a single file prior to running this script.
By default it is assumed reads are in .fastq format, if .fasta options are required please edit this script."

usage="Usage: $(basename "$0")
{-d path/to/nr/.dmnd <- defaul for bioref is /data/bioref/diamond_db/nr-xxxxxx_diamondVxxxx.dmnd} <- make sure the correct version is specified - currently 0.9.22
{-i /input/dir}
{-o /output/dir}
{-j job_name}
{-n nfiles}
{-c run_njobs_at_once}
{-t max time (hh:mm:ss format)}
{-f fasta or fastq input (enter one) default=fastq}
[-h show this help message]"

while getopts hd:i:o:j:n:c:t:f: option; do
	case "${option}" in
		h) echo "$hmessage"
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

# fastq/fasta switch
if [ $fa_fq != 'fasta' ] && [ $fa_fq != 'fastq' ]
then
	echo 'Argument error: -f must be either "fasta" or "fastq"'
	exit 1
elif [ $fa_fq = "fasta" ]
then
	fa_fq=".fasta"
else
	fa_fq=".fastq"
fi

# set vars
slurm_script="/OSM/CBR/NCMI_AGOF/work/metaFly/slurm-submission-scripts/diamond_nr_${job_name}.q"
narrays=$(($n_jobs-1))

# set dirs
mkdir -p ${out_dir}
mkdir -p ${out_dir}/logs

# array index
file_index="(`for x in ${in_dir}/*${fa_fq}; do
				echo -n '"'
				echo -n $(basename "$x")
				echo -n '"'
			done`);"
file_index=`sed -E 's@""@" \\\\\\n"@g' <<< ${file_index}`

out_index="(`for x in ${in_dir}/*${fa_fq}; do
				echo -n '"'
				echo -n $(basename "$x" .${fa_fq})
				echo -n '"'
			done`);"
out_index=`sed -E 's@""@" \\\\\\n"@g' <<< ${out_index}`

d6_index="(`for x in ${in_dir}/*${fa_fq}; do
				echo -n '"'
				echo -n $(basename "$x" .${fa_fq}).tab
				echo -n '"'
			done`);"
d6_index=`sed -E 's@""@" \\\\\\n"@g' <<< ${d6_index}`

#script vars
satid1='"$SLURM_ARRAY_TASK_ID"'
satid2='${SLURM_ARRAY_TASK_ID}'
fiP='${FILE_INDEX[$i]}'
oiP='${OUT_INDEX[$i]}'
d6P='${D6_INDEX[$i]}'

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


module load diamond/0.9.22 bioref blast+

FILE_INDEX=$file_index
OUT_INDEX=$out_index
D6_INDEX=$d6_index

if [ ! -z ${satid1} ]
then
i=${satid2}

diamond blastx \
--db ${database} \
--query ${in_dir}/${fiP} \
--out ${out_dir}/${oiP} \
--outfmt 100 \
--threads 20 \
--strand both \
--min-orf 1 \
--sensitive \
--unal 1

diamond view -a ${out_dir}/${oiP} > ${out_dir}/${d6P}

else
	echo "Error: missing array index as SLURM_ARRAY_TASK_ID"
fi
" > ${slurm_script}

# pushing job to slurm
sbatch ${slurm_script}
