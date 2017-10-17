Installation
============
BACTpipe is written in Nextflow and is designed to run on Linux systems.

Dependencies
************
In order to run BACTpipe, you need to have the following programs installed:

- `Nextflow`_ for workflow management
- `Mauve`_ for contig reordering
- `tbl2asn2`_ for annotation format convertion
- `BBMap`_ (specifically; ``bbduk.sh``, ``reformat.sh``, ``stats.sh``/``statswrapper.sh``) 
  for quality filtering/trimming, and general format wrangling
- `FastQC`_ for quality control
- `prokka`_ for contig annotation
- `Shovill`_ for sequence assembly

.. _Nextflow: https://www.nextflow.io/
.. _Mauve: http://darlinglab.org/mauve/mauve.html
.. _tbl2asn2: https://www.ncbi.nlm.nih.gov/genbank/tbl2asn2/
.. _BBmap: https://sourceforge.net/projects/bbmap/
.. _FastQC: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
.. _SPAdes: http://bioinf.spbau.ru/spades
.. _prokka: https://github.com/tseemann/prokka
.. _Shovill: https://github.com/tseemann/shovill

Install BACTpipe
****************
After installing all the beforementioned dependencies, you need to get the BACTpipe code from
the `Github repository`_. 

.. _Github repository: https://github.com/ctmrbio/BACTpipe
