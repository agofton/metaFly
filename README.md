# metaFly
## metaFly is a workflow under development assembly and taxonomically characterise the metagenome of flies, however, could also be applicable to other hosts.
## Workflow:
### 1) read QC with trimmomatic and usearch
### 2) filtering host (fly) reads with bowtie2 map-to-ref, and megablast for host-read mopup
### 3) pre-assembly read binning with LSA
### 4) assembly of bins with SPAdes
### 5) taxonomic assignment of contigs with ...
### 6) taxonomic assignment of reads with kraken2/centrifuge/blast-MEGAN
### 7) ...still in development...
