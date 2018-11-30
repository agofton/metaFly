#!/bin/bash

####
#
#
####

# set params & help
help_message="Writes a slurm script that 1) merges PE reads (bbmerge vstrict=t) in R1 and R2 files in -i /inpit/dir and 2) quality filters the merged and unmerged reads (trimmomatic).
Each same in -i /input/dir will be send to its own node for processing. Output will be R1, R1 (fwd and rev paired unmerged reads), and R0, merged and single-end reads."
usage="Usage: merge_and_trim.sh \
{-i /path/to/input/R1-R2/files} \
{-o /all/output/will/go/here} \
{-j job_name} \
{-t max time hh:mm:ss} \
{-n num samples} \
{-c run n samples at once} \
{-w trimmomatic sliding window size} \
{-q trimmomatic window ave qual} \
{-l trimmomatic min len} \
[-h show this message]"

while getopts hi:o:j:t:n:c:w:q:l option
do
	case "${option}"
	in
		h) echo "$help_message"
		    echo ""
		    echo "$usage"
			exit;;
		i) in_dir=${OPTARG};;
		o) out_dir=${OPTARG};;
		j) job_name=${OPTARG};;
		t) mtime=${OPTARG};;
		n) nsamples=${OPTARG};;
		c) narray_at_once=${OPTARG};;
        w) window_size=${OPTARG};;
        q) ave_qual=${OPTARG};;
        l) min_len=${OPTARG};;
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
narray=$(($nsamples-1))
slurm_script="./slurm-submission-scripts/merge_and_trim_${job_name}_`date -I`.q"
satid='"$SLURM_ARRAY_TASK_ID"'
satid2='${SLURM_ARRAY_TASK_ID}'

# set dirs
mkdir -p ${out_dir}
mkdir -p ${out_dir}/logs
mkdir -p ${out_dir}/logs/pe
mkdir -p ${out_dir}/logs/se
mkdir -p ${out_dir}/bbmerge_out
mkdir -p ${out_dir}/trimmomatic_out

# merging arrays
# R1
R1index=`for x in ${in_dir}/*R1.fastq; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
    R1index="(${R1index});"
        R1index=`sed -E 's@""@" \\\\\n"@g' <<< ${R1index}`
# R2
R2index=`for x in ${in_dir}/*R2.fastq; do
			echo -n '"'
			echo -n $(basename "$x")
			echo -n '"'
		done`
    R2index="(${R2index});"
        R2index=`sed -E 's@""@" \\\\\n"@g' <<< ${R2index}`
# merged out
merged_out_index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_merged.fastq
            echo -n '"'
			echo -n ${id}
			echo -n '"'
		done`
    merged_out_index="(${merged_out_index});"
        merged_out_index=`sed -E 's@""@" \\\\\n"@g' <<< ${merged_out_index}`
# paired out
paired_out_index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_paired.fastq
            echo -n '"'
			echo -n ${id}
			echo -n '"'
		done`
    paired_out_index="(${paired_out_index});"
        paired_out_index=`sed -E 's@""@" \\\\\n"@g' <<< ${paired_out_index}`
# trimmomatic base out index
Tbase_index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq).fastq
			echo -n '"'
			echo -n $id
			echo -n '"'
		done`
    Tbase_index="(${Tbase_index});"
        Tbase_index=`sed -E 's@""@" \\\\\n"@g' <<< ${Tbase_index}`
# P1 index
P1_index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_1P.fastq
            echo -n '"'
			echo -n ${id}
			echo -n '"'
		done`
    P1_index="(${P1_index});"
        P1_index=`sed -E 's@""@" \\\\\n"@g' <<< ${P1_index}`
# P2 index
P2_index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_2P.fastq
            echo -n '"'
			echo -n ${id}
			echo -n '"'
		done`
    P2_index="(${P2_index});"
        P2_index=`sed -E 's@""@" \\\\\n"@g' <<< ${P2_index}`
# summary index
sum_index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq).sum
            echo -n '"'
			echo -n ${id}
			echo -n '"'
		done`
    sum_index="(${sum_index});"
        sum_index=`sed -E 's@""@" \\\\\n"@g' <<< ${sum_index}`
# U1 index
U1_index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_1U.fastq
            echo -n '"'
			echo -n ${id}
			echo -n '"'
		done`
    U1_index="(${U1_index});"
        U1_index=`sed -E 's@""@" \\\\\n"@g' <<< ${U1_index}`
# U2 index
U2_index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_2U.fastq
            echo -n '"'
			echo -n ${id}
			echo -n '"'
		done`
    U2_index="(${U2_index});"
        U2_index=`sed -E 's@""@" \\\\\n"@g' <<< ${U2_index}`
# R0 index
R0_index=`for x in ${in_dir}/*R1.fastq; do
			id=$(basename "$x" _R1.fastq)_R0.fastq
            echo -n '"'
			echo -n ${id}
			echo -n '"'
		done`
    R0_index="(${R0_index});"
        R0_index=`sed -E 's@""@" \\\\\n"@g' <<< ${R0_index}`

# index pointers
R1_pointer='${R1_i[$i]}'
R2_pointer='${R2_i[$i]}'
merged_pointer='${merged_i[$i]}'
unmerged_pointer='${unmerged_i[$i]}'
Tbase_pointer='${Tbase_i[$i]}'
P1_pointer='${P1_i[$i]}'
P2_pointer='${P2_i[$i]}'
sum_pointer='${sum_i[$i]}'
U1_pointer='${U1_i[$i]}'
U2_pointer='${U2_i[$i]}'
R0_pointer='${R0_i[$i]}'

# write slurm script
echo "#!/bin/bash
#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time=${mtime}
#SBATCH -e ${out_dir}/logs/${job_name}_%A_%a.err
#SBATCH -o ${out_dir}/logs/${job_name}_%A_%a.out
#SBATCH --array=0-${narray}%${narray_at_once}

module load bbmap
module load trimmomatic

# bbmap arrays
R1_i=${R1index}
R2_i=${R2index}
merged_i=${merged_out_index}
unmerged_i=${paired_out_index}

# trimmomatic arrays
Tbase_i=${Tbase_index}
P1_i=${P1_index}
P2_i=${P2_index}
sum_i=${sum_index}
U1_i=${U1_index}
U2_i=${U2_index}
R0_i=${R0_index}

# main script
if [ ! -z ${satid2} ]
then
	i=${satid}

bbmerge.sh in=${in_dir}/${R1_pointer} in2=${in_dir}/${R2_pointer} out=${out_dir}/bbmerge_out/${merged_pointer} outu=${out_dir}/bbmerge_out/${unmerged_pointer} vstrict=t

# output is
# bbmerge_out/sample_merged.fastq <- SE reads
# bbmerge_out/sample_unmerged.fasta <- interleaved PE reads

bin/deinterleave_fastq.sh < ${out_dir}/bbmerge_out/${unmerged_pointer} ${out_dir}/bbmerge_out/${R1_pointer} ${out_dir}/bbmerge_out/${R2_pointer}

# output is:
# bbmerge_out/sample_merged.fastq <- unchanged from previous step
# bbmerge_out/sample_R1.fastq <- fwd and rev unmerged interleave pe reads now in separate files
# bbmerge_out/sample_R2.fastq <- fwd and rev unmerged interleave pe reads now in separate files

# trimmomatic pe
trimmomatic PE -threads 20 -summary ${out_dir}/logs/pe/${sum_pointer} ${out_dir}/bbmerge_out/${R1_pointer} ${out_dir}/bbmerge_out/${R2_pointer} -baseout ${out_dir}/trimmomatic_out/${Tbase_pointer} SLIDINGWINDOW:${window_size}:${ave_qual} MINLEN:${min_len}

# output is:
# trimmomatic_out/sample_1P.fastq
# trimmomatic_out/sample_2P.fastq
# trimmomatic_out/sample_1U.fastq
# trimmomatic_out/sample_2U.fastq

mv ${out_dir}/trimmomatic_out/${P1_pointer} ${out_dir}/${R1_pointer}
mv ${out_dir}/trimmomatic_out/${P2_pointer} ${out_dir}/${R2_pointer}

# output is:
# out_dir/sample_R1.fastq <- just changed filename from P to R
# out_dir/sample_R2.fastq <- just changed filename from P to R

# trimmomatic se
trimmomatic SE -threads 20 -summary ${out_dir}/logs/se/${sum_pointer} ${out_dir}/bbmerge_out/${merged_pointer} ${out_dir}/trimmomatic_out/${merged_pointer}

cat ${out_dir}/trimmomatic_out/${U1_pointer} ${out_dir}/trimmomatic_out/${U2_pointer} ${out_dir}/trimmomatic_out/${merged_pointer} > ${out_dir}/${R0_pointer}

else
	echo Error: missing array index as SLURM_ARRAY_TASK_ID
fi
" > ${slurm_script}

# push job to slurm
#sbatch ${slurm_script}
