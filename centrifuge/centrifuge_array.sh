#!/bin/bash

####
# usage: centrifuge_array.sh \
#				-i {in dir with .fastq files}   <-host_filtered reads
#				-db {indexed db dir + db prefix}
#				-o {output dir}
#				-j {job name}
# 				-t {time: hh:mm:ss}
# 				-n {nsamples}
# 				-c {narrays at once}
# 				-h [help message]
####

# set params and help/usage message
help_message="Writes and launches a slurm array job sending each sample in  -i [in_dir], consisting of a fwd, rev, and unpaired .fastq files, to its own node to run centrifuge against the specified indexed database"
usage='Usage: centrifuge_array.sh \
{-d indexed/db/dir/prefix} \
{-i input/.fastq/directory} \
{-o output/directory} \
{-j job_name} \
{-t max run time (hh:mm:ss)} \
{-n nsamples} \
{-c njobs at once} \
{-p nthreads} \
{-m mem in GB eg. 128GB}
[-h disply this message]'

while getopts hd:i:o:t:j:n:c:p:m: option
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
		p) nthreads=$OPTARG;;
		m) mem=$OPTARG;;	
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
slurm_script="/OSM/CBR/NCMI_AGOF/work/metaFly/slurm-submission-scripts/centrifuge_array_${job_name}_`date -I`.q"
narrays=$(($nsamples-1))
satid='"$SLURM_ARRAY_TASK_ID"'
satid2='${SLRUM_ARRAY_TASK_ID}'

# set dirs
mkdir -p ${out_dir}
mkdir -p ${out_dir}/logs
mkdir -p ${out_dir}/cent_reports
mkdir -p ${out_dir}/kreports

# R1 index
R1_index="(`for z in ${in_dir}/*R1*; do
				echo -n '"'
				echo -n $(basename "$z")
				echo -n '"'
			done`);"
	R1_index=`sed -E 's@""@" \\\\\n"@g' <<< ${R1_index}`
        
# R2 index
R2_index="(`for z in ${in_dir}/*R1*; do
				echo -n '"'
				echo -n $(basename "$z" R1.fastq)R2.fastq
				echo -n '"'
			done`);"
	R2_index=`sed -E 's@""@" \\\\\n"@g' <<< ${R2_index}`
        
# R0 index 
R0_index="(`for z in ${in_dir}/*R1*; do
				echo -n '"'
				echo -n $(basename "$z" R1.fastq)R0.fastq
				echo -n '"'
			done`);"
	R0_index=`sed -E 's@""@" \\\\\n"@g' <<< ${R0_index}`
        
# output index
out_index="(`for z in ${in_dir}/*R1*; do
				echo -n '"'
				echo -n $(basename "$z" _R1.fastq).cent.out
				echo -n '"'
			done`);"
	out_index=`sed -E 's@""@" \\\\\n"@g' <<< ${out_index}`
        
# kreport index
krep_index="(`for z in ${in_dir}/*R1*; do
				echo -n '"'
				echo -n $(basename "$z" _R1.fastq).cent.krep
				echo -n '"'
			done`);"
	krep_index=`sed -E 's@""@" \\\\\n"@g' <<< ${krep_index}`
        
R1='${R1_INDEX[$i]}'
R2='${R2_INDEX[$i]}'
R0='${R0_INDEX[$i]}'
out='${OUT_INDEX[$i]}'
krep='${KREP_INDEX[$i]}'

# write slurm script
echo """#!/bin/bash
#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time=${time}
#SBATCH -o ${out_dir}/logs/${job_name}_%A_%a.out
#SBATCH -e ${out_dir}/logs/${job_name}_%A_%a.err
#SBATCH --mem=${mem}
#SBATCH --array=0-${narrays}%${narrays_at_once}

# load centrifuge
module load centrifuge/1.0.4b

# array indexes
R1_INDEX=${R1_index}
R2_INDEX=${R2_index}
R0_INDEX=${R0_index}
OUT_INDEX=${out_index}
KREP_INDEX=${krep_index}

#run centrifuge
if [ ! -z ${satid} ]
	then
i=${satid2}

centrifuge -q -t -x ${db} -1 ${in_dir}/${R1} -2 ${in_dir}/${R2} -U ${in_dir}/${R0} -p ${nthreads} -S ${out_dir}/${out} --report-file ${out_dir}/cent_reports/${out}.rep -k 10

#kraken style report
bin/centrifuge/centrifuge-kreport -x ${db} ${out_dir}/${OUT} > ${out_dir}/kreports/${krep}

else
	echo "Error: incorrect array indexing"
fi

""" > ${slurm_script}

# push job to slurm
sbatch ${slurm_script}


