BACTpipe introduction and overview
==================================
BACTpipe uses whole genome shotgun sequenced, paired end reads, to assemble and annotate single bacterial genomes.

.. image:: img/flowchart.png
    :alt: Flowchart showing BACTpipe pipeline.
    :align: center

BACTpipe's analysis flow starts with a screening of the input reads to verify that they are
likely to be from a pure isolate (one species) using Mash-screen. If this is the case the pipeline continues
with pre-processing of paired end reads in fastq format using bbduk, quality evaluation using 
FastQC, de novo assembly using Shovill, including contig renaming and, finally, genome annotation 
using prokka. Basic statistics about the assembly and annotation is collected using MultiQC.

BACTpipe is implemented in Nextflow and an overview of the workflow can be seen below.
Output files are marked in blue.
