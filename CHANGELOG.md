# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).  
The version numbering consists of three digits: `major.minor.patch`. The major
version is expected to increment following major structural changes to the
BACTpipe workflow.  Typically, any changes to the user interface (command line
arguments etc.), or output files will increment the minor version.
Under-the-hood changes that do not have an impact on how end-users run our
process the output will typically only increment the patch number.

Changes should fall into one of the following categories: 
- `Added`, for new features
- `Changed`, for changes in existing functionality
- `Deprecated`, for soon-to-be removed features.
- `Removed`, for now removed features.
- `Fixed`, for any bug fixes.

## [3.1.0] - In development
### Added
- New profile for use on CTMR Gandalf, `ctmr_gandalf`.
- Kraken2 added for taxonomic profiling, replaces sendsketch as contamination
  screen.
- Docker profile

### Changed
- Renamed profile for CTMR-NAS to `ctmr_nas` to better conform to incoming
  profiles.
- Moved contig renaming script to shovill process from contamination screen
  process.
- Now publishes `shovill.log` in the output directory by default.
- Limited the search scope for MultiQC to minimize risk of process timeouts on
  HPC systems.

### Removed
- Sendsketch replaced with Kraken2

## [3.0.0] - 2021-01-15
### Added
- A script was implemented that renames the headers of fasta-files.
- New optional flags to lessen storage use:
	`--keep_trimmed_fastq` will allow output of trimmed reads (default = not saved)
	`--keep_shovill_output` will output the assemblies from shovill, in conjunction
	with assembled genomes from prokka (default = only from prokka)
- Contamination screen is now parsed and used as taxonomic info for prokka.
- MultiQC now incorporates the trimmed QC reports as well.
- User now receives a file with compiled assemblystats, generated via BBmap's
  statswrapper. 

### Changed
- QC and trimming now done by FastP, not BBduk and FastQC, resulting in a much
  faster runtime.
- Contamination screening now done by Sendsketch.
- Contamination now ascertained from assemblies, not trimmed reads.
- BACTpipe now updated to DLS2-format.
- Updated BACTpipe now requires a newer Nextflow version.

### Removed
- BBduk no longer used.
- FastQC no longer used.
- Mashscreen no longer used.

### Deprecated


## [2.7.0] - 2019-01-16
### Added
- New command-line argument `--ignore_contamination_screen` will ignore all inputs
  that `FAIL` mash screen contamination check. 

### Changed
- Set default errorstrategy for Nextflow to `ignore`. 
- Updated process declarations to use new `withName` syntax.

### Removed
- The intermediate output from `mash screen` (i.e.  `<sample>.mash_screen.tsv`)
  is now removed from the output directory, in favor of the concatenated table
  `all_samples.mash_screening_results.tsv`, containing results for all samples.

### Deprecated


## [2.6.0] - 2018-05-28
### Added
- Created this changelog.
- New output file, `all_samples.mash_screening_results.tsv`, which is a concatenation
  of all individual mash screening results, intended to provide a better overview of
  the mash screening output for all samples.

### Changed
- Created separate `develop` branch to contain future code development separate
  from the `master` branch, which is now considered stable.
- Renamed `mash.screen` output folder to `mash_screen`, repacing the dot with
  an underscore.
- [Docs] Added note about single (e.g. `-profile`) vs double dash (e.g.
  `--reads`) command line arguments.

### Removed
- Removed outdated cluster configurations for UPPMAX's now defunct Milou cluster.

### Deprecated
- The intermediate output from `mash screen` (i.e.  `<sample>.mash_screen.tsv`)
  will be removed from the output directory in a future release.


## [2.5.3b] - 2018-05-03
### Changed
- Updated `assess_mash_screen.py` to v0.6.1b, fixing accidental PASS of failing
  samples.
