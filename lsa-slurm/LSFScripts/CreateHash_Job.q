#!/bin/bash
#SBATCH -J CreateHash
#SBATCH -o ./Logs/CreateHash-Out.out
#SBATCH -e ./Logs/CreateHash-Err.err
#SBATCH -t 02:00:00
#SBATCH --nodes=1
#SBATCH --mem=128GB
<<<<<<< HEAD:lsa-slurm/LSFScripts/CreateHash_Job.q
module load python/2.7.13
=======
>>>>>>> parent of f3ac50c... added assemble mod:lsa/LSFScripts/CreateHash_Job.q
echo Date: `date`
t1=`date +%s`
python LSA/create_hash.py -i ./original_reads/ -o ./hashed_reads/ -k 33 -s 31
[ $? -eq 0 ] || echo 'JOB FAILURE: $?'
echo Date: `date`
t2=`date +%s`
tdiff=`echo 'scale=3;('$t2'-'$t1')/3600' | bc`
echo 'Total time:  '$tdiff' hours'
