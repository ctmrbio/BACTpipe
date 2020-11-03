#!/usr/bin/env nextflow
// vim: syntax=groovy expandtab

bactpipe_version = '3.E'
nf_required_version = '19.10.0'

log.info "".center(60, "=")
log.info "BACTpipe".center(60)
log.info "Version ${bactpipe_version}".center(60)
log.info "Bacterial whole genome analysis pipeline".center(60)
log.info "https://bactpipe.readthedocs.io".center(60)
log.info "".center(60, "=")

params.help = false
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


try {
    if ( ! nextflow.version.matches(">= $nf_required_version") ){
        throw GroovyException('Nextflow version too old')
    }
} catch (all) {
    log.error "\n" +
              "".center(60, "=") + "\n" +
              "BACTpipe requires Nextflow version $nf_required_version!".center(60) + "\n" +
              "You are running version $workflow.nextflow.version.".center(60) + "\n" +
              "Please run `nextflow self-update` to update Nextflow.".center(60) + "\n" +
              "".center(60, "=") + "\n"
    exit(1)
}

if (workflow['profile'] in params.profiles_that_require_project) {
    if (!params.project) {
        log.error "BACTpipe requires that you set the 'project' parameter when running the ${workflow['profile']} profile.\n".center(60) +
                  "Specify --project <project_name> on the command line, or tuple it in a custom configuration file.".center(60)
        exit(1)
    }
}

if ( params.help ) {
    printHelp()
    exit(0)
}
printSettings()


try {
    Channel
        .fromFilePairs( params.reads )
        .ifEmpty { 
            log.error "Cannot find any reads matching: '${params.reads}'\n\n" + 
                      "Did you specify --reads 'path/to/*_{1,2}.fastq.gz'? (note the single quotes)\n" +
                      "Specify --help for a summary of available commands."
            printHelp()
            exit(1)
        }
        .into { fastp_input;
                read_pairs }
} catch (all) {
    log.error "It appears params.reads is empty!\n" + 
              "Did you specify --reads 'path/to/*_{1,2}.fastq.gz'? (note the single quotes)\n" +
              "Specify --help for a summary of available commands."
    exit(1)
}


process fastp {
    tag {pair_id}
    publishDir "${params.output_dir}/fastp", mode: 'copy'

    input:
    tuple pair_id, file(reads) from fastp_input

    output:
    tuple pair_id, file("${pair_id}_{1,2}.fastp.fq.gz") into shovill
    file("${pair_id}.json") into fastp_reports

    """
    fastp \
        --in1 ${reads[0]} \
        --in2 ${reads[1]} \
        --out1 ${pair_id}_1.fastp.fq.gz \
        --out2 ${pair_id}_2.fastp.fq.gz \
        --json ${pair_id}.json \
        --html ${pair_id}.html \
        --thread ${task.cpus}
    """
}


process shovill {
    tag {pair_id}
    publishDir "${params.output_dir}/shovill", mode: 'copy'

    input:
    tuple pair_id, file(reads) from shovill

    output:
    tuple pair_id, file("${pair_id}.contigs.fa") into prokka_input, stats_input, sendsketch_input
    file("${pair_id}_shovill/*.{fasta,fastg,log,fa,gfa,changes,hist,tab}") 
    
    """
    shovill \
         --depth ${params.shovill_depth} \
         --kmers ${params.shovill_kmers} \
         --minlen ${params.shovill_minlen} \
         --R1 ${reads[0]} \
         --R2 ${reads[1]} \
         --outdir ${pair_id}_shovill
    cp ${pair_id}_shovill/contigs.fa ${pair_id}.contigs.fa
    """
}


process screen_for_contaminants {
    tag { pair_id }
    publishDir "${params.output_dir}/sendsketch", mode: 'copy'

    input:
    tuple pair_id, file("${pair_id}.contigs.fa") from sendsketch_input

    output:
    file("${pair_id}.sendsketch.txt")
//  stdout gramstain_result

    script:
    """
    sendsketch.sh \
        in=${pair_id}.contigs.fa \
        samplerate=0.1 \
        out=${pair_id}.sendsketch.txt \
    """
/*
 *  sendsketch_stainer.py \
 *      ${pair_id}.sendsketch.txt \ 
 *     "$projectDir/resources/gram_stain.txt"
 */
}

process prokka {
    tag {pair_id}
    publishDir "${params.output_dir}/prokka", mode: 'copy'

    input:
    tuple pair_id, file("${pair_id}.contigs.fa") from prokka_input
//  val "gramstain" from gramstain_result

    output:
    tuple pair_id, file("${pair_id}_prokka") into prokka_out

    script:

    prokka_reference_argument = ""
    if (params.prokka_reference) {
        prokka_reference_argument = "--proteins ${params.prokka_reference}"
    }
/*
 *  prokka_gramstain_argument = ""
 *  if (gramstain == "pos") {
 *      prokka_gramstain_argument = "--gram pos"
 *  } else if (gramstain == "neg") {
 *      prokka_gramstain_argument = "--gram neg"
 *  } else {
 *      prokka_gramstain_argument = ""
 *  }
 */    
    """
    prokka \
        --force \
        --evalue ${params.prokka_evalue} \
        --kingdom ${params.prokka_kingdom} \
        --locustag ${pair_id} \
        --outdir ${pair_id}_prokka \
        --prefix ${pair_id} \
        --compliant \
        ${prokka_reference_argument} \
        ${pair_id}.contigs.fa
    """
//      ${prokka_gramstain_argument} \

}


process assembly_stats {
    tag {pair_id}
    publishDir "${params.output_dir}/shovill", mode: 'copy'

    input:
    tuple pair_id, file("${pair_id}.contigs.fa") from stats_input

    output:
    file("${pair_id}.assembly_stats.txt")
    
    """
    statswrapper.sh \
        in=${pair_id}.contigs.fa \
        > ${pair_id}.assembly_stats.txt        
    """
}


process multiqc {
    publishDir "${params.output_dir}/multiqc", mode: 'copy'

    input:
    file(fastp:'fastp/*.json') from fastp_reports.collect()
    file(prokka:'prokka/*') from prokka_out.collect()

    output:
    file('multiqc_report.html')  

    script:

    """
    multiqc . --filename multiqc_report.html
    """
}


workflow.onComplete { 
    log.info "".center(60, "=")
    if ( workflow.success ) {
        log.info "BACTpipe workflow completed without errors".center(60)
    } else {
        log.error "Oops .. something went wrong!".center(60)
    }
    log.info "Check output files in folder:".center(60)
    log.info "${params.output_dir}".center(60)
    log.info "".center(60, "=")
}

