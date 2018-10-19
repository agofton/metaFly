#!/bin/bash
#SBATCH -J KmerClusterIndex
#SBATCH -o ./Logs/KmerClusterIndex-Out.out
#SBATCH -e ./Logs/KmerClusterIndex-Err.err
#SBATCH -t 02:00:00
echo Date: `date`
t1=`date +%s`
python LSA/kmer_cluster_index.py -i ./hashed_reads/ -o ./cluster_vectors/ -t 0.7
python LSFScripts/create_jobs.py -j KmerClusterParts -i ./
X=`sed -n 1p hashed_reads/hashParts.txt`
sed -i 's/%parts%/$X/g' LSFScripts/KmerClusterParts_ArrayJob.q
python LSFScripts/create_jobs.py -j LSFScripts/KmerClusterMerge -i ./
X=`sed -n 1p cluster_vectors/numClusters.txt`
sed -i 's/%clusters%/$X/g' LSFScripts/KmerClusterMerge_ArrayJob.q
[ $? -eq 0 ] || echo 'JOB FAILURE: $?'
echo Date: `date`
t2=`date +%s`
tdiff=`echo 'scale=3;('$t2'-'$t1')/3600' | bc`
echo 'Total time:  '$tdiff' hours'
