#!/bin/bash

####
# usage: 1-trimmomatic-array.sh \
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
		n) nsamples=${OPTARG};;
		c) narray_at_once=${OPTARG};;	
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
slurm_script="./slurm-submission-scripts/trim-qc_${job_name}.q"
out="${out_dir}/QC_out"
logs="${out_dir}/logs"
slogs="${out_dir}/slurm-logs"
satid='${SLURM_ARRAY_TASK_ID}'
narray=$(($nsamples-1))
tmp1=${out_dir}/tmp1
tmp2=${out_dir}/tmp2
tmp3=${out_dir}/tmp3

# set dirs
mkdir -p ${out_dir}
mkdir -p ${logs}
mkdir -p ${out}
mkdir -p ${slogs}
mkdir -p ${tmp1}
mkdir -p ${tmp2}
mkdir -p ${tmp3}

# R1 index
R1index=`for x in ${in_dir}/*R1.fastq; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
R1index="(${R1index});"
R1index=`sed -E 's@""@" \\\\\n"@g' <<< ${R1index}`

# R2 index
R2index=`for x in ${in_dir}/*R2.fastq; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
R2index="(${R2index});"
R2index=`sed -E 's@""@" \\\\\n"@g' <<< ${R2index}`

# out index
Outindex=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq).fastq
			echo -n '"'
			echo -n $id
			echo -n '"'
		done`
Outindex="(${Outindex});"
Outindex=`sed -E 's@""@" \\\\\n"@g' <<< ${Outindex}`

# trimlog index
trimlogindex=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq).trimlog
			echo -n '"'
			echo -n $id
			echo -n '"'
		done`
trimlogindex="(${trimlogindex});"
trimlogindex=`sed -E 's@""@" \\\\\n"@g' <<< ${trimlogindex}`

# summary index
sumfileindex=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq).sum
			echo -n '"'
			echo -n $id
			echo -n '"'
		done`
sumfileindex="(${sumfileindex});"
sumfileindex=`sed -E 's@""@" \\\\\n"@g' <<< ${sumfileindex}`

# 1P index
P1index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_1P.fastq
			echo -n '"'
			echo -n $id
			echo -n '"'
		done`
P1index="(${P1index});"
P1index=`sed -E 's@""@" \\\\\n"@g' <<< ${P1index}`

# 2P index
P2index=`for x in ${in_dir}/*R2.fastq; do
			id=$(basename "$x" _R2.fastq)_2P.fastq
			echo -n '"'
			echo -n $id
			echo -n '"'
		done`
P2index="(${P2index});"
P2index=`sed -E 's@""@" \\\\\n"@g' <<< ${P2index}`

# 1U index
U1index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_1U.fastq
			echo -n '"'
			echo -n $id
			echo -n '"'
		done`
U1index="(${U1index});"
U1index=`sed -E 's@""@" \\\\\n"@g' <<< ${U1index}`

# 2U index
U2index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_2U.fastq
			echo -n '"'
			echo -n $id
			echo -n '"'
		done`
U2index="(${U2index});"
U2index=`sed -E 's@""@" \\\\\n"@g' <<< ${U2index}`

# R0 index
R0index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_R0.fastq
			echo -n '"'
			echo -n $id
			echo -n '"'
		done`
R0index="(${R0index});"
R0index=`sed -E 's@""@" \\\\\n"@g' <<< ${R0index}`

# R1 .fasta 
R1fa=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_R1.fasta
			echo -n '"'
			echo -n $id
			echo -n '"'
		done`
R1fa="(${R1fa});"
R1fa=`sed -E 's@""@" \\\\\n"@g' <<< ${R1fa}`

# R2.fasta
R2fa=`for x in ${in_dir}/*R2.fastq; do
			id=$(basename "$x" _R2.fastq)_R2.fasta
			echo -n '"'
			echo -n $id
			echo -n '"'
		done`
R2fa="(${R2fa});"
R2fa=`sed -E 's@""@" \\\\\n"@g' <<< ${R2fa}`

# R0 .fasta
R0fa=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_R0.fasta
			echo -n '"'
			echo -n $id
			echo -n '"'
		done`
R0fa="(${R0fa});"
R0fa=`sed -E 's@""@" \\\\\n"@g' <<< ${R0fa}`

# index vars
R1I='${R1[$i]}'
R2I='${R2[$i]}'
OutI='${Out[$i]}'
SumI='${sumfile[$i]}'
TrimI='${trimlog[$i]}'
P1I='${P1[$i]}'
P2I='${P2[$i]}'
U1I='${U1[$i]}'
U2I='${U2[$i]}'
R0I='${R0[$i]}'
R1faI='${R1f[$i]}'
R2faI='${R2f[$i]}'
R0faI='${R0f[$i]}'

satid='${SLURM_ARRAY_TASK_ID}'
satid2='"$SLURM_ARRAY_TASK_ID"'

# writ slurm scrip
echo "#!/bin/bash
#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time ${max_time}
#SBATCH -e ${slogs}/${job_name}_%A_%a.err
#SBATCH -o ${slogs}/${job_name}_%A_%a.out
#SBATCH --array=0-${narray}%${narray_at_once}

# load modules
module load trimmomatic/0.38

# sample arrays
R1=${R1index}
R2=${R2index}
Out=${Outindex}
trimlog=${trimlogindex}
sumfile=${sumfileindex}
P1=${P1index}
P2=${P2index}
U1=${U1index}
U2=${U2index}
R0=${R0index}
R1f=${R1fa}
R2f=${R2fa}
R0f=${R0fa}

# trimmomatic command
if [ ! -z ${satid2} ]
then
	i=${satid}
	
trimmomatic PE \
-threads 20 \
-phred33 \
-trimlog ${logs}/${TrimI} \
-summary ${logs}/${SumI} \
${in_dir}/${R1I} \
${in_dir}/${R2I} \
-baseout ${tmp1}/${OutI} \
SLIDINGWINDOW:5:25 \
LEADING:15 \
TRAILING:15 \
MINLEN:50

else
	echo Error: missing array index as SLURM_ARRAY_TASK_ID

fi

# filtering phiX from PE reads
bin/usearch9.2 -filter_phix ${tmp1}/${P1I} -reverse ${tmp1}/${P2I} -output ${tmp3}/${R1I} -output2 ${tmp3}/${R2I}

# concatenating 1U and 2U reads
cat ${tmp1}/${U1I} ${tmp1}/${U2I} > ${tmp2}/${R0I}

# filtering phix from SE reads
bin/usearch9.2 -filter_phix ${tmp2}/${R0I} -output ${tmp3}/${R0I}

# converting .fasta to .fastq
#bin/usearch9.2 -fastq_filter ${tmp3}/${R1I} -fastaout ${out}/${R1faI}
#bin/usearch9.2 -fastq_filter ${tmp3}/${R2I} -fastaout ${out}/${R2faI}
#bin/usearch9.2 -fastq_filter ${tmp3}/${R0I} -fastaout ${out}/${R0faI}

" > ${slurm_script}

# pushing script to slurm
sbatch ${slurm_script}
