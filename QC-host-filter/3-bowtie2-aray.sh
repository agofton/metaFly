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
  
# set vars
slurm_script="./slurm-submission-scripts/bt2_SLURM_${job_name}.q"
work_dir="`pwd`"
satid='${SLRUM_ARRAY_TASK_ID}'  

# set dirs
mkdir -p ${output_dir}
mkdir -p ${output_dir}/logs
mkdir -p ${output_dir}/tmp

# writing slurm script
  # SLURM variables
echo """#!/bin/bash

#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${time_per_sample}
#SBATCH -o ${output_dir}/logs/${job_name}_%A_sample_%a.out
#SBATCH -e ${output_dir}/logs/${job_name}_%A_sample_%a.err
#SBATCH --array=1-${n_jobs}%${n_jobs_at_once}

#load modules
module load bowtie/2.2.9

# loop through input R1 to creat tmp dirs
for x in ${seqs_dir}/*R1.fasta; do
	mkdir -p ${output_dir}/tmp/$(basename "$x" R1.fasta)unmapped
done

# bowtie2 command
bowtie2 \
-f \
-x ${database} \
-1 ${seqs_dir}/sample_${satid}_R1.fasta \
-2 ${seqs_dir}/sample_${satid}_R2.fasta \
-U ${seqs_dir}/sample_${satid}_R0.fasta \
--no-unal \
--no-hd \
--threads 20 \
--fast-local \
--un-conc ${output_dir}/tmp/sample_${satid}_unmapped \
--al ${output_dir}/tmp/sample_${satid}_unmapped

# cleanup - yet to be tested
cd ${output_dir}/tmp/sample_${satid}_unmapped
mv un-conc-mate.1 ${output_dir}/sample_${satid}_R1.fasta
mv un-conc-mate.2 ${output_dir}/sample_${satid}_R2.fasta
mv al-seqs ${output_dir}/sample_${satid}_R0.fasta
cd ${work_dir}

rm -r -f ${output_dir}/tmp/sample_${satid}_unmapped""" > ${slurm_script}

# pushing script to slurm
sbatch ${slurm_script}

