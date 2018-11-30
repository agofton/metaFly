#!/bin/bash

#SBATCH -J lastnrdb
#SBATCH --time=48:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --mem=128GB

module load last/843


lastdb -P 20 nt_last_db ../genbank_nt/nt.fa
