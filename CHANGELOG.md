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

## [2.7.0]
### Added
- New command-line argument `--ignore_contamination_screen` will ignore all inputs
  that `FAIL` mash screen contamination check. 

### Changed

### Removed
- The intermediate output from `mash screen` (i.e.  `<sample>.mash_screen.tsv`)
  is now removed from the output directory, in favor of the concatenated table
  `all_samples.mash_screening_results.tsv`, containing results for all samples.

### Deprecated


## [2.6.0]
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
