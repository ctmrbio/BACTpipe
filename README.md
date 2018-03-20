# BACTpipe
BACTpipe implemented in Nextflow.

Bactpipe uses Nexflow as a workflow tool manager. It takes paired end fastq
files as input and performs pre-processing, quality assessment, de novo
assembly and annotation of the genome. 

![BACTpipe flowchart](./docs/source/img/BACTpipe_workflow.jpg)

## Documentation
Complete documentation is available at https://bactpipe.readthedocs.io. 


## Requirements
* nextflow.config file
* Raw fastq format paired end read files
* Adapters file


## Dependencies
Make sure to install the following software and have the executables in your `$PATH`:

* Nextflow (https://www.nextflow.io/) `nextflow` executable to run the pipeline
* tbl2asn (https://www.ncbi.nlm.nih.gov/genbank/tbl2asn2/) `tbl2asn` executable
* `bbduk` executable from BBMap (https://github.com/BioInfoTools/BBMap)


## Run bactpipe.nf 
1. Modify the nextflow.config file including the 

* reads - Read input file format file, default `"*_{R1,R2}.fastq.gz"`
* adapters - Path to bbduk `adapters.fa` file
* prokka_ref - Path to the protein fasta file to be used as primary annotation source, for details, see https://github.com/tseemann/prokka#fasta-database-format


2. Provide  the path to the executable file `bactpipe.nf` in the folder containing the raw read files

3. Invoke the nextflow script
*  `nextflow run bactpipe.nf -profile ctmrnas --reads '*_R{1,2}.fastq.gz'`
*  Options: `-resume` (in case you make a rerun from any step of the pipeline)


## License
This pipeline is published under the MIT license 2017


## Authors
Joseph Kirangwa (@b16joski), 
Sandra Alvarez-Carretero (@sabifo4),
Fredrik Boulund (@boulund),
Kaisa Thorell (@thorellk)
