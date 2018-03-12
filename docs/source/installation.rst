Installation
============
BACTpipe pipeline is written in Nextflow and runs on Linux and Mac OSX systems.

Dependencies
************
In order to run BACTpipe, you need to have the following programs installed:

- `Java v8+`_ for nextflow 
- `Nextflow`_ for workflow management
- `mash`_ for fast sequence contamination screening
- `BBMap`_ (specifically; ``bbduk.sh``, ``reformat.sh``, ``stats.sh``/``statswrapper.sh``) 
  for quality filtering/trimming, and general format wrangling
- `FastQC`_ for quality control
- `Shovill`_ for sequence assembly
- `prokka`_ for contig annotation
- `tbl2asn2`_ for annotation format convertion
- `signalP`_ for prediction of signal peptides features in CDS of both gram neg and gram pos bacteria
- `MultiQC`_ for general statistics

.. _Java v8+: https://www.java.com/sv/download/help/download_options.xml
.. _Nextflow: https://www.nextflow.io/
.. _mash: https://genomeinformatics.github.io/mash-screen/
.. _BBmap: https://sourceforge.net/projects/bbmap/
.. _FastQC: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
.. _Shovill: https://github.com/tseemann/shovill
.. _prokka: https://github.com/tseemann/prokka
.. _tbl2asn2: https://www.ncbi.nlm.nih.gov/genbank/tbl2asn2/
.. _signalP: http://www.cbs.dtu.dk/services/SignalP/
.. _MultiQC: http://multiqc.info
	 
Install BACTpipe
****************
After installing all the beforementioned dependencies, you need to get the BACTpipe code from
the `Github repository`_. 

.. _Github repository: https://github.com/ctmrbio/BACTpipe/tree/master


Quick guide on how to install most tools
****************************************

1. Java v8+: https://anaconda.org/cyclus/java-jdk
2. mash: https://anaconda.org/bioconda/mash
3. MultiQC: https://anaconda.org/bioconda/multiqc
4. Shovill: https://anaconda.org/bioconda/shovill
5. BBMap: https://anaconda.org/bioconda/bbmap
6. FastQC: https://anaconda.org/biobuilds/fastqc
7. signalP: http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?signalp
8. prokka: https://github.com/tseemann/prokka#installation

Installing using conda into the ``base`` environment
*****************************************************

``(base)$ conda install java mash multiqc shovill bbmap fastqc``


Installing into a specific ``bactpipe_env`` conda environment::
***************************************************************

$ conda create -n bactpipe_env python=3 java mash multiqc shovill bbmap fastqc 
$ conda activate bactpipe_env
(bactpipe_env)$

N.B Note that ``signalP`` is not available for installation via conda, and must be installed manually according to instructions from the ``signalP`` authors.
