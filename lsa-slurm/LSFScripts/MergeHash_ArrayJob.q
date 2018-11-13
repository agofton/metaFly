#!/bin/bash
#SBATCH --array=1-50
#SBATCH -J MergeHash
#SBATCH -o ./Logs/MergeHash-Out-%A.out
#SBATCH -e ./Logs/MergeHash-Err-%A.err
#SBATCH -t 00:30:00
#SBATCH --nodes=1
#SBATCH --mem=128GB
module load python/2.7.13
echo Date: `date`
t1=`date +%s`
sleep $(($SLURM_ARRAY_TASK_ID % 60))
python LSA/merge_hashq_files.py -r ${SLURM_ARRAY_TASK_ID} -i ./hashed_reads/ -o ./hashed_reads/
[ $? -eq 0 ] || echo 'JOB FAILURE: $?'
echo Date: `date`
t2=`date +%s`
tdiff=`echo 'scale=3;('$t2'-'$t1')/3600' | bc`
echo 'Total time:  '$tdiff' hours'
