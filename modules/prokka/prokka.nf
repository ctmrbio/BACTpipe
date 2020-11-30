
process PROKKA {
    tag { pair_id }
    publishDir "${params.output_dir}/prokka", mode: 'copy'

    input:
    tuple val(pair_id), path("${pair_id}.contigs.fa")

    output:
    path("${pair_id}_prokka")

    script:

    prokka_reference_argument = ""
    if (params.prokka_reference) {
        prokka_reference_argument = "--proteins ${params.prokka_reference}"
    }

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
}
