BACTpipe introduction and overview
==================================
BACTpipe uses whole genome shotgun sequenced paired end reads, preferably by
Illumina MiSeq, to assemble and annotate single bacterial genomes.

.. image:: img/flowchart.png
    :alt: Flowchart showing BACTpipe pipeline.
    :align: center

BACTpipe's analysis flow starts with pre-processing of paired end reads in
fastq format, quality evaluation using FastQC, de novo assembly using Shovill,
assembly filtering using a customized Pearl script, contig ordering using
Mauve, contig renaming using a customized python script and genome annotation
using prokka. Intermediate output files from each analysis step are indicated
by arrows.  
