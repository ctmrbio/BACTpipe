Installation
============
BACTpipe pipeline is written in Nextflow and runs on Linux and Mac OSX systems.

Dependencies
************
In order to run BACTpipe, you need to have the following programs installed:

- `Java v8+`_ for nextflow 
- `Nextflow`_ for workflow management, more specifically `v21.04.0`_
- `Conda`_ for installation of workflow tools
- (Optionally) `Kraken db`_ when you'd like to classify taxonomy as well

.. _Java v8+: https://www.java.com/sv/download/help/download_options.xml
.. _Nextflow: https://www.nextflow.io/
.. _v21.04.0: https://github.com/nextflow-io/nextflow/releases/download/v21.04.0/nextflow-21.04.0-all
.. _Conda: https://docs.conda.io/en/latest/
.. _Kraken db: http://ccb.jhu.edu/software/kraken2/index.shtml?t=downloads


Install BACTpipe
****************
After installing all the beforementioned dependencies, BACTpipe (`Github
repository`_) will itself install the software needed for the process using
conda when running the pieline. 

.. _Github repository: https://github.com/ctmrbio/BACTpipe/tree/master


Quick guide on how to install most tools
****************************************

1. Java v8+: https://anaconda.org/cyclus/java-jdk
2. Nextflow: https://www.nextflow.io/docs/latest/getstarted.html#installation
3. Conda: https://docs.conda.io/projects/conda/en/latest/user-guide/install/#
4. Kraken database: http://ccb.jhu.edu/software/kraken2/index.shtml?t=downloads

.. tip::
   We have included a `download script <https://github.com/ctmrbio/BACTpipe/tree/master/resources/download_kraken_db.sh` for the `Kraken DB` within the repository.
