#!/bin/bash

####
# usage: centrifuge_array.sh \
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
usage='Usage: centrifuge_array.sh \
{-d indexed/db/dir/prefix} \
{-i input/.fasta/directory} \
{-o output/directory} \
{-j job_name} \
{-t max run time (hh:mm:ss)} \
{-n nsamples} \
{-c njobs at once} \
[-h disply this message]'

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

# set vars
slurm_script="/OSM/CBR/NCMI_AGOF/work/metaFly/slurm-submission-scripts/centrifuge_array_${job_name}.q"
narrays=$(($nsamples-1))
satid='"$SLURM_ARRAY_TASK_ID"'
satid2='${SLRUM_ARRAY_TASK_ID}'

# set dirs
mkdir -p ${out_dir}
mkdir -p ${out_dir}/logs
mkdir -p ${out_dir}/cent_reports
mkdir -p ${out_dir}/kreports

# R1 index
r1=`for z in ${in_dir}/*R1.fasta; do
				echo -n '"'
				echo -n $(basename "$z")
				echo -n '"'
				done`
	r1="(${r1});"
		r1=`sed -E 's@""@" \\\\\n"@g' <<< ${r1}`
        R1='${R1index[$i]}'
# R2 index
r2=`for z in ${in_dir}/*R1.fasta; do
				echo -n '"'
				echo -n $(basename "$z" R1.fasta)R2.fasta
				echo -n '"'
				done`
	r2="(${r2});"
		r2=`sed -E 's@""@" \\\\\n"@g' <<< ${r2}`
        R2='${R2index[$i]}'
# R0 index 
r0=`for z in ${in_dir}/*R1.fasta; do
				echo -n '"'
				echo -n $(basename "$z" R1.fasta)R0.fasta
				echo -n '"'
				done`
	r0="(${r0});"
		r0=`sed -E 's@""@" \\\\\n"@g' <<< ${r0}`
        R0='${R0index[$i]}'
# output index
out=`for z in ${in_dir}/*R1.fasta; do
				echo -n '"'
				echo -n $(basename "$z" _R1.fasta).cent.out
				echo -n '"'
				done`
	out="(${out});"
		out=`sed -E 's@""@" \\\\\n"@g' <<< ${out}`
        OUT='${OUTindex[$i]}'
# kreport index
krep=`for z in ${in_dir}/*R1.fasta; do
				echo -n '"'
				echo -n $(basename "$z" _R1.fasta).cent.krep
				echo -n '"'
				done`
	krep="(${krep});"
		krep=`sed -E 's@""@" \\\\\n"@g' <<< ${krep}`
        KREP='${KREPindex[$i]}'

# write slurm script
echo """#!/bin/bash
#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time=${time}
#SBATCH -o ${out_dir}/logs/${job_name}_%A_%a.out
#SBATCH -e ${out_dir}/logs/${job_name}_%A_%a.err
#SBATCH --mem=128GB
#SBATCH --array=0-${narrays}%${narrays_at_once}

# load centrifuge
module load centrifuge

# array indexes
r1=${r1}
r2=${r2}
r0=${r0}
out=${out}
krep=${krep}

#run centrifuge
if [ ! -z ${satid} ]
	then
i=${satid2}

centrifuge -f -t -x ${db} -1 ${in_dir}/${R1} -2 ${in_dir}/${R2} -U ${in_dir}/${R0} -p 20 -S ${out_dir}/${OUT} --report-file ${out_dir}/cent_reports/${OUT}.rep

#kraken style report
bin/centrifuge/centrifuge-kreport -x ${db} ${out_dir}/${OUT} > ${out_dir}/kreports/${KREP}

""" > ${slurm_script}

# push job to slurm
#sbatch ${slurm_script}


