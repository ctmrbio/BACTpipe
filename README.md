# bactpipe_nextflow
BACTpipe  implemented in Nextflow

## Requirements
* nextflow.config file
* Reference genomes for both Mauve and prokka
* Raw fastq format paired end read files
* Adapters file

## Dependencies

Make sure to install the following software and have the executables in your `$PATH`:

* Mauve's (http://darlinglab.org/mauve/download.html) `progressiveMauve` executable

* tbl2asn (https://www.ncbi.nlm.nih.gov/genbank/tbl2asn2/) `tbl2asn` executable


## Run bactpipe.nf 

1. Modify the nextflow.config file including the 

* project - SLURM project
* reads - Read input file format file, default "*_{R1,R2}.fastq.gz"
* adapters - Path to bbduk adapters.fa file
* mauve_ref - Path to the complete genome file to be used by mauve order_contigs tool
* mauve_path - Path to Mauve executable Mauve.jar
* prokka_ref - Path to the protein fasta file to be used as primary annotation source
* output_dir - Path to the directory for output, default "./results"

2. Place the bactpipe.nf and the nextflow.config file or symbolic links to them in the folder containing the raw fastq files

3. Invoke the nextflow script
*  `nextflow run bactpipe.nf`
*  Options: `-resume` (in case you make a rerun from any step of the pipeline)
