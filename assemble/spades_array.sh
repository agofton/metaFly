#!/bin/bash

####
#
#
# Written by Alexander Gofton, ANIC, CSIRO, 2018
# alexander.gofton@gmail.com; alexander.gofton@csiro.au
####

# set params & help
hmessage=""
usage="Usage: $(basename "$0") "

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

# set dirs
mkdir -p ${outdir}
mkdir -p ${outdir}/logs
mkdir -p /flush2/gof005/spades_tmp_${jobname}
# write slurm script
 # SLURM vars
    echo '#!/bin/bash' 												> $sscript
    echo "" 														>> $sscript
    echo "#SBATCH -J ${jobname}" 									>> $sscript
    echo '#SBATCH --nodes=1' 										>> $sscript
	echo '#SBATCH --ntasks-per-node=20' 							>> $sscript
    echo "#SBATCH --time ${max_time}" 								>> $sscript
    echo "#SBATCH -o ${outdir}/logs/${jobname}_%A_sample_%a.out" 	>> $sscript
    echo "#SBATCH -e ${outdir}/logs/${jobname}_%A_sample_%a.err" 	>> $sscript
    echo "#SBATCH --array=1-${njobs}%${njobs_at_once}" 				>> $sscript
	echo "#SBATCH --mem=128GB" 										>> $sscript
	echo "#SBATCH --array1-${njobs}%${njobs_at_once}" 				>> $sscript
    echo "" 														>> $sscript
	# load spades
	echo "module load spades" 										>> $sscript
	echo "" 														>> $sscript
	# spades command
	echo -n 'spades.py --only-assembler -t 20 -m 128' 				>> $sscript
		# R1
	echo -n "-i ${indir}/" 											>> $sscript
	echo -n 'sample_${SLURM_ARRAY_TASK_ID}_R1.fasta ' 				>> $sscript
		# R2
	echo -n "-2 ${indir}/" 											>> $sscript
	echo -n 'sample_${SLURM_ARRAY_TASK_ID}_R2.fasta ' 				>> $sscript
		# R0
	echo -n "-s ${indir}/" 											>> $sscript
	echo -n 'sample_${SLURM_ARRAY_TASK_ID}_R0.fasta ' 				>> $sscript
   		# output
	echo -n "-o ${outdir}/" 										>> $sscript
	echo -n 'sample_${SLURM_ARRAY_TASK_ID} ' 						>> $sscript
		# tmp
	echo -n "--tmp-dir /flush2/gof005/spades-tmp-${jobname}" 		>> $sscript
	echo '/sample_${SLURM_ARRAY_TASK_ID}' 							>> $sscript	

