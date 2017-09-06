# bactpipe_nextflow
BACTpipe  implemented in Nextflow

## Important gotchas
* Make sure to put Mauve's `progressiveMauve` binary in your `$PATH` before
  running, otherwise the Mauve step will fail.

## Run bactpipe.nf 
 
*  nextflow run bactpipe.nf
* Options: -resume (in case you make a rerun of the pipeline)

## Requirements
* nextflow.config file
* Reference genomes for both Mauve and prokka
* Fastq read files
* Adapters file
