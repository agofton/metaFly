#!/bin/bash
#SBATCH -J SplitInput
#SBATCH -o Logs/SplitInput-Out-%A.out
#SBATCH -e Logs/SplitInput-Err-%A.err
#SBATCH -t 24:00:00:
#SBATCH --array=1-5
echo Date: `date`
t1=`date +%s`
sleep ${SLURM_ARRAY_TASK_ID}
python LSFScripts/array_merge.py -r ${SLURM_ARRAY_TASK_ID} -i /OSM/CBR/NCMI_AGOF/work/metaFly_test/lsa_in/ -o original_reads/
[ $? -eq 0 ] || echo 'JOB FAILURE: $?'
echo Date: `date`
t2=`date +%s`
tdiff=`echo 'scale=3;('$t2'-'$t1')/3600' | bc`
echo 'Total time:  '$tdiff' hours'
