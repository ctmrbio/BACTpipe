
def printHelp() {
    log.info """
    Example usage:
    nextflow run ctmrbio/BACTpipe --reads '*_R{1,2}.fastq.gz'

    Mandatory arguments:
      --reads                Path to input data (must be surrounded with single quotes).

    Output options:
      --output_dir           Output directory, where results will be saved (default: ${params.output_dir}).

    Refer to the online manual for more information on available options:
               https://bactpipe.readthedocs.io
    """
}

def printSettings() {
    log.info "Running with the following settings:".center(60)
    for (option in params) {
        if (option.key in ['cluster-options', 'help']) {
            continue
        }
        log.info "${option.key}: ".padLeft(30) + "${option.value}"
    }
    log.info "".center(60, "=")
}
