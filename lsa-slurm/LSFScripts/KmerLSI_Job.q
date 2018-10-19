#!/bin/bash
#SBATCH -J KmerLSI
#SBATCH -o ./Logs/KmerLSI-Out.out
#SBATCH -e ./Logs/KmerLSI-Err.err
#SBATCH -t 02:00:00
python -m Pyro4.naming -n 0.0.0.0 > ./Logs/nameserver.log 2>&1 &
P1=$!
python -m gensim.models.lsi_worker > ./Logs/worker1.log 2>&1 &
P2=$!
python -m gensim.models.lsi_worker > ./Logs/worker2.log 2>&1 &
P3=$!
python -m gensim.models.lsi_worker > ./Logs/worker3.log 2>&1 &
P4=$!
python -m gensim.models.lsi_worker > ./Logs/worker4.log 2>&1 &
P5=$!
python -m gensim.models.lsi_worker > ./Logs/worker5.log 2>&1 &
P6=$!
python -m gensim.models.lsi_dispatcher > ./Logs/dispatcher.log 2>&1 &
P7=$!
echo Date: `date`
t1=`date +%s`
python LSA/kmer_lsi.py -i ./hashed_reads/ -o ./cluster_vectors/
kill $P1 $P2 $P3 $P4 $P5 $P6 $P7
[ $? -eq 0 ] || echo 'JOB FAILURE: $?'
echo Date: `date`
t2=`date +%s`
tdiff=`echo 'scale=3;('$t2'-'$t1')/3600' | bc`
echo 'Total time:  '$tdiff' hours'
