BACTpipe introduction and overview
==================================
BACTpipe uses whole genome shotgun sequenced, paired end reads, to assemble and
annotate single bacterial genomes.

.. image:: img/BACTpipe_flowchart.jpg
    :alt: Flowchart showing BACTpipe pipeline.
    :align: center

BACTpipe's analysis flow starts with a screening of the input reads to verify
that they are likely to be from a pure isolate (one species) using ``mash
screen``.  If this is the case the pipeline continues with pre-processing of
paired end reads in fastq format using bbduk, performs quality evaluation using
FastQC, *de-novo* assembly using Shovill, and finally, genome annotation using
prokka. Basic statistics about the assembly and annotation are collected into a
HTML report using MultiQC.

BACTpipe is implemented in Nextflow and an overview of the workflow can be seen
below. Output files are marked in blue.
