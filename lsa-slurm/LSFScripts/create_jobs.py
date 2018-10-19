#!/usr/bin/env python

import sys, getopt
import glob, os

# MergeHash can maybe go on the hour queue

JobParams = {
	'CreateHash': {
		'outfile': """CreateHash_Job.q""",
		'header': ["""#SBATCH -J CreateHash""","""#SBATCH -o PROJECT_HOME/Logs/CreateHash-Out.out""","""#SBATCH -e PROJECT_HOME/Logs/CreateHash-Err.err""","""#SBATCH -t 24:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		'body': ["""python LSA/create_hash.py -i PROJECT_HOME/original_reads/ -o PROJECT_HOME/hashed_reads/ -k 33 -s 31"""]},

	'HashReads': {
		'outfile': """HashReads_ArrayJob.q""",
		'array': ["""original_reads/""","""*.fastq.*"""],
		'header': ["""#SBATCH --array=1-""","""#SBATCH -J HashReads""","""#SBATCH -o PROJECT_HOME/Logs/HashReads-Out-%A.out""","""#SBATCH -e PROJECT_HOME/Logs/HashReads-Err-%A.err""","""#SBATCH -t 02:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		# add -z option to omit reverse complimenting
		'body': ["""sleep $(($SLURM_ARRAY_TASK_ID % 60))""","""python LSA/hash_fastq_reads.py -r ${SLURM_ARRAY_TASK_ID} -i PROJECT_HOME/original_reads/ -o PROJECT_HOME/hashed_reads/"""]},

	'MergeHash': {
		'outfile': """MergeHash_ArrayJob.q""",
		'array': ["""original_reads/""","""*.fastq""",5],
		'header': ["""#SBATCH --array=1-""","""#SBATCH -J MergeHash""","""#SBATCH -o PROJECT_HOME/Logs/MergeHash-Out-%A.out""","""#SBATCH -e PROJECT_HOME/Logs/MergeHash-Err-%A.err""","""#SBATCH -t 02:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		'body': ["""sleep $(($SLURM_ARRAY_TASK_ID % 60))""","""python LSA/merge_hashq_files.py -r ${SLURM_ARRAY_TASK_ID} -i PROJECT_HOME/hashed_reads/ -o PROJECT_HOME/hashed_reads/"""]},

	'CombineFractions': {
		'outfile': """CombineFractions_ArrayJob.q""",
		'array': ["""original_reads/""","""*.fastq""",1],
		'header': ["""#SBATCH --array=1-""","""#SBATCH -J CombineFractions""","""#SBATCH -o PROJECT_HOME/Logs/CombineFractions-Out-%A.out""","""#SBATCH -e PROJECT_HOME/Logs/CombineFractions-Err-%A.err""","""#SBATCH -t 24:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		'body': ["""sleep $(($SLURM_ARRAY_TASK_ID % 60))""","""python LSA/merge_hashq_fractions.py -r ${SLURM_ARRAY_TASK_ID} -i PROJECT_HOME/hashed_reads/ -o PROJECT_HOME/hashed_reads/"""]},

	'GlobalWeights': {
		'outfile': """GlobalWeights_Job.q""",
		'header': ["""#SBATCH -J GlobalWeights""","""#SBATCH -o PROJECT_HOME/Logs/GlobalWeights-Out.out""","""#SBATCH -e PROJECT_HOME/Logs/GlobalWeights-Err.err""","""#SBATCH -t 24:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		'body': ["""python LSA/tfidf_corpus.py -i PROJECT_HOME/hashed_reads/ -o PROJECT_HOME/cluster_vectors/"""]},

	'KmerCorpus': {
		'outfile': """KmerCorpus_ArrayJob.q""",
		'array': ["""hashed_reads/""","""*.count.hash"""],
		'header': ["""#SBATCH --array=1-""","""#SBATCH -J KmerCorpus""","""#SBATCH -o PROJECT_HOME/Logs/KmerCorpus-Out-%A.out""","""#SBATCH -e PROJECT_HOME/Logs/KmerCorpus-Err-%A.err""","""#SBATCH -t 02:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		'body': ["""sleep $(($SLURM_ARRAY_TASK_ID % 60))""","""python LSA/kmer_corpus.py -r ${SLURM_ARRAY_TASK_ID} -i PROJECT_HOME/hashed_reads/ -o PROJECT_HOME/cluster_vectors/"""]},

	'KmerLSI': {
		'outfile': """KmerLSI_Job.q""",
		'header': ["""#SBATCH -J KmerLSI""","""#SBATCH -o PROJECT_HOME/Logs/KmerLSI-Out.out""","""#SBATCH -e PROJECT_HOME/Logs/KmerLSI-Err.err""","""#SBATCH -t 02:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13""","""python -m Pyro4.naming -n 0.0.0.0 > PROJECT_HOME/Logs/nameserver.log 2>&1 &""","""P1=$!""","""python -m gensim.models.lsi_worker > PROJECT_HOME/Logs/worker1.log 2>&1 &""","""P2=$!""","""python -m gensim.models.lsi_worker > PROJECT_HOME/Logs/worker2.log 2>&1 &""","""P3=$!""","""python -m gensim.models.lsi_worker > PROJECT_HOME/Logs/worker3.log 2>&1 &""","""P4=$!""","""python -m gensim.models.lsi_worker > PROJECT_HOME/Logs/worker4.log 2>&1 &""","""P5=$!""","""python -m gensim.models.lsi_worker > PROJECT_HOME/Logs/worker5.log 2>&1 &""","""P6=$!""","""python -m gensim.models.lsi_dispatcher > PROJECT_HOME/Logs/dispatcher.log 2>&1 &""","""P7=$!"""],
		'body': ["""python LSA/kmer_lsi.py -i PROJECT_HOME/hashed_reads/ -o PROJECT_HOME/cluster_vectors/""","""kill $P1 $P2 $P3 $P4 $P5 $P6 $P7"""]},

	'KmerClusterIndex': {
		'outfile': """KmerClusterIndex_Job.q""",
		'header': ["""#SBATCH -J KmerClusterIndex""","""#SBATCH -o PROJECT_HOME/Logs/KmerClusterIndex-Out.out""","""#SBATCH -e PROJECT_HOME/Logs/KmerClusterIndex-Err.err""","""#SBATCH -t 02:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		# adjust cluster thresh (-t) as necessary
		'body': ["""python LSA/kmer_cluster_index.py -i PROJECT_HOME/hashed_reads/ -o PROJECT_HOME/cluster_vectors/ -t 0.7""","""python LSFScripts/create_jobs.py -j KmerClusterParts -i ./""","""X=`sed -n 1p hashed_reads/hashParts.txt`""","""sed -i 's/%parts%/$X/g' LSFScripts/KmerClusterParts_ArrayJob.q""","""python LSFScripts/create_jobs.py -j LSFScripts/KmerClusterMerge -i ./""","""X=`sed -n 1p cluster_vectors/numClusters.txt`""","""sed -i 's/%clusters%/$X/g' LSFScripts/KmerClusterMerge_ArrayJob.q"""]},

	'KmerClusterParts': {
		'outfile': """KmerClusterParts_ArrayJob.q""",
		# number of tasks is 2**hash_size/10**6 + 1
		#'array': ["""hashed_reads/""","""*.hashq.*"""],
		'header': ["""#SBATCH --array=1-%parts%""","""#SBATCH -J KmerClusterParts""","""#SBATCH -o PROJECT_HOME/Logs/KmerClusterParts-Out-%A.out""","""#SBATCH -e PROJECT_HOME/Logs/KmerClusterParts-Err-%A.err""","""#SBATCH -t 02:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		###!!!
		# adjust cluster thresh (-t) as necessary - probably same as Index step (maybe slightly higher)
		###!!!
		'body': ["""sleep $(($SLURM_ARRAY_TASK_ID % 60))""","""python LSA/kmer_cluster_part.py -r ${SLURM_ARRAY_TASK_ID} -i PROJECT_HOME/hashed_reads/ -o PROJECT_HOME/cluster_vectors/ -t 0.7"""]},
	
	'KmerClusterMerge': {
		'outfile': """KmerClusterMerge_ArrayJob.q""",
		# number of tasks is number of clusters
		#'array': ["""hashed_reads/""","""*.hashq.*"""],
		'header': ["""#SBATCH --array=1-%clusters%""","""#SBATCH -J KmerClusterMerge""","""#SBATCH -o PROJECT_HOME/Logs/KmerClusterMerge-Out-%A.out""","""#SBATCH -e PROJECT_HOME/Logs/KmerClusterMerge-Err-%A.err""","""#SBATCH -t 02:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		'body': ["""sleep $(($SLURM_ARRAY_TASK_ID % 60))""","""python LSA/kmer_cluster_merge.py -r ${SLURM_ARRAY_TASK_ID} -i PROJECT_HOME/cluster_vectors/ -o PROJECT_HOME/cluster_vectors/"""]},

	'KmerClusterCols': {
		'outfile': """KmerClusterCols_Job.q""",
		'header': ["""#SBATCH -J KmerClusterCols""","""#SBATCH -o PROJECT_HOME/Logs/KmerClusterCols-Out.out""","""#SBATCH -e PROJECT_HOME/Logs/KmerClusterCols-Err.err""","""#SBATCH -t 24:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		'body': ["""python LSA/kmer_cluster_cols.py -i PROJECT_HOME/hashed_reads/ -o PROJECT_HOME/cluster_vectors/"""]},

	'ReadPartitions': {
		'outfile': """ReadPartitions_ArrayJob.q""",
		'array': ["""hashed_reads/""","""*.hashq.*"""],
		# MAKE SURE TO SET TMP FILE LOCATION
		'header': ["""#SBATCH --array=1-""","""#SBATCH -J ReadPartitions""","""#SBATCH -o PROJECT_HOME/Logs/ReadPartitions-Out-%A.out""","""#SBATCH -e PROJECT_HOME/Logs/ReadPartitions-Err-%A.err""","""#SBATCH -t 24:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		'body': ["""sleep $(($SLURM_ARRAY_TASK_ID % 60))""","""python LSA/write_partition_parts.py -r ${SLURM_ARRAY_TASK_ID} -i PROJECT_HOME/hashed_reads/ -o PROJECT_HOME/cluster_vectors/ -t /flush1/gof005"""]},

	'MergeIntermediatePartitions': {
		'outfile': """MergeIntermediatePartitions_ArrayJob.q""",
		'array': ["""cluster_vectors/""","""*.cluster.npy"""],
		'header': ["""#SBATCH --array=1-""","""#SBATCH -J MergeIntermediatePartitions""","""#SBATCH -o PROJECT_HOME/Logs/MergeIntermediatePartitions-Out-%A.out""","""#SBATCH -e PROJECT_HOME/Logs/MergeIntermediatePartitions-Err-%A.err""","""#SBATCH -t 02:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		'body': ["""sleep $(($SLURM_ARRAY_TASK_ID % 60))""","""python LSA/merge_partition_parts.py -r ${SLURM_ARRAY_TASK_ID} -i PROJECT_HOME/cluster_vectors/ -o PROJECT_HOME/read_partitions/"""]},
	# Check to make sure there are no files remaining in cluster_vectors/PARTITION_NUM/
	
	'SplitPairs': {
		'outfile': """SplitPairs_ArrayJob.q""",
		'array': ["""cluster_vectors/""","""*.cluster.npy"""],
		'header': ["""#SBATCH --array=1-""","""#SBATCH -J SplitPairs""","""#SBATCH -o PROJECT_HOME/Logs/SplitPairs-Out-%A.out""","""#SBATCH -e PROJECT_HOME/Logs/SplitPairs-Err-%A.err""","""#SBATCH -t 02:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		'body': ["""sleep $(($SLURM_ARRAY_TASK_ID % 60))""","""python LSA/split_read_pairs.py -r ${SLURM_ARRAY_TASK_ID} -i PROJECT_HOME/read_partitions/ -o PROJECT_HOME/read_partitions/"""]},
	
	'PhylerClassify': {
		'outfile': """PhylerClassify_ArrayJob.q""",
		'array': ["""cluster_vectors/""","""*.cluster.npy"""],
		'header': ["""#SBATCH --array=1-""","""#SBATCH -J PhylerClassify""","""#SBATCH -o PROJECT_HOME/Logs/PhylerClassify-Out-%A.out""","""#SBATCH -e PROJECT_HOME/Logs/PhylerClassify-Err-%A.err""","""#SBATCH -t 02:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13""","""source /broad/software/scripts/useuse""","""reuse BLAST"""],
		'body': ["""sleep $(($SLURM_ARRAY_TASK_ID % 60))""","""python misc/phyler_classify.py -r ${SLURM_ARRAY_TASK_ID} -i PROJECT_HOME/read_partitions/ -o PROJECT_HOME/phyler/"""]},

	'PhylerIdentify': {
		'outfile': """PhylerIdentify_ArrayJob.q""",
		'array': ["""cluster_vectors/""","""*.cluster.npy"""],
		'header': ["""#SBATCH --array=1-""","""#SBATCH -J PhylerIdentify""","""#SBATCH -o PROJECT_HOME/Logs/PhylerIdentify-Out-%A.out""","""#SBATCH -e PROJECT_HOME/Logs/PhylerIdentify-Err-%A.err""","""#SBATCH -t 02:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		'body': ["""sleep $(($SLURM_ARRAY_TASK_ID % 60))""","""python misc/phyler_identify.py -r ${SLURM_ARRAY_TASK_ID} -i PROJECT_HOME/read_partitions/ -o PROJECT_HOME/phyler/"""]},
	
	'PhylerSummary': {
		'outfile': """PhylerSummary_Job.q""",
		'header': ["""#SBATCH -J PhylerSummary""","""#SBATCH -o PROJECT_HOME/Logs/PhylerSummary-Out.out""","""#SBATCH -e PROJECT_HOME/Logs/PhylerSummary-Err.err""","""#SBATCH -t 02:00:00""","""#SBATCH --nodes=1""","""#SBATCH --mem=128GB""","""module load python/2.7.13"""],
		'body': ["""python misc/phyler_summary.py -i PROJECT_HOME/phyler/"""]}
}

CommonElements = {
	'header': ["""#!/bin/bash"""],
	'body': ["""echo Date: `date`""","""t1=`date +%s`"""],
	'footer': ["""[ $? -eq 0 ] || echo 'JOB FAILURE: $?'""","""echo Date: `date`""","""t2=`date +%s`""","""tdiff=`echo 'scale=3;('$t2'-'$t1')/3600' | bc`""","""echo 'Total time:  '$tdiff' hours'"""]
}
					
help_message = 'usage example: python create_jobs.py -j HashReads -i /project/home/'
if __name__ == "__main__":
	job = 'none specified'
	try:
		opts, args = getopt.getopt(sys.argv[1:],'hj:i:',["--jobname","inputdir="])
	except:
		print help_message
		sys.exit(2)
	for opt, arg in opts:
		if opt in ('-h','--help'):
			print help_message
			sys.exit()
		elif opt in ('-j',"--jobname"):
			job = arg
		elif opt in ('-i','--inputdir'):
			inputdir = arg
			if inputdir[-1] != '/':
				inputdir += '/'
	try:
		params = JobParams[job]
	except:
		print job+' is not a known job.'
		print 'known jobs:',JobParams.keys()
		print help_message
		sys.exit(2)
	if params.get('array',None) != None:
		FP = glob.glob(os.path.join(inputdir+params['array'][0],params['array'][1]))
		if len(params['array']) == 3:
			FP = [fp[fp.rfind('/')+1:] for fp in FP]
			if params['array'][2] == -1:
				suffix = params['array'][1].replace('*','').replace('.','')
				FP = set([fp[:fp.index(suffix)] for fp in FP])
			else:
				FP = set([fp[:fp.index('.')] for fp in FP])
			FP = [None]*len(FP)*abs(params['array'][2])
		array_size = str(len(FP))
		params['header'][0] += array_size
		print job+' array size will be '+array_size
	f = open(inputdir+'LSFScripts/'+params['outfile'],'w')
	f.write('\n'.join(CommonElements['header']) + '\n')
	f.write('\n'.join(params['header']).replace('PROJECT_HOME/',inputdir) + '\n')
	f.write('\n'.join(CommonElements['body']) + '\n')
	f.write('\n'.join(params['body']).replace('PROJECT_HOME/',inputdir) + '\n')
	f.write('\n'.join(CommonElements['footer']) +'\n')
	f.close()
	
