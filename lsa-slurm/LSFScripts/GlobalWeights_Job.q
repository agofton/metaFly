#!/bin/bash
#SBATCH -J GlobalWeights
#SBATCH -o ./Logs/GlobalWeights-Out.out
#SBATCH -e ./Logs/GlobalWeights-Err.err
#SBATCH -t 00:20:00
#SBATCH --nodes=1
#SBATCH --mem=128GB
module load python/2.7.13
echo Date: `date`
t1=`date +%s`
python LSA/tfidf_corpus.py -i ./hashed_reads/ -o ./cluster_vectors/
[ $? -eq 0 ] || echo 'JOB FAILURE: $?'
echo Date: `date`
t2=`date +%s`
tdiff=`echo 'scale=3;('$t2'-'$t1')/3600' | bc`
echo 'Total time:  '$tdiff' hours'
