#!/bin/bash

##### 
# Written by Alexander W. Gofton, ANIC, CSIRO, 2018
# alexander.gofton@csiro.au; alexander.gofton@gmail.com
#### 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# set params & help
help_message="Maps seqs to a ref genome with BWA and partition reads into mapped and unmapped. Ref genome should already be indexed with bwa index.
Writes and launches a slurm array sending each sample to its own node for mapping.
Assumes .fastq files, pe reads in separate files, and one unpaired read file - all labeled with the same filename_prefix_R1/R2/R0.fasta.
Edit lines 114-117 to change mapping params."

usage="Usage: $(basename "$0") 
{-d path/to/indexed/genome(s)/index_prefix} 
{-i /input/dir} 
{-o /output/dir} 
{-j job_name} 
{-n nsamples} 
{-c run_nsamples_at_once} 
{-t max time (hh:mm:ss format)}
[-h show this help message]"

while getopts hd:i:o:j:n:c:t: option; do
	case "${option}" in
		h) echo "$hmessage"
		   echo "$usage"
		   exit;;
		d) database=$OPTARG;;
		i) in_dir=$OPTARG;;
		o) out_dir=$OPTARG;;
		j) job_name=$OPTARG;;
		n) n_jobs=$OPTARG;;
		c) n_jobs_at_once=$OPTARG;;
		t) time_per_sample=$OPTARG;;
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
slurm_script="./slurm-submission-scripts/bwa_array_${job_name}.q"
narrays=$(($n_jobs-1))
satid='"$SLURM_ARRAY_TASK_ID"'
satid2='${SLURM_ARRAY_TASK_ID}'

# set dirs
mkdir -p ${out_dir}
mkdir -p ${out_dir}/unmapped
mkdir -p ${out_dir}/mapped
mkdir -p ${out_dir}/bwa_out
mkdir -p ${out_dir}/logs

# R0 index
R0index="(`for x in ${in_dir}/*R0.fastq; do
				echo -n '"'
				echo -n $(basename "$x")
				echo -n '"'
			done`);"
	R0index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R0index}`
# R1 index
R1index="(`for x in ${in_dir}/*R1.fastq; do
				echo -n '"'
				echo -n $(basename "$x")
				echo -n '"'
			done`);"
	R1index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R1index}`
# R2 index
R2index="(`for x in ${in_dir}/*R2.fastq; do
				echo -n '"'
				echo -n $(basename "$x")
				echo -n '"'
			done`);"
	R2index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R2index}`
# R0sam index
R0samindex="(`for x in ${in_dir}/*R0.fastq; do
				id=$(basename "$x" .fastq).sam
				echo -n '"'
				echo -n $id
				echo -n '"'
			done`);"
	R0samindex=`sed -E 's@""@" \\\\\\n"@g' <<< ${R0samindex}`
# PEsam index
PEsamindex="(`for x in ${in_dir}/*R1.fastq; do
				id=$(basename "$x" _R1.fastq)_pe.sam
				echo -n '"'
				echo -n $id
				echo -n '"'
			done`);"
	PEsamindex=`sed -E 's@""@" \\\\\\n"@g' <<< ${PEsamindex}`
# paired fq index
pairedfqindex="(`for x in ${in_dir}/*R1.fastq; do
				id=$(basename "$x" _R1.fastq)_pe_interleaved.fastq
				echo -n '"'
				echo -n $id
				echo -n '"'
			done`);"
	pairedfqindex=`sed -E 's@""@" \\\\\\n"@g' <<< ${pairedfqindex}`
prefixindex="(`for x in ${in_dir}/*R1.fastq; do
				echo -n '"'
				echo -n $(basename "$x" _R1.fastq)
				echo -n '"'
			done`);"
	prefixindex=`sed -E 's@""@" \\\\\\n"@g' <<< ${prefixindex}`

#############################################################
# index vars
R0i='${R0[$i]}'
R1i='${R1[$i]}'
R2i='${R2[$i]}'
PEsami='${PEsam[$i]}'
R0sami='${R0sam[$i]}'
pairedfqi='${pairedfq[$i]}'
#############################################################
# writing slurm script
  # SLURM variables

echo "#!/bin/bash

#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${time_per_sample}
#SBATCH -o ${out_dir}/logs/${job_name}_%A_sample_%a.out
#SBATCH -e ${out_dir}/logs/${job_name}_%A_sample_%a.err
#SBATCH --array=0-${narrays}%${n_jobs_at_once}

# load modules
module load bwa
module load bbmap
module load samtools

# print arrays
R0=${R0index}
R1=${R1index}
R2=${R2index}
PEsam=${PEsamindex}
R0sam=${R0samindex}
pairedfq=${pairedfqindex}

# main script
if [ ! -z ${satid} ]
then
i=${satid2}

# bwa on R0
bwa mem -t 20 ${database} ${in_dir}/${R0i} > ${out_dir}/bwa_out/${R0sami}
# Extract unmapped reads as fq
samtools fastq -f 4 ${out_dir}/bwa_out/${R0sami} > ${out_dir}/unmapped/${R0i}

# bwa on R1/2
bwa mem -t 20 -p ${database} ${in_dir}/${R1i} ${in_dir}/${R2i} > ${out_dir}/bwa_out/${PEsami}
# extract unmapped as fq
samtools fastq -f 4 ${out_dir}/bwa_out/${PEsami} > out=${out_dir}/unmapped/${pairedfqi} 

else
	echo "Error: missing array index as SLURM_ARRAY_TASK_ID"
fi
" > ${slurm_script}

# pushing script to slurm
sbatch ${slurm_script}

