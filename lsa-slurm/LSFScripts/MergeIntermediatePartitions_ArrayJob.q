#!/bin/bash
#SBATCH --array=1-0
#SBATCH -J MergeIntermediatePartitions
#SBATCH -o ./Logs/MergeIntermediatePartitions-Out-%A-%a.out
#SBATCH -e ./Logs/MergeIntermediatePartitions-Err-%A-%a.err
#SBATCH -t 02:00:00
echo Date: `date`
t1=`date +%s`
sleep $(($SLURM_ARRAY_TASK_ID % 60))
python LSA/merge_partition_parts.py -r ${SLURM_ARRAY_TASK_ID} -i ./cluster_vectors/ -o ./read_partitions/
[ $? -eq 0 ] || echo 'JOB FAILURE: $?'
echo Date: `date`
t2=`date +%s`
tdiff=`echo 'scale=3;('$t2'-'$t1')/3600' | bc`
echo 'Total time:  '$tdiff' hours'
