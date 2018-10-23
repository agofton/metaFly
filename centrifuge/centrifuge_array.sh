#!/bin/bash

####
# usage: centrifuge_array.sh.sh \
#				-i {in dir with .fasta files}   <-host_filtered reads
#				-db {indexed db dir + db prefix}
#				-o {output dir}
#				-j {job name}
# 				-t {time: hh:mm:ss}
# 				-n {nsamples}
# 				-c {narrays at once}
# 				-h [help message]
####

# set params and help/usage message
help_message="Writes and launches a slurm array job sending each sample in  -i [in_dir], consisting of a fwd, rev, and unpaired .fasta files, to its own node to run centrifuge against the specified indexed database"
usage="Usage: $(basename "$0") -d {indexed/db/dir/prefix} -i {input/.fasta/directory} -o {output/directory} -j {job_name} -t {max run time (hh:mm:ss)} -n {nsamples} -c {njobs at once} -h [disply this message] "

while getopts hd:i:o:t:j:n:c: option
do
	case "${option}"
	in
		h) echo "$help_message"
		   echo "$usage"
	       exit;;
		d) db=$OPTARG;; 
		i) in_dir=$OPTARG;; 
		o) out_dir=$OPTARG;;
		t) time=$OPTARG;;
		j) job_name=$OPTARG;;
		n) nsamples=$OPTARG;;
		c) narrays_at_once=$OPTARG;;	
		:) printf "missing argument for  -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
	  	   exit 1;;
	   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
		   exit 1;;
	esac
done
shift $((OPTIND - 1))

# set dirs
mkdir -p ${out_dir}
mkdir -p ${out_dir}/logs

# set vars
y="/OSM/CBR/NCMI_AGOF/work/metaFly/mf_sub_scripts/centrifuge_${job_name}.q"
satid='${SLURM_ARRAY_TASK_ID}'

# write slurm script
echo """#!/bin/bash
#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time=${time}
#SBATCH -o ${out_dir}/logs/${job_name}_%A.out
#SBATCH -e ${out_dir}/logs/${job_name}_%A.err
#SBATCH --mem=128GB
#SBATCH --array=1-${nsamples}%${narrays_at_once}

module load centrifuge

#run centrifuge
centrifuge \
-f \
-t \
-x ${db} \
-1 sample_${satid}_host-filtered_R1.fasta \
-2 sample_${satid}_host-filtered_R2.fasta \
-U sample_${satid}_host-filtered_R0.fasta \
-p 20 \
-S ${out_dir}/sample_${satid}.cent.out \
--report-file ${out_dir}/sample_${satid}.cent.rep

#kraken style report
bin/centrifuge/centrifuge-kreport \
-x ${db} \
${out_dir}/sample_${satid}.cent.out > ${out_dir}/sample_${satid}.cent.krep""" > $y

# push job to slurm
sbatch $y


