Running BACTpipe
================
After installing all the required dependencies, it is very easy to run
BACTpipe. There are several ways to run BACTpipe, but we'll start with the
easiest::

    $ nextflow run cmtrbio/BACTpipe --reads 'path/to/reads/*_R{1,2}.fastq.gz'

This will instruct Nextflow to go to the ``ctmrbio`` Github organization to
download and run the ``BACTpipe`` workflow. The argument ``--reads`` is used to
tell the workflow which input files you want to run BACTpipe on. Note that the
path to the reads must be enclosed in single quotes (``'``), to prevent the
shell from automatically expanding asterisks (``*``) and curly braces (``{}``).
In the above example, the part of the filename matched by the asterisk will be
used as the sample name in BACTpipe, and ``{1,2}`` refers to the pair of FASTQ
files for paired-end data.  Input data should be in FASTQ, and can be either
plain FASTQ, or compressed with gzip or bzip2 (with ``.gz`` or ``.bz2`` file
suffixes). 

When BACTpipe is run like this, it by default assumes you want to run
everything locally, on the current machine. Since we didn't specify the paths
to the sketches for mash screen or the adapters for BBDuk, BACTpipe will detect
this and download the missing reference files. They can be specified using
``--mashscreen_database`` and ``--bbduk_adapters`` for future runs, or by
adding the paths to a configuration file (see more details about configuration
files below).

Note thatBACTpipe is capable of running on practically any machine, ranging
from laptops to powerful multicore machines to high-performance computing (HPC)
clusters. 

.. _BACTpipe repository: https://www.github.com/ctmrbio/BACTpipe


Changing settings on the command line
-------------------------------------
When running BACTpipe, you will most likely have to modify the paths for some
parameters so that BACTpipe can find reference databases etc. Luckily, it is
possible to modify several settings for how BACTpipe operates using
configuration parameters. All changes can be added as command-line arguments
when running BACTpipe, e.g.::

    $ nextflow run ctmrbio/BACTpipe --bbduk_mink 8 --reads 'path/to/reads/*_{1,2}.fastq.gz'

The ``--bbduk_mink`` flag will modify the minimum kmer length for BBDuk. The 
following parameters can be easily configured from the command line::

    Parameter name        Default setting
    output_dir            BACTpipe_results
    reads                 [empty]  
    mashscreen_database   Path to refseq minhash sketches for Mash screen
    bbduk_adapters        Path to adapters.fa for BBDuk filtering
    bbduk_minlen          30
    bbduk_qtrim           rl
    bbduk_trimq           10
    bbduk_ktrim           r
    bbduk_k               30
    bbduk_mink            11
    bbduk_hdist           1
    bbduk_trimbyoverlap   trimbyoverlap
    bbduk_trimpairsevenly trimpairsevenly
    shovill_depth         100
    shovill_kmers         31,33,55,77,99,127
    shovill_minlen        500
    prokka_evalue         1e-09
    prokka_kingdom        Bacteria
    prokka_reference      [not used]
    prokka_gram_stain     [not used]

To modify any parameter, just add ``--<parameter_name> <new_setting>`` on the
command line when running BACTpipe, e.g. ``--shovill_depth 75`` to set
Shovill's depth parameter to 75 instead of 100.  Refer to ``params.config`` in
the ``conf`` directory of the `BACTpipe repository`_ for a complete up-to-date
listing of all available parameters. 


Change many settings at once
............................
If you want to change many different settings at the same time when running
BACTpipe, it can quickly result in very long command lines. A way to make it
easier to change several parameters at once is to create a custom configuration
file in YAML or JSON format that you give to BACTpipe using ``-params-file``::

    $ nextflow run ctmrbio/BACTpipe -params-file path/to/your/custom/params.yaml --reads 'path/to/reads/*_{1,2}.fastq.gz'

This parameter settings in your custom configuration file will override the
default settings. The simplest format for the custom parameters file is probably
YAML. Here is an example that modifies some shovill parameters and the BBDuk quality
trimming value::

    bbduk_qtrim: "20"
    shovill_depth: "100"
    shovill_kmers: "31,33,55,77,99,111,127"
    shovill_minlen: "400"


Profiles
--------
A convenient way to modify the way BACTpipe is run is to load a profile. BACTpipe 
comes with a few pre-installed profiles:

* ``standard`` -- For local use on e.g. a laptop or Linux server.
* ``rackham`` -- For use on UPPMAX's Rackham HPC system. Note however, that it
  is currently preconfigured specifically for use within CTMR project folders.
* ``milou`` -- For use on UPPMAX's now decomissioned Milou HPC system.
* ``ctmrnas`` -- For use on CTMR's internal analysis server.
 
To run BACTpipe with a specific profile, use the ``-profile <profilename>`` argument
when running, e.g.::

    $ nextflow run ctmrbio/BACTpipe -profile rackham --reads '/proj/projectname/reads/*_{1,2}.fastq.gz'

This will run BACTpipe using the ``rackham`` profile, which automatically
configures settings so BACTpipe can find all the required software and
databases in the CTMR project folders. Running BACTpipe without a ``-profile``
argument will default to running the ``standard`` profile.


Custom profile
--------------
It is possible to create a custom profile to use instead of the preconfigured
ones. The best way to start is probably to download one of the pre-existing
profiles from ``conf`` directory of the `BACTpipe repository`_. 

If you are working on a Slurm-managed system, starting with ``rackham.config``
would be a good choice, as Rackham is also a Slurm-managed HPC system. Download 
the configuration file from the ``conf`` directory of the `BACTpipe repository`_
and modify settings to your preference. Then, to run BACTpipe using your custom
configuration file, you need to tell Nextflow to read parameters from your file instead
of the default parameters::

    $ nextflow run ctmrbio/BACTpipe -params-file path/to/your/custom/profile.config --reads 'path/to/reads/*_{1,2}.fastq.gz'

The custom profile is not limited to configuring time, cpu, and memory limits
for the different processes. It is also possible to set parameter values inside
the custom profile, to change e.g. paths to reference databases or runtime
parameters for the different processes. It is also possible to just use a configuration
file that changes settings, without modifying how the workflow is run, see below.


