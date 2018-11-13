#!/bin/bash

####
#
####

# set params & help
help_message=""

usage="Usage: $(basename "$0") 
{-d /path/to/database}
{-i /input/file/fastaORfastq}
{-o /output/goes/here.d100}
{-u /unaligned/queries/go/here.fasta}
{-j job_name}
{-t max run time hh:mm:ss}
[-h print this message]"

while getopts hd:i:o:j:t:u: option; do
	case "${option}" in
		h) echo "$hmessage"
		   echo "$usage"
		   exit;;
		d) database=$OPTARG;;
		i) in_file=$OPTARG;;
		o) out_file=$OPTARG;;
		u) un_al_queries=$OPTARG;;
		j) job_name=$OPTARG;;
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
slurm_script=/OSM/CBR/NCMI_AGOF/work/metaFly/slurm-submission-scripts/diamond_nt_${job_name}

# write slurm script
echo "#!/bin/bash

#SBATCH -J ${job_name}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --mem=128GB
#SBATCH --time=${max_time}
#SBATCH -e /flush1/gof005/diamond_nt_${job_name}_%A.err
#SBATCH -o /flush1/gof005/diamond_nt_${job_name}_%A.out

module load diamond bioref blast+

diamond blastx \
--threads 20 \
--db ${database} \
--out ${out_file} \
--outfmt 100 \
--query ${in_file} \
--strand both \
--un ${un_al_queries} \
--top 10 \
--min-orf 20 \
--block-size 9
" > ${slurm_script}

# pushing script to slurm
#sbatch slurm-submission-script/${slurm_script}







