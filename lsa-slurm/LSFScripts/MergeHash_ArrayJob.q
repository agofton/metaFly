#!/bin/bash
#SBATCH --array=1-0
#SBATCH -J MergeHash
#SBATCH -o ./Logs/MergeHash-Out-%A-%a.out
#SBATCH -e ./Logs/MergeHash-Err-%A-%a.err
#SBATCH -t 02:00:00
echo Date: `date`
t1=`date +%s`
sleep $(($SLURM_ARRAY_TASK_ID % 60))
python LSA/merge_hashq_files.py -r ${SLURM_ARRAY_TASK_ID} -i ./hashed_reads/ -o ./hashed_reads/
[ $? -eq 0 ] || echo 'JOB FAILURE: $?'
echo Date: `date`
t2=`date +%s`
tdiff=`echo 'scale=3;('$t2'-'$t1')/3600' | bc`
echo 'Total time:  '$tdiff' hours'
