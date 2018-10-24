#!/bin/bash

#### 
# usage: 5_split_n_blast_array.sh \
#         -i {input reads dir} \
#		  -o {blast output dir} \
#		  -j {job name} \
#		  -n {number of splits per sample} \
# 		  -c {n arrays per same to run at once} \
# 	      -t {time per array in hh:mm:ss} \
# 		  -h for help
#
# This script will split each .fasta file in a given directory into n
# pieces & send each piece to its own node (threads=20) and megablast against 
# the complete ncbi nt db.
#
# Note if you have few seqs you can use blastn, but larger datasetst
# it is significatnly faster to use megablast
##
# This script does this by creating and launching a SLURM array script
# for each sample (narrays=nchunks+1). Given that you may launch 100's of samples at once,
# please limit the c variable so you don't clog up the cluster.
#
# This script utilises usearch9.2 to split up input fasta files. Given that the login
# shell is not designed for large operations it may be wise to enter an interactive node
# to run this script. sinteractive -p h2 -t 02:00:00
#
# SLURM scripts will be written to ./slurm-submission-scripts/split-n-blast_SLURM_{job name}/sample_ID_blast.q 
# and automatically sent to the queue.
#
# Following the completion of this script run stitch-b6out.sh to stitch
# the pieces from corresponding samples back together.
#
# Written by Alexander Gofton, ANIC, CSIRO, 2018
# alexander.gofton@csiro.au; alexander.gofton@gmail.com
####

# set params and help
help_message="Splits input files into -n {nchunks} (will normally get nchunks + 1), writes and launches a series of slurm array jobs (one per sample, with narrays=nchunks+1), sending each chunk to its own node for megablast to nr. Results given in outfmt 6."
usage="Usage: $(basename "$0") -i {input reads} -o {output blast files} -j {job name} -n {nchunks per file} -d {run n arrays per sample at once} -t {max time per array (hh:mm:ss)}"

while getopts hi:o:j:n:d:t: option; do
	case "${option}" in
		h) echo "$help_message"
		   echo ""
		   echo "$usage"
		   exit;;
		i) input_reads_dir=$OPTARG;;
		o) blast_output_dir=$OPTARG;;
		j) job_name=$OPTARG;;
		n) nchunks=$OPTARG;;
		d) n_arrays_at_once=$OPTARG;;
		t) max_time=$OPTARG;;
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
narrays=$(($nchunks+1))
satid='${SLURM_ARRAY_TASK_ID}'
SBscripts_dir="./slurm-submission-scripts/split-n-blast_${job_name}"
logs="${blast_output_dir}/logs"

# set dirs 
mkdir -p ${SBscripts_dir}
mkdir -p ${input_reads_dir}/split_files
mkdir -p ${blast_output_dir}
mkdir -p ${logs}

# using loop to split each input file
for x in ${input_reads_dir}/*.fasta; do
    
    # sample spec. vars.
    name="$(basename "$x")"
    seqs_per_sample="`cat ${x} | grep -c "^>"`"
    seqs_per_chunk=$(($seqs_per_sample / $narrays))
    
	# callout
    echo ""
    echo "========================================================="
    echo "Splitting ${name} into ${narrays} chunks; "
    echo "Approx ${seqs_per_chunk} reads per chunk"
	echo "========================================================="
    echo ""

    # command
    bin/usearch9.2 \
	     -fastx_split ${x} \
  	     -splits  ${nchunks} \
  	     -outname "${input_reads_dir}/split_files/$(basename "$x" .fasta)_@.fasta"
done

# using loop to creating 1 SLURM array script per original input file
for z in ${input_reads_dir}/*.fasta; do

# set vars
slurm_script="${SBscripts_dir}/$(basename "$z" .fasta)-blast-array.q"
f="${input_reads_dir}/split_files/$(basename "$z" .fasta)_${satid}.fasta"
o="${blast_output_dir}/$(basename "$z" .fasta)_${satid}.b6out"

# writing SLURM script
echo """#!/bin/bash
#SBATCH -J ${job_name}
#SBATCH --time 02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH -o ${logs}/${job_name}_%A_%a.out
#SBATCH -e ${logs}/${job_name}_%A_%a.err
#SBATCH --array=1-${narrays}%${n_arrays_at_once}

# load modules
module load blast+/2.6.0
module load bioref

# blast script
blastn \
-task megablast \
-query ${f} \
-db /data/bioref/blast/ncbi/nt \
-strand both
-num_threads 20
-max_target_seqs 5
-outfmt '6 ssciname scomname staxid qseqid saccver pident length mismatch gapopen evalue bitscore'
-out ${o}""" > ${slurm_script}

done

# pushing jobs to SLURM
for job in ${SBscripts_dir}/*.q; do
  	
	echo ""
	echo "========================="
	echo "Pushing ${job} to slurm"
  	sbatch ${job}
  	sleep 1
done
