#!/bin/bash

####
#
#
# Written by Alexander Gofton, ANIC, CSIRO, 2018
# alexander.gofton@gmail.com; alexander.gofton@csiro.au
####

# set params & help
hmessage="Writes and lauches a slurm array, sending each sample in -i {in dir} to its own node for assembly with SPAdes. Each sample should have a R1, R2, and R0 file with the same prefix eg. sample _n_R1.fasta."
usage="Usage: $(basename "$0") -i {input dir} -o {output dir} -j {job name} -t {max time (hh:mm:ss)} -n {n samples} -c {n arrays at once} -h [show this help message]"

while getopts hi:o:j:t:n:c: option
do
	case "${option}"
	in
		h) echo "$hmessage"
		   echo "$usage"
		   exit;;
		i) indir=$OPTARG;;
		o) outdir=$OPTARG;;
		j) jobname=$OPTARG;;
		t) max_time=$OPTARG;;
		n) njobs=$OPTARG;;
		c) njobs_at_once=$OPTARG;;
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
sscript="./mf_sub_scripts/spades_${jobname}"
satid='${SLURM_ARRAY_TASK_ID}'

# set dirs
mkdir -p ${outdir}
mkdir -p ${outdir}/logs
mkdir -p /flush2/gof005/spades_tmp_${jobname}

# write slurm script

echo """#!/bin/bash'

#SBATCH -J ${jobname}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${max_time}
#SBATCH -o ${outdir}/logs/${jobname}_%A_sample_%a.out
#SBATCH -e ${outdir}/logs/${jobname}_%A_sample_%a.err
#SBATCH --array=1-${njobs}%${njobs_at_once}
#SBATCH --mem=128GB

# load spades
module load spades

# spades command
spades.py \
--only-assembler \
-t 20 \
-m 128 \
-1 ${indir}/sample_${satid}_R1.fasta \
-2 ${indir}/sample_${satid}_R2.fasta \
-s ${indir}/sample_${satid}_R0.fasta \
-o ${outdir}/sample_${satid} \
-tmp-dir /flush2/gof005/spades-tmp-${jobname}/sample_${satid}""" > $sscript

# push to slurm
#sbatch $sscript

