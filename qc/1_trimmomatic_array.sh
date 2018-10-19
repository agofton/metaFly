#!/bin/bash

####
# usage: trim-qc.sh \
#			-i {input dir containing raw .fastq} \ 
# 			-o {output dir} 					# all output including logs will go here
# 			-a {Illumina adapters to trim} \ 	# as specified in trimmomatic manual
# 			-j {job name} \ 					# for slurm job
# 			-t {max time per sample hh:mm:ss} \ # for slurm job
# 			-n {nsamples} \ 					# will launch n arrays, sending each sample to it's own node
# 			-c {run n samples at once} \ 		# limit this for large n values so as not to overrun the cluster
# 			-f {filename prefix for samples}
# -h for help
# This script pushes jobs to slurm. 
#
# Edit lines 95-115 to change trimmomatic params.
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
hmessage="Runs a slurm array for eash sample in -i; assuming paired end reads"
usage="Usage: $(basename "$0") -i {input dir} -o {output dir} -a {Trimmomatic adapter file} -j {job name} -t {max time (hh:mm:ss format)} -n {n_samples} -c {n jobs at once} -f {filename prefix for samples eg. sample_}"

while getopts hi:o:a:j:t:n:c: option; do
	case "${option}"
	in
		h) echo "$hmessage"
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
y="/home/gof005/metaFly/mf_sub_scripts/trim-qc_${job_name}.q"
q="${out_dir}/trimmomatic_out"
l="${out_dir}/logs"
er="${out_dir}/slurm_std_err_out"
SATID='${SLURM_ARRAY_TASK_ID}'

# set dirs
mkdir -p ${out_dir}
mkdir -p ${l}
mkdir -p ${q}
mkdir -p ${er}

# writ slurm scrip
echo """#!/bin/bash
#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${max_time}
#SBATCH -e ${er}/${job_name}_%A_%a.err
#SBATCH -o ${er}/${job_name}_%A_%a.out
#SBATCH --array=1-${narray}%${narray_at_once}

# load modules
module load trimmomatic/0.38

# trimmomatic command	
trimmomatic PE \
-threads 20 \
-phred33 \
-trimlog ${l}/trimlog_sample_${SATID} \
-summary ${l}/sumfile_sample_${SATID} \
${in_dir}/${filename_prefix}${SATID}_R1.fastq \
${in_dir}/${filename_prefix}${SATID}_R2.fastq \
-baseout ${q}/${filename_prefix}${SATID}.fastq \
ILLUMINACLIP:${adapters} \
SLIDINGWINDOW:5:30 \
LEADING:15
TRAILING:15
MINLEN:50""" > $y


# pushing script to slurm
sbatch $y

