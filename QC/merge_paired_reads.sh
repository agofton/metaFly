#!/bin/bash
#SBATCH -J merge_pairs_Mvet_AC
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --time 00:30:00
#SBATCH -e flush1/gof005/merge_pairs_Mvet_AC_%A.err
#SBATCH -o flush1/gof005/merge_pairs_Mvet_AC_%A.out

module load bbmap

for x in /flush1/gof005/M_vet_raw_data/*R1.fastq
    do
        rev=$(basename "$x" R1.fastq)R2.fastq
        prefix=$(basename "$x" _R1.fasta) 

        bbmap \
            in=${x} \
            in2=${in_dir}/${rev}
            out=/flush1/M_vet_merged2/${prefix}_merged.fastq \
            outu=/flush1/M_vet_merged2/${prefix}_paired.fastq \
            vstrict=t
done