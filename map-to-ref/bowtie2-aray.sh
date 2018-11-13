#!/bin/bash

##### 
# usage: 3-bowtie2-array.sh -d {indexed bt2 ref genome} \
#                         -s {dir containing input pe and se reads} \ 				<- output from QC - phix_filt
#                         -o {dir for output} \ 									<- all output including logs will go here
#                         -j {job name for SLURM} \
#                         -n {num. of samples} \
#                         -c {num. of arrayed job to run concurrently} \ 			<- limit this as not to overload slurm or the clusters
#                         -t {time limit for each sample to map fmt: hh:mm:ss} \
# -h for help
#                         
# This script will write and launch an array job via SLURM where each set of
# input files for each sample is sent to its own node.
#
# Input seqs are expected to be in .fasta format by default and in paired-end
# format with fwd reads in one file and rev reads in another file.
#
# File name are expected as "sample_x_R1.fasta" -> fwd pe reads
#                           "sample_x_R2.fasta" -> rev pe reads
#                           "sample_x_R0.fasta" -> orphan se reads
#                           etc.
#
# PE fwd and rev reads must correspond file-for-file and read-for-read in each 
# file.
#
# Input seqs are by default are in .fasta format. This is because if you are
# up to this step (map-to-ref host read filtering) either 1) qc has already
# been done or, 2) you are not doing qc on these reads
#
# SLURM scripts will be written to ./mf_sub_scrips/bt2/bt2_SLURM_{job name for SLURM}.q and 
# automatically sent to the queue.
#
# Written by Alexander W. Gofton, ANIC, CSIRO, 2018
# alexander.gofton@csiro.au; alexander.gofton@gmail.com
#### 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
[-h show this help message]"

while getopts hd:s:o:j:n:c:t: option; do
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
		:) printf "missing argument for  -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
	  	   exit 1;;
	   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
		   exit 1;;
	esac
done
shift $((OPTIND - 1))
###########################################################################
# set vars
slurm_script="./slurm-submission-scripts/bt2_SLURM_${job_name}.q"
work_dir="`pwd`"
satid='${SLRUM_ARRAY_TASK_ID}'  
narrays=$(($n_jobs-1))
satid='${SLURM_ARRAY_TASK_ID}'
satid2='"$SLURM_ARRAY_TASK_ID"'
######################################################################## 
# set dirs
mkdir -p ${output_dir}
mkdir -p ${output_dir}/logs
mkdir -p ${output_dir}/mapped
mkdir -p ${output_dir}/unmapped
##############################
# set array indexes
# R1 index
R1index=`for x in ${seqs_dir}/*R1.fastq; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
	R1index="(${R1index});"
		R1index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R1index}`
###########################################################
# R2 index
R2index=`for x in ${seqs_dir}/*R2.fastq; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
	R2index="(${R2index});"
		R2index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R2index}`
############################################################
# R0 index
R0index=`for x in ${seqs_dir}/*R0.fastq; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
	R0index="(${R0index});"
		R0index=`sed -E 's@""@" \\\\\\n"@g' <<< ${R0index}`
#############################################################
# unmapped dir index
UMindex=`for x in ${seqs_dir}/*R1.fastq; do
			echo -n '"'
			echo -n $(basename "$x" _R1.fastq)_R%_unmapped.fastq
			echo -n '"'
		done`
	UMindex="(${UMindex});"
		UMindex=`sed -E 's@""@" \\\\\\n"@g' <<< ${UMindex}`
#############################################################
# unmapped dir index
UNindex=`for x in ${seqs_dir}/*R1.fastq; do
			echo -n '"'
			echo -n $(basename "$x" _R1.fastq)_R0_unmapped.fastq
			echo -n '"'
		done`
	UNindex="(${UNindex});"
		UNindex=`sed -E 's@""@" \\\\\\n"@g' <<< ${UNindex}`
#############################################################
# unmapped dir index
ALindex=`for x in ${seqs_dir}/*R1.fastq; do
			echo -n '"'
			echo -n $(basename "$x" _R1.fastq)_R0_mapped.fastq
			echo -n '"'
		done`
	ALindex="(${ALindex});"
		ALindex=`sed -E 's@""@" \\\\\\n"@g' <<< ${ALindex}`
#############################################################
# unmapped dir index
ACindex=`for x in ${seqs_dir}/*R1.fastq; do
			echo -n '"'
			echo -n $(basename "$x" _R1.fastq)_R%_mapped.fastq
			echo -n '"'
		done`
	ACindex="(${ACindex});"
		ACindex=`sed -E 's@""@" \\\\\\n"@g' <<< ${ACindex}`
#############################################################
# index vars
R1I='${R1[$i]}'
R2I='${R2[$i]}'
R0I='${R0[$i]}'
UMI='${UM[$i]}'
UNI='${UN[$i]}'
ALI='${AL[$i]}'
ACI='${AC[$i]}'
#############################################################
# writing slurm script
echo """#!/bin/bash

#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${time_per_sample}
#SBATCH -o ${output_dir}/logs/${job_name}_%A_sample_%a.out
#SBATCH -e ${output_dir}/logs/${job_name}_%A_sample_%a.err
#SBATCH --array=0-${narrays}%${n_jobs_at_once}
#SBATCH --qos=express

# load modules
module load bowtie/2.2.9

# print arrays
R1=${R1index}
R2=${R2index}
R0=${R0index}
UM=${UMindex}
UN=${UNindex}
AL=${ALindex}
AC=${ACindex}

# main script
if [ ! -z ${satid2} ]
then
i=${satid}

bowtie2 \
-q \
-x ${database} \
-1 ${seqs_dir}/${R1I} \
-2 ${seqs_dir}/${R2I} \
-U ${seqs_dir}/${R0I} \
--threads 20 \
--very-fast \
--un ${output_dir}/unmapped/${UNI} \
--un-conc ${output_dir}/unmapped/${UMI} \
--al ${output_dir}/mapped/${ALI} \
--al-conc ${output_dir}/mapped/${ACI}

else
	echo "Error: missing array index as SLURM_ARRAY_TASK_ID"
fi
""" > ${slurm_script}

############################################################
# pushing script to slurm
sbatch ${slurm_script}

