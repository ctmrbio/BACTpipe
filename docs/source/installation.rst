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
.. _MultiQC: http://multiqc.info
.. _tbl2asn2: https://www.ncbi.nlm.nih.gov/genbank/tbl2asn2/
.. _signalP: http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?signalp
	 
Install BACTpipe
****************
After installing all the beforementioned dependencies, you need to get the BACTpipe code from
the `Github repository`_. 

.. _Github repository: https://github.com/ctmrbio/BACTpipe/tree/master


Quick guide on how to install most tools
****************************************

.. _Java v8+: https://anaconda.org/cyclus/java-jdk
.. _mash: https://anaconda.org/bioconda/mash
.. _MultiQC: https://anaconda.org/bioconda/multiqc
.. _Shovill: https://anaconda.org/bioconda/shovill
.. _BBMap: https://anaconda.org/bioconda/bbmap
.. _FastQC: https://anaconda.org/biobuilds/fastqc
.. _signalP: http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?signalp
