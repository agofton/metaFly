#!/bin/bash
#SBATCH -J KmerClusterCols
#SBATCH -o ./Logs/KmerClusterCols-Out.out
#SBATCH -e ./Logs/KmerClusterCols-Err.err
#SBATCH -t 24:00:00
echo Date: `date`
t1=`date +%s`
python LSA/kmer_cluster_cols.py -i ./hashed_reads/ -o ./cluster_vectors/
[ $? -eq 0 ] || echo 'JOB FAILURE: $?'
echo Date: `date`
t2=`date +%s`
tdiff=`echo 'scale=3;('$t2'-'$t1')/3600' | bc`
echo 'Total time:  '$tdiff' hours'
