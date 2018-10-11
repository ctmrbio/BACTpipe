#!/usr/bin/env nextflow
// vim: syntax=groovy expandtab

bactpipe_version = '2.7.0-dev'
nf_required_version = '0.26.0'

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
    nextflow run ctmrbio/BACTpipe --mashscreen_database path/to/refseq.genomes.k21s1000.msh --reads '*_R{1,2}.fastq.gz'

    Mandatory arguments:
      --reads                Path to input data (must be surrounded with single quotes).
      --mashscreen_database  Path to mash screen database (can be omitted if set in config file).

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
                  "Specify --project <project_name> on the command line, or set it in a custom configuration file.".center(60)
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
        .into { mash_input;
                read_pairs }
} catch (all) {
    log.error "It appears params.reads is empty!\n" + 
              "Did you specify --reads 'path/to/*_{1,2}.fastq.gz'? (note the single quotes)\n" +
              "Specify --help for a summary of available commands."
    exit(1)
}


try {
    if (file(params.mashscreen_database).exists()) {
    Channel
        .fromPath(params.mashscreen_database)
        .set { ref_sketches_ch }
    } else { 
        throw Exception("mashscreen_database error")
   }
} catch (all) {
    mashscreen_db_url = "https://gembox.cbcb.umd.edu/mash/refseq.genomes.k21s1000.msh"
    log.error "Cannot load mashscreen_database: '${params.mashscreen_database}'\n" +
              "Did you specify --mashscreen_database on the command line or set\n" +
              "it in a config file? Download from:\n" +
              "${mashscreen_db_url}"
    exit(1)
}


process screen_for_contaminants {
    validExitStatus 0,3
    tag { pair_id }

    input:
    set pair_id, file(reads) from mash_input
    each file(ref_sketches) from ref_sketches_ch

    output:
    set pair_id, stdout into screening_results_for_bbduk, screening_results_for_prokka, screening_results_for_phiX
    file("${pair_id}.screening_results.tsv") into screening_results_to_concatenate

    script:
    """
    mash screen \
        -w \
        -p ${task.cpus} \
        ${ref_sketches} \
        ${reads[0]} \
        ${reads[1]} \
        > ${pair_id}.mash_screen.tsv \
    && \
    assess_mash_screen.py \
        --gram "$baseDir/resources/gram_stain.txt"  \
        ${pair_id}.mash_screen.tsv \
        | tee ${pair_id}.screening_results.tsv
    """
}


process concatenate_mash_screen_results {
    publishDir "${params.output_dir}/mash_screen", mode: 'copy'

    input:
    file(screening_results) from screening_results_to_concatenate.collect()

    output:
    file("all_samples.mash_screening_results.tsv")

    script:
    """
    cat ${screening_results} > all_samples.mash_screening_results.tsv
    """
}


/*
 * Check screening results. Print warning for samples that did not pass.
 * Continue only with samples that pass the contaminant screening step.
 */
pure_isolates = screening_results_for_bbduk.filter {
    screening_result = it[1].split("\t")[1]
    passed = screening_result == "PASS"
    if ( ! passed ) {
        log.warn "'${it[0]}' might not be a pure isolate! Check screening results in the output folder."
        if ( params.ignore_contamination_screen ) {
            log.warn "Ignoring warning for '${it[0]}' (ignore_contamination_screen=true)."
            passed = true
        }
    }
    return passed
}
bbduk_input = pure_isolates.join(read_pairs).map {[it[0], it[2]]}

phiX_detected = false
screening_results_for_phiX.filter {
    phiX = it[1].split("\t")[2]
    if ( phiX.length() != 0 ) {
        log.warn "'${it[0]}' appears to be contaminated with phiX! Adding phiX removal to BBDuk filtering."
        phiX_detected = true
    }
}


process bbduk {
    tag {pair_id}
    publishDir "${params.output_dir}/bbduk", mode: 'copy'

    input:
    set pair_id, file(reads) from bbduk_input

    output:
    set pair_id, file("${pair_id}_{1,2}.trimmed.fastq.gz") into fastqc_input, shovill
    file "${pair_id}.stats.txt"

    script:
    if (params.bbduk_adapters == "" || params.bbduk_adapters == "adapters") {
        bbduk_adapters = params.bbduk_adapters
    } else {
        bbduk_adapters = file(params.bbduk_adapters)
    }
    if (phiX_detected) {
        bbduk_adapters = "phix,${bbduk_adapters}"
    }
    """
    bbduk.sh \
        in1=${reads[0]} \
        in2=${reads[1]} \
        ref=${bbduk_adapters} \
        out1=${pair_id}_1.trimmed.fastq.gz \
        out2=${pair_id}_2.trimmed.fastq.gz \
        stats=${pair_id}.stats.txt \
        threads=${task.cpus} \
        minlen=${params.bbduk_minlen} \
        qtrim=${params.bbduk_qtrim} \
        trimq=${params.bbduk_trimq} \
        ktrim=${params.bbduk_ktrim} \
        k=${params.bbduk_k} \
        mink=${params.bbduk_mink} \
        hdist=${params.bbduk_hdist} \
        ${params.bbduk_trimbyoverlap} \
        ${params.bbduk_trimpairsevenly}
    """
}


process fastqc {
    tag {pair_id}
    publishDir "${params.output_dir}/fastqc", mode: 'copy'

    input:
    set pair_id, file(clean_reads) from fastqc_input

    output:
    file("*_fastqc.{zip,html}") into fastqc_output

    """
    fastqc \
        --quiet \
        --threads ${task.cpus} \
        ${clean_reads} 
    """
}


process shovill {
    tag {pair_id}
    publishDir "${params.output_dir}/shovill", mode: 'copy'

    input:
    set pair_id, file(reads) from shovill

    output:
    set pair_id, file("${pair_id}.contigs.fa") into prokka_channel
    file("${pair_id}_shovill/*.{fasta,fastg,log,fa,gfa,changes,hist,tab}") 
    file("${pair_id}.assembly_stats.txt")
    
    """
    shovill \
         --depth ${params.shovill_depth} \
         --kmers ${params.shovill_kmers} \
         --minlen ${params.shovill_minlen} \
         --R1 ${reads[0]} \
         --R2 ${reads[1]} \
         --outdir ${pair_id}_shovill \
    && \
    cp ${pair_id}_shovill/contigs.fa ${pair_id}.contigs.fa \
    && \
    statswrapper.sh \
        in=${pair_id}.contigs.fa \
        > ${pair_id}.assembly_stats.txt
    """
}


/*
 * Read expected gram stain from the assess_mash_screen output,
 * for use in Prokka.
 * Explanation of how this works:
 * from_shovill = [pair_id, contigs.fa]
 * from_screen = [pair_id, "sample\tPASS\tneg\tHelicobacter pylori"]
 * prokka_input = [pair_id, contigs.fa, "sample\tPASS\tneg\tHelicobacter pylori"]
 */
prokka_input = prokka_channel.join(screening_results_for_prokka).map {
    [it[0], it[1], it[2].split("\t")[3]]
}


process prokka {
    tag {sample_id}
    publishDir "${params.output_dir}/prokka", mode: 'copy'

    input:
    set sample_id, file(renamed_contigs), gram_stain from prokka_input

    output:
    set sample_id, file("${sample_id}_prokka") into prokka_out

    script:
    prokka_reference_argument = ""
    if (params.prokka_reference) {
        prokka_reference_argument = "--proteins ${params.prokka_reference}"
    }
    gram_stain_argument = ""
    # If ignore_contamination_screen is used, gram_stain is a string with
    # potentially several comma-separated gram stain assignments. We just
    # use the first one.
    if ( gram_stain.split(", ").size() > 1 ) {
        gram_stain = gram_stain.split(", ")[0]
    }
    if (gram_stain) {
        gram_stain_argument = "--gram ${gram_stain}"
    }
    if (params.prokka_gram_stain) {
        gram_stain_argument = "--gram ${params.prokka_gram_stain}"
        log.warn "Overriding automatically determined gram stain (${gram_stain}) " +
                    "due to user configured setting (${params.prokka_gram_stain})."
    }
    
    """
    prokka \
        --force \
        --evalue ${params.prokka_evalue} \
        --kingdom ${params.prokka_kingdom} \
        --locustag ${sample_id} \
        --outdir ${sample_id}_prokka \
        --prefix ${sample_id} \
        --strain ${sample_id} \
        ${params.prokka_reference} \
        ${prokka_reference_argument} \
        ${gram_stain_argument} \
        $renamed_contigs
    """
}

process multiqc {
    publishDir "${params.output_dir}/multiqc", mode: 'copy'

    input:
    file(fastqc:'fastqc/*') from fastqc_output.collect()
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

