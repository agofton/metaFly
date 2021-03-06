#!/bin/bash

# From the merged R1.fastq file, goes back and extracts the raw R1 and R2 reads that went into the merging.
# now metaSPAdes and IDBA_UD can be run on the merged/QC'd data using the paired reads as required.

# set params & help
usage="Usage: $(basename "$0") -m /path/to/R0/folder -u /path/to/raw/unmerged/data -o /out/put/goes/here [-h show this help]"

while getopts hm:u:o: option
do
	case "${option}"
	in
		h) echo "$usage"
		   exit;;
		m) merged_dir=$OPTARG;;
    	u) unmerged_dir=$OPTARG;;
		o) out_dir=$OPTARG;;
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
echo "Making output directories..."

mkdir ${out_dir}
mkdir ${out_dir}/seq_IDs
mkdir ${out_dir}/tmp

sleep 5
echo""

# set vars
usearch="/OSM/CBR/NCMI_AGOF/work/metaFly/bin/usearch9.2"

# get R1 and R2 seq ids from R0.fq - either from mergeing & QC or after host mapping

echo "STEP 1: Finding R1 and R2 seq IDs..."

for x in ${merged_dir}/*R0*; do
	echo ""
	echo -n $(basename $x)
	y=$(basename $x)
	# write R1 seq ids to AJxx.R0.r1.seqIDs
	R1_ids=${y:0:4}.R0.r1.seqIDs
	cat $x | grep "^@HWI" | sed -E 's/^@//g' | sed -e 's/2:N/1:N/g' > ${out_dir}/seq_IDs/${R1_ids}
	# write R2 seq ids to AJxx.R0.r2.seqIDs
	R2_ids=${y:0:4}.R0.r2.seqIDs
	cat ${out_dir}/seq_IDs/${R1_ids} | sed -E 's/1:N/2:N/g' > ${out_dir}/seq_IDs/${R2_ids}
	echo "...DONE"
done

# extract R1 reads
echo ""
echo "STEP 2: Extracting R1 reads from raw fastq files..."

for x in ${unmerged_dir}/*R1.fastq; do
	echo ""
	echo $(basename $x)
	echo ""
	y=$(basename $x)
	r1_labels=${out_dir}/seq_IDs/${y:0:4}.R0.r1.seqIDs
	r1_fq_out=${out_dir}/tmp/${y:0:4}.R0.r1.fq
	${usearch} -fastx_getseqs ${x} -labels ${r1_labels} -fastqout ${r1_fq_out}
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
done

# extract R2
echo ""
echo "STEP 3: Extracting R2 reads from raw fastq files..."
echo ""

for x in ${unmerged_dir}/*R2.fastq; do
	echo ""
	echo $(basename $x)
	echo ""
	y=$(basename $x)
	r2_labels=${out_dir}/seq_IDs/${y:0:4}.R0.r2.seqIDs
	r2_fq_out=${out_dir}/tmp/${y:0:4}.R0.r2.fq
	${usearch} -fastx_getseqs ${x} -labels ${r2_labels} -fastqout ${r2_fq_out}
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
done

# make sure R1 and R2 are perfect matches
echo ""
echo "STEP 4: Checking R1 and R2 files match perfectly..."
echo ""

for x in ${out_dir}/tmp/*r1.fq; do
	echo ""
	echo $(basename $x)
	echo ""
	r2=$(basename $x r1.fq)r2.fq
	repair.sh in=${x} in2=${r2} out=${out_dir}/$(basename $x) out2=${out_dir}/${r2}
done
