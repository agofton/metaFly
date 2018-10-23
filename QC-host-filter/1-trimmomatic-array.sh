#!/bin/bash

####
# usage: trim-qc.sh \
# 			-i {input dir containing raw .fastq} \ 
# 			-o {output dir} 							# all output including logs will go here
# 			-a {Illumina adapters to trim} \ 			# as specified in trimmomatic manual
# 			-j {job name} \ 							# for slurm job
# 			-t {max time per sample hh:mm:ss} \ 		# for slurm job
# 			-n {nsamples} \ 							# will launch n arrays, sending each sample to it's own node
# 			-c {run n samples at once} \ 				# limit this for large n values so as not to overrun the cluster
# 			-f {filename prefix for samples} 		    # eg. sample_	
# 			-h for help
#
# This script pushes jobs to slurm. 
#
# Edit lines 107-111 to change trimmomatic params.
#
# Output will inlcude 4 .fastq files:
# 		sample_x_1P.fastq
# 		sample_x_2P.fastq
# 		sample_x_1U.fastq
# 		sample_x_2U.fastq
#
# Written by Alexander Gofton, ANIC, CSIRO, 2018
# alexander.gofton@csiro.au; alexander.gofton@gmail.com
####

# set params & help
help_message="Writes and launches an array slurm script sending each sample in -i {input dir} to its own node to run trimmomatic.
Assumes seqs are paired-end with fwd and rev seqs in two .fastq files (R1 & R2) (Illumina format .fastq).
Changes trimmomatic QC params by editing lines 107-111."

usage="Usage: $(basename "$0") 
{-i /input/dir} 
{-o /output/dir} 
{-a Trimmomatic_adapter_file.fasta} 
{-j job_name} 
{-t max time (hh:mm:ss format)} 
{-n nsamples} 
{-c run njobs at once} 
{-f filename prefix eg. sample_}
[-h print this help message]"

while getopts hi:o:a:j:t:n:c: option
do
	case "${option}"
	in
		h) echo "$help_message"
		    echo ""
		    echo "$usage"
			exit;;
		i) in_dir=${OPTARG};;
		o) out_dir=${OPTARG};;
		a) adapters=${OPTARG};;
		j) job_name=${OPTARG};;
		t) max_time=${OPTARG};;
		n) narray=${OPTARG};;
		c) narray_at_once=${OPTARG};;
		f) filename_prefix=${OPTARG};;
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
home_dir="`pwd`"
slurm_script="${home_dir}/trim-qc_${job_name}.q"
out="${out_dir}/trimmomatic_out"
logs="${out_dir}/logs"
slogs="${home_dir}/slurm-logs"
satid='${SLURM_ARRAY_TASK_ID}'

# set dirs
mkdir -p ${out_dir}
mkdir -p ${logs}
mkdir -p ${out}
mkdir -p ${slogs}

# writ slurm scrip
echo """#!/bin/bash
#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${max_time}
#SBATCH -e ${slogs}/${job_name}_%A_%a.err
#SBATCH -o ${slogs}/${job_name}_%A_%a.out
#SBATCH --array=1-${narray}%${narray_at_once}

# load modules
module load trimmomatic/0.38

# trimmomatic command
trimmomatic PE \
-threads 20 \
-phred33 \
-trimlog ${logs}/trimlog_sample_${SATID} \
-summary ${logs}/sumfile_sample_${SATID} \
${in_dir}/${filename_prefix}${SATID}_R1.fastq \
${in_dir}/${filename_prefix}${SATID}_R2.fastq \
-baseout ${out}/${filename_prefix}${SATID}.fastq \
ILLUMINACLIP:${adapters} \
SLIDINGWINDOW:5:30 \
LEADING:15
TRAILING:15
MINLEN:50""" > ${slurm_script}


# pushing script to slurm
sbatch ${slurm_script}
