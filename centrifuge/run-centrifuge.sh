#!/bin/bash

####
# usage: run-centrifuge.sh \
#				-i {in dir with .fasta files}
#				-db {indexed db dir + db prefix}
#				-o {output dir}
#				-j {job name}
# 				-t {time: hh:mm:ss}
#
#
#
####
# set params
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -db|--db)
      db=$2
      shift 2
      ;;
    -i|--in_dir)
      in_dir=$2
      shift 2
      ;;
    -o|--out_dir) 
      out_dir=$2
      shift 2
      ;;
	-j|--job_name)
	  job_name=$2
	  shift 2
	  ;;
	-t|--time)
	  time=$2
	  shift 2
	  ;;
	-*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAM="$PARAMS $1"
      shift
      ;;
  esac
done

eval set -- "$PARAMS"

# set dirs
mkdir -p ${out_dir}
mkdir -p ${out_dir}/logs

# set vars
outfile=${out_dir}/centrifuge_${job_name}.out
report=${out_dir}/centrifuge_${job_name}.rep
y="/home/gof005/metaFly/mf_sub_scripts/centrifuge_${job_name}.q"

	# FWD seqs file list
fwd_list=$(for x in ${in_dir}/*R1.fasta; do 
				echo -n "${x},"
		   done)							# assumes std illuma file naming "sample_x_R1.fasta"
	fwd_list=$(sed 's/.$//g' <<< $fwd_list) # removing last , in list

	# REV seqs file list
rev_list=$(for x in ${in_dir}/*R2.fasta; do
				echo -n "${x},"
		   done)
	rev_list=$(sed 's/.$//g' <<< $rev_list)

	# Unpaired seqs file list
unp_list=$(for x in ${in_dir}/*R0.fasta; do
				echo -n "${x},"
		   done) 							# R0 is my naming for unpaired reads
	unp_list=$(sed 's/.$//g' <<< $unp_list)
	
# write slurm script
echo """#!/bin/bash
#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time=${time}
#SBATCH -o ${out_dir}/logs/${job_name}_%A.out
#SBATCH -e ${out_dir}/logs/${job_name}_%A.err
#SBATCH --mem=128GB

module load centrifuge

centrifuge \
-f \
-t \
-x ${db} \
-1 ${fwd_list} \
-2 ${rev_list} \
-U ${unp_list} \
-p 20 \
-S ${outfile} \
--report-file ${report}""" > $y


# push job to slurm
sbatch $y


