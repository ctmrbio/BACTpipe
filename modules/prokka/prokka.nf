nextflow.enable.dsl = 2

process PROKKA {
    tag { pair_id }
    publishDir "${params.output_dir}/prokka", mode: 'copy'

    input:
    tuple val(pair_id), path(contigs_file)
	path(classification)

    output:
    path("${pair_id}_prokka")

    script:
    prokka_reference_argument = ""
    if( params.prokka_reference ) {
        prokka_reference_argument = "--proteins ${params.prokka_reference}"
    }

    prokka_gramstain_argument = ""
    prokka_genus_argument = ""
    prokka_species_argument = ""

    """
    prokka \
        --cpus ${task.cpus} \
        --force \
        --evalue ${params.prokka_evalue} \
        --kingdom ${params.prokka_kingdom} \
        --locustag ${pair_id} \
        --outdir ${pair_id}_prokka \
        --prefix ${pair_id} \
        --strain ${pair_id} \
        ${prokka_reference_argument} \
        ${prokka_gramstain_argument} \
        ${prokka_genus_argument} \
        ${prokka_species_argument} \
        ${contigs_file}
    """

    stub:
    """
    mkdir ${pair_id}_prokka
    """

}

