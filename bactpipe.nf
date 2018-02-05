#!/usr/bin/env nextflow
// vim: syntax=groovy expandtab

bactpipe_version = '2.1b-dev'
nf_required_version = '0.26.0'

log.info "".center(60, "=")
log.info "BACTpipe".center(60)
log.info "Version ${bactpipe_version}".center(60)
log.info "Bacterial whole genome analysis pipeline".center(60)
log.info "https://bactpipe.readthedocs.io".center(60)
log.info "".center(60, "=")

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


Channel
    .fromFilePairs( params.reads )
    .ifEmpty { 
        log.error "Cannot find any reads matching: ${params.reads}\n\n" + 
                  "Did you specify --reads 'path/to/*_{1,2}.fastq.gz'? (note the single quotes)"
        exit(1)
    }
    .into { mash_input;
            read_pairs }


// Set up the file objects required by some processes
ref_sketches = file( params.mashscreen_database )
bbduk_adapters = file( params.bbduk_adapters )


process screen_for_contaminants {
    validExitStatus 0,3
    tag { pair_id }
    publishDir "${params.output_dir}/mash.screen", mode: 'copy'

    input:
    set pair_id, file(reads) from mash_input

    output:
    set pair_id, stdout into screening_results
    file("${pair_id}.mash_screen.tsv")
    file("${pair_id}.screening_results.tsv")

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
        --pipeline \
        --outfile ${pair_id}.screening_results.tsv \
        ${pair_id}.mash_screen.tsv 
    """
}


/*
 * Check screening results. Print warning for samples that did not pass.
 * Continue only with samples that pass the contaminant screening step.
 */
pure_isolates = screening_results.filter { 
    def passed=it[1] == "PASS"
    if ( ! passed ) {
        log.warn "'${it[0]}' might not be a pure isolate! Check screening results in the output folder."
    }
    return passed
}
bbduk_input = pure_isolates.join(read_pairs).map {[it[0], it[2]]}


process bbduk {
    tag {pair_id}
    publishDir "${params.output_dir}/bbduk", mode: 'copy'

    input:
    set pair_id, file(reads) from bbduk_input
    file bbduk_adapters

    output:
    set pair_id, file("${pair_id}_{1,2}.trimmed.fastq.gz") into fastqc_input, shovill
    file "${pair_id}.stats.txt"

    script:
    """
    bbduk.sh \
        in1=${reads[0]} \
        in2=${reads[1]} \
        ref=${bbduk_adapters} \
        out1=${pair_id}_1.trimmed.fastq.gz \
        out2=${pair_id}_2.trimmed.fastq.gz \
        stats=${pair_id}.stats.txt \
        threads=${task.cpus} \
        minlen=30 \
        qtrim=rl \
        trimq=10 \
        ktrim=r \
        k=30 \
        mink=11 \
        hdist=1 \
        trimbyoverlap \
        trimpairsevenly
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
         --depth 100 \
         --kmers 31,33,55,77,99,127 \
         --minlen 500 \
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


process prokka {
    tag {sample_id}
    publishDir "${params.output_dir}/prokka", mode: 'copy'

    input:
    set sample_id, file(renamed_contigs) from prokka_channel

    output:
    set sample_id, file("${sample_id}_prokka") into prokka_out

    """
    prokka \
        --force \
        --addgenes \
        --evalue 1e-12 \
        --kingdom Bacteria \
        --locustag ${sample_id} \
        --outdir ${sample_id}_prokka \
        --prefix ${sample_id} \
        --strain ${sample_id} \
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
    println ( "".center(60, "=") )
    if ( workflow.success ) {
        println ( "BACTpipe workflow completed without errors".center(60) )
    } else {
        println ( "Oops .. something went wrong!".center(60) )
    }
    println ( "Check output files in folder:".center(60) )
    println ( "${params.output_dir}".center(60) )
    println ( "".center(60, "=") )
}

